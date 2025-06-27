import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';

/// 🎯 PURPOSE: Reusable summary cards for metrics
/// 📝 WHAT IT SHOWS: Title, amount/value, icon with color coding
/// 🔧 HOW TO USE: SummaryCard(title: 'Total Paid', value: '₱5000', icon: Icons.check_circle)
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // 🎨 ICON
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              
              // 💰 VALUE (main text)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              
              // 🏷️ TITLE
              Text(
                title,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  color: SMSTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              // 📝 SUBTITLE (optional)
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 10,
                    color: SMSTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎯 PURPOSE: Quick action card for dashboard
/// 📝 WHAT IT SHOWS: Icon, title, subtitle with tap action
/// 🔧 HOW TO USE: QuickActionCard(title: 'Pay Fees', subtitle: 'Manage payments', icon: Icons.payment)
class QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 ICON with background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              
              // 🏷️ TITLE
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              
              // 📝 SUBTITLE
              Expanded(
                child: Center(
                  child: Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 11,
                      color: SMSTheme.textSecondaryColor,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎯 PURPOSE: Info card with icon and content
/// 📝 WHAT IT SHOWS: Colored background with title and description
/// 🔧 HOW TO USE: InfoCard(title: 'DepEd Guidelines', content: '...', color: Colors.blue)
class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final IconData? icon;
  final Widget? child;

  const InfoCard({
    super.key,
    required this.title,
    this.content = '',
    required this.color,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ HEADER with icon
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          ],
          
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}

/// 🎯 PURPOSE: Individual payment card display
/// 📝 WHAT IT SHOWS: Payment details with status and action button
/// 🔧 HOW TO USE: PaymentCard(payment: paymentData, onPayNow: () => process())
class PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback? onPayNow;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payment['status']) {
      case 'paid':
        statusColor = SMSTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = SMSTheme.secondaryColor;
        statusIcon = Icons.schedule;
        break;
      case 'overdue':
        statusColor = SMSTheme.errorColor;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = SMSTheme.textSecondaryColor;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎓 STUDENT & AMOUNT ROW
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['studentName'] ?? 'Unknown Student',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        payment['description'] ?? 'No description',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${(payment['amount'] ?? 0.0).toStringAsFixed(0)}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          (payment['status']?.toString().toUpperCase()) ?? 'UNKNOWN',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            // 💰 FEE BREAKDOWN (if available)
            if (payment['breakdown'] != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fee Breakdown:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...(payment['breakdown'] as Map<String, dynamic>).entries.map((entry) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 11,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '₱${(entry.value ?? 0.0).toStringAsFixed(0)}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ],
            
            const SizedBox(height: 12),
            
            // 📅 DUE DATE & ACTION ROW
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payment['dueDate'] != null)
                        Text(
                          'Due: ${_formatDate(payment['dueDate'])}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                      if (payment['receiptNumber'] != null)
                        Text(
                          'OR No: ${payment['receiptNumber']}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 11,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // 💳 PAY NOW BUTTON
                if ((payment['status'] == 'pending' || payment['status'] == 'overdue') && onPayNow != null)
                  ElevatedButton(
                    onPressed: onPayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SMSTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Pay Now',
                      style: TextStyle(fontFamily: 'Poppins',fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📅 Format date helper
  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (date is String) {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      }
    } catch (e) {
      // If parsing fails, return the original string
      return date.toString();
    }
    
    return date.toString();
  }
}