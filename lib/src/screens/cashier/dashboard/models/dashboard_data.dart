// lib/screens/cashier/dashboard/models/dashboard_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

/// 🎯 Think of this as a "Recipe Card" that tells us what information 
/// our dashboard needs to show
class DashboardData {
  final double todayCollections;
  final double weeklyCollections;
  final int todayTransactions;
  final List<TransactionModel> recentTransactions;
  final Map<String, double> monthlyCollections;
  final double monthTarget;
  final double monthProgress;
  final List<FlSpot> weeklyCollectionSpots;

  DashboardData({
    required this.todayCollections,
    required this.weeklyCollections,
    required this.todayTransactions,
    required this.recentTransactions,
    required this.monthlyCollections,
    required this.monthTarget,
    required this.monthProgress,
    required this.weeklyCollectionSpots,
  });

  /// 🎯 This creates an "empty" dashboard when we're loading data
  factory DashboardData.empty() {
    return DashboardData(
      todayCollections: 0.0,
      weeklyCollections: 0.0,
      todayTransactions: 0,
      recentTransactions: [],
      monthlyCollections: {},
      monthTarget: 1000000.0,
      monthProgress: 0.0,
      weeklyCollectionSpots: [],
    );
  }
}

/// 🎯 This represents ONE transaction (like buying candy at the store)
class TransactionModel {
  final String id;
  final double amount;
  final DateTime timestamp;
  final String paymentMethod;
  final String studentName;
  final String studentId;
  final String studentGradeLevel;
  final String paymentType;
  final bool receiptGenerated;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.paymentMethod,
    required this.studentName,
    required this.studentId,
    required this.studentGradeLevel,
    required this.paymentType,
    required this.receiptGenerated,
  });

  /// 🎯 This converts Firebase data into our TransactionModel
  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    String studentName = 'Unknown Student';
    String studentGradeLevel = '';

    // Try to get student info from the cached studentInfo in the payment document
    if (data.containsKey('studentInfo') && data['studentInfo'] is Map) {
      final studentInfo = data['studentInfo'] as Map<String, dynamic>;
      final lastName = studentInfo['lastName'] as String? ?? '';
      final firstName = studentInfo['firstName'] as String? ?? '';
      studentName = '$lastName, $firstName'.trim();
      if (studentName.isEmpty) studentName = 'Unknown Student';
      studentGradeLevel = studentInfo['gradeLevel'] as String? ?? '';
    }

    return TransactionModel(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      studentName: studentName,
      studentId: data['studentId'] ?? '',
      studentGradeLevel: studentGradeLevel,
      paymentType: data['paymentType'] ?? 'Tuition Fee',
      receiptGenerated: data['receiptGenerated'] ?? false,
    );
  }
}

/// 🎯 This represents ONE notification (like a text message)
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? actionLink;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.actionLink,
  });

  /// 🎯 This converts Firebase data into our NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'info',
      actionLink: data['actionLink'],
    );
  }
}