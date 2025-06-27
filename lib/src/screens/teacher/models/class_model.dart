import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String teacherId;
  final List<String> subjects;
  final bool isHomeroom;
  final String gradeLevel;
  final String section;
  List<String> studentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final DateTime? archivedAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.subjects,
    required this.isHomeroom,
    required this.gradeLevel,
    required this.section,
    required this.studentIds,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.archivedAt,
  });

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      name: map['name'] ?? '',
      teacherId: map['teacherId'] ?? '',
      subjects: List<String>.from(map['subjects'] ?? []),
      isHomeroom: map['isHomeroom'] ?? false,
      gradeLevel: map['gradeLevel'] ?? '',
      section: map['section'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: map['isArchived'] ?? false,
      archivedAt: map['archivedAt'] != null
          ? (map['archivedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'subjects': subjects,
      'isHomeroom': isHomeroom,
      'gradeLevel': gradeLevel,
      'section': section,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? teacherId,
    List<String>? subjects,
    bool? isHomeroom,
    String? gradeLevel,
    String? section,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      subjects: subjects ?? this.subjects,
      isHomeroom: isHomeroom ?? this.isHomeroom,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      section: section ?? this.section,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
