// lib/screens/cashier/dashboard/widgets/dashboard_app_bar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';

/// 🎯 This is the top bar of your dashboard (like the header of a website)
/// It shows: menu button, title, date, notifications, theme toggle, and profile
class DashboardAppBar extends StatelessWidget {
  final String userName;
  final bool darkMode;
  final int unreadNotifications;
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onThemeToggle;
  final VoidCallback onProfilePressed;

  const DashboardAppBar({
    super.key,
    required this.userName,
    required this.darkMode,
    required this.unreadNotifications,
    required this.onMenuPressed,
    required this.onNotificationsPressed,
    required this.onThemeToggle,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🍔 Hamburger menu button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenuPressed,
            color: SMSTheme.primaryColor,
            tooltip: 'Open menu',
          ),

          const SizedBox(width: 8),

          // 📱 Title and date section
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Row(
                  children: [
                    Expanded(
                      child: _buildTitleSection(),
                    ),
                    if (!isSmallScreen) ...[
                      // 🔔 Notifications button
                      _buildNotificationButton(),
                      const SizedBox(width: 8),
                      // 🌙 Theme toggle button
                      _buildThemeToggle(),
                      const SizedBox(width: 8),
                    ],
                    // 👤 Profile section
                    _buildProfileSection(),
                  ],
                );
              },
            ),
          ),

          // Show these buttons outside on small screens
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = MediaQuery.of(context).size.width < 600;
              return isSmallScreen
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        _buildNotificationButton(),
                        _buildThemeToggle(),
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// 🎯 The title and date part
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cashier Dashboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
          ),
        ),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
          style: TextStyle(
            fontSize: 12,
            color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 🎯 The notification bell with red dot if there are unread notifications
  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onNotificationsPressed,
          color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
          tooltip: 'View notifications',
        ),

        // Red dot for unread notifications
        if (unreadNotifications > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadNotifications <= 9 ? '$unreadNotifications' : '9+',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// 🎯 The sun/moon button to switch between light and dark mode
  Widget _buildThemeToggle() {
    return IconButton(
      icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: onThemeToggle,
      color: darkMode ? Colors.amber : Colors.grey.shade700,
      tooltip: darkMode ? 'Switch to light mode' : 'Switch to dark mode',
    );
  }

  /// 🎯 The profile section with avatar and name
  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: onProfilePressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile picture (using first letter of name)
          CircleAvatar(
            backgroundColor: SMSTheme.primaryColor,
            radius: 16,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Greeting text
          Flexible(
            child: Text(
              'Hi, $userName',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
