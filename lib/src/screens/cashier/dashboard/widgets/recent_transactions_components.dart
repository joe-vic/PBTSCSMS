// lib/screens/cashier/dashboard/widgets/recent_transactions_components.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../models/dashboard_data.dart';

/// 🎯 This shows the list of recent transactions
/// Like your recent purchases in your banking app
class RecentTransactionsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool darkMode;
  final VoidCallback onViewAll;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.darkMode,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader(),
        
        const SizedBox(height: 16),
        
        // Transactions list or empty view
        transactions.isEmpty 
            ? _buildEmptyView() 
            : _buildTransactionsList(context, currencyFormat),
      ],
    );
  }

  /// 🎯 Section header with "View All" button
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
          ),
        ),
        TextButton.icon(
          onPressed: onViewAll,
          icon: Icon(
            Icons.arrow_forward,
            color: SMSTheme.primaryColor,
            size: 16,
          ),
          label: Text(
            'View All',
            style: TextStyle(
              color: SMSTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 🎯 Show when no transactions are available
  Widget _buildEmptyView() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No recent transactions',
            style: TextStyle(
              color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Build the list of transactions
  Widget _buildTransactionsList(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Transaction items
          ...transactions.map((transaction) => TransactionItem(
            transaction: transaction,
            darkMode: darkMode,
            currencyFormat: currencyFormat,
            onTap: () => _showTransactionDetails(context, transaction, currencyFormat),
          )),
          
          // View all button
          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewAll,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: SMSTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'View All Transactions',
                    style: TextStyle(
                      color: SMSTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🎯 Show detailed transaction information in a dialog
  void _showTransactionDetails(
    BuildContext context,
    TransactionModel transaction,
    NumberFormat currencyFormat,
  ) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(
        transaction: transaction,
        currencyFormat: currencyFormat,
        darkMode: darkMode,
      ),
    );
  }
}

/// 🎯 This represents ONE transaction in the list
/// Like one item in your shopping receipt
class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final bool darkMode;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.darkMode,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isToday = DateTime.now().difference(transaction.timestamp).inHours < 24;

    return ListTile(
      leading: _buildTransactionIcon(),
      title: _buildTransactionTitle(),
      subtitle: _buildTransactionSubtitle(isToday),
      trailing: _buildViewButton(),
      onTap: onTap,
    );
  }

  /// 🎯 Icon representing the payment type
  Widget _buildTransactionIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getPaymentTypeColor(transaction.paymentType).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getPaymentTypeIcon(transaction.paymentType),
        color: _getPaymentTypeColor(transaction.paymentType),
        size: 20,
      ),
    );
  }

  /// 🎯 Student name and amount
  Widget _buildTransactionTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.studentName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          currencyFormat.format(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  /// 🎯 Payment type and time
  Widget _buildTransactionSubtitle(bool isToday) {
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.paymentType,
            style: TextStyle(
              fontSize: 12,
              color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          isToday
              ? DateFormat('h:mm a').format(transaction.timestamp)
              : DateFormat('MMM d').format(transaction.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 🎯 Arrow button to view details
  Widget _buildViewButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade700 : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 12),
        color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
        onPressed: onTap,
      ),
    );
  }

  /// 🎯 Get color for each payment type
  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'tuition fee':
        return Colors.blue.shade700;
      case 'registration':
        return SMSTheme.primaryColor;
      case 'uniform':
        return Colors.purple.shade700;
      case 'books':
        return Colors.green.shade700;
      case 'miscellaneous':
        return Colors.orange.shade700;
      default:
        return darkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }

  /// 🎯 Get icon for each payment type
  IconData _getPaymentTypeIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'tuition fee':
        return Icons.school;
      case 'registration':
        return Icons.app_registration;
      case 'uniform':
        return Icons.checkroom;
      case 'books':
        return Icons.book;
      case 'miscellaneous':
        return Icons.miscellaneous_services;
      default:
        return Icons.payments;
    }
  }
}

/// 🎯 Dialog showing detailed transaction information
/// Like clicking on a transaction in your bank app to see full details
class TransactionDetailsDialog extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat currencyFormat;
  final bool darkMode;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
    required this.currencyFormat,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: darkMode ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogHeader(),
            const SizedBox(height: 20),
            _buildTransactionDetails(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 🎯 Dialog header with icon and title
  Widget _buildDialogHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: _getPaymentTypeColor(transaction.paymentType).withOpacity(0.1),
          child: Icon(
            _getPaymentTypeIcon(transaction.paymentType),
            color: _getPaymentTypeColor(transaction.paymentType),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy h:mm a').format(transaction.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🎯 All transaction details in rows
  Widget _buildTransactionDetails() {
    return Column(
      children: [
        _buildDetailsRow('Student', transaction.studentName),
        if (transaction.studentGradeLevel.isNotEmpty)
          _buildDetailsRow('Grade Level', transaction.studentGradeLevel),
        _buildDetailsRow(
          'Amount', 
          currencyFormat.format(transaction.amount), 
          isBold: true,
        ),
        _buildDetailsRow('Payment Type', transaction.paymentType),
        _buildDetailsRow('Payment Method', transaction.paymentMethod),
        _buildDetailsRow('Transaction ID', transaction.id),
        _buildDetailsRow(
          'Receipt Generated',
          transaction.receiptGenerated ? 'Yes' : 'No',
          valueColor: transaction.receiptGenerated 
              ? Colors.green 
              : Colors.red.shade500,
        ),
      ],
    );
  }

  /// 🎯 One detail row (label: value)
  Widget _buildDetailsRow(
    String label, 
    String value, {
    bool isBold = false, 
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? 
                    (darkMode ? Colors.white : SMSTheme.textPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Close and Generate Receipt buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(
              color: darkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Navigate to receipt generation
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => ReceiptGenerationScreen(
            //       paymentId: transaction.id,
            //     ),
            //   ),
            // );
          },
          icon: const Icon(Icons.receipt),
          label: const Text('Generate Receipt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: SMSTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 🎯 Helper methods for payment type colors and icons
  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'tuition fee':
        return Colors.blue.shade700;
      case 'registration':
        return SMSTheme.primaryColor;
      case 'uniform':
        return Colors.purple.shade700;
      case 'books':
        return Colors.green.shade700;
      case 'miscellaneous':
        return Colors.orange.shade700;
      default:
        return darkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }

  IconData _getPaymentTypeIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'tuition fee':
        return Icons.school;
      case 'registration':
        return Icons.app_registration;
      case 'uniform':
        return Icons.checkroom;
      case 'books':
        return Icons.book;
      case 'miscellaneous':
        return Icons.miscellaneous_services;
      default:
        return Icons.payments;
    }
  }
}