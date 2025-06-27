import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/fee_calculator_service.dart'; // Import your fee calculator service

/// Enrollment Type options for payment flexibility
enum EnrollmentType {
  standard('Standard Enrollment', 'Regular enrollment with standard payment requirements.'),
  flexible('Flexible Enrollment', 'Flexible payment options with reduced minimum requirements.'),
  emergency('Emergency Enrollment', 'For urgent enrollment cases with low minimum payment.'),
  scholarship('Scholarship Enrollment', 'For students with scholarships or financial aid.');

  final String label;
  final String description;
  const EnrollmentType(this.label, this.description);
}

/// Payment Plan options
enum PaymentPlan {
  cashBasis('Cash Basis', 'Full payment today'),
  installment('Installment', 'Pay over time');

  final String label;
  final String description;
  const PaymentPlan(this.label, this.description);
}

/// Scholarship Type options
enum ScholarshipType {
  academic('Academic Excellence'),
  athletic('Athletic'),
  financial('Financial Need'),
  government('Government Voucher'),
  employee('Employee Discount'),
  family('Family Discount'),
  other('Other');

  final String label;
  const ScholarshipType(this.label);
}

/// Discount Type options
enum DiscountType {
  none('None'),
  earlyBird('Early Bird'),
  sibling('Sibling Discount'),
  academic('Academic Excellence'),
  financial('Financial Aid'),
  referral('Referral Discount'),
  loyalty('Loyalty Discount'),
  other('Other');

  final String label;
  const DiscountType(this.label);
}

/// Payment Method options
enum PaymentMethod {
  cash('Cash'),
  onlineTransfer('Online Transfer'),
  creditCard('Credit Card'),
  debitCard('Debit Card'),
  check('Check'),
  scholarship('Scholarship');

  final String label;
  const PaymentMethod(this.label);
}

/// Enrollment Status options
enum EnrollmentStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String label;
  const EnrollmentStatus(this.label);
}

/// Payment Status options
enum PaymentStatus {
  unpaid('Unpaid'),
  partial('Partially Paid'),
  paid('Fully Paid');

  final String label;
  const PaymentStatus(this.label);
}

/// Provider class to manage enrollment payment state
class EnrollmentPaymentProvider extends ChangeNotifier {
  // Selected values
  EnrollmentType _enrollmentType = EnrollmentType.standard;
  PaymentPlan _paymentPlan = PaymentPlan.installment;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  EnrollmentStatus _enrollmentStatus = EnrollmentStatus.pending;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  DiscountType _discountType = DiscountType.none;
  
  // Scholarship information
  bool _hasScholarship = false;
  ScholarshipType _scholarshipType = ScholarshipType.academic;
  double _scholarshipPercentage = 0.0;
  
  // Payment override (for admin/supervisor)
  bool _paymentOverride = false;
  String _overrideReason = '';
  
  // Fee details
  double _baseFee = 0.0;
  double _idFee = 150.0;
  double _systemFee = 120.0;
  double _bookFee = 0.0;
  double _otherFees = 0.0;
  double _discountAmount = 0.0;
  double _initialPaymentAmount = 0.0;
  String _gradeLevel = '';
  bool _isVoucherBeneficiary = false;
  String _semesterType = '1st Semester';
  String _currentAcademicYear = '';
  
  // Calculated values
  double _minimumPayment = 0.0;
  double _recommendedPayment = 0.0;
  double _totalFee = 0.0;
  
  // Payment guidance
  bool _isValidPayment = false;
  String _paymentValidationMessage = '';

  // Constructor
  EnrollmentPaymentProvider() {
    // Set default academic year based on current date
    final now = DateTime.now();
    final year = now.month >= 6 ? now.year : now.year - 1; // Academic year starts in June
    _currentAcademicYear = '$year-${year + 1}';
    
    // Initialize fee calculator service
    _initializeFees();
  }
  
  // Getters
  EnrollmentType get enrollmentType => _enrollmentType;
  PaymentPlan get paymentPlan => _paymentPlan;
  PaymentMethod get paymentMethod => _paymentMethod;
  EnrollmentStatus get enrollmentStatus => _enrollmentStatus;
  PaymentStatus get paymentStatus => _paymentStatus;
  DiscountType get discountType => _discountType;
  bool get hasScholarship => _hasScholarship;
  ScholarshipType get scholarshipType => _scholarshipType;
  double get scholarshipPercentage => _scholarshipPercentage;
  bool get paymentOverride => _paymentOverride;
  String get overrideReason => _overrideReason;
  double get baseFee => _baseFee;
  double get idFee => _idFee;
  double get systemFee => _systemFee;
  double get bookFee => _bookFee;
  double get otherFees => _otherFees;
  double get discountAmount => _discountAmount;
  double get initialPaymentAmount => _initialPaymentAmount;
  String get gradeLevel => _gradeLevel;
  bool get isVoucherBeneficiary => _isVoucherBeneficiary;
  String get semesterType => _semesterType;
  String get currentAcademicYear => _currentAcademicYear;
  double get minimumPayment => _minimumPayment;
  double get recommendedPayment => _recommendedPayment;
  double get totalFee => _totalFee;
  bool get isValidPayment => _isValidPayment;
  String get paymentValidationMessage => _paymentValidationMessage;
  
