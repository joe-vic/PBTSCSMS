// lib/screens/cashier/dashboard/widgets/dashboard_drawer_components.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../config/theme.dart';

/// 🎯 This is the side navigation drawer that slides in from the left
/// Think of it like a filing cabinet with all your tools organized
class DashboardDrawer extends StatelessWidget {
  final bool darkMode;
  final int selectedIndex;
  final VoidCallback onCloseDrawer;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  // Navigation items data
  final List<DrawerItem> navigationItems;
  final List<DrawerItem> settingsItems;

  const DashboardDrawer({
    super.key,
    required this.darkMode,
    required this.selectedIndex,
    required this.onCloseDrawer,
    required this.onItemSelected,
    required this.onLogout,
    required this.onToggleTheme,
    required this.navigationItems,
    required this.settingsItems,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userEmail = user?.email ?? 'cashier@pbts.edu.ph';
    final userName = user?.displayName ?? 'PBTS Cashier';

    return Container(
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 🎯 USER PROFILE SECTION (top colorful area)
            _buildProfileSection(userName, userEmail),
            
            // 🎯 NAVIGATION MENU
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Main navigation items
                  ...navigationItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildDrawerItem(
                      item.title,
                      item.icon,
                      index,
                      () => onItemSelected(index),
                    );
                  }),
                  
                  const Divider(height: 1),
                  
                  // Settings section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'SETTINGS & HELP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ),
                  
                  // Settings items
                  ...settingsItems.map((item) => ListTile(
                    leading: Icon(
                      item.icon,
                      color: darkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: darkMode ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    dense: true,
                    onTap: () {
                      onCloseDrawer();
                      item.onTap();
                    },
                  )),
                ],
              ),
            ),
            
            // 🎯 LOGOUT BUTTON
            _buildLogoutSection(),
            
            // 🎯 APP VERSION
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  /// 🎯 Colorful profile section at the top
  Widget _buildProfileSection(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SMSTheme.primaryColor,
            SMSTheme.accentColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Name and role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cashier',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Email badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Individual navigation item
  Widget _buildDrawerItem(
    String title,
    IconData icon,
    int index,
    VoidCallback onTap,
  ) {
    final bool isSelected = selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? SMSTheme.primaryColor 
            : (darkMode ? Colors.white70 : Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected 
              ? SMSTheme.primaryColor 
              : (darkMode ? Colors.white : Colors.grey.shade800),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      dense: true,
      selected: isSelected,
      selectedTileColor: SMSTheme.primaryColor.withOpacity(0.1),
      onTap: () {
        onCloseDrawer();
        onTap();
      },
    );
  }

  /// 🎯 Red logout button at the bottom
  Widget _buildLogoutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          onCloseDrawer();
          onLogout();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade100,
          foregroundColor: Colors.red.shade800,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 🎯 App version text
  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        'Version 1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: darkMode ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
      ),
    );
  }
}

/// 🎯 Data model for drawer items
class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// 🎯 Settings and Help Dialogs
class SettingsDialog extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onToggleTheme;

  const SettingsDialog({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
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
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Theme toggle
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                ),
              ),
              subtitle: Text(
                'Switch between light and dark theme',
                style: TextStyle(
                  fontSize: 12,
                  color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                ),
              ),
              value: darkMode,
              onChanged: (value) {
                onToggleTheme();
                Navigator.pop(context);
              },
              activeColor: SMSTheme.primaryColor,
            ),
            
            // Add more settings here as needed
            
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: SMSTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 Help and Support Dialog
class HelpDialog extends StatelessWidget {
  final bool darkMode;

  const HelpDialog({
    super.key,
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
            Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'For assistance, please contact:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSupportContact(
              'Technical Support',
              'support@pbts.edu.ph',
              Icons.email,
            ),
            const SizedBox(height: 8),
            _buildSupportContact(
              'Admin Office',
              '+63 (123) 456-7890',
              Icons.phone,
            ),
            
            const SizedBox(height: 20),
            Text(
              'Quick Links:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            ListTile(
              leading: Icon(
                Icons.article,
                color: SMSTheme.primaryColor,
                size: 20,
              ),
              title: Text(
                'User Manual',
                style: TextStyle(
                  color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                  fontSize: 14,
                ),
              ),
              dense: true,
              onTap: () {
                Navigator.pop(context);
                // TODO: Open user manual
              },
            ),
            ListTile(
              leading: Icon(
                Icons.video_library,
                color: SMSTheme.primaryColor,
                size: 20,
              ),
              title: Text(
                'Video Tutorials',
                style: TextStyle(
                  color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                  fontSize: 14,
                ),
              ),
              dense: true,
              onTap: () {
                Navigator.pop(context);
                // TODO: Open video tutorials
              },
            ),
            
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: SMSTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportContact(String title, String contact, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: SMSTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            Text(
              contact,
              style: TextStyle(
                fontSize: 12,
                color: darkMode ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}