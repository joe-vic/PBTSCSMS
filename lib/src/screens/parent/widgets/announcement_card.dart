import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

/// 🎯 PURPOSE: Shows school announcements in beautiful cards
/// 📝 WHAT IT SHOWS: Title, content, date, priority level
/// 🔧 HOW TO USE: AnnouncementCard(announcement: myAnnouncement, onTap: () {})
class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷️ HEADER: Priority dot + Title
              _buildHeader(),
              const SizedBox(height: 8),
              
              // 📝 CONTENT: Announcement text
              _buildContent(),
              const SizedBox(height: 8),
              
              // 📅 FOOTER: Date posted
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🏷️ Builds header with priority indicator and title
  Widget _buildHeader() {
    final priorityColor = _getPriorityColor();
    
    return Row(
      children: [
        // 🔴 PRIORITY INDICATOR (colored dot)
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: priorityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        
        // 📢 ANNOUNCEMENT TITLE
        Expanded(
          child: Text(
            announcement['title'] ?? 'Untitled Announcement',
            style: TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: SMSTheme.textPrimaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // 🏷️ PRIORITY BADGE (for high priority)
        if (announcement['priority'] == 'high')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SMSTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SMSTheme.errorColor.withOpacity(0.3)),
            ),
            child: Text(
              'URGENT',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: SMSTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  /// 📝 Builds the announcement content text
  Widget _buildContent() {
    return Text(
      announcement['content'] ?? 'No content available.',
      style: TextStyle(fontFamily: 'Poppins',
        color: SMSTheme.textSecondaryColor,
        fontSize: 14,
        height: 1.4, // Better line spacing
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 📅 Builds the footer with posting date
  Widget _buildFooter() {
    final date = announcement['date'] as DateTime?;
    final dateText = date != null 
        ? 'Posted on ${DateFormat('MMMM d, yyyy').format(date)}'
        : 'Posted recently';
    
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: SMSTheme.textSecondaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          dateText,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
        const Spacer(),
        
        // 👁️ READ MORE INDICATOR
        if (onTap != null)
          Row(
            children: [
              Text(
                'Read more',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  color: SMSTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: SMSTheme.primaryColor,
              ),
            ],
          ),
      ],
    );
  }

  /// 🎨 Gets color based on announcement priority
  Color _getPriorityColor() {
    final priority = announcement['priority'] as String?;
    
    switch (priority) {
      case 'high':
        return SMSTheme.errorColor;      // 🔴 Red for urgent
      case 'medium':
        return SMSTheme.secondaryColor;  // 🟡 Yellow for medium
      case 'low':
      default:
        return SMSTheme.successColor;    // 🟢 Green for normal
    }
  }
}