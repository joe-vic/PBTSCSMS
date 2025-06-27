import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../config/theme.dart';

/// A widget for selecting payment plan type
class PaymentPlanSelector extends StatelessWidget {
  const PaymentPlanSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Plan Type',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How will the student pay the tuition fees?',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Cash Basis Option
              Expanded(
                child: _buildPaymentPlanCard(
                  context,
                  plan: PaymentPlan.cashBasis,
                  isSelected: provider.paymentPlan == PaymentPlan.cashBasis,
                  onTap: () => provider.setPaymentPlan(PaymentPlan.cashBasis),
                ),
              ),

              const SizedBox(width: 16),

              // Installment Option
              Expanded(
                child: _buildPaymentPlanCard(
                  context,
                  plan: PaymentPlan.installment,
                  isSelected: provider.paymentPlan == PaymentPlan.installment,
                  onTap: () => provider.setPaymentPlan(PaymentPlan.installment),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payment plan description
          _buildPaymentPlanDescription(provider.paymentPlan, provider.gradeLevel),
        ],
      ),
    );
  }
  
  /// Build a card for a payment plan option
  Widget _buildPaymentPlanCard(
    BuildContext context, {
    required PaymentPlan plan,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = plan == PaymentPlan.cashBasis
        ? Colors.blue.shade600
        : Colors.orange.shade600;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              plan == PaymentPlan.cashBasis ? Icons.payments : Icons.schedule_send,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              plan.label,
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? color
                    : Colors.grey.shade600,
              ),
            ),
            Text(
              plan.description,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: isSelected
                    ? color
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a description for the selected payment plan
  Widget _buildPaymentPlanDescription(PaymentPlan plan, String gradeLevel) {
    final bool isCollege = gradeLevel == 'College';
    String description;
    Color color;
    
    if (plan == PaymentPlan.cashBasis) {
      color = Colors.blue.shade700;
      description = isCollege
          ? 'Full payment of ₱8,500 for the semester. College students get a discount when paying in full.'
          : 'Full payment of all fees in one transaction. This will immediately confirm the enrollment.';
    } else {
      color = Colors.orange.shade700;
      description = isCollege
          ? 'Pay ₱10,000 in installments for the semester. Payments must be made monthly before exams.'
          : 'Pay the minimum required amount now and the rest in installments according to the school\'s payment schedule.';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            plan == PaymentPlan.cashBasis ? Icons.info_outline : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}