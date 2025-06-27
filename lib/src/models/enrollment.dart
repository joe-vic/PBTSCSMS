import 'package:cloud_firestore/cloud_firestore.dart';

class Enrollment {
  final String enrollmentId;
  final String studentId;
  final Map<String, dynamic> studentInfo;
  final Map<String, dynamic> parentInfo; // Primary contact/guardian
  final List<Map<String, dynamic>> additionalContacts; // New field for additional contacts
  final String parentId;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String academicYear;
  final DateTime? preEnrollmentDate;
  final DateTime? officialEnrollmentDate;

  Enrollment({
    required this.enrollmentId,
    required this.studentId,
    required this.studentInfo,
    required this.parentInfo,
    required this.additionalContacts,
    required this.parentId,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.academicYear,
    this.preEnrollmentDate,
    this.officialEnrollmentDate,
  });

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      enrollmentId: map['enrollmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentInfo: Map<String, dynamic>.from(map['studentInfo'] ?? {}),
      parentInfo: Map<String, dynamic>.from(map['parentInfo'] ?? {}),
      additionalContacts: (map['additionalContacts'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          [],
      parentId: map['parentId'] ?? '',
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      academicYear: map['academicYear'] ?? '',
      preEnrollmentDate:
          (map['preEnrollmentDate'] as Timestamp?)?.toDate(),
      officialEnrollmentDate:
          (map['officialEnrollmentDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enrollmentId': enrollmentId,
      'studentId': studentId,
      'studentInfo': studentInfo,
      'parentInfo': parentInfo,
      'additionalContacts': additionalContacts,
      'parentId': parentId,
      'status': status,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'academicYear': academicYear,
      'preEnrollmentDate': preEnrollmentDate != null
          ? Timestamp.fromDate(preEnrollmentDate!)
          : null,
      'officialEnrollmentDate': officialEnrollmentDate != null
          ? Timestamp.fromDate(officialEnrollmentDate!)
          : null,
    };
  }
}