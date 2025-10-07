import 'package:flutter/material.dart';
import '../../../../models/fee_structure.dart';

// Fee Reduction Types
enum FeeReductionType {
  scholarship('Scholarship', Icons.school),
  discount('Discount', Icons.discount),
  voucher('Voucher', Icons.card_giftcard);

  final String label;
  final IconData icon;

  const FeeReductionType(this.label, this.icon);
}

// Enrollment Type Enum
enum EnrollmentType {
  online, // Parent/Student online enrollment (creates pending enrollment)
  cashier, // Cashier walk-in enrollment (direct processing)
  processing // Cashier processing pending online enrollment
}

// Primary Contact Source
enum PrimaryContactSource { none, mother, father, manual }

// Predefined fee reduction categories
final Map<FeeReductionType, List<String>> feeReductionCategories = {
  FeeReductionType.scholarship: [
    'Academic Excellence',
    'Athletic',
    'Financial Need',
    'Merit-based',
    'Special Program',
  ],
  FeeReductionType.discount: [
    'Early Bird',
    'Sibling Discount',
    'Employee Child',
    'Referral',
    'Loyalty',
    'Promotional',
  ],
  FeeReductionType.voucher: [
    'Government SHS',
    'Local Government',
    'Private Sponsor',
  ],
};

class EnrollmentFormState {
  // Required Student Information
  String lastName = '';
  String firstName = '';
  String middleName = '';
  String streetAddress = '';
  String region = 'REGION IV-A';
  String province = 'RIZAL';
  String municipality = 'BINANGONAN';
  String barangay = '';
  String gender = 'Male';
  DateTime? dateOfBirth;
  String placeOfBirth = '';

  // Optional Student Information
  String? religion; // Optional field
  double? height;
  double? weight;
  String? lastSchoolName;
  String? lastSchoolAddress;

  // Required Educational Information
  String? gradeLevel;
  String? branch;
  String? strand;
  String? course;

  List<Map<String, dynamic>> additionalContacts = [];

  // Parent/Guardian Information
  String? motherLastName;
  String? motherFirstName;
  String? motherMiddleName;
  String? motherOccupation;
  String? motherContact;
  String? motherFacebook;

  String? fatherLastName;
  String? fatherFirstName;
  String? fatherMiddleName;
  String? fatherOccupation;
  String? fatherContact;
  String? fatherFacebook;

  String? primaryLastName;
  String? primaryFirstName;
  String? primaryMiddleName;
  String? primaryOccupation;
  String? primaryContact;
  String? primaryFacebook;
  String? primaryRelationship = 'Parent';

  // Academic Information
  String? collegeYearLevel;
  String? semesterType;
  String academicYear = '';

  // Payment Configuration
  String paymentScheme = 'Standard Installment';
  List<FeeReduction> feeReductions = [];
  String paymentMethod = 'Cash';
  double initialPaymentAmount = 0.0;
  bool requiresApproval = false;
  String approvalNotes = '';

  // NEW: Additional payment fields for your billing structure
  String paymentType = 'cash'; // cash, installment, downPayment
  double downPayment = 0.0;
  double monthlyInstallment = 0.0;
  int installmentMonths = 0;

  // Status Fields
  String enrollmentStatus = 'pending';
  String paymentStatus = 'unpaid';

  // Fees
  double bookFee = 0.0;
  double idFee = 0.0;
  double systemFee = 0.0;
  double otherFees = 0.0;
  double tuitionFee = 0.0; 
  List<Map<String, dynamic>> appliedDiscounts = [];
  double totalDiscountAmount = 0.0;

 

  // Computed Fields
  double totalAmountDue = 0.0;
  double totalAmountPaid = 0.0;
  double balanceRemaining = 0.0;
  DateTime? nextPaymentDueDate;

