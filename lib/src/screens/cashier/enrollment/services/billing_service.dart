import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enrollment_form_state.dart';

class BillingService {
  final FirebaseFirestore _firestore;

  BillingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create billing record using your exact payment structure
  Future<void> createBillingRecord({
    required String studentId,
    required EnrollmentFormState formState,
  }) async {
    try {
      final now = DateTime.now();
      
      // Calculate tuition fee (total minus other fees)
      final tuitionFee = formState.tuitionFee;
      // final tuitionFee = formState.calculatedTotalAmountDue - 
      //                   formState.idFee - 
      //                   formState.systemFee - 
      //                   formState.graduationFee;
      
      Map<String, dynamic> billingData;
      
      // Check if college level for semester structure
      final isCollege = _isCollegeLevel(formState);
      
      if (isCollege) {
        // College structure with semesters - matching your JSON structure
        billingData = {
          'semesters': {
            'Semester1': {
              'grade': formState.collegeYearLevel ?? formState.gradeLevel,
              'yearLevel': _getCollegeYearLevel(formState.collegeYearLevel),
              'tuitionFee': tuitionFee,
              'idFee': formState.idFee,
              'systemFee': formState.systemFee,
              'totalPaid': formState.initialPaymentAmount,
              'balance': formState.balance,
              'timestamp': now.toIso8601String(),
            }
          }
        };
        
        // Add payment plan info if installment
        if (formState.paymentType == 'installment') {
          billingData['semesters']['Semester1']['paymentType'] = 'installment';
          billingData['semesters']['Semester1']['downPayment'] = formState.downPayment;
          billingData['semesters']['Semester1']['monthlyInstallment'] = formState.monthlyInstallment;
          billingData['semesters']['Semester1']['installmentMonths'] = formState.installmentMonths;
        }
        
      } else {
        // K-12 structure - matching your JSON structure
        billingData = {
          'grade': formState.gradeLevel,
          'yearLevel': formState.gradeLevel,
          'tuitionFee': tuitionFee,
          'idFee': formState.idFee,
          'systemFee': formState.systemFee,
          'totalPaid': formState.initialPaymentAmount,
          'balance': formState.balance,
          'timestamp': now.toIso8601String(),
        };
        
        // Add graduation fee if applicable
        if (formState.graduationFee > 0) {
          billingData['graduationFee'] = formState.graduationFee;
        }
      }
      
      // Save billing record to student's billing subcollection
      await _firestore
          .collection('students')
          .doc(studentId)
          .collection('billing')
          .doc(formState.academicYear)
          .set(billingData);
          
      print('✅ Billing record created successfully for student: $studentId');
      
    } catch (e) {
      print('❌ Error creating billing record: $e');
      throw Exception('Failed to create billing record: $e');
    }
  }

  /// Record a payment using your exact payment structure
  Future<String> recordPayment({
    required String studentId,
    required String academicYear,
    required double amount,
    required String paymentType,
    String? semester,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      
      // Generate payment ID and official receipt number - matching your structure
      final paymentSequence = now.millisecondsSinceEpoch.toString().substring(7);
      final paymentId = 'payment$paymentSequence';
      final receiptNumber = 'OR-${now.year}-$paymentSequence';
      
      // Your exact payment structure
      final paymentData = {
        'schoolYear': academicYear,
        'amount': amount,
        'type': paymentType, // cash, installment, downPayment
        'date': now.toIso8601String(),
        'officialReceipt': receiptNumber,
      };
      
      // Add semester if it's a college payment
      if (semester != null) {
        paymentData['semester'] = semester;
      }
      
      // Add notes if provided
      if (notes != null && notes.isNotEmpty) {
        paymentData['notes'] = notes;
      }
      
      // Save payment record to student's payments subcollection
      await _firestore
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .doc(paymentId)
          .set(paymentData);
      
      // Update billing record with new payment
      await _updateBillingAfterPayment(
        studentId: studentId,
        academicYear: academicYear,
        amount: amount,
        semester: semester,
      );
      
      print('✅ Payment recorded successfully: $receiptNumber');
      return receiptNumber;
      
    } catch (e) {
      print('❌ Error recording payment: $e');
      throw Exception('Failed to record payment: $e');
    }
  }

