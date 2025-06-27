import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late, excused }

class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${map['status'] ?? 'present'}',
        orElse: () => AttendanceStatus.present,
      ),
      remarks: map['remarks'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'date': Timestamp.fromDate(date),
      'status': status.toString().split('.').last,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? classId,
    DateTime? date,
    AttendanceStatus? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AttendanceSession {
  final String id;
  final String classId;
  final DateTime date;
  final Map<String, AttendanceRecord> records;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceSession({
    required this.id,
    required this.classId,
    required this.date,
    required this.records,
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceSession.fromMap(String id, Map<String, dynamic> map) {
    final recordsMap = map['records'] as Map<String, dynamic>? ?? {};
    final records = recordsMap.map((key, value) => MapEntry(
          key,
          AttendanceRecord.fromMap(key, value as Map<String, dynamic>),
        ));

    return AttendanceSession(
      id: id,
      classId: map['classId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      records: records,
      isComplete: map['isComplete'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'date': Timestamp.fromDate(date),
      'records': records.map((key, value) => MapEntry(key, value.toMap())),
      'isComplete': isComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AttendanceSession copyWith({
    String? id,
    String? classId,
    DateTime? date,
    Map<String, AttendanceRecord>? records,
    bool? isComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceSession(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      records: records ?? this.records,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
