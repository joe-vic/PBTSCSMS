// lib/screens/cashier/dashboard/widgets/quick_actions_components.dart

import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// 🎯 This creates the grid of action buttons (like a remote control)
/// Each button takes you to a different screen
class QuickActionsGrid extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onRecordPayment;
  final VoidCallback onGenerateReceipt;
  final VoidCallback onDailyCollections;
  final VoidCallback onTransactionSummary;
  final VoidCallback onStudentPayments;
  final VoidCallback onExpensesTracker;
  final VoidCallback onWalkInEnrollment;

  const QuickActionsGrid({
    super.key,
    required this.darkMode,
    required this.onRecordPayment,
    required this.onGenerateReceipt,
    required this.onDailyCollections,
    required this.onTransactionSummary,
    required this.onStudentPayments,
    required this.onExpensesTracker,
    required this.onWalkInEnrollment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader('Quick Actions', 'Refresh', null),
        
        const SizedBox(height: 16),
        
        // Grid of action cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            QuickActionCard(
              title: 'Record Payment',
              subtitle: 'Process student payments',
              icon: Icons.payment,
              color: SMSTheme.primaryColor,
              darkMode: darkMode,
              onTap: onRecordPayment,
            ),
            QuickActionCard(
              title: 'Walk-in Enrollment',
              subtitle: 'Register new students',
              icon: Icons.add_circle,
              color: Colors.indigo.shade500,
              darkMode: darkMode,
              onTap: onWalkInEnrollment,
            ),
            QuickActionCard(
              title: 'Generate Receipt',
              subtitle: 'Print payment receipts',
              icon: Icons.receipt,
              color: Colors.amber.shade700,
              darkMode: darkMode,
              onTap: onGenerateReceipt,
            ),
            QuickActionCard(
              title: 'Daily Collections',
              subtitle: 'View today\'s summary',
              icon: Icons.savings,
              color: Colors.green.shade600,
              darkMode: darkMode,
              onTap: onDailyCollections,
            ),
            QuickActionCard(
              title: 'Transaction Summary',
              subtitle: 'Full payment records',
              icon: Icons.assessment,
              color: Colors.purple.shade500,
              darkMode: darkMode,
              onTap: onTransactionSummary,
            ),
            QuickActionCard(
              title: 'Student Payments',
              subtitle: 'View student history',
              icon: Icons.school,
              color: Colors.teal.shade600,
              darkMode: darkMode,
              onTap: onStudentPayments,
            ),
            QuickActionCard(
              title: 'Expenses Tracker',
              subtitle: 'Record & track expenses',
              icon: Icons.account_balance_wallet,
              color: Colors.deepOrange.shade500,
              darkMode: darkMode,
              onTap: onExpensesTracker,
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 Determine how many columns based on screen size
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 4;  // Large screens
    if (width > 600) return 3;  // Medium screens  
    return 2;                   // Small screens
  }

  /// 🎯 Section header with optional action button
  Widget _buildSectionHeader(String title, String? actionText, VoidCallback? onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
          ),
          if (onAction != null && actionText != null)
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(
                actionText == 'Refresh' ? Icons.refresh : Icons.arrow_forward,
                color: SMSTheme.primaryColor,
                size: 16,
              ),
              label: Text(
                actionText,
                style: TextStyle(
                  color: SMSTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 🎯 This is ONE action card (like a button on your phone's home screen)
/// Each card represents one action the cashier can take
class QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool darkMode;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with colored background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}