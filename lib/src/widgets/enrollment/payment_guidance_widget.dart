import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../config/theme.dart';

/// A widget for displaying payment guidance
class PaymentGuidanceWidget extends StatelessWidget {
  const PaymentGuidanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    final totalFee = provider.totalFee;
    final currentPayment = provider.initialPaymentAmount;
    final minimumPayment = provider.minimumPayment;
    final recommendedPayment = provider.recommendedPayment;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Guidance',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Payment amounts display
          _buildPaymentAmountRow(
            label: 'Total Fee:',
            amount: totalFee,
            color: Colors.teal.shade700,
            currencyFormat: currencyFormat,
          ),
          _buildPaymentAmountRow(
            label: 'Minimum Payment:',
            amount: minimumPayment,
            color: Colors.orange.shade700,
            currencyFormat: currencyFormat,
          ),
          _buildPaymentAmountRow(
            label: 'Recommended Payment:',
            amount: recommendedPayment,
            color: Colors.green.shade700,
            currencyFormat: currencyFormat,
          ),
          _buildPaymentAmountRow(
            label: 'Current Payment:',
            amount: currentPayment,
            color: Colors.blue.shade700,
            currencyFormat: currencyFormat,
          ),

          const SizedBox(height: 16),

          // Payment progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Progress',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: provider.paymentProgress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentPayment >= totalFee
                      ? Colors.green.shade600
                      : currentPayment >= minimumPayment
                          ? Colors.blue.shade600
                          : Colors.orange.shade600,
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.paymentProgressPercentage} of total fee',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment status indicator
          _buildPaymentStatusIndicator(currentPayment, minimumPayment, totalFee),
          
          // Payment validation message (if any)
          if (!provider.isValidPayment)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.paymentValidationMessage,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build a row showing a payment amount
  Widget _buildPaymentAmountRow({
    required String label,
    required double amount,
    required Color color,
    required NumberFormat currencyFormat,
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
              color: Colors.teal.shade700,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build payment status indicator based on current payment
  Widget _buildPaymentStatusIndicator(double currentPayment, double minimumPayment, double totalFee) {
    String status;
    Color statusColor;
    IconData statusIcon;

    if (currentPayment >= totalFee) {
      status = 'Full Payment Complete';
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
    } else if (currentPayment >= minimumPayment) {
      status = 'Minimum Payment Met';
      statusColor = Colors.blue.shade700;
      statusIcon = Icons.check_circle_outline;
    } else if (currentPayment > 0) {
      status = 'Partial Payment (Below Minimum)';
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.warning;
    } else {
      status = 'No Payment';
      statusColor = Colors.red.shade600;
      statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}