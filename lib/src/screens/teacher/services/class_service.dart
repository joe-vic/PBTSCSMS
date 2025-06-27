import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import '../models/class_model.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new class
  Future<ClassModel> createClass(ClassModel classModel) async {
    try {
      final docRef =
          await _firestore.collection('classes').add(classModel.toMap());
      return classModel.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  // Get all classes for a teacher (including archived)
  Stream<List<ClassModel>> getTeacherClasses(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get active classes for a teacher (excluding archived)
  Stream<List<ClassModel>> getActiveTeacherClasses(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get archived classes for a teacher
  Stream<List<ClassModel>> getArchivedTeacherClasses(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update a class
  Future<void> updateClass(ClassModel classModel) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classModel.id)
          .update(classModel.toMap());
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  // Archive a class
  Future<void> archiveClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to archive class: $e');
    }
  }

  // Restore an archived class
  Future<void> restoreClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'isArchived': false,
        'archivedAt': null,
      });
    } catch (e) {
      throw Exception('Failed to restore class: $e');
    }
  }

  // Delete a class (hard delete - should rarely be used)
  Future<void> deleteClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).delete();
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  // Add students to a class
  Future<void> addStudentsToClass(
      String classId, List<String> studentIds) async {
    try {
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }

      final currentStudents =
          List<String>.from(classDoc.data()?['studentIds'] ?? []);
      final updatedStudents = {...currentStudents, ...studentIds}.toList();

      await _firestore
          .collection('classes')
          .doc(classId)
          .update({'studentIds': updatedStudents});
    } catch (e) {
      throw Exception('Failed to add students: $e');
    }
  }

  // Remove students from a class
  Future<void> removeStudentsFromClass(
      String classId, List<String> studentIds) async {
    try {
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }

      final currentStudents =
          List<String>.from(classDoc.data()?['studentIds'] ?? []);
      final updatedStudents =
          currentStudents.where((id) => !studentIds.contains(id)).toList();

      await _firestore
          .collection('classes')
          .doc(classId)
          .update({'studentIds': updatedStudents});
    } catch (e) {
      throw Exception('Failed to remove students: $e');
    }
  }

  // Import students from CSV
  Future<List<String>> importStudentsFromCSV(String csvData) async {
    try {
      final rows = const CsvToListConverter().convert(csvData);
      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Assuming first row is headers
      final headers = rows[0].map((e) => e.toString().toLowerCase()).toList();
      final studentIdIndex = headers.indexOf('student_id');
      if (studentIdIndex == -1) {
        throw Exception('CSV must contain a student_id column');
      }

      // Extract student IDs from CSV
      final studentIds =
          rows.skip(1).map((row) => row[studentIdIndex].toString()).toList();
      return studentIds;
    } catch (e) {
      throw Exception('Failed to import students from CSV: $e');
    }
  }

  // Get class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final doc = await _firestore.collection('classes').doc(classId).get();
      if (!doc.exists) {
        return null;
      }
      return ClassModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get class: $e');
    }
  }

  // Get all classes for a student
  Stream<List<ClassModel>> getStudentClasses(String studentId) {
    return _firestore
        .collection('classes')
        .where('studentIds', arrayContains: studentId)
        .where('isArchived', isEqualTo: false) // Only get active classes
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addStudentToClass(String classId, String studentId) async {
    final classRef =
        FirebaseFirestore.instance.collection('classes').doc(classId);
    await classRef.update({
      'studentIds': FieldValue.arrayUnion([studentId])
    });
  }

  Future<void> markAttendance({
    required String classId,
    required String studentId,
    required DateTime date,
    required bool isPresent,
  }) async {
    final attendanceRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc('$classId-$studentId-${date.toIso8601String().substring(0, 10)}');

    await attendanceRef.set({
      'classId': classId,
      'studentId': studentId,
      'date': date,
      'isPresent': isPresent,
    });
  }
}
