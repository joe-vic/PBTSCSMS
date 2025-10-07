import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enrollment_form_state.dart';
import '../utils/number_formatter.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/dropdown_field.dart';
import 'package:intl/intl.dart';
import '../services/enrollment_service.dart';

class PaymentInfoForm extends StatefulWidget {
  final EnrollmentFormState formState;
  final VoidCallback onChanged;

  const PaymentInfoForm({
    Key? key,
    required this.formState,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PaymentInfoForm> createState() => _PaymentInfoFormState();
}

class _PaymentInfoFormState extends State<PaymentInfoForm> {
  final TextEditingController _bookFeeController = TextEditingController();
  final TextEditingController _idFeeController = TextEditingController();
  final TextEditingController _systemFeeController = TextEditingController();
  final TextEditingController _otherFeesController = TextEditingController();
  final TextEditingController _initialPaymentController = TextEditingController();
  final EnrollmentService _enrollmentService = EnrollmentService();
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadTuitionFee();
    _calculateTotals();
  }

void _initializeControllers() {
  _bookFeeController.text = widget.formState.bookFee > 0 
      ? widget.formState.bookFee.toStringAsFixed(0) 
      : '';
  _idFeeController.text = widget.formState.idFee > 0 
      ? widget.formState.idFee.toStringAsFixed(0) 
      : '200'; // Default fallback
  _systemFeeController.text = widget.formState.systemFee > 0 
      ? widget.formState.systemFee.toStringAsFixed(0) 
      : '120'; // Default fallback
  _otherFeesController.text = widget.formState.otherFees > 0 
      ? widget.formState.otherFees.toStringAsFixed(0) 
      : '';
  _initialPaymentController.text = widget.formState.initialPaymentAmount > 0 
      ? widget.formState.initialPaymentAmount.toStringAsFixed(0) 
      : '';
}

  void _calculateTotals() {
    // Update the total amount due and recalculate
    widget.formState.totalAmountDue = widget.formState.calculatedTotalAmountDue;
    widget.onChanged();
  }

  Future<void> _loadTuitionFee() async {
    try {
      print('🔍 Loading tuition fee for grade: ${widget.formState.gradeLevel}');
      print('🔍 Payment scheme: ${widget.formState.paymentScheme}');
      
      // Initialize the enrollment service
      await _enrollmentService.initialize();
      
      // Update tuition fee based on grade level and payment scheme
      await _enrollmentService.updateAllFees(widget.formState);
      
      // Refresh the UI
      if (mounted) {
        setState(() {
          _calculateTotals();
        });
      }
      
      print('✅ Tuition fee loaded: ₱${widget.formState.tuitionFee}');
    } catch (e) {
      print('❌ Error loading tuition fee: $e');
      // Set tuition fee to 0 if there's an error
      widget.formState.tuitionFee = 0.0;
      if (mounted) {
        setState(() {
          _calculateTotals();
        });
      }
    }
  }
  void _onFeeChanged() {
    setState(() {
      _calculateTotals();
    });
  }

  @override
  void dispose() {
    _bookFeeController.dispose();
    _idFeeController.dispose();
    _systemFeeController.dispose();
    _otherFeesController.dispose();
    _initialPaymentController.dispose();
    _enrollmentService.clearCache(); // Clear any cached data
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          SizedBox(height: 24),

          // Fee Breakdown Card
          _buildFeeSummaryCard(),
          SizedBox(height: 24),

          // Fee Configuration
          _buildFeeConfigurationSection(),
          SizedBox(height: 24),

          // Payment Configuration
          _buildPaymentConfigurationSection(),
          SizedBox(height: 24),

          // Payment Summary
          _buildPaymentSummaryCard(),

          // Approval Section
          if (widget.formState.needsApproval()) ...[
            SizedBox(height: 24),
            _buildApprovalSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.payment,
              color: Colors.blue[700],
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Configure payment details and fee structure for enrollment',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildFeeSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Fee Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (widget.formState.tuitionFee > 0)  // ← ADD THIS LINE
                  _buildSummaryRow('Tuition Fee:', widget.formState.tuitionFee),
              if (widget.formState.bookFee > 0)
                _buildSummaryRow('Book Fee:', widget.formState.bookFee),
              _buildSummaryRow('ID Fee:', widget.formState.idFee),
              _buildSummaryRow('System Fee:', widget.formState.systemFee),
              if (widget.formState.otherFees > 0)
                _buildSummaryRow('Other Fees:', widget.formState.otherFees),
              
              // Graduation Fee
              if (widget.formState.graduationFee > 0) ...[
                _buildSummaryRow('Graduation Fee:', widget.formState.graduationFee),
                SizedBox(height: 4),
                Text(
                  _getGraduationFeeNote(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              
              SizedBox(height: 12),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade100],
                  ),
                ),
              ),
              SizedBox(height: 12),
              _buildSummaryRow(
                'Total Amount Due:',
                widget.formState.calculatedTotalAmountDue,
                isBold: true,
                color: Colors.blue.shade700,
                fontSize: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGraduationFeeNote() {
    if (widget.formState.gradeLevel == null) return '';
    
    final grade = widget.formState.gradeLevel!;
    if (grade.contains('Kinder 2')) {
      return 'Kindergarten graduation fee included';
    } else if (grade.contains('Grade 6')) {
      return 'Elementary graduation fee included';
    } else if (grade.contains('Grade 10')) {
      return 'Junior High graduation fee included';
    } else if (grade.contains('Grade 12')) {
      return 'Senior High graduation fee included';
    } else if (grade.contains('4th Year') || grade.contains('Senior')) {
      return 'College graduation fee included';
    }
    return '';
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
              fontSize: fontSize,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '₱${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
              fontSize: fontSize,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeConfigurationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.orange.shade700, size: 20),
                SizedBox(width: 8),
                Text(
                  'Fee Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Tuition Fee (read-only display)
              if (widget.formState.tuitionFee > 0) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Colors.blue.shade700, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tuition Fee: ₱${NumberFormat('#,##0.00').format(widget.formState.tuitionFee)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Based on grade level and payment scheme',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],
            // Book Fee
            _buildFeeField(
              label: 'Book Fee',
              controller: _bookFeeController,
              onChanged: (value) {
                widget.formState.bookFee = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                _onFeeChanged();
              },
              icon: Icons.menu_book,
              hint: 'Enter book fee amount',
            ),
            SizedBox(height: 12),

            // ID Fee
            _buildFeeField(
              label: 'ID Fee',
              controller: _idFeeController,
              onChanged: (value) {
                widget.formState.idFee = double.tryParse(value.replaceAll(',', '')) ?? 200.0;
                _onFeeChanged();
              },
              icon: Icons.badge,
              hint: 'School ID fee',
              isRequired: true,
            ),
            SizedBox(height: 12),

            // System Fee
            _buildFeeField(
              label: 'System Fee',
              controller: _systemFeeController,
              onChanged: (value) {
                widget.formState.systemFee = double.tryParse(value.replaceAll(',', '')) ?? 120.0;
                _onFeeChanged();
              },
              icon: Icons.computer,
              hint: 'System/technology fee',
              isRequired: true,
            ),
            SizedBox(height: 12),

            // Other Fees
            _buildFeeField(
              label: 'Other Fees',
              controller: _otherFeesController,
              onChanged: (value) {
                widget.formState.otherFees = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                _onFeeChanged();
              },
              icon: Icons.attach_money,
              hint: 'Additional fees (if any)',
            ),

            // Graduation fee info (read-only)
            if (widget.formState.graduationFee > 0) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.green.shade700, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Graduation Fee: ₱${NumberFormat('#,##0.00').format(widget.formState.graduationFee)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            _getGraduationFeeNote(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeeField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required IconData icon,
    String? hint,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [NumberFormatter()],
      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.orange.shade700, size: 20),
        suffixText: '₱',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.orange.shade50,
        labelStyle: TextStyle(fontFamily: 'Poppins'),
        hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildPaymentConfigurationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple.shade700, size: 20),
                SizedBox(width: 8),
                Text(
                  'Payment Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Payment Scheme Selection
            DropdownField(
              label: 'Payment Scheme',
              value: widget.formState.paymentScheme,
              items: const [
                'Standard Full Payment',
                'Standard Installment',
                'Flexible Installment',
                'Scholarship Plan',
                'Emergency Plan',
              ],
            onChanged: (value) async {  // ← Add async here
              setState(() {
                widget.formState.paymentScheme = value ?? 'Standard Installment';
                // Update payment type based on scheme
                if (value == 'Standard Full Payment') {
                  widget.formState.paymentType = 'cash';
                } else {
                  widget.formState.paymentType = 'installment';
                }
              });
              
              // ← ADD THIS: Update fees when payment scheme changes
              if (widget.formState.gradeLevel != null && widget.formState.gradeLevel!.isNotEmpty) {
                try {
                  print('🔄 Payment scheme changed to: $value, updating tuition fee...');
                  final enrollmentService = EnrollmentService(); // Create instance
                  await enrollmentService.updateAllFees(widget.formState);
                  print('✅ Tuition fee updated for payment scheme change');
                  setState(() {}); // Refresh UI to show new fees
                } catch (e) {
                  print('❌ Error updating fees: $e');
                }
              }
              
              widget.onChanged();
          },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Payment scheme is required';
                }
                return null;
              },
              icon: Icons.payment,
            ),
            SizedBox(height: 16),

            // Payment Method
            DropdownField(
              label: 'Payment Method',
              value: widget.formState.paymentMethod,
              items: const [
                'Cash',
                'Check',
                'Bank Transfer',
                'GCash',
                'Credit Card',
              ],
              onChanged: (value) {
                widget.formState.paymentMethod = value ?? 'Cash';
                widget.onChanged();
              },
              icon: Icons.account_balance_wallet,
            ),
            SizedBox(height: 16),

            // Initial Payment Amount
            TextFormField(
              controller: _initialPaymentController,
              keyboardType: TextInputType.number,
              inputFormatters: [NumberFormatter()],
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Initial Payment Amount *',
                hintText: 'Amount to pay now',
                prefixIcon: Icon(Icons.money, color: Colors.purple.shade700, size: 20),
                suffixText: '₱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
                ),
                filled: true,
                fillColor: Colors.purple.shade50,
                labelStyle: TextStyle(fontFamily: 'Poppins'),
                hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500),
              ),
              onChanged: (value) {
                setState(() {
                  widget.formState.initialPaymentAmount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                });
                widget.onChanged();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Initial payment amount is required';
                }
                final amount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                final minPayment = widget.formState.getMinimumPayment(widget.formState.calculatedTotalAmountDue);
                if (amount < minPayment) {
                  return 'Minimum payment of ₱${NumberFormat('#,##0.00').format(minPayment)} required';
                }
                return null;
              },
            ),

