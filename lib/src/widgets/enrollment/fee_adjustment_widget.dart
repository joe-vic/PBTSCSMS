import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../config/theme.dart';

/// A widget for managing scholarships and discounts
class FeeAdjustmentWidget extends StatefulWidget {
  const FeeAdjustmentWidget({Key? key}) : super(key: key);

  @override
  _FeeAdjustmentWidgetState createState() => _FeeAdjustmentWidgetState();
}

class _FeeAdjustmentWidgetState extends State<FeeAdjustmentWidget>
    with SingleTickerProviderStateMixin {
  final _scholarshipPercentageController = TextEditingController();
  final _discountAmountController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize controllers from provider
    final provider =
        Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    _scholarshipPercentageController.text =
        provider.scholarshipPercentage.toString();
    _discountAmountController.text = provider.discountAmount.toString();

    // Add listeners
    _scholarshipPercentageController.addListener(_updateScholarshipPercentage);
    _discountAmountController.addListener(_updateDiscountAmount);
  }

  @override
  void dispose() {
    _scholarshipPercentageController
        .removeListener(_updateScholarshipPercentage);
    _discountAmountController.removeListener(_updateDiscountAmount);
    _scholarshipPercentageController.dispose();
    _discountAmountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateScholarshipPercentage() {
    final provider =
        Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    final percentage =
        double.tryParse(_scholarshipPercentageController.text) ?? 0.0;
    provider.setScholarshipPercentage(percentage);
  }

  void _updateDiscountAmount() {
    final provider =
        Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    final amount = double.tryParse(_discountAmountController.text) ?? 0.0;
    provider.setDiscountAmount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Adjustments',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar for Scholarships and Discounts
          TabBar(
            controller: _tabController,
            labelColor: Colors.purple.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.purple.shade800,
            tabs: [
              Tab(
                icon: Icon(Icons.school),
                text: 'Scholarships',
                iconMargin: const EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.discount),
                text: 'Discounts',
                iconMargin: const EdgeInsets.only(bottom: 4),
              ),
            ],
          ),

          // Tab content
          SizedBox(
            height: provider.hasScholarship ||
                    provider.discountType != DiscountType.none
                ? 300
                : 180,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Scholarship Tab
                _buildScholarshipTab(provider),

                // Discount Tab
                _buildDiscountTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the scholarship tab content
  Widget _buildScholarshipTab(EnrollmentPaymentProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scholarship checkbox
          Row(
            children: [
              Checkbox(
                value: provider.hasScholarship,
                onChanged: (value) =>
                    provider.setHasScholarship(value ?? false),
                activeColor: Colors.purple.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Student has a scholarship',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: SMSTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),

          if (provider.hasScholarship) ...[
            const SizedBox(height: 16),

            // Scholarship type
            DropdownButtonFormField<ScholarshipType>(
              value: provider.scholarshipType,
              decoration: InputDecoration(
                labelText: 'Scholarship Type',
                labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.purple.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.school, color: Colors.purple.shade600),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: ScholarshipType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setScholarshipType(value);
                }
              },
              style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),

            // Scholarship percentage and amount
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scholarshipPercentageController,
                    decoration: InputDecoration(
                      labelText: 'Scholarship Percentage (%)',
                      labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.purple.shade600, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon:
                          Icon(Icons.percent, color: Colors.purple.shade600),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    style:
                        TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final percentage = double.tryParse(value);
                      if (percentage == null) return 'Invalid number';
                      if (percentage < 0 || percentage > 100)
                        return 'Must be between 0 and 100';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    initialValue: provider.scholarshipAmount.toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: 'Scholarship Amount',
                      labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.purple.shade600, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.monetization_on,
                          color: Colors.purple.shade600),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    style:
                        TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
                  ),
                ),
              ],
            ),

            // Scholarship explanation
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.scholarshipPercentage >= 100
                          ? 'Full scholarship (100%). No payment required.'
                          : 'Scholarship reduces the base tuition fee by ${provider.scholarshipPercentage}%.',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // No scholarship message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No scholarship applied',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the discount tab content
  Widget _buildDiscountTab(EnrollmentPaymentProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discount type
          DropdownButtonFormField<DiscountType>(
            value: provider.discountType,
            decoration: InputDecoration(
              labelText: 'Discount Type',
              labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.discount, color: Colors.teal.shade600),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: DiscountType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                provider.setDiscountType(value);
              }
            },
            style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryLight),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),

          if (provider.discountType != DiscountType.none) ...[
            const SizedBox(height: 16),

            // Discount amount
            TextFormField(
              controller: _discountAmountController,
              decoration: InputDecoration(
                labelText: 'Discount Amount',
                labelStyle: TextStyle(color: SMSTheme.textSecondaryLight),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon:
                    Icon(Icons.monetization_on, color: Colors.teal.shade600),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                if (amount > provider.baseFee) return 'Cannot exceed base fee';
                return null;
              },
            ),

            // Discount explanation
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.teal.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Discount of ₱${provider.discountAmount.toStringAsFixed(2)} will be deducted from the total fee.',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // No discount message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No discount applied',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
