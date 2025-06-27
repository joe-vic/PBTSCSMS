import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../widgets/payment_card.dart' as payment_widget;
import '../widgets/metric_cards.dart';
import '../services/parent_data_service.dart';

/// 🎯 PURPOSE: DepEd-compliant payments management tab
/// 📝 WHAT IT SHOWS: Fee summaries, payment history, DepEd guidelines
/// 🔧 HOW TO USE: PaymentsTab()
class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  // 📊 DATA VARIABLES
  final ParentDataService _dataService = ParentDataService();
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  /// 📥 Loads payment data
  Future<void> _loadPayments() async {
    try {
      setState(() => _isLoading = true);
      
      final payments = await _dataService.getPayments();
      
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payments: $e'),
            backgroundColor: SMSTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: SMSTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📋 HEADER
            _buildHeaderSection(),
            const SizedBox(height: 24),
            
            // 📊 PAYMENT SUMMARY
            _buildPaymentSummary(),
            const SizedBox(height: 24),
            
            // ℹ️ DEPED FEE STRUCTURE
            _buildDepEdFeeStructure(),
            const SizedBox(height: 24),
            
            // 💳 PAYMENT HISTORY
            _buildPaymentHistory(),
            const SizedBox(height: 24),
            
            // 📋 PAYMENT GUIDELINES
            _buildPaymentGuidelines(),
          ],
        ),
      ),
    );
  }

  /// ⏳ Shows loading spinner
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Payments...',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Builds header section
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fee Management',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage miscellaneous and other school fees as per DepEd guidelines',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 📊 Builds payment summary cards
  Widget _buildPaymentSummary() {
    double totalPending = _payments
        .where((p) => p['status'] == 'pending' || p['status'] == 'overdue')
        .fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));
    
    double totalPaid = _payments
        .where((p) => p['status'] == 'paid')
        .fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Total Pending',
            value: '₱${totalPending.toStringAsFixed(0)}',
            icon: Icons.pending_actions,
            color: SMSTheme.errorColor,
            subtitle: 'Due payments',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            title: 'Total Paid',
            value: '₱${totalPaid.toStringAsFixed(0)}',
            icon: Icons.check_circle,
            color: SMSTheme.successColor,
            subtitle: 'Completed payments',
          ),
        ),
      ],
    );
  }

  /// ℹ️ Builds DepEd fee structure information
  Widget _buildDepEdFeeStructure() {
    return InfoCard(
      title: 'DepEd Approved Fee Structure (SY 2023-2024)',
      color: Colors.blue,
      icon: Icons.info_outline,
      child: _buildFeeBreakdown(),
    );
  }

  /// 💰 Builds fee breakdown
  Widget _buildFeeBreakdown() {
    final fees = [
      {'name': 'Laboratory Fee', 'amount': '₱800.00', 'description': 'Science laboratory equipment and materials'},
      {'name': 'Library Fee', 'amount': '₱500.00', 'description': 'Books, references, and library maintenance'},
      {'name': 'Computer Fee', 'amount': '₱700.00', 'description': 'Computer laboratory and ICT equipment'},
      {'name': 'Sports Fee', 'amount': '₱300.00', 'description': 'Sports equipment and facilities'},
      {'name': 'Maintenance Fee', 'amount': '₱200.00', 'description': 'School building and facilities maintenance'},
    ];

    return Column(
      children: fees.map((fee) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee['name']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      fee['description']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                fee['amount']!,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 💳 Builds payment history section
  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History & Billing',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_payments.isEmpty)
          _buildEmptyPayments()
        else
        // ✅ CORRECT:
        ..._payments.map((payment) => payment_widget.PaymentCard(
          payment: payment,
          onPayNow: () => _processPayment(payment),
        )).toList(),
      ],
    );
  }

  /// 🫙 Shows empty payments state
  Widget _buildEmptyPayments() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: SMSTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Payment Records',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment history will appear here once fees are processed',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Builds payment guidelines
  Widget _buildPaymentGuidelines() {
    return InfoCard(
      title: 'Payment Guidelines',
      color: SMSTheme.primaryColor,
      icon: Icons.policy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...[
            '• Fees are payable quarterly as per DepEd schedule',
            '• No student shall be denied admission for inability to pay fees',
            '• Payment can be made through the school cashier or authorized payment centers',
            '• Official receipts must be kept for record purposes',
            '• Late payment penalties may apply after grace period',
            '• Financial assistance is available for qualified students',
          ].map((guideline) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              guideline,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// 💳 Process payment
  Future<void> _processPayment(Map<String, dynamic> payment) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Payment', style: TextStyle(fontFamily: 'Poppins',)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${payment['studentName']}', style: TextStyle(fontFamily: 'Poppins',)),
            Text('Amount: ₱${payment['amount']}', style: TextStyle(fontFamily: 'Poppins',)),
            Text('Description: ${payment['description']}', style: TextStyle(fontFamily: 'Poppins',)),
            const SizedBox(height: 12),
            Text(
              'Note: Payment will be processed through the school cashier or authorized payment centers.',
              style: TextStyle(fontFamily: 'Poppins',fontSize: 12, color: SMSTheme.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins',)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
                  ),
                ),
              );
              
              try {
                // Process payment
                await _dataService.processPayment(payment);
                
                // Close loading
                Navigator.pop(context);
                
                // Show success
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment request submitted. Please pay at the school cashier.'),
                    backgroundColor: SMSTheme.successColor,
                  ),
                );
                
                // Reload payments
                _loadPayments();
              } catch (e) {
                // Close loading
                Navigator.pop(context);
                
                // Show error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error processing payment: $e'),
                    backgroundColor: SMSTheme.errorColor,
                  ),
                );
              }
            },
            child: Text('Proceed', style: TextStyle(fontFamily: 'Poppins',)),
          ),
        ],
      ),
    );
  }
}