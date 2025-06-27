import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to prevent duplicate student and enrollment records in Firestore
class EnrollmentDuplicateChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a student already exists based on name and birthdate
  /// Returns the existing student ID if found, null otherwise
  static Future<String?> findExistingStudent({
    required String firstName,
    required String lastName,
    required String middleName,
    required DateTime dateOfBirth,
  }) async {
    try {
      // Create a normalized search key (lowercase, trimmed)
      final searchKey = '${firstName.trim().toLowerCase()}_${lastName.trim().toLowerCase()}_${middleName.trim().toLowerCase()}';
      
      // Query students collection for matching name and birthdate
      final querySnapshot = await _firestore
          .collection('students')
          .where('searchKey', isEqualTo: searchKey)
          .where('dateOfBirth', isEqualTo: Timestamp.fromDate(dateOfBirth))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final existingStudent = querySnapshot.docs.first;
        print('✅ Found existing student: ${existingStudent.id}');
        return existingStudent.id;
      }

      // Fallback: search without searchKey (for existing data without searchKey)
      final fallbackQuery = await _firestore
          .collection('students')
          .where('firstName', isEqualTo: firstName.trim())
          .where('lastName', isEqualTo: lastName.trim())
          .where('middleName', isEqualTo: middleName.trim())
          .where('dateOfBirth', isEqualTo: Timestamp.fromDate(dateOfBirth))
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        final existingStudent = fallbackQuery.docs.first;
        print('✅ Found existing student (fallback): ${existingStudent.id}');
        return existingStudent.id;
      }

      print('❌ No existing student found');
      return null;
    } catch (e) {
      print('❌ Error checking for existing student: $e');
      return null;
    }
  }

  /// Check if an enrollment already exists for the same student and academic year
  /// Returns true if duplicate exists, false otherwise
  static Future<bool> checkDuplicateEnrollment({
    required String studentId,
    required String academicYear,
    String? excludeEnrollmentId, // For updates, exclude current enrollment
  }) async {
    try {
      Query query = _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('academicYear', isEqualTo: academicYear);

      // Exclude current enrollment if updating
      if (excludeEnrollmentId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeEnrollmentId);
      }

      final querySnapshot = await query.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final existingEnrollment = querySnapshot.docs.first;
        print('⚠️ Duplicate enrollment found: ${existingEnrollment.id}');
        return true;
      }

      print('✅ No duplicate enrollment found');
      return false;
    } catch (e) {
      print('❌ Error checking for duplicate enrollment: $e');
      return false;
    }
  }

  /// Get existing student data if found
  /// Returns the student document data if found, null otherwise
  static Future<Map<String, dynamic>?> getExistingStudentData({
    required String firstName,
    required String lastName,
    required String middleName,
    required DateTime dateOfBirth,
  }) async {
    try {
      final studentId = await findExistingStudent(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        dateOfBirth: dateOfBirth,
      );

      if (studentId != null) {
        final studentDoc = await _firestore.collection('students').doc(studentId).get();
        if (studentDoc.exists) {
          return studentDoc.data();
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting existing student data: $e');
      return null;
    }
  }

  /// Create a search key for student lookup
  /// This should be called when creating new students
  static String createStudentSearchKey({
    required String firstName,
    required String lastName,
    required String middleName,
  }) {
    return '${firstName.trim().toLowerCase()}_${lastName.trim().toLowerCase()}_${middleName.trim().toLowerCase()}';
  }

  /// Validate if student data has changed significantly
  /// Returns true if significant changes detected, false if minor updates
  static bool hasSignificantChanges({
    required Map<String, dynamic> existingData,
    required Map<String, dynamic> newData,
  }) {
    // Define fields that constitute significant changes
    const significantFields = [
      'firstName',
      'lastName',
      'middleName',
      'dateOfBirth',
      'gender',
      'gradeLevel',
    ];

    for (final field in significantFields) {
      if (existingData[field] != newData[field]) {
        print('🔄 Significant change detected in field: $field');
        return true;
      }
    }

    return false;
  }

  /// Get enrollment summary for duplicate checking
  static Future<Map<String, dynamic>?> getEnrollmentSummary({
    required String studentId,
    required String academicYear,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('academicYear', isEqualTo: academicYear)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final enrollment = querySnapshot.docs.first;
        return {
          'enrollmentId': enrollment.id,
          'status': enrollment.data()['status'],
          'paymentStatus': enrollment.data()['paymentStatus'],
          'createdAt': enrollment.data()['createdAt'],
          ...enrollment.data(),
        };
      }

      return null;
    } catch (e) {
      print('❌ Error getting enrollment summary: $e');
      return null;
    }
  }
} 