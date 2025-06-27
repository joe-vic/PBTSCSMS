import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Service class to handle dynamic fee calculations
class FeeCalculatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for fee structures to avoid repeated Firestore calls
  Map<String, dynamic>? _cachedFeeStructure;
  DateTime? _lastFetchTime;
  
  /// Calculate base tuition fee based on grade level and payment plan
  Future<double> calculateBaseFee({
    required String gradeLevel,
    required bool isCashBasis,
    bool isVoucherBeneficiary = false,
    String semester = '1st Semester',
  }) async {
    // First check if we need to fetch the latest fee structure
    await _ensureFeeStructureLoaded();
    
    // If we have cached fee structure, use it
    if (_cachedFeeStructure != null) {
      final feeStructure = _cachedFeeStructure!;
      
      // Check if there's a specific fee structure for this grade level
      if (feeStructure.containsKey(gradeLevel)) {
        final levelFees = feeStructure[gradeLevel] as Map<String, dynamic>;
        
        // Handle voucher beneficiaries
        if (isVoucherBeneficiary && (gradeLevel == 'Grade 11' || gradeLevel == 'Grade 12')) {
          return levelFees['voucherFee'] as double? ?? 0.0;
        }
        
        // Handle college semester-based and payment plan-based fees
        if (gradeLevel == 'College') {
          final semesterFees = levelFees[semester] as Map<String, dynamic>?;
          if (semesterFees != null) {
            return isCashBasis 
                ? (semesterFees['cashFee'] as double? ?? 8500.0)
                : (semesterFees['installmentFee'] as double? ?? 10000.0);
          }
        }
        
        // Return standard fee for this level
        return levelFees['standardFee'] as double? ?? 8500.0;
      }
    }
    
    // Fallback to hardcoded values if fee structure not available
    switch (gradeLevel) {
      case 'Nursery':
      case 'Kinder 1':
      case 'Kinder 2':
      case 'Preparatory':
      case 'Grade 1':
      case 'Grade 2':
      case 'Grade 3':
      case 'Grade 4':
      case 'Grade 5':
      case 'Grade 6':
      case 'Grade 7':
      case 'Grade 8':
      case 'Grade 9':
      case 'Grade 10':
        return 8500.0;

      case 'Grade 11':
      case 'Grade 12':
        if (isVoucherBeneficiary) {
          return 0.0;
        } else {
          return 17500.0;
        }

      case 'College':
        if (isCashBasis) {
          return 8500.0;
        } else {
          return 10000.0;
        }

      default:
        return 8500.0;
    }
  }
  
  /// Calculate minimum payment based on enrollment type and total fee
  Future<double> calculateMinimumPayment({
    required String enrollmentType,
    required double totalFee,
    required bool isCashBasis,
    required bool hasFullScholarship,
  }) async {
    // For cash basis, full payment is required
    if (isCashBasis) return totalFee;
    
    // Full scholarship requires no payment
    if (hasFullScholarship) return 0.0;
    
    // First check if we need to fetch the latest payment policies
    await _ensureFeeStructureLoaded();
    
    // If we have cached fee structure, check for payment policies
    if (_cachedFeeStructure != null && _cachedFeeStructure!.containsKey('paymentPolicies')) {
      final policies = _cachedFeeStructure!['paymentPolicies'] as Map<String, dynamic>;
      
      if (policies.containsKey(enrollmentType)) {
        final policy = policies[enrollmentType] as Map<String, dynamic>;
        
        // Check for tiered minimum payments
        if (policy.containsKey('tieredMinimum') && policy['tieredMinimum'] == true) {
          final tiers = policy['tiers'] as List<dynamic>;
          
          // Find the appropriate tier for this fee amount
          for (final tier in tiers) {
            final tierMap = tier as Map<String, dynamic>;
            final maxAmount = tierMap['maxAmount'] as double? ?? double.infinity;
            
            if (totalFee <= maxAmount) {
              return tierMap['minimumPayment'] as double? ?? 0.0;
            }
          }
          
          // If no tier matches, use the default
          return policy['defaultMinimum'] as double? ?? 1000.0;
        } else {
          // Use percentage-based minimum
          final percentage = policy['minimumPercentage'] as double? ?? 0.2;
          final minimumAmount = policy['minimumAmount'] as double? ?? 1000.0;
          
          return math.max(totalFee * percentage, minimumAmount);
        }
      }
    }
    
    // Fallback to hardcoded values
    switch (enrollmentType) {
      case 'Standard Enrollment':
        // Standard installment: 20% or ₱1,000 minimum, whichever is higher
        return math.max(totalFee * 0.2, 1000.0);

      case 'Flexible Enrollment':
        // Flexible installment: Tiered system
        if (totalFee <= 5000) return 500;
        if (totalFee <= 10000) return 1000;
        if (totalFee <= 15000) return 1500;
        return 2000;

      case 'Emergency Enrollment':
        // Emergency: Very low minimum, requires approval
        return math.min(500, totalFee * 0.05);

      case 'Scholarship Enrollment':
        // Scholarship students may have different requirements
        return math.max(totalFee * 0.1, 300); // Lower minimum for scholarship students

      default:
        return math.max(totalFee * 0.2, 1000.0);
    }
  }
  
  /// Calculate recommended payment amount
  Future<double> calculateRecommendedPayment({
    required String enrollmentType,
    required double totalFee,
    required bool isCashBasis,
  }) async {
    // For cash basis, full payment is recommended
    if (isCashBasis) return totalFee;
    
    // First check if we need to fetch the latest payment policies
    await _ensureFeeStructureLoaded();
    
    // If we have cached fee structure, check for payment policies
    if (_cachedFeeStructure != null && _cachedFeeStructure!.containsKey('paymentPolicies')) {
      final policies = _cachedFeeStructure!['paymentPolicies'] as Map<String, dynamic>;
      
      if (policies.containsKey(enrollmentType)) {
        final policy = policies[enrollmentType] as Map<String, dynamic>;
        
        // Use recommended percentage
        final percentage = policy['recommendedPercentage'] as double? ?? 0.3;
        final minimumAmount = policy['recommendedAmount'] as double? ?? 1500.0;
        
        return math.max(totalFee * percentage, minimumAmount);
      }
    }
    
    // Fallback to hardcoded values
    switch (enrollmentType) {
      case 'Standard Enrollment':
        return math.max(totalFee * 0.3, 1500); // 30% recommended
      case 'Flexible Enrollment':
        return math.max(totalFee * 0.25, 1200); // 25% recommended
      case 'Emergency Enrollment':
        return math.max(totalFee * 0.15, 800); // 15% recommended
      case 'Scholarship Enrollment':
        return math.max(totalFee * 0.2, 600); // 20% recommended
      default:
        return math.max(totalFee * 0.3, 1500);
    }
  }
  
  /// Calculate ID fee based on grade level
  Future<double> calculateIdFee(String gradeLevel) async {
    // First check if we need to fetch the latest fee structure
    await _ensureFeeStructureLoaded();
    
    // If we have cached fee structure, check for ID fees
    if (_cachedFeeStructure != null && _cachedFeeStructure!.containsKey('idFees')) {
      final idFees = _cachedFeeStructure!['idFees'] as Map<String, dynamic>;
      
      if (idFees.containsKey(gradeLevel)) {
        return idFees[gradeLevel] as double? ?? 150.0;
      } else if (idFees.containsKey('default')) {
        return idFees['default'] as double? ?? 150.0;
      }
    }
    
    // Fallback to hardcoded values
    return gradeLevel == 'College' ? 250.0 : 150.0;
  }
  
  /// Calculate system fee
  Future<double> calculateSystemFee(String gradeLevel) async {
    // First check if we need to fetch the latest fee structure
    await _ensureFeeStructureLoaded();
    
    // If we have cached fee structure, check for system fees
    if (_cachedFeeStructure != null && _cachedFeeStructure!.containsKey('systemFees')) {
      final systemFees = _cachedFeeStructure!['systemFees'] as Map<String, dynamic>;
      
      if (systemFees.containsKey(gradeLevel)) {
        return systemFees[gradeLevel] as double? ?? 120.0;
      } else if (systemFees.containsKey('default')) {
        return systemFees['default'] as double? ?? 120.0;
      }
    }
    
    // Fallback to hardcoded value
    return 120.0;
  }
  
  /// Calculate book fee based on grade level
  Future<double> calculateBookFee(String gradeLevel) async {
    // First check if we need to fetch the latest fee structure
    await _ensureFeeStructureLoaded();
    
    // If we have cached fee structure, check for book fees
    if (_cachedFeeStructure != null && _cachedFeeStructure!.containsKey('bookFees')) {
      final bookFees = _cachedFeeStructure!['bookFees'] as Map<String, dynamic>;
      
      if (bookFees.containsKey(gradeLevel)) {
        return bookFees[gradeLevel] as double? ?? 0.0;
      } else if (bookFees.containsKey('default')) {
        return bookFees['default'] as double? ?? 0.0;
      }
    }
    
    // Fallback to hardcoded value (no book fee for SHS and College)
    if (gradeLevel == 'Grade 11' || gradeLevel == 'Grade 12' || gradeLevel == 'College') {
      return 0.0;
    }
    
    return 0.0; // Default to no book fee
  }
  
  /// Calculate total fee
  Future<double> calculateTotalFee({
    required String gradeLevel,
    required bool isCashBasis,
    required bool isVoucherBeneficiary,
    required String semester,
    required double scholarshipPercentage,
    required double discountAmount,
    double bookFee = 0.0,
    double otherFees = 0.0,
  }) async {
    final baseFee = await calculateBaseFee(
      gradeLevel: gradeLevel,
      isCashBasis: isCashBasis,
      isVoucherBeneficiary: isVoucherBeneficiary,
      semester: semester,
    );
    
    final idFee = await calculateIdFee(gradeLevel);
    final systemFee = await calculateSystemFee(gradeLevel);
    
    // Calculate total other fees
    double totalOtherFees = systemFee + idFee;
    
    // Add book fee for applicable levels
    if (gradeLevel != 'Grade 11' && gradeLevel != 'Grade 12' && gradeLevel != 'College') {
      totalOtherFees += bookFee;
    }
    
    // Add other miscellaneous fees
    totalOtherFees += otherFees;
    
    // Calculate scholarship discount
    double scholarshipAmount = 0.0;
    if (scholarshipPercentage > 0) {
      scholarshipAmount = (baseFee * scholarshipPercentage) / 100;
    }
    
    // Calculate total fee
    double totalFee = baseFee + totalOtherFees - discountAmount - scholarshipAmount;
    
    // Ensure total fee is not negative
    return math.max(0, totalFee);
  }
  
  /// Fetch fee structure from Firestore and cache it
  Future<void> _ensureFeeStructureLoaded() async {
    // If cache is valid (less than 1 hour old), use it
    if (_cachedFeeStructure != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!).inHours < 1) {
      return;
    }
    
    try {
      // Get the current academic year
      final now = DateTime.now();
      final year = now.month >= 6 ? now.year : now.year - 1; // Academic year starts in June
      final academicYear = '$year-${year + 1}';
      
      // Fetch fee structure from Firestore
      final doc = await _firestore
          .collection('feeStructures')
          .doc(academicYear)
          .get();
      
      if (doc.exists) {
        _cachedFeeStructure = doc.data();
        _lastFetchTime = DateTime.now();
      } else {
        // If no fee structure for current academic year, try to get the latest one
        final querySnapshot = await _firestore
            .collection('feeStructures')
            .orderBy('academicYear', descending: true)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          _cachedFeeStructure = querySnapshot.docs.first.data();
          _lastFetchTime = DateTime.now();
        } else {
          // No fee structure found, use defaults
          _cachedFeeStructure = null;
          _lastFetchTime = DateTime.now();
        }
      }
    } catch (e) {
      print('Error fetching fee structure: $e');
      // Use defaults on error
      _cachedFeeStructure = null;
      _lastFetchTime = DateTime.now();
    }
  }
  
  /// Clear cache to force refresh
  void clearCache() {
    _cachedFeeStructure = null;
    _lastFetchTime = null;
  }
}