  /// Update billing record after payment
  Future<void> _updateBillingAfterPayment({
    required String studentId,
    required String academicYear,
    required double amount,
    String? semester,
  }) async {
    try {
      final billingRef = _firestore
          .collection('students')
          .doc(studentId)
          .collection('billing')
          .doc(academicYear);

      await _firestore.runTransaction((transaction) async {
        final billingDoc = await transaction.get(billingRef);
        
        if (!billingDoc.exists) {
          throw Exception('Billing record not found');
        }

        final billingData = Map<String, dynamic>.from(billingDoc.data()!);
        
        // Update based on structure (K-12 or College)
        if (billingData.containsKey('semesters')) {
          // College structure
          final semesters = Map<String, dynamic>.from(billingData['semesters']);
          final semesterKey = semester ?? 'Semester1';
          
          if (semesters.containsKey(semesterKey)) {
            final semesterData = Map<String, dynamic>.from(semesters[semesterKey]);
            final currentPaid = (semesterData['totalPaid'] as num?)?.toDouble() ?? 0.0;
            final currentBalance = (semesterData['balance'] as num?)?.toDouble() ?? 0.0;
            
            semesterData['totalPaid'] = currentPaid + amount;
            semesterData['balance'] = currentBalance - amount;
            semesters[semesterKey] = semesterData;
            billingData['semesters'] = semesters;
          }
        } else {
          // K-12 structure
          final currentPaid = (billingData['totalPaid'] as num?)?.toDouble() ?? 0.0;
          final currentBalance = (billingData['balance'] as num?)?.toDouble() ?? 0.0;
          
          billingData['totalPaid'] = currentPaid + amount;
          billingData['balance'] = currentBalance - amount;
        }
        
        // Update the document
        transaction.update(billingRef, billingData);
      });
      
    } catch (e) {
      print('❌ Error updating billing after payment: $e');
      throw Exception('Failed to update billing: $e');
    }
  }

  /// Get student billing information
  Future<Map<String, dynamic>?> getStudentBilling(
    String studentId, 
    String academicYear
  ) async {
    try {
      final billingDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('billing')
          .doc(academicYear)
          .get();
      
      if (billingDoc.exists) {
        return billingDoc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting billing data: $e');
      return null;
    }
  }

  /// Get student payment history
  Future<List<Map<String, dynamic>>> getStudentPayments(
    String studentId, 
    String academicYear
  ) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('payments')
          .where('schoolYear', isEqualTo: academicYear)
          .orderBy('date', descending: true)
          .get();
      
      return paymentsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('❌ Error getting payment history: $e');
      return [];
    }
  }

  /// Check if student has outstanding balance
  Future<bool> hasOutstandingBalance(String studentId, String academicYear) async {
    try {
      final billingData = await getStudentBilling(studentId, academicYear);
      if (billingData == null) return false;
      
      if (billingData.containsKey('semesters')) {
        // College structure - check all semesters
        final semesters = billingData['semesters'] as Map<String, dynamic>;
        for (final semesterData in semesters.values) {
          final balance = (semesterData['balance'] as num?)?.toDouble() ?? 0.0;
          if (balance > 0) return true;
        }
        return false;
      } else {
        // K-12 structure
        final balance = (billingData['balance'] as num?)?.toDouble() ?? 0.0;
        return balance > 0;
      }
    } catch (e) {
      print('❌ Error checking outstanding balance: $e');
      return false;
    }
  }

  /// Get billing summary for dashboard
  Future<Map<String, dynamic>> getBillingSummary(String studentId, String academicYear) async {
    try {
      final billingData = await getStudentBilling(studentId, academicYear);
      final payments = await getStudentPayments(studentId, academicYear);
      
      if (billingData == null) {
        return {
          'totalAmountDue': 0.0,
          'totalPaid': 0.0,
          'balance': 0.0,
          'paymentCount': 0,
          'lastPaymentDate': null,
        };
      }
      
      double totalAmountDue = 0.0;
      double totalPaid = 0.0;
      double balance = 0.0;
      
      if (billingData.containsKey('semesters')) {
        // College structure
        final semesters = billingData['semesters'] as Map<String, dynamic>;
        for (final semesterData in semesters.values) {
          final semesterMap = semesterData as Map<String, dynamic>;
          totalAmountDue += (semesterMap['tuitionFee'] as num?)?.toDouble() ?? 0.0;
          totalAmountDue += (semesterMap['idFee'] as num?)?.toDouble() ?? 0.0;
          totalAmountDue += (semesterMap['systemFee'] as num?)?.toDouble() ?? 0.0;
          totalPaid += (semesterMap['totalPaid'] as num?)?.toDouble() ?? 0.0;
          balance += (semesterMap['balance'] as num?)?.toDouble() ?? 0.0;
        }
      } else {
        // K-12 structure
        totalAmountDue = (billingData['tuitionFee'] as num?)?.toDouble() ?? 0.0;
        totalAmountDue += (billingData['idFee'] as num?)?.toDouble() ?? 0.0;
        totalAmountDue += (billingData['systemFee'] as num?)?.toDouble() ?? 0.0;
        totalAmountDue += (billingData['graduationFee'] as num?)?.toDouble() ?? 0.0;
        totalPaid = (billingData['totalPaid'] as num?)?.toDouble() ?? 0.0;
        balance = (billingData['balance'] as num?)?.toDouble() ?? 0.0;
      }
      
      // Get last payment date
      DateTime? lastPaymentDate;
      if (payments.isNotEmpty) {
        lastPaymentDate = DateTime.parse(payments.first['date']);
      }
      
      return {
        'totalAmountDue': totalAmountDue,
        'totalPaid': totalPaid,
        'balance': balance,
        'paymentCount': payments.length,
        'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting billing summary: $e');
      return {
        'totalAmountDue': 0.0,
        'totalPaid': 0.0,
        'balance': 0.0,
        'paymentCount': 0,
        'lastPaymentDate': null,
      };
    }
  }

  /// Generate next official receipt number
  Future<String> _generateOfficialReceiptNumber() async {
    try {
      final now = DateTime.now();
      final year = now.year;
      
      // Get the last receipt number for this year
      final receiptsRef = _firestore.collection('receiptCounters').doc(year.toString());
      
      String receiptNumber = '';
      
      await _firestore.runTransaction((transaction) async {
        final receiptDoc = await transaction.get(receiptsRef);
        
        int counter = 1;
        if (receiptDoc.exists) {
          counter = (receiptDoc.data()?['counter'] ?? 0) + 1;
        }
        
        // Format: OR-YYYY-000001
        receiptNumber = 'OR-$year-${counter.toString().padLeft(6, '0')}';
        
        // Update counter
        transaction.set(receiptsRef, {'counter': counter, 'year': year});
      });
      
      return receiptNumber;
    } catch (e) {
      // Fallback to timestamp-based receipt number
      final now = DateTime.now();
      return 'OR-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  /// Helper method to determine if grade level is college
  bool _isCollegeLevel(EnrollmentFormState formState) {
    if (formState.collegeYearLevel != null) return true;
    
    final gradeLevel = formState.gradeLevel?.toLowerCase() ?? '';
    return gradeLevel.contains('college') || 
           gradeLevel.contains('1st year') || 
           gradeLevel.contains('2nd year') || 
           gradeLevel.contains('3rd year') || 
           gradeLevel.contains('4th year') ||
           gradeLevel.contains('freshman') ||
           gradeLevel.contains('sophomore') ||
           gradeLevel.contains('junior') ||
           gradeLevel.contains('senior');
  }

  /// Helper method to get college year level
  String _getCollegeYearLevel(String? yearLevel) {
    if (yearLevel == null) return 'Freshman';
    
    switch (yearLevel.toLowerCase()) {
      case '1st year':
        return 'Freshman';
      case '2nd year':
        return 'Sophomore';
      case '3rd year':
        return 'Junior';
      case '4th year':
        return 'Senior';
      default:
        return yearLevel;
    }
  }

  /// Calculate installment plan
  Map<String, dynamic> calculateInstallmentPlan({
    required double totalAmount,
    required double initialPayment,
    required String paymentScheme,
  }) {
    final remainingBalance = totalAmount - initialPayment;
    
    Map<String, dynamic> plan = {
      'totalAmount': totalAmount,
      'initialPayment': initialPayment,
      'remainingBalance': remainingBalance,
      'installments': <Map<String, dynamic>>[],
    };
    
    if (remainingBalance <= 0) {
      plan['paymentType'] = 'cash';
      return plan;
    }
    
    switch (paymentScheme) {
      case 'Standard Installment':
        // 3 quarterly payments
        final quarterlyAmount = remainingBalance / 3;
        for (int i = 1; i <= 3; i++) {
          plan['installments'].add({
            'installmentNumber': i,
            'amount': i == 3 ? remainingBalance - (quarterlyAmount * 2) : quarterlyAmount,
            'dueDate': DateTime.now().add(Duration(days: 90 * i)).toIso8601String(),
          });
        }
        plan['paymentType'] = 'installment';
        plan['monthlyInstallment'] = quarterlyAmount;
        plan['installmentMonths'] = 3;
        break;
        
      case 'Flexible Installment':
        // 10 monthly payments
        final monthlyAmount = remainingBalance / 10;
        for (int i = 1; i <= 10; i++) {
          plan['installments'].add({
            'installmentNumber': i,
            'amount': i == 10 ? remainingBalance - (monthlyAmount * 9) : monthlyAmount,
            'dueDate': DateTime.now().add(Duration(days: 30 * i)).toIso8601String(),
          });
        }
        plan['paymentType'] = 'installment';
        plan['monthlyInstallment'] = monthlyAmount;
        plan['installmentMonths'] = 10;
        break;
        
      default:
        // Full payment
        plan['paymentType'] = 'cash';
    }
    
    return plan;
  }
}