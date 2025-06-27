// lib/screens/cashier/dashboard/services/dashboard_data_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_data.dart';

/// 🎯 Think of this as your "Personal Assistant" that goes and gets
/// all the information you need for your dashboard
class DashboardDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 This gets ALL the dashboard data at once
  /// It's like asking your assistant to bring you everything you need for work
  Future<DashboardData> fetchDashboardData() async {
    try {
      // Get all the data at the same time with timeouts
      final results = await Future.wait(
        [
          _getTodayCollections().timeout(
            const Duration(seconds: 10),
            onTimeout: () => {'total': 0.0},
          ),
          _getWeeklyCollections().timeout(
            const Duration(seconds: 10),
            onTimeout: () => {'total': 0.0, 'spots': <FlSpot>[]},
          ),
          _getTodayTransactions().timeout(
            const Duration(seconds: 10),
            onTimeout: () => 0,
          ),
          _getRecentTransactions().timeout(
            const Duration(seconds: 10),
            onTimeout: () => <TransactionModel>[],
          ),
          _getMonthlyCollections().timeout(
            const Duration(seconds: 10),
            onTimeout: () => {'total': 0.0, 'breakdown': <String, double>{}},
          ),
        ],
        cleanUp: (successValue) {
          // Log successful queries for debugging
          print('Successfully fetched dashboard data component');
        },
        eagerError: false, // Continue even if some queries fail
      );

      // Put all the pieces together, handling potential null values
      return DashboardData(
        todayCollections: (results[0] as Map)['total'] as double? ?? 0.0,
        weeklyCollections: (results[1] as Map)['total'] as double? ?? 0.0,
        todayTransactions: results[2] as int? ?? 0,
        recentTransactions: results[3] as List<TransactionModel>? ?? [],
        monthlyCollections:
            (results[4] as Map)['breakdown'] as Map<String, double>? ?? {},
        monthTarget: 1000000.0, // You can make this configurable later
        monthProgress:
            ((results[4] as Map)['total'] as double? ?? 0.0) / 1000000.0,
        weeklyCollectionSpots:
            (results[1] as Map)['spots'] as List<FlSpot>? ?? [],
      );
    } catch (e) {
      print('❌ Error fetching dashboard data: $e');
      // Return empty data instead of throwing
      return DashboardData.empty();
    }
  }

  /// 🎯 Get how much money was collected today
  Future<Map<String, dynamic>> _getTodayCollections() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('payments')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          total += (amount as num).toDouble();
        }
      }

      return {'total': total};
    } catch (e) {
      print('❌ Error fetching today collections: $e');
      return {'total': 0.0};
    }
  }

  /// 🎯 Get this week's collections and create chart data
  Future<Map<String, dynamic>> _getWeeklyCollections() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekMidnight =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('payments')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekMidnight))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
          .orderBy('timestamp', descending: false)
          .get();

      // Initialize daily totals (Monday = 0, Sunday = 6)
      Map<int, double> dailyTotals = {};
      for (int i = 0; i < 7; i++) {
        dailyTotals[i] = 0;
      }

      double weeklyTotal = 0;

      // Process each payment
      for (var doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        final timestamp = doc.data()['timestamp'] as Timestamp?;

        if (amount != null && timestamp != null) {
          final paymentDate = timestamp.toDate();
          weeklyTotal += (amount as num).toDouble();

          // Calculate day of week (0 = Monday, 6 = Sunday)
          final dayDiff = paymentDate.difference(startOfWeekMidnight).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            dailyTotals[dayDiff] =
                (dailyTotals[dayDiff] ?? 0) + (amount as num).toDouble();
          }
        }
      }

      // Convert to chart data
      final spots = dailyTotals.entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();

      return {
        'total': weeklyTotal,
        'spots': spots,
      };
    } catch (e) {
      print('❌ Error fetching weekly collections: $e');
      return {
        'total': 0.0,
        'spots': <FlSpot>[],
      };
    }
  }

  /// 🎯 Get how many transactions happened today
  Future<int> _getTodayTransactions() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('payments')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error fetching today transactions: $e');
      return 0;
    }
  }

  /// 🎯 Get the last 5 transactions (like your recent purchases)
  Future<List<TransactionModel>> _getRecentTransactions() async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .where((model) => model != null) // Filter out null models
          .toList();
    } catch (e) {
      print('❌ Error fetching recent transactions: $e');
      return [];
    }
  }

  /// 🎯 Get this month's collections broken down by payment type
  Future<Map<String, dynamic>> _getMonthlyCollections() async {
    try {
      final now = DateTime.now();

      // Create timestamps for start and end of month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59,
          999 // Include milliseconds for complete coverage
          );

      print(
          'Fetching monthly collections from ${startOfMonth.toIso8601String()} to ${endOfMonth.toIso8601String()}');

      // Create Firestore timestamps
      final startTimestamp = Timestamp.fromDate(startOfMonth);
      final endTimestamp = Timestamp.fromDate(endOfMonth);

      // Query with proper error handling
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('payments')
            .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
            .where('timestamp', isLessThanOrEqualTo: endTimestamp)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Query timed out'),
            );
      } catch (e) {
        print('❌ Error querying monthly collections: $e');
        return {
          'total': 0.0,
          'breakdown': <String, double>{},
        };
      }

      if (snapshot.docs.isEmpty) {
        print('No monthly collection records found');
        return {
          'total': 0.0,
          'breakdown': <String, double>{},
        };
      }

      double monthlyTotal = 0;
      Map<String, double> breakdown = {};

      // Process documents with null safety
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Verify timestamp is within range
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) {
            print('Warning: Document ${doc.id} has no timestamp');
            continue;
          }

          final docDate = timestamp.toDate();
          if (docDate.isBefore(startOfMonth) || docDate.isAfter(endOfMonth)) {
            print('Warning: Document ${doc.id} timestamp out of range');
            continue;
          }

          // Get amount with null safety
          final amount = data['amount'];
          if (amount == null) {
            print('Warning: Document ${doc.id} has no amount');
            continue;
          }

          final amountDouble = (amount is int)
              ? amount.toDouble()
              : (amount is double)
                  ? amount
                  : null;

          if (amountDouble == null) {
            print(
                'Warning: Document ${doc.id} has invalid amount type: ${amount.runtimeType}');
            continue;
          }

          // Get payment type with default
          final paymentType = data['paymentType'] as String? ?? 'Other';

          monthlyTotal += amountDouble;
          breakdown[paymentType] = (breakdown[paymentType] ?? 0) + amountDouble;
        } catch (e) {
          print('❌ Error processing document ${doc.id}: $e');
          continue;
        }
      }

      print(
          'Successfully processed ${snapshot.docs.length} monthly collection records');
      print('Monthly total: $monthlyTotal');
      print('Breakdown: $breakdown');

      return {
        'total': monthlyTotal,
        'breakdown': breakdown,
      };
    } catch (e) {
      print('❌ Error in _getMonthlyCollections: $e');
      return {
        'total': 0.0,
        'breakdown': <String, double>{},
      };
    }
  }
}
