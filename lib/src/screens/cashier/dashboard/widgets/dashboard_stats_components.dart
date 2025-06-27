// lib/screens/cashier/dashboard/widgets/dashboard_stats_components.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../models/dashboard_data.dart';

/// 🎯 This shows the 4 main numbers at the top of your dashboard
/// Like: Today's Collections, Weekly Collections, etc.
class DashboardStatsGrid extends StatelessWidget {
  final DashboardData data;
  final bool darkMode;
  final VoidCallback onTodayCollectionsTap;
  final VoidCallback onWeeklyCollectionsTap;
  final VoidCallback onTodayTransactionsTap;

  const DashboardStatsGrid({
    super.key,
    required this.data,
    required this.darkMode,
    required this.onTodayCollectionsTap,
    required this.onWeeklyCollectionsTap,
    required this.onTodayTransactionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Grid of stat cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isLargeScreen ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              DashboardStatCard(
                title: 'Today\'s Collections',
                value: currencyFormat.format(data.todayCollections),
                icon: Icons.payments,
                color: Colors.green.shade500,
                darkMode: darkMode,
                onTap: onTodayCollectionsTap,
              ),
              DashboardStatCard(
                title: 'Weekly Collections',
                value: currencyFormat.format(data.weeklyCollections),
                icon: Icons.date_range,
                color: SMSTheme.accentColor,
                darkMode: darkMode,
                onTap: onWeeklyCollectionsTap,
              ),
              DashboardStatCard(
                title: 'Today\'s Transactions',
                value: data.todayTransactions.toString(),
                icon: Icons.receipt_long,
                color: Colors.purple.shade500,
                darkMode: darkMode,
                onTap: onTodayTransactionsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🎯 This is ONE stat card (like a trading card with a number on it)
/// Example: "Pending Enrollments: 5"
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool darkMode;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.darkMode,
    this.onTap,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: darkMode ? Colors.white70 : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 This shows the monthly progress bar (like a health bar in games)
class MonthlyProgressCard extends StatelessWidget {
  final DashboardData data;
  final bool darkMode;

  const MonthlyProgressCard({
    super.key,
    required this.data,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final monthlyTotal =
        data.monthlyCollections.values.fold(0.0, (sum, value) => sum + value);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Target',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                ),
              ),
              Text(
                '${(data.monthProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(data.monthProgress),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.monthProgress,
              backgroundColor:
                  darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(data.monthProgress)),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 12),

          // Collected vs Target amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collected: ${currencyFormat.format(monthlyTotal)}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                ),
              ),
              Text(
                'Target: ${currencyFormat.format(data.monthTarget)}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                ),
              ),
            ],
          ),

          // Payment type breakdown
          if (data.monthlyCollections.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Breakdown by Payment Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...(_buildPaymentTypeBreakdown(currencyFormat)),
          ],
        ],
      ),
    );
  }

  /// 🎯 Shows what types of payments were made (Tuition, Books, etc.)
  List<Widget> _buildPaymentTypeBreakdown(NumberFormat currencyFormat) {
    final sortedEntries = data.monthlyCollections.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // Colored dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPaymentTypeColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Payment type name
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: darkMode
                            ? Colors.white70
                            : SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ),

                  // Amount
                  Text(
                    currencyFormat.format(entry.value),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  /// 🎯 Get color based on how close we are to the target
  /// Red = bad (0-30%), Orange = okay (30-70%), Green = good (70%+)
  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red.shade500;
    } else if (progress < 0.7) {
      return Colors.orange.shade500;
    } else {
      return Colors.green.shade500;
    }
  }

  /// 🎯 Get colors for different payment types
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
}