  // Calculated getters
  double get scholarshipAmount => hasScholarship ? (baseFee * scholarshipPercentage / 100) : 0.0;
  double get balanceRemaining => totalFee - initialPaymentAmount;
  double get paymentProgress => totalFee > 0 ? (initialPaymentAmount / totalFee).clamp(0.0, 1.0) : 0.0;
  String get paymentProgressPercentage => '${(paymentProgress * 100).toStringAsFixed(1)}%';
  
  // Setters
  void setEnrollmentType(EnrollmentType type) {
    _enrollmentType = type;
    _updateCalculations();
    notifyListeners();
  }
  
  void setPaymentPlan(PaymentPlan plan) {
    _paymentPlan = plan;
    _updateCalculations();
    notifyListeners();
  }
  
  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }
  
  void setEnrollmentStatus(EnrollmentStatus status) {
    _enrollmentStatus = status;
    notifyListeners();
  }
  
  void setPaymentStatus(PaymentStatus status) {
    _paymentStatus = status;
    notifyListeners();
  }
  
  void setDiscountType(DiscountType type) {
    _discountType = type;
    if (type == DiscountType.none) {
      _discountAmount = 0.0;
    }
    _updateCalculations();
    notifyListeners();
  }
  
  void setHasScholarship(bool value) {
    _hasScholarship = value;
    if (!value) {
      _scholarshipPercentage = 0.0;
    }
    _updateCalculations();
    notifyListeners();
  }
  
  void setScholarshipType(ScholarshipType type) {
    _scholarshipType = type;
    notifyListeners();
  }
  
  void setScholarshipPercentage(double percentage) {
    _scholarshipPercentage = percentage.clamp(0.0, 100.0);
    _updateCalculations();
    notifyListeners();
  }
  
  void setPaymentOverride(bool value) {
    _paymentOverride = value;
    if (!value) {
      _overrideReason = '';
    }
    _validatePayment();
    notifyListeners();
  }
  
  void setOverrideReason(String reason) {
    _overrideReason = reason;
    _validatePayment();
    notifyListeners();
  }
  
  void setBaseFee(double fee) {
    _baseFee = fee;
    _updateCalculations();
    notifyListeners();
  }
  
  void setIdFee(double fee) {
    _idFee = fee;
    _updateCalculations();
    notifyListeners();
  }
  
  void setSystemFee(double fee) {
    _systemFee = fee;
    _updateCalculations();
    notifyListeners();
  }
  
  void setBookFee(double fee) {
    _bookFee = fee;
    _updateCalculations();
    notifyListeners();
  }
  
  void setOtherFees(double fee) {
    _otherFees = fee;
    _updateCalculations();
    notifyListeners();
  }
  
  void setDiscountAmount(double amount) {
    _discountAmount = amount;
    _updateCalculations();
    notifyListeners();
  }
  
  void setInitialPaymentAmount(double amount) {
    _initialPaymentAmount = amount;
    _validatePayment();
    _updatePaymentStatus();
    notifyListeners();
  }
  
  void setGradeLevel(String level) async {
    _gradeLevel = level;
    await _initializeFees();
    notifyListeners();
  }
  
  void setIsVoucherBeneficiary(bool value) async {
    _isVoucherBeneficiary = value;
    await _initializeFees();
    notifyListeners();
  }
  
  void setSemesterType(String type) async {
    _semesterType = type;
    await _initializeFees();
    notifyListeners();
  }
  
  // Fee calculator service for dynamic fee calculations
  final FeeCalculatorService _feeCalculator = FeeCalculatorService();
  
  Future<void> _initializeFees() async {
    try {
      if (_gradeLevel.isNotEmpty) {
        _baseFee = await _feeCalculator.calculateBaseFee(
          gradeLevel: _gradeLevel,
          isCashBasis: _paymentPlan == PaymentPlan.cashBasis,
          isVoucherBeneficiary: _isVoucherBeneficiary,
          semester: _semesterType,
        );

        _idFee = await _feeCalculator.calculateIdFee(_gradeLevel);
        _systemFee = await _feeCalculator.calculateSystemFee(_gradeLevel);
        _bookFee = await _feeCalculator.calculateBookFee(_gradeLevel);

        await _updateCalculations();
      }
    } catch (e) {
      debugPrint('Error initializing fees: $e');
    }
  }
  
  /// Update all calculated values
  Future<void> _updateCalculations() async {
    try {
      // Calculate total fee
      _totalFee = _baseFee + _idFee + _systemFee + _bookFee + _otherFees;
      
      // Apply discounts and scholarships
      if (_hasScholarship) {
        final scholarshipAmount = _baseFee * _scholarshipPercentage / 100;
        _totalFee -= scholarshipAmount;
      }
      _totalFee -= _discountAmount;
      
      // Ensure total fee doesn't go below zero
      _totalFee = math.max(0.0, _totalFee);
      
      // Calculate minimum and recommended payments
      _minimumPayment = await _feeCalculator.calculateMinimumPayment(
        enrollmentType: _enrollmentType.label,
        totalFee: _totalFee,
        isCashBasis: _paymentPlan == PaymentPlan.cashBasis,
        hasFullScholarship: _hasScholarship && _scholarshipPercentage >= 100,
      );
      
      _recommendedPayment = await _feeCalculator.calculateRecommendedPayment(
        enrollmentType: _enrollmentType.label,
        totalFee: _totalFee,
        isCashBasis: _paymentPlan == PaymentPlan.cashBasis,
      );
      
      _validatePayment();
    } catch (e) {
      debugPrint('Error updating calculations: $e');
    }
  }
  
  /// Check if payment override is allowed for the current user
  bool canOverridePayment(String userRole) {
    // Implement your role-based logic here
    return userRole == 'admin' || userRole == 'supervisor' || _enrollmentType == EnrollmentType.emergency;
  }
  
  /// Validate payment amount
  void _validatePayment() {
    if (_paymentOverride) {
      _isValidPayment = _overrideReason.isNotEmpty;
      _paymentValidationMessage = _isValidPayment ? 'Payment override applied' : 'Please provide override reason';
      return;
    }

    if (_paymentPlan == PaymentPlan.cashBasis) {
      _isValidPayment = _initialPaymentAmount >= _totalFee;
      _paymentValidationMessage = _isValidPayment ? 'Valid full payment' : 'Full payment required for cash basis';
      return;
    }

    _isValidPayment = _initialPaymentAmount >= _minimumPayment;
    if (!_isValidPayment) {
      _paymentValidationMessage = 'Minimum payment required: ${_formatCurrency(_minimumPayment)}';
    } else if (_initialPaymentAmount < _recommendedPayment) {
      _paymentValidationMessage = 'Payment accepted, but recommended: ${_formatCurrency(_recommendedPayment)}';
    } else {
      _paymentValidationMessage = 'Valid payment amount';
    }
  }
  
  /// Update payment status based on current payment amount
  void _updatePaymentStatus() {
    if (_hasScholarship && _scholarshipPercentage >= 100) {
      _paymentStatus = PaymentStatus.paid;
    } else if (_initialPaymentAmount >= _totalFee) {
      _paymentStatus = PaymentStatus.paid;
    } else if (_initialPaymentAmount >= _minimumPayment) {
      _paymentStatus = PaymentStatus.partial;
    } else if (_initialPaymentAmount > 0) {
      _paymentStatus = PaymentStatus.partial;
    } else {
      _paymentStatus = PaymentStatus.unpaid;
    }
    
    // For emergency enrollments with no payment, require approval
    if (_enrollmentType == EnrollmentType.emergency && _initialPaymentAmount == 0) {
      _enrollmentStatus = EnrollmentStatus.pending;
    }
  }
  
  /// Load values from an existing enrollment (for editing)
  void loadFromEnrollment(Map<String, dynamic> enrollmentData) {
    // Implement this to load provider state from existing enrollment data
    // This would be used when editing an existing enrollment
  }
  
  /// Prepare data map for saving enrollment to Firestore
  Map<String, dynamic> toFirestoreData({required String studentId, required String cashierId, required String cashierName}) {
    return {
      'studentId': studentId,
      'enrollmentType': _enrollmentType.label,
      'paymentPlan': _paymentPlan.label,
      'status': _enrollmentStatus.name,
      'paymentStatus': _paymentStatus.name,
      'paymentMethod': _paymentMethod.label,
      'hasScholarship': _hasScholarship,
      'scholarshipType': _hasScholarship ? _scholarshipType.label : null,
      'scholarshipPercentage': _hasScholarship ? _scholarshipPercentage : null,
      'discountType': _discountType != DiscountType.none ? _discountType.label : null,
      'discountAmount': _discountAmount > 0 ? _discountAmount : null,
      'baseFee': _baseFee,
      'idFee': _idFee,
      'systemFee': _systemFee,
      'bookFee': _bookFee,
      'otherFees': _otherFees,
      'totalFee': _totalFee,
      'initialPaymentAmount': _initialPaymentAmount,
      'balanceRemaining': _totalFee - _initialPaymentAmount,
      'minimumPayment': _minimumPayment,
      'academicYear': _currentAcademicYear,
      'gradeLevel': _gradeLevel,
      'isVoucherBeneficiary': _isVoucherBeneficiary,
      'semesterType': _gradeLevel == 'College' ? _semesterType : null,
      'paymentOverride': _paymentOverride,
      'overrideReason': _paymentOverride ? _overrideReason : null,
      'overrideBy': _paymentOverride ? cashierName : null,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'cashierId': cashierId,
      'cashierName': cashierName,
    };
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }
}