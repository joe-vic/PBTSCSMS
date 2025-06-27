import 'package:flutter/material.dart';
import '../models/enrollment_form_state.dart';
import '../utils/number_formatter.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/dropdown_field.dart';

class PaymentInfoForm extends StatelessWidget {
  final EnrollmentFormState formState;
  final VoidCallback onChanged;

  const PaymentInfoForm({
    Key? key,
    required this.formState,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Scheme Selection
        DropdownField(
          label: 'Payment Scheme',
          value: formState.paymentScheme,
          items: const [
            'Standard Full Payment',
            'Standard Installment',
            'Flexible Installment',
            'Scholarship Plan',
            'Emergency Plan',
          ],
          onChanged: (value) {
            formState.paymentScheme = value ?? 'Standard Installment';
            onChanged();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Payment scheme is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Payment Method
        DropdownField(
          label: 'Payment Method',
          value: formState.paymentMethod,
          items: const [
            'Cash',
            'Check',
            'Bank Transfer',
            'GCash',
            'Credit Card',
          ],
          onChanged: (value) {
            formState.paymentMethod = value ?? 'Cash';
            onChanged();
          },
        ),
        const SizedBox(height: 16),

        // Initial Payment Amount
        CustomTextField(
          label: 'Initial Payment Amount',
          value: formState.initialPaymentAmount.toString(),
          onChanged: (value) {
            formState.initialPaymentAmount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
            onChanged();
          },
          keyboardType: TextInputType.number,
          inputFormatters: [NumberFormatter()],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Initial payment amount is required';
            }
            final amount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
            final minPayment = formState.getMinimumPayment(formState.totalAmountDue);
            if (amount < minPayment) {
              return 'Minimum payment of ${minPayment.toStringAsFixed(2)} required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Fee Breakdown
        const Text(
          'Fee Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Book Fee
        CustomTextField(
          label: 'Book Fee',
          value: formState.bookFee.toString(),
          onChanged: (value) {
            formState.bookFee = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
            onChanged();
          },
          keyboardType: TextInputType.number,
          inputFormatters: [NumberFormatter()],
        ),
        const SizedBox(height: 8),

        // ID Fee
        CustomTextField(
          label: 'ID Fee',
          value: formState.idFee.toString(),
          onChanged: (value) {
            formState.idFee = double.tryParse(value.replaceAll(',', '')) ?? 200.0;
            onChanged();
          },
          keyboardType: TextInputType.number,
          inputFormatters: [NumberFormatter()],
        ),
        const SizedBox(height: 8),

        // System Fee
        CustomTextField(
          label: 'System Fee',
          value: formState.systemFee.toString(),
          onChanged: (value) {
            formState.systemFee = double.tryParse(value.replaceAll(',', '')) ?? 120.0;
            onChanged();
          },
          keyboardType: TextInputType.number,
          inputFormatters: [NumberFormatter()],
        ),
        const SizedBox(height: 8),

        // Other Fees
        CustomTextField(
          label: 'Other Fees',
          value: formState.otherFees.toString(),
          onChanged: (value) {
            formState.otherFees = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
            onChanged();
          },
          keyboardType: TextInputType.number,
          inputFormatters: [NumberFormatter()],
        ),
        const SizedBox(height: 16),

        // Total Amount
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount Due: ₱${formState.totalAmountDue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Initial Payment: ₱${formState.initialPaymentAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                'Balance: ₱${(formState.totalAmountDue - formState.initialPaymentAmount).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        if (formState.needsApproval()) ...[
          const SizedBox(height: 16),
          const Text(
            'This payment scheme requires approval',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Approval Notes',
            value: formState.approvalNotes,
            onChanged: (value) {
              formState.approvalNotes = value;
              onChanged();
            },
            maxLines: 3,
            validator: (value) {
              if (formState.needsApproval() && (value == null || value.isEmpty)) {
                return 'Please provide notes for approval';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
} 