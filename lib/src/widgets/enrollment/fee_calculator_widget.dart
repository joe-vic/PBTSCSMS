import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../config/theme.dart';

/// A widget for displaying fee calculations
class FeeCalculatorWidget extends StatelessWidget {
  const FeeCalculatorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined,
                  color: SMSTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fee Breakdown',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh calculations',
                onPressed: () {
                  // Refresh fee calculations
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fees refreshed')),
                  );
                },
                color: SMSTheme.primaryColor,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Base Tuition Fee
          _buildFeeRow(
            label: 'Base Tuition Fee',
            amount: provider.baseFee,
            currencyFormat: currencyFormat,
          ),

          // Conditional fees based on level
          if (provider.gradeLevel != 'Grade 11' &&
              provider.gradeLevel != 'Grade 12' &&
              provider.gradeLevel != 'College' &&
              provider.bookFee > 0)
            _buildFeeRow(
              label: 'Book Fee',
              amount: provider.bookFee,
              currencyFormat: currencyFormat,
            ),

          _buildFeeRow(
            label: 'ID Fee',
            amount: provider.idFee,
            currencyFormat: currencyFormat,
          ),

          _buildFeeRow(
            label: 'System Fee (SMS)',
            amount: provider.systemFee,
            currencyFormat: currencyFormat,
          ),

          if (provider.otherFees > 0)
            _buildFeeRow(
              label: 'Other Fees',
              amount: provider.otherFees,
              currencyFormat: currencyFormat,
            ),

          // Discounts
          if (provider.discountAmount > 0)
            _buildFeeRow(
              label: 'Discount (${provider.discountType.label})',
              amount: -provider.discountAmount,
              currencyFormat: currencyFormat,
              isDiscount: true,
            ),

          if (provider.hasScholarship && provider.scholarshipPercentage > 0)
            _buildFeeRow(
              label: 'Scholarship (${provider.scholarshipType.label})',
              amount: -provider.scholarshipAmount,
              currencyFormat: currencyFormat,
              isDiscount: true,
            ),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL AMOUNT:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.primaryColor,
                ),
              ),
              Text(
                currencyFormat.format(provider.totalFee),
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fee explanations for specific grade levels
          if (provider.gradeLevel == 'Grade 11' ||
              provider.gradeLevel == 'Grade 12')
            _buildSeniorHighFeeExplanation(provider.isVoucherBeneficiary),

          if (provider.gradeLevel == 'College')
            _buildCollegeFeeExplanation(
                provider.paymentPlan, provider.semesterType),
        ],
      ),
    );
  }

  /// Build a row showing a fee item
  Widget _buildFeeRow({
    required String label,
    required double amount,
    required NumberFormat currencyFormat,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: isDiscount
                  ? Colors.green.shade700
                  : SMSTheme.textPrimaryLight,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDiscount
                  ? Colors.green.shade700
                  : SMSTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Build explanation for Senior High School fees
  Widget _buildSeniorHighFeeExplanation(bool isVoucherBeneficiary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isVoucherBeneficiary ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVoucherBeneficiary
              ? Colors.green.shade200
              : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVoucherBeneficiary ? Icons.card_giftcard : Icons.payment,
            color: isVoucherBeneficiary
                ? Colors.green.shade700
                : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isVoucherBeneficiary
                  ? 'Government Voucher: Tuition fee is free, only pay system fees and other charges.'
                  : 'Regular SHS: Full tuition fee applies plus system fees and other charges.',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: isVoucherBeneficiary
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build explanation for College fees
  Widget _buildCollegeFeeExplanation(
      PaymentPlan paymentPlan, String semesterType) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'College Payment Options:',
            style: TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Full Payment: ₱8,500 per semester',
            style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12, color: Colors.purple.shade700),
          ),
          Text(
            '• Monthly Installment: ₱10,000 per semester (paid monthly before exams)',
            style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12, color: Colors.purple.shade700),
          ),
          Text(
            '• Current Semester: $semesterType',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '• Current Plan: ${paymentPlan.label}',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
