import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// A widget to display payment notifications and reminders
class PaymentNotificationWidget extends StatelessWidget {
  final String? studentId;
  final String? enrollmentId;

  const PaymentNotificationWidget({
    Key? key,
    this.studentId,
    this.enrollmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If both studentId and enrollmentId are null, return a general notifications widget
    if (studentId == null && enrollmentId == null) {
      return _buildGeneralNotifications(context);
    }
    
    // If enrollmentId is provided, show enrollment-specific notifications
    if (enrollmentId != null) {
      return _buildEnrollmentNotifications(context, enrollmentId!);
    }
    
    // Otherwise, show student-specific notifications
    return _buildStudentNotifications(context, studentId!);
  }
  
  /// Build notifications for a specific enrollment
  Widget _buildEnrollmentNotifications(BuildContext context, String enrollmentId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .doc(enrollmentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Error loading notifications: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red.shade700),
            ),
          );
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        
        final enrollmentData = snapshot.data!.data() as Map<String, dynamic>;
        final paymentStatus = enrollmentData['paymentStatus'] as String? ?? 'unpaid';
        final isOverdue = enrollmentData['isOverdue'] as bool? ?? false;
        final balanceRemaining = enrollmentData['balanceRemaining'] as double? ?? 0.0;
        final nextPaymentDueDate = enrollmentData['nextPaymentDueDate'] as Timestamp?;
        
        // If fully paid, no notifications needed
        if (paymentStatus == 'paid' || balanceRemaining <= 0) {
          return const SizedBox.shrink();
        }
        
        // If overdue, show overdue notification
        if (isOverdue) {
          return _buildOverdueNotification(context, enrollmentData);
        }
        
        // If has next payment date, show upcoming payment notification
        if (nextPaymentDueDate != null) {
          final dueDate = nextPaymentDueDate.toDate();
          final today = DateTime.now();
          final difference = dueDate.difference(today).inDays;
          
          // Show upcoming payment notification if due within 7 days
          if (difference >= 0 && difference <= 7) {
            return _buildUpcomingPaymentNotification(context, enrollmentData, difference);
          }
        }
        
        // Show balance reminder for partial payments
        if (paymentStatus == 'partial' && balanceRemaining > 0) {
          return _buildBalanceReminderNotification(context, enrollmentData);
        }
        
