import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// A widget for entering payment details
class PaymentFormWidget extends StatefulWidget {
  const PaymentFormWidget({Key? key}) : super(key: key);

  @override
  _PaymentFormWidgetState createState() => _PaymentFormWidgetState();
}

class _PaymentFormWidgetState extends State<PaymentFormWidget> {
  final _initialPaymentController = TextEditingController();
  final _overrideReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers from provider
    final provider =
        Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    _initialPaymentController.text = provider.initialPaymentAmount.toString();
    _overrideReasonController.text = provider.overrideReason;

    // Add listeners
    _initialPaymentController.addListener(_updateInitialPayment);
    _overrideReasonController.addListener(_updateOverrideReason);
  }

  @override
  void dispose() {
    _initialPaymentController.removeListener(_updateInitialPayment);
    _overrideReasonController.removeListener(_updateOverrideReason);
    _initialPaymentController.dispose();
    _overrideReasonController.dispose();
    super.dispose();
  }

  void _updateInitialPayment() {
    final provider =
        Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    final amount = double.tryParse(_initialPaymentController.text) ?? 0.0;
    provider.setInitialPaymentAmount(amount);
  }

  void _updateOverrideReason() {
    final provider =
        Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    provider.setOverrideReason(_overrideReasonController.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canOverride = provider.canOverridePayment(
        authProvider.user?.email?.contains('admin') == true
            ? 'admin'
            : 'cashier');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Payment method dropdown
          DropdownButtonFormField<PaymentMethod>(
            value: provider.paymentMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.payment, color: Colors.green.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: PaymentMethod.values
                .map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                provider.setPaymentMethod(value);
              }
            },
            style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),

          // Initial payment amount
          TextFormField(
            controller: _initialPaymentController,
            decoration: InputDecoration(
              labelText: 'Initial Payment Amount',
              labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  Icon(Icons.monetization_on, color: Colors.green.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: provider.paymentPlan == PaymentPlan.cashBasis
                  ? 'Full payment required (${provider.totalFee.toStringAsFixed(2)})'
                  : 'Minimum: ${provider.minimumPayment.toStringAsFixed(2)}',
              helperStyle: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: provider.isValidPayment
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final amount = double.tryParse(value);
              if (amount == null) return 'Invalid number';
              if (amount < 0) return 'Must be positive';
              if (amount > provider.totalFee) return 'Cannot exceed total fee';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Payment override (for authorized users)
          if (canOverride) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Admin Override',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Override minimum payment requirement',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    subtitle: Text(
                      'Allows enrollment with any payment amount',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    value: provider.paymentOverride,
                    onChanged: (value) =>
                        provider.setPaymentOverride(value ?? false),
                    activeColor: Colors.amber.shade700,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (provider.paymentOverride) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _overrideReasonController,
                      decoration: InputDecoration(
                        labelText: 'Override Reason (Required)',
                        labelStyle: TextStyle(color: Colors.amber.shade800),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.amber.shade600),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      style:
                          TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
                      validator: (value) =>
                          provider.paymentOverride && (value?.isEmpty ?? true)
                              ? 'Override reason is required'
                              : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Enrollment status
          DropdownButtonFormField<EnrollmentStatus>(
            value: provider.enrollmentStatus,
            decoration: InputDecoration(
              labelText: 'Enrollment Status',
              labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  Icon(Icons.check_circle, color: Colors.green.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: EnrollmentStatus.values
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                provider.setEnrollmentStatus(value);
              }
            },
            style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),

          // Payment status info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(provider.paymentStatus)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _getPaymentStatusColor(provider.paymentStatus)
                      .withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _getPaymentStatusIcon(provider.paymentStatus),
                  color: _getPaymentStatusColor(provider.paymentStatus),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Status: ${provider.paymentStatus.label}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getPaymentStatusColor(provider.paymentStatus),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPaymentStatusDescription(provider.paymentStatus),
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _getPaymentStatusColor(provider.paymentStatus)
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green.shade700;
      case PaymentStatus.partial:
        return Colors.orange.shade700;
      case PaymentStatus.unpaid:
        return Colors.red.shade400;
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.partial:
        return Icons.timelapse;
      case PaymentStatus.unpaid:
        return Icons.error_outline;
    }
  }

  String _getPaymentStatusDescription(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Student has paid all required fees for enrollment.';
      case PaymentStatus.partial:
        return 'Student has made a partial payment or downpayment.';
      case PaymentStatus.unpaid:
        return 'Student has not made any payment yet.';
    }
  }
}