  // NEW: Graduation fee calculation based on your structure
  double get graduationFee {
    if (gradeLevel == null) return 0.0;
    
    if (gradeLevel!.contains('Kinder 2')) {
      return 2500.0;
    } else if (gradeLevel!.contains('Grade 6') || gradeLevel!.contains('Grade 10')) {
      return 3500.0;
    } else if (gradeLevel!.contains('Grade 12')) {
      return 4000.0;
    } else if (gradeLevel!.contains('4th Year College') || gradeLevel!.contains('Senior')) {
      return 5500.0;
    }
    return 0.0;
  }

  // NEW: Updated total amount calculation
  double get calculatedTotalAmountDue {
    return tuitionFee + bookFee + idFee + systemFee + otherFees + graduationFee;
  }

  // NEW: Balance calculation
  double get balance {
    return calculatedTotalAmountDue - initialPaymentAmount;
  }

  double get finalAmountDue => calculatedTotalAmountDue - totalDiscountAmount;

  // Validation States
  Map<String, bool> validationStates = {
    'lastName': false,
    'firstName': false,
    'gender': true, // Default value is 'Male'
    'dateOfBirth': false,
    'region': true, // Default value is 'REGION IV-A'
    'province': true, // Default value is 'RIZAL'
    'municipality': true, // Default value is 'BINANGONAN'
    'barangay': false,
    'streetAddress': false,
    // Parent Information Validation States
    'motherLastName': false,
    'motherFirstName': false,
    'motherContact': false,
    'fatherLastName': false,
    'fatherFirstName': false,
    'fatherContact': false,
    'primaryLastName': false,
    'primaryFirstName': false,
    'primaryContact': false,
  };

  // Constructor
  EnrollmentFormState() {
    // Initialize validation states based on default values
    validationStates['gender'] = gender.isNotEmpty;
    validationStates['region'] = region.isNotEmpty;
    validationStates['province'] = province.isNotEmpty;
    validationStates['municipality'] = municipality.isNotEmpty;
  }

  // Helper Methods
  bool needsApproval() {
    return paymentScheme.contains('Emergency') ||
        (paymentScheme.contains('Flexible') && initialPaymentAmount < 500);
  }

  double getMinimumPayment(double totalFee,
      [Map<String, dynamic>? adminSettings]) {
    final settings = adminSettings ?? {};

    switch (paymentScheme) {
      case 'Standard Full Payment':
        return totalFee;
      case 'Standard Installment':
        final minPercentage =
            (settings['standardInstallmentMinimumPercentage'] as num?)
                    ?.toDouble() ??
                20.0;
        final minAmount = (settings['standardInstallmentMinimumAmount'] as num?)
                ?.toDouble() ??
            1000.0;
        final calculatedMin = totalFee * (minPercentage / 100);
        return calculatedMin > minAmount ? calculatedMin : minAmount;
      case 'Flexible Installment':
        return (settings['flexibleInstallmentMinimumAmount'] as num?)
                ?.toDouble() ??
            500.0;
      default:
        return 0.0;
    }
  }

  // NEW: Generate student ID using your structure  
  String generateStudentId() {
    final now = DateTime.now();
    final year = now.year;
    final sequence = now.millisecondsSinceEpoch.toString().substring(8);
    return 'PBTS-MAC-$year-$sequence';
  }