            // Payment scheme info
            SizedBox(height: 12),
            _buildPaymentSchemeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSchemeInfo() {
    Color infoColor = Colors.blue;
    String infoText = '';
    IconData infoIcon = Icons.info;

    switch (widget.formState.paymentScheme) {
      case 'Standard Full Payment':
        infoColor = Colors.green;
        infoIcon = Icons.check_circle;
        infoText = 'Full payment required. No additional payments needed.';
        break;
      case 'Standard Installment':
        infoColor = Colors.blue;
        infoIcon = Icons.schedule;
        infoText = 'Minimum 20% down payment, remaining balance in quarterly installments.';
        break;
      case 'Flexible Installment':
        infoColor = Colors.orange;
        infoIcon = Icons.schedule;
        infoText = 'Minimum ₱500 down payment, remaining balance in monthly installments.';
        break;
      case 'Scholarship Plan':
        infoColor = Colors.purple;
        infoIcon = Icons.school;
        infoText = 'Special payment terms for scholarship recipients.';
        break;
      case 'Emergency Plan':
        infoColor = Colors.red;
        infoIcon = Icons.warning;
        infoText = 'Emergency payment plan - requires administrative approval.';
        break;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: infoColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(infoIcon, color: infoColor, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              infoText,
              style: TextStyle(
                color: infoColor,
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    final balance = widget.formState.balance;
    final totalDue = widget.formState.calculatedTotalAmountDue;
    final initialPayment = widget.formState.initialPaymentAmount;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.summarize, color: Colors.green.shade700, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              _buildSummaryRow(
                'Total Amount Due:',
                totalDue,
                color: Colors.black87,
              ),
              _buildSummaryRow(
                'Initial Payment:',
                initialPayment,
                                              color: Colors.green.shade700,
              ),
              
              SizedBox(height: 8),
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 8),
              
              _buildSummaryRow(
                'Remaining Balance:',
                balance,
                isBold: true,
                color: balance > 0 ? Colors.red.shade700 : Colors.green.shade700,
                fontSize: 16,
              ),
              
              if (balance > 0) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          balance == totalDue 
                            ? 'Full payment pending'
                            : 'Partial payment made - ₱${NumberFormat('#,##0.00').format(balance)} remaining',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (initialPayment > 0) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment complete - No remaining balance',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Approval Required',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'This payment scheme requires approval from administration.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Approval Notes',
                value: widget.formState.approvalNotes,
                onChanged: (value) {
                  widget.formState.approvalNotes = value;
                  widget.onChanged();
                },
                maxLines: 3,
                validator: (value) {
                  if (widget.formState.needsApproval() && (value == null || value.isEmpty)) {
                    return 'Please provide notes for approval';
                  }
                  return null;
                },
                prefixIcon: Icons.note_alt,
                hintText: 'Explain why this payment scheme is needed...',
              ),
            ],
          ),
        ),
      ),
    );
  }
}