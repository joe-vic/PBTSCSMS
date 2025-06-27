import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for enrollment payment data
class EnrollmentPayment {
  final String id;
  final String studentId;
  final String enrollmentType;
  final String paymentPlan;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final bool hasScholarship;
  final String? scholarshipType;
  final double? scholarshipPercentage;
  final String? discountType;
  final double? discountAmount;
  final double baseFee;
  final double idFee;
  final double systemFee;
  final double bookFee;
  final double otherFees;
  final double totalFee;
  final double initialPaymentAmount;
  final double balanceRemaining;
  final double minimumPayment;
  final String academicYear;
  final String gradeLevel;
  final bool isVoucherBeneficiary;
  final String? semesterType;
  final bool paymentOverride;
  final String? overrideReason;
  final String? overrideBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String cashierId;
  final String cashierName;
  final Map<String, dynamic> studentInfo;
  final Map<String, dynamic> parentInfo;
  final List<Map<String, dynamic>>? additionalContacts;

  EnrollmentPayment({
    required this.id,
    required this.studentId,
    required this.enrollmentType,
    required this.paymentPlan,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.hasScholarship,
    this.scholarshipType,
    this.scholarshipPercentage,
    this.discountType,
    this.discountAmount,
    required this.baseFee,
    required this.idFee,
    required this.systemFee,
    required this.bookFee,
    required this.otherFees,
    required this.totalFee,
    required this.initialPaymentAmount,
    required this.balanceRemaining,
    required this.minimumPayment,
    required this.academicYear,
    required this.gradeLevel,
    required this.isVoucherBeneficiary,
    this.semesterType,
    required this.paymentOverride,
    this.overrideReason,
    this.overrideBy,
    required this.createdAt,
    required this.updatedAt,
    required this.cashierId,
    required this.cashierName,
    required this.studentInfo,
    required this.parentInfo,
    this.additionalContacts,
  });

  /// Create a model from Firestore document
  factory EnrollmentPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EnrollmentPayment(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      enrollmentType: data['enrollmentType'] ?? 'Standard Enrollment',
      paymentPlan: data['paymentPlan'] ?? 'Installment',
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      hasScholarship: data['hasScholarship'] ?? false,
      scholarshipType: data['scholarshipType'],
      scholarshipPercentage: data['scholarshipPercentage'] != null 
          ? (data['scholarshipPercentage'] as num).toDouble() 
          : null,
      discountType: data['discountType'],
      discountAmount: data['discountAmount'] != null 
          ? (data['discountAmount'] as num).toDouble() 
          : null,
      baseFee: (data['baseFee'] as num?)?.toDouble() ?? 0.0,
      idFee: (data['idFee'] as num?)?.toDouble() ?? 150.0,
      systemFee: (data['systemFee'] as num?)?.toDouble() ?? 120.0,
      bookFee: (data['bookFee'] as num?)?.toDouble() ?? 0.0,
      otherFees: (data['otherFees'] as num?)?.toDouble() ?? 0.0,
      totalFee: (data['totalFee'] as num?)?.toDouble() ?? 0.0,
      initialPaymentAmount: (data['initialPaymentAmount'] as num?)?.toDouble() ?? 0.0,
      balanceRemaining: (data['balanceRemaining'] as num?)?.toDouble() ?? 0.0,
      minimumPayment: (data['minimumPayment'] as num?)?.toDouble() ?? 0.0,
      academicYear: data['academicYear'] ?? '',
      gradeLevel: data['gradeLevel'] ?? '',
      isVoucherBeneficiary: data['isVoucherBeneficiary'] ?? false,
      semesterType: data['semesterType'],
      paymentOverride: data['paymentOverride'] ?? false,
      overrideReason: data['overrideReason'],
      overrideBy: data['overrideBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashierId: data['cashierId'] ?? '',
      cashierName: data['cashierName'] ?? '',
      studentInfo: data['studentInfo'] as Map<String, dynamic>? ?? {},
      parentInfo: data['parentInfo'] as Map<String, dynamic>? ?? {},
      additionalContacts: (data['additionalContacts'] as List<dynamic>?)
          ?.map((contact) => contact as Map<String, dynamic>)
          .toList(),
    );
  }

