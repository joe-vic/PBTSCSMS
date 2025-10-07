import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository(this._firestore);

  // Existing methods...
  Future<Map<String, dynamic>> fetchStudentData() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      Map<String, int> distribution = {};
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final gradeLevel = data['gradeLevel'] as String? ?? 'Unassigned';
        distribution[gradeLevel] = (distribution[gradeLevel] ?? 0) + 1;
      }

      return {
        'count': studentsSnapshot.docs.length,
        'distribution': distribution,
      };
    } catch (e) {
      throw Exception('Failed to fetch student data: $e');
    }
  }

  Future<int> fetchTeacherData() async {
    try {
      final teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      return teachersSnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to fetch teacher data: $e');
    }
  }

  Future<int> fetchCourseData() async {
    try {
      final coursesSnapshot = await _firestore.collection('courses').get();
      return coursesSnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to fetch course data: $e');
    }
  }

  Future<int> fetchEnrollmentData() async {
    try {
      final pendingSnapshot = await _firestore
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .get();
      return pendingSnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to fetch enrollment data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchActivityData() async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return activitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'Unknown',
          'description': data['description'] ?? 'Unknown action',
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Unknown user',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // New methods for enhanced data
  Future<Map<String, dynamic>> loadFinancialMetrics() async {
    try {
      final paymentsSnapshot = await _firestore.collection('payments').get();

      double totalRevenue = 0.0;
      double thisMonthRevenue = 0.0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String? ?? 'unknown';
        final paymentDate = (data['paymentDate'] as Timestamp?)?.toDate();

        if (status == 'completed') {
          totalRevenue += amount;

          if (paymentDate != null && paymentDate.isAfter(startOfMonth)) {
            thisMonthRevenue += amount;
          }
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'thisMonthRevenue': thisMonthRevenue,
      };
    } catch (e) {
      return {'totalRevenue': 0.0, 'thisMonthRevenue': 0.0};
    }
  }

  Future<Map<String, dynamic>> loadEnrollmentMetrics() async {
    try {
      final enrollmentsSnapshot = await _firestore.collection('enrollments').get();
      final currentYear = DateTime.now().year;
      
      final activeEnrollments = enrollmentsSnapshot.docs.where((doc) {
        final schoolYear = doc.data()['schoolYear'] as String?;
        return schoolYear?.contains(currentYear.toString()) ?? false;
      }).length;

      return {
        'totalEnrollments': enrollmentsSnapshot.docs.length,
        'activeEnrollments': activeEnrollments,
      };
    } catch (e) {
      return {'totalEnrollments': 0, 'activeEnrollments': 0};
    }
  }

  Future<List<Map<String, dynamic>>> loadEnhancedActivities() async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Get recent enrollments
      final enrollmentsQuery = await _firestore
          .collection('enrollments')
          .orderBy('enrollmentDate', descending: true)
          .limit(5)
          .get();

      for (var doc in enrollmentsQuery.docs) {
        final data = doc.data();
        activities.add({
          'type': 'enrollment',
          'title': 'New Enrollment',
          'description': 'Student enrolled in ${data['gradeLevel']}',
          'timestamp': data['enrollmentDate'],
          'icon': 'person_add_rounded',
          'color': 'successColor',
          'priority': 'high',
        });
      }

      // Get recent payments
      final paymentsQuery = await _firestore
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(5)
          .get();

      for (var doc in paymentsQuery.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        activities.add({
          'type': 'payment',
          'title': 'Payment Received',
          'description': 'Amount: ₱${NumberFormat('#,##0.00').format(amount)}',
          'timestamp': data['paymentDate'],
          'icon': 'payments_rounded',
          'color': 'primaryColor',
          'priority': 'medium',
        });
      }

      return activities;
    } catch (e) {
      return [];
    }
  }

  Future<void> createBackup() async {
    // Backup creation logic
    await Future.delayed(const Duration(seconds: 2)); // Simulate backup process
  }
}