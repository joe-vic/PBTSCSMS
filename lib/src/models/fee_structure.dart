// Define the fee calculation structure for different educational levels
class FeeCalculator {
  // Calculate fees based on educational level and other parameters
  static Map<String, double> calculateFees({
    required String gradeLevel,
    required String branch,
    bool isVoucherBeneficiary = false,
    String paymentType = 'Full', // 'Full' or 'Installment'
    bool hasDiscount = false,
    double discountPercentage = 0.0,
  }) {
    double tuitionFee = 0.0;
    double miscFee = 0.0;
    double idFee = 150.0; // Standard ID fee
    double systemFee = 500.0; // Standard system fee
    double bookFee = 0.0;
    double discount = 0.0;
    
    // NKP, Elementary, JHS
    if (_isBasicEducation(gradeLevel)) {
      tuitionFee = 8500.0;
      bookFee = 2500.0;
      miscFee = 1000.0;
    } 
    // SHS with voucher program
    else if (_isSHS(gradeLevel)) {
      if (isVoucherBeneficiary) {
        tuitionFee = 0.0; // Covered by government
        miscFee = 1500.0;
      } else {
        tuitionFee = 17500.0;
        miscFee = 1500.0;
      }
    } 
    // College with payment options
    else if (gradeLevel == 'College') {
      miscFee = 2000.0;
      
      if (paymentType == 'Full') {
        tuitionFee = 8500.0;
        // Apply full payment discount if applicable
        if (hasDiscount) {
          discount = tuitionFee * (discountPercentage / 100);
        }
      } else {
        tuitionFee = 10000.0; // Installment has higher total
      }
    }
    
    // Calculate total
    double totalFee = tuitionFee + miscFee + idFee + systemFee + bookFee - discount;
    
    return {
      'tuitionFee': tuitionFee,
      'miscFee': miscFee,
      'idFee': idFee,
      'systemFee': systemFee,
      'bookFee': bookFee,
      'discount': discount,
      'totalFee': totalFee,
    };
  }
  
  // Helper methods for educational level categorization
  static bool _isBasicEducation(String gradeLevel) {
    return gradeLevel == 'Nursery' || 
           gradeLevel == 'Kinder 1' || 
           gradeLevel == 'Kinder 2' || 
           gradeLevel == 'Preparatory' ||
           (gradeLevel.startsWith('Grade') && 
           int.tryParse(gradeLevel.split(' ').last) != null && 
           int.parse(gradeLevel.split(' ').last) <= 10);
  }
  
  static bool _isSHS(String gradeLevel) {
    return gradeLevel == 'Grade 11' || gradeLevel == 'Grade 12';
  }
  
  // Get available payment options based on grade level
  static List<String> getPaymentOptions(String gradeLevel) {
    if (gradeLevel == 'College') {
      return ['Full', 'Installment'];
    } else {
      return ['Full', 'Partial'];
    }
  }
  
  // Generate payment schedule for installment plans
  static List<Map<String, dynamic>> generatePaymentSchedule({
    required String gradeLevel,
    required double totalFee,
    required String paymentType,
    required DateTime enrollmentDate,
  }) {
    List<Map<String, dynamic>> schedule = [];
    
    if (paymentType == 'Full') {
      schedule.add({
        'dueDate': enrollmentDate,
        'description': 'Full Payment',
        'amount': totalFee,
        'isPaid': false,
      });
    } else if (paymentType == 'Installment' && gradeLevel == 'College') {
      // College installment: Split into 5 monthly payments
      double monthlyPayment = totalFee / 5;
      for (int i = 0; i < 5; i++) {
        DateTime dueDate = DateTime(
          enrollmentDate.year, 
          enrollmentDate.month + i, 
          15
        ); // Due on the 15th of each month
        
        schedule.add({
          'dueDate': dueDate,
          'description': 'Installment ${i + 1}',
          'amount': monthlyPayment,
          'isPaid': false,
        });
      }
    } else if (paymentType == 'Partial') {
      // Partial payment for other levels: 50% now, 50% later
      double downPayment = totalFee * 0.5;
      double finalPayment = totalFee - downPayment;
      
      // Initial payment (now)
      schedule.add({
        'dueDate': enrollmentDate,
        'description': 'Initial Payment (50%)',
        'amount': downPayment,
        'isPaid': false,
      });
      
      // Final payment (2 months later)
      DateTime finalDueDate = DateTime(
        enrollmentDate.year, 
        enrollmentDate.month + 2, 
        enrollmentDate.day
      );
      
      schedule.add({
        'dueDate': finalDueDate,
        'description': 'Final Payment (50%)',
        'amount': finalPayment,
        'isPaid': false,
      });
    }
    
    return schedule;
  }
}

class FeeReduction {
  final String type;
  final String category;
  final double amount;
  final String? description;

  FeeReduction({
    required this.type,
    required this.category,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
    };
  }

  factory FeeReduction.fromJson(Map<String, dynamic> json) {
    return FeeReduction(
      type: json['type'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}