        // No notification needed
        return const SizedBox.shrink();
      },
    );
  }
  
  /// Build notifications for a specific student
  Widget _buildStudentNotifications(BuildContext context, String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('paymentStatus', whereIn: ['unpaid', 'partial'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Error loading notifications: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red.shade700),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Sort enrollments: overdue first, then by next payment date
        final enrollments = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        
        enrollments.sort((a, b) {
          // Overdue items come first
          final aIsOverdue = a['isOverdue'] as bool? ?? false;
          final bIsOverdue = b['isOverdue'] as bool? ?? false;
          
          if (aIsOverdue && !bIsOverdue) return -1;
          if (!aIsOverdue && bIsOverdue) return 1;
          
          // Then sort by next payment date
          final aNextPayment = a['nextPaymentDueDate'] as Timestamp?;
          final bNextPayment = b['nextPaymentDueDate'] as Timestamp?;
          
          if (aNextPayment != null && bNextPayment != null) {
            return aNextPayment.compareTo(bNextPayment);
          }
          
          if (aNextPayment != null) return -1;
          if (bNextPayment != null) return 1;
          
          return 0;
        });
        
        // Show the most important notification
        final enrollment = enrollments.first;
        
        // If overdue, show overdue notification
        if (enrollment['isOverdue'] as bool? ?? false) {
          return _buildOverdueNotification(context, enrollment);
        }
        
        // If has next payment date, show upcoming payment notification
        final nextPaymentDueDate = enrollment['nextPaymentDueDate'] as Timestamp?;
        if (nextPaymentDueDate != null) {
          final dueDate = nextPaymentDueDate.toDate();
          final today = DateTime.now();
          final difference = dueDate.difference(today).inDays;
          
          // Show upcoming payment notification if due within 7 days
          if (difference >= 0 && difference <= 7) {
            return _buildUpcomingPaymentNotification(context, enrollment, difference);
          }
        }
        
        // Show balance reminder for partial payments
        final paymentStatus = enrollment['paymentStatus'] as String? ?? 'unpaid';
        final balanceRemaining = enrollment['balanceRemaining'] as double? ?? 0.0;
        
        if (paymentStatus == 'partial' && balanceRemaining > 0) {
          return _buildBalanceReminderNotification(context, enrollment);
        }
        
        // No notification needed
        return const SizedBox.shrink();
      },
    );
  }
  
  /// Build general notifications for the user
  Widget _buildGeneralNotifications(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.email?.contains('admin') == true ? 'admin' : 'cashier';
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientRoles', arrayContains: userRole)
          .where('status', isEqualTo: 'unread')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'Error loading notifications: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red.shade700),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Get notifications
        final notifications = snapshot.data!.docs;
        
        // Count payment overdue notifications
        final overdueCount = notifications
            .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'payment_overdue')
            .length;
        
        if (overdueCount > 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Alerts',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You have $overdueCount student${overdueCount > 1 ? 's' : ''} with overdue payments. Please check the payment dashboard.',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to payment dashboard
                    },
                    child: Text(
                      'View Dashboard',
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        // No important notifications
        return const SizedBox.shrink();
      },
    );
  }
  
  /// Build an overdue payment notification
  Widget _buildOverdueNotification(BuildContext context, Map<String, dynamic> enrollment) {
    final studentInfo = enrollment['studentInfo'] as Map<String, dynamic>? ?? {};
    final studentName = '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}';
    final balanceRemaining = enrollment['balanceRemaining'] as double? ?? 0.0;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Payment Overdue',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment for $studentName is overdue. Please contact the parent as soon as possible.',
            style: TextStyle(fontFamily: 'Poppins',
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance Due:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              Text(
                currencyFormat.format(balanceRemaining),
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Record payment
                },
                child: Text(
                  'Record Payment',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build an upcoming payment notification
  Widget _buildUpcomingPaymentNotification(
    BuildContext context,
    Map<String, dynamic> enrollment,
    int daysRemaining,
  ) {
    final studentInfo = enrollment['studentInfo'] as Map<String, dynamic>? ?? {};
    final studentName = '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}';
    final balanceRemaining = enrollment['balanceRemaining'] as double? ?? 0.0;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final nextPaymentDueDate = enrollment['nextPaymentDueDate'] as Timestamp?;
    final dueDate = nextPaymentDueDate?.toDate() ?? DateTime.now();
    
    Color backgroundColor;
    Color textColor;
    
    if (daysRemaining <= 1) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (daysRemaining <= 3) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: textColor),
              const SizedBox(width: 8),
              Text(
                'Upcoming Payment',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            daysRemaining == 0
                ? 'Payment for $studentName is due today.'
                : daysRemaining == 1
                    ? 'Payment for $studentName is due tomorrow.'
                    : 'Payment for $studentName is due in $daysRemaining days.',
            style: TextStyle(fontFamily: 'Poppins',
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due Date:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(dueDate),
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance Due:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                currencyFormat.format(balanceRemaining),
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Record payment
                },
                child: Text(
                  'Record Payment',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build a balance reminder notification
  Widget _buildBalanceReminderNotification(BuildContext context, Map<String, dynamic> enrollment) {
    final studentInfo = enrollment['studentInfo'] as Map<String, dynamic>? ?? {};
    final studentName = '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}';
    final balanceRemaining = enrollment['balanceRemaining'] as double? ?? 0.0;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Balance Reminder',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$studentName has a remaining balance on their enrollment.',
            style: TextStyle(fontFamily: 'Poppins',
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                currencyFormat.format(balanceRemaining),
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // View enrollment details
                },
                child: Text(
                  'View Details',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Record payment
                },
                child: Text(
                  'Record Payment',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}