  // Factory constructor to create from JSON
  factory EnrollmentFormState.fromJson(Map<String, dynamic> json) {
    final state = EnrollmentFormState();
    state.lastName = json['lastName'] ?? '';
    state.firstName = json['firstName'] ?? '';
    state.middleName = json['middleName'] ?? '';
    state.streetAddress = json['streetAddress'] ?? '';
    state.province = json['province'] ?? 'RIZAL';
    state.municipality = json['municipality'] ?? 'BINANGONAN';
    state.barangay = json['barangay'] ?? '';
    state.gender = json['gender'] ?? 'Male';
    state.dateOfBirth = json['dateOfBirth'] != null
        ? DateTime.parse(json['dateOfBirth'])
        : null;
    state.placeOfBirth = json['placeOfBirth'] ?? '';
    state.religion = json['religion'];
    state.height = (json['height'] as num?)?.toDouble();
    state.weight = (json['weight'] as num?)?.toDouble();
    state.lastSchoolName = json['lastSchoolName'];
    state.lastSchoolAddress = json['lastSchoolAddress'];
    state.gradeLevel = json['gradeLevel'];
    state.branch = json['branch'];
    state.strand = json['strand'];
    state.course = json['course'];
    
    // Payment fields
    state.paymentScheme = json['paymentScheme'] ?? 'Standard Installment';
    state.paymentMethod = json['paymentMethod'] ?? 'Cash';
    state.initialPaymentAmount = (json['initialPaymentAmount'] as num?)?.toDouble() ?? 0.0;
    state.paymentType = json['paymentType'] ?? 'cash';
    state.downPayment = (json['downPayment'] as num?)?.toDouble() ?? 0.0;
    state.monthlyInstallment = (json['monthlyInstallment'] as num?)?.toDouble() ?? 0.0;
    state.installmentMonths = (json['installmentMonths'] as num?)?.toInt() ?? 0;
    
    // Fee fields
    state.tuitionFee = (json['tuitionFee'] as num?)?.toDouble() ?? 0.0;
    state.bookFee = (json['bookFee'] as num?)?.toDouble() ?? 0.0;
    state.idFee = (json['idFee'] as num?)?.toDouble() ?? 200.0;
    state.systemFee = (json['systemFee'] as num?)?.toDouble() ?? 120.0;
    state.otherFees = (json['otherFees'] as num?)?.toDouble() ?? 0.0;
        
    state.appliedDiscounts = List<Map<String, dynamic>>.from(json['appliedDiscounts'] ?? []);
    state.totalDiscountAmount = (json['totalDiscountAmount'] as num?)?.toDouble() ?? 0.0;

    state.totalAmountDue = (json['totalAmountDue'] as num?)?.toDouble() ?? 0.0;
    return state;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'streetAddress': streetAddress,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'placeOfBirth': placeOfBirth,
      'religion': religion,
      'height': height,
      'weight': weight,
      'lastSchoolName': lastSchoolName,
      'lastSchoolAddress': lastSchoolAddress,
      'gradeLevel': gradeLevel,
      'branch': branch,
      'strand': strand,
      'course': course,
      'collegeYearLevel': collegeYearLevel,
      'semesterType': semesterType,
      'academicYear': academicYear,
      
      // Payment information
      'paymentScheme': paymentScheme,
      'paymentMethod': paymentMethod,
      'initialPaymentAmount': initialPaymentAmount,
      'paymentType': paymentType,
      'downPayment': downPayment,
      'monthlyInstallment': monthlyInstallment,
      'installmentMonths': installmentMonths,
      
      // Fee information
      'tuitionFee': tuitionFee,
      'bookFee': bookFee,
      'idFee': idFee,
      'systemFee': systemFee,
      'otherFees': otherFees,
      'graduationFee': graduationFee,
      'appliedDiscounts': appliedDiscounts,
      'totalDiscountAmount': totalDiscountAmount,
      
      // Calculated fields
      'totalAmountDue': calculatedTotalAmountDue,
      'balance': balance,
      
      // Status
      'enrollmentStatus': enrollmentStatus,
      'paymentStatus': paymentStatus,
      
      // Parent information
      'motherLastName': motherLastName,
      'motherFirstName': motherFirstName,
      'motherMiddleName': motherMiddleName,
      'motherOccupation': motherOccupation,
      'motherContact': motherContact,
      'motherFacebook': motherFacebook,
      
      'fatherLastName': fatherLastName,
      'fatherFirstName': fatherFirstName,
      'fatherMiddleName': fatherMiddleName,
      'fatherOccupation': fatherOccupation,
      'fatherContact': fatherContact,
      'fatherFacebook': fatherFacebook,
      
      'primaryLastName': primaryLastName,
      'primaryFirstName': primaryFirstName,
      'primaryMiddleName': primaryMiddleName,
      'primaryOccupation': primaryOccupation,
      'primaryContact': primaryContact,
      'primaryFacebook': primaryFacebook,
      'primaryRelationship': primaryRelationship,
    };
  }
}