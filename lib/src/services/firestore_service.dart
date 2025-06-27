import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/billing.dart';
import '../models/enrollment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Students
  Future<void> addStudent(Student student) async {
    try {
      print('Adding student with ID: ${student.id}');
      await _firestore
          .collection('students')
          .doc(student.id)
          .set(student.toJson());
      print('Student added successfully: ${student.id}');
    } catch (e) {
      print('Error adding student: $e');
      throw Exception('Failed to add student: $e');
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      print('Updating student with ID: ${student.id}');
      await _firestore
          .collection('students')
          .doc(student.id)
          .update(student.toJson());
      print('Student updated successfully: ${student.id}');
    } catch (e) {
      print('Error updating student: $e');
      throw Exception('Failed to update student: $e');
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      print('Attempting to delete student with ID: $studentId');
      final studentRef = _firestore.collection('students').doc(studentId);
      final studentDoc = await studentRef.get();
      if (!studentDoc.exists) {
        print('Student document does not exist: $studentId');
        throw Exception('Student not found');
      }
      await studentRef.delete();
      print('Student deleted successfully: $studentId');
    } catch (e) {
      print('Error deleting student: $e');
      throw Exception('Failed to delete student: $e');
    }
  }

  Future<List<Student>> getStudents(String parentId) async {
    try {
      print('Fetching students for parentId: $parentId');
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .get();
      final students = snapshot.docs
          .map((doc) => Student.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      print('Fetched ${students.length} students for parentId: $parentId');
      return students;
    } catch (e) {
      print('Error fetching students: $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      print('Fetching all students');
      QuerySnapshot snapshot = await _firestore.collection('students').get();
      final students = snapshot.docs
          .map((doc) => Student.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      print('Fetched ${students.length} students');
      return students;
    } catch (e) {
      print('Error fetching all students: $e');
      throw Exception('Failed to fetch all students: $e');
    }
  }

  // Billing
  Future<List<Billing>> getBilling(String studentId) async {
    try {
      print('Fetching billing for studentId: $studentId');
      QuerySnapshot snapshot = await _firestore
          .collection('billing')
          .where('studentId', isEqualTo: studentId)
          .get();
      final billing = snapshot.docs
          .map((doc) => Billing.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      print('Fetched ${billing.length} billing records for studentId: $studentId');
      return billing;
    } catch (e) {
      print('Error fetching billing: $e');
      throw Exception('Failed to fetch billing: $e');
    }
  }

  Future<void> updateBilling(Billing billing) async {
    try {
      print('Updating billing with ID: ${billing.id}');
      await _firestore
          .collection('billing')
          .doc(billing.id)
          .update(billing.toMap());
      print('Billing updated successfully: ${billing.id}');
    } catch (e) {
      print('Error updating billing: $e');
      throw Exception('Failed to update billing: $e');
    }
  }

  // Enrollments
  Future<void> addEnrollment(Enrollment enrollment) async {
    try {
      print('Adding enrollment with ID: ${enrollment.enrollmentId}');
      await _firestore
          .collection('enrollments')
          .doc(enrollment.enrollmentId)
          .set(enrollment.toMap());
      print('Enrollment added successfully: ${enrollment.enrollmentId}');
    } catch (e) {
      print('Error adding enrollment: $e');
      throw Exception('Failed to add enrollment: $e');
    }
  }

  Future<Enrollment?> getEnrollment(String enrollmentId) async {
    try {
      print('Fetching enrollment with ID: $enrollmentId');
      DocumentSnapshot doc = await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .get();
      if (doc.exists) {
        final enrollment = Enrollment.fromMap(doc.data() as Map<String, dynamic>);
        print('Enrollment fetched successfully: $enrollmentId');
        return enrollment;
      }
      print('Enrollment not found: $enrollmentId');
      return null;
    } catch (e) {
      print('Error fetching enrollment: $e');
      throw Exception('Failed to fetch enrollment: $e');
    }
  }

  Future<void> updateEnrollment(Enrollment enrollment) async {
    try {
      print('Updating enrollment with ID: ${enrollment.enrollmentId}');
      await _firestore
          .collection('enrollments')
          .doc(enrollment.enrollmentId)
          .update(enrollment.toMap());
      print('Enrollment updated successfully: ${enrollment.enrollmentId}');
    } catch (e) {
      print('Error updating enrollment: $e');
      throw Exception('Failed to update enrollment: $e');
    }
  }
 Future<void> deleteEnrollment(String enrollmentId) async {
  try {
    print('Entering deleteEnrollment with enrollmentId: $enrollmentId');
    final enrollmentRef = _firestore.collection('enrollments').doc(enrollmentId);
    print('Fetching enrollment document');
    final enrollmentDoc = await enrollmentRef.get(const GetOptions(source: Source.server));
    if (!enrollmentDoc.exists) {
      print('Enrollment document does not exist: $enrollmentId');
      throw Exception('Enrollment not found');
    }
    print('Enrollment found: ${enrollmentDoc.data()}');

    final data = enrollmentDoc.data() as Map<String, dynamic>;
    final studentId = data['studentId'] as String?;

    WriteBatch batch = _firestore.batch();

    if (studentId != null) {
      print('Attempting to delete student with ID: $studentId');
      final studentRef = _firestore.collection('students').doc(studentId);
      print('Fetching student document');
      final studentDoc = await studentRef.get(const GetOptions(source: Source.server));
      if (studentDoc.exists) {
        batch.delete(studentRef);
        print('Added student deletion to batch: $studentId');
      } else {
        print('Student document does not exist: $studentId');
      }
    } else {
      print('No studentId found in enrollment document');
    }

    batch.delete(enrollmentRef);
    print('Added enrollment deletion to batch: $enrollmentId');

    print('Committing batch');
    await batch.commit();
    print('Batch commit successful. Enrollment deleted: $enrollmentId');
  } catch (e) {
    print('Error in deleteEnrollment: $e');
    throw Exception('Failed to delete enrollment: $e');
  }
}
  Future<void> deletePendingEnrollments(String parentId) async {
    try {
      print('Attempting to delete pending enrollments for parentId: $parentId');
      QuerySnapshot snapshot = await _firestore
          .collection('enrollments')
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: 'pending')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        print('Processing pending enrollment ID: ${doc.id}');
        final enrollment = Enrollment.fromMap(doc.data() as Map<String, dynamic>);
        if (enrollment.studentId != null) {
          print('Adding student deletion to batch: ${enrollment.studentId}');
          batch.delete(_firestore.collection('students').doc(enrollment.studentId));
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('Pending enrollments deleted successfully for parentId: $parentId');
    } catch (e) {
      print('Error in deletePendingEnrollments: $e');
      throw Exception('Failed to delete pending enrollments: $e');
    }
  }

  // Stream of enrollments for a parent
  Stream<QuerySnapshot> getEnrollmentsStream(String parentId) {
    print('Starting enrollments stream for parentId: $parentId');
    return _firestore
        .collection('enrollments')
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}