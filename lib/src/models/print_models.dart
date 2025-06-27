class EnrollmentFormData {
  final String enrollmentId;
  final String studentId;
  final Map<String, dynamic> studentInfo;
  final Map<String, dynamic> parentInfo;
  final List<Map<String, dynamic>> additionalContacts;
  final Map<String, dynamic> addressInfo;
  final String paymentScheme;
  final List<Map<String, dynamic>> feeReductions;
  final double totalFee;
  final double initialPayment;
  final double balance;
  final DateTime enrollmentDate;
  final String academicYear;
  
  EnrollmentFormData({
    required this.enrollmentId,
    required this.studentId,
    required this.studentInfo,
    required this.parentInfo,
    required this.additionalContacts,
    required this.addressInfo,
    required this.paymentScheme,
    required this.feeReductions,
    required this.totalFee,
    required this.initialPayment,
    required this.balance,
    required this.enrollmentDate,
    required this.academicYear,
  });
}

class PaymentSchedule {
  final String month;
  final DateTime dueDate;
  final double amount;
  final String description;
  final bool isPaid;
  
  PaymentSchedule({
    required this.month,
    required this.dueDate,
    required this.amount,
    required this.description,
    this.isPaid = false,
  });
}

class BIRReceipt {
  final String receiptNumber;
  final String studentId;
  final String studentName;
  final double amount;
  final DateTime issuedDate;
  final String cashierName;
  final String paymentFor;
  
  BIRReceipt({
    required this.receiptNumber,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.issuedDate,
    required this.cashierName,
    required this.paymentFor,
  });
}