import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String gradeLevel;
  final String? strand;
  final String? course;
  final String parentId;
  final int age;
  final String gender;
  final Map<String, String> address;
  final String contactNumber;
  final DateTime dateOfBirth;
  final String placeOfBirth;
  final String? religion;
  final double? height; // in cm
  final double? weight; // in kg
  final Map<String, dynamic> guardianInfo;
  final Map<String, dynamic> fatherInfo;
  final Map<String, dynamic> motherInfo;
  final String? lastSchoolName;
  final String? lastSchoolAddress;

  Student({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.gradeLevel,
    this.strand,
    this.course,
    required this.parentId,
    required this.age,
    required this.gender,
    required this.address,
    required this.contactNumber,
    required this.dateOfBirth,
    required this.placeOfBirth,
    this.religion,
    this.height,
    this.weight,
    required this.guardianInfo,
    required this.fatherInfo,
    required this.motherInfo,
    this.lastSchoolName,
    this.lastSchoolAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'gradeLevel': gradeLevel,
      'strand': strand,
      'course': course,
      'parentId': parentId,
      'age': age,
      'gender': gender,
      'address': address,
      'contactNumber': contactNumber,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'placeOfBirth': placeOfBirth,
      'religion': religion,
      'height': height,
      'weight': weight,
      'guardianInfo': guardianInfo,
      'fatherInfo': fatherInfo,
      'motherInfo': motherInfo,
      'lastSchoolName': lastSchoolName,
      'lastSchoolAddress': lastSchoolAddress,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? '',
      strand: json['strand'] as String?,
      course: json['course'] as String?,
      parentId: json['parentId'] as String? ?? '',
      age: json['age'] != null
          ? (json['age'] is int
              ? json['age'] as int
              : int.tryParse(json['age'].toString()) ?? 0)
          : 0,
      gender: json['gender'] as String? ?? '',
      address: json['address'] != null
          ? Map<String, String>.from(
              (json['address'] as Map).map((key, value) => MapEntry(key, value?.toString() ?? '')))
          : {'houseNo': '', 'barangay': '', 'municipality': '', 'province': ''},
      contactNumber: json['contactNumber'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? (json['dateOfBirth'] is Timestamp
              ? (json['dateOfBirth'] as Timestamp).toDate()
              : DateTime.tryParse(json['dateOfBirth'].toString()) ?? DateTime.now())
          : DateTime.now(),
      placeOfBirth: json['placeOfBirth'] as String? ?? '',
      religion: json['religion'] as String?,
      height: json['height'] != null
          ? (json['height'] is num
              ? (json['height'] as num).toDouble()
              : double.tryParse(json['height'].toString()))
          : null,
      weight: json['weight'] != null
          ? (json['weight'] is num
              ? (json['weight'] as num).toDouble()
              : double.tryParse(json['weight'].toString()))
          : null,
      guardianInfo: json['guardianInfo'] != null
          ? Map<String, dynamic>.from(
              (json['guardianInfo'] as Map).map((key, value) => MapEntry(key, value?.toString() ?? '')))
          : {'lastName': '', 'firstName': '', 'middleName': '', 'occupation': '', 'contactNumber': ''},
      fatherInfo: json['fatherInfo'] != null
          ? Map<String, dynamic>.from(
              (json['fatherInfo'] as Map).map((key, value) => MapEntry(key, value?.toString() ?? '')))
          : {'lastName': '', 'firstName': '', 'middleName': '', 'occupation': '', 'contactNumber': '', 'email': ''},
      motherInfo: json['motherInfo'] != null
          ? Map<String, dynamic>.from(
              (json['motherInfo'] as Map).map((key, value) => MapEntry(key, value?.toString() ?? '')))
          : {'lastName': '', 'firstName': '', 'middleName': '', 'occupation': '', 'contactNumber': '', 'email': ''},
      lastSchoolName: json['lastSchoolName'] as String?,
      lastSchoolAddress: json['lastSchoolAddress'] as String?,
    );
  }
}