  /// Convert model to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'enrollmentType': enrollmentType,
      'paymentPlan': paymentPlan,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'hasScholarship': hasScholarship,
      'scholarshipType': scholarshipType,
      'scholarshipPercentage': scholarshipPercentage,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'baseFee': baseFee,
      'idFee': idFee,
      'systemFee': systemFee,
      'bookFee': bookFee,
      'otherFees': otherFees,
      'totalFee': totalFee,
      'initialPaymentAmount': initialPaymentAmount,
      'balanceRemaining': balanceRemaining,
      'minimumPayment': minimumPayment,
      'academicYear': academicYear,
      'gradeLevel': gradeLevel,
      'isVoucherBeneficiary': isVoucherBeneficiary,
      'semesterType': semesterType,
      'paymentOverride': paymentOverride,
      'overrideReason': overrideReason,
      'overrideBy': overrideBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cashierId': cashierId,
      'cashierName': cashierName,
      'studentInfo': studentInfo,
      'parentInfo': parentInfo,
      'additionalContacts': additionalContacts,
    };
  }

  /// Create a copy of this model with modified fields
  EnrollmentPayment copyWith({
    String? id,
    String? studentId,
    String? enrollmentType,
    String? paymentPlan,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    bool? hasScholarship,
    String? scholarshipType,
    double? scholarshipPercentage,
    String? discountType,
    double? discountAmount,
    double? baseFee,
    double? idFee,
    double? systemFee,
    double? bookFee,
    double? otherFees,
    double? totalFee,
    double? initialPaymentAmount,
    double? balanceRemaining,
    double? minimumPayment,
    String? academicYear,
    String? gradeLevel,
    bool? isVoucherBeneficiary,
    String? semesterType,
    bool? paymentOverride,
    String? overrideReason,
    String? overrideBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cashierId,
    String? cashierName,
    Map<String, dynamic>? studentInfo,
    Map<String, dynamic>? parentInfo,
    List<Map<String, dynamic>>? additionalContacts,
  }) {
    return EnrollmentPayment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      enrollmentType: enrollmentType ?? this.enrollmentType,
      paymentPlan: paymentPlan ?? this.paymentPlan,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      hasScholarship: hasScholarship ?? this.hasScholarship,
      scholarshipType: scholarshipType ?? this.scholarshipType,
      scholarshipPercentage: scholarshipPercentage ?? this.scholarshipPercentage,
      discountType: discountType ?? this.discountType,
      discountAmount: discountAmount ?? this.discountAmount,
      baseFee: baseFee ?? this.baseFee,
      idFee: idFee ?? this.idFee,
      systemFee: systemFee ?? this.systemFee,
      bookFee: bookFee ?? this.bookFee,
      otherFees: otherFees ?? this.otherFees,
      totalFee: totalFee ?? this.totalFee,
      initialPaymentAmount: initialPaymentAmount ?? this.initialPaymentAmount,
      balanceRemaining: balanceRemaining ?? this.balanceRemaining,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      academicYear: academicYear ?? this.academicYear,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      isVoucherBeneficiary: isVoucherBeneficiary ?? this.isVoucherBeneficiary,
      semesterType: semesterType ?? this.semesterType,
      paymentOverride: paymentOverride ?? this.paymentOverride,
      overrideReason: overrideReason ?? this.overrideReason,
      overrideBy: overrideBy ?? this.overrideBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      studentInfo: studentInfo ?? this.studentInfo,
      parentInfo: parentInfo ?? this.parentInfo,
      additionalContacts: additionalContacts ?? this.additionalContacts,
    );
  }
}

/// Service class to handle Firestore operations for enrollment payments
class EnrollmentPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'enrollments';
  
  /// Get a stream of enrollment payments for a specific student
  Stream<List<EnrollmentPayment>> getStudentEnrollments(String studentId) {
    return _firestore
        .collection(_collectionPath)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnrollmentPayment.fromFirestore(doc))
            .toList());
  }
  
  /// Get a specific enrollment payment by ID
  Future<EnrollmentPayment?> getEnrollmentById(String id) async {
    final doc = await _firestore.collection(_collectionPath).doc(id).get();
    if (doc.exists) {
      return EnrollmentPayment.fromFirestore(doc);
    }
    return null;
  }
  
  /// Add a new enrollment payment
  Future<String> addEnrollment(EnrollmentPayment enrollment) async {
    final docRef = await _firestore
        .collection(_collectionPath)
        .add(enrollment.toFirestore());
    return docRef.id;
  }
  
  /// Update an existing enrollment payment
  Future<void> updateEnrollment(EnrollmentPayment enrollment) async {
    await _firestore
        .collection(_collectionPath)
        .doc(enrollment.id)
        .update(enrollment.toFirestore());
  }
  
  /// Delete an enrollment payment
  Future<void> deleteEnrollment(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }
  
  /// Get a list of enrollment payments for the current academic year
  Future<List<EnrollmentPayment>> getCurrentAcademicYearEnrollments(String academicYear) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('academicYear', isEqualTo: academicYear)
        .get();
    
    return snapshot.docs
        .map((doc) => EnrollmentPayment.fromFirestore(doc))
        .toList();
  }
  
  /// Get a count of enrollments by status for reporting
  Future<Map<String, int>> getEnrollmentCountsByStatus(String academicYear) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('academicYear', isEqualTo: academicYear)
        .get();
    
    final enrollments = snapshot.docs
        .map((doc) => EnrollmentPayment.fromFirestore(doc))
        .toList();
    
    final Map<String, int> counts = {
      'pending': 0,
      'approved': 0,
      'rejected': 0,
      'paid': 0,
      'partial': 0,
      'unpaid': 0,
    };
    
    for (final enrollment in enrollments) {
      counts[enrollment.status] = (counts[enrollment.status] ?? 0) + 1;
      counts[enrollment.paymentStatus] = (counts[enrollment.paymentStatus] ?? 0) + 1;
    }
    
    return counts;
  }
}