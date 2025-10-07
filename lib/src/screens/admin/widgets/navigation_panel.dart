import 'package:flutter/material.dart';
import 'package:school_management_system/src/config/theme.dart';

class NavigationPanel extends StatefulWidget {
  final Function(int index, VoidCallback action) onItemSelected;

  const NavigationPanel({
    super.key,
    required this.onItemSelected,
  });

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Brand Header
            _buildBrandHeader(),
            
            const SizedBox(height: 8),
            
            // User Profile
            _buildUserProfile(context),
            
            const SizedBox(height: 16),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildSectionLabel('MAIN MENU'),
                  _buildNavItem(
                    'Dashboard',
                    Icons.dashboard_rounded,
                    0,
                    () {},
                  ),
                  _buildNavItem(
                    'Analytics',
                    Icons.analytics_rounded,
                    1,
                    () {},
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionLabel('MANAGEMENT'),
                  _buildNavItem(
                    'Students',
                    Icons.school_rounded,
                    2,
                    () {},
                  ),
                  _buildNavItem(
                    'Teachers',
                    Icons.people_rounded,
                    3,
                    () {},
                  ),
                  _buildNavItem(
                    'Courses',
                    Icons.book_rounded,
                    4,
                    () {},
                  ),
                  _buildNavItem(
                    'Attendance',
                    Icons.calendar_today_rounded,
                    5,
                    () {},
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionLabel('FINANCIAL'),
                  _buildNavItem(
                    'Fee Management',
                    Icons.payments_rounded,
                    6,
                    () {},
                  ),
                  _buildNavItem(
                    'Transactions',
                    Icons.receipt_long_rounded,
                    7,
                    () {},
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionLabel('SYSTEM'),
                  _buildNavItem(
                    'Settings',
                    Icons.settings_rounded,
                    8,
                    () {},
                  ),
                  _buildNavItem(
                    'Reports',
                    Icons.assessment_rounded,
                    9,
                    () {},
                  ),
                ],
              ),
            ),
            
            // Footer Actions
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.primaryColor.withOpacity(0.1),
            SMSTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: SMSTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PBTS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Admin Portal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.primaryColor,
            SMSTheme.primaryColor.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: SMSTheme.primaryColor.withOpacity(0.2),
              child: const Text(
                'AU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: SMSTheme.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String title,
    IconData icon,
    int index,
    VoidCallback action,
  ) {
    final isSelected = _selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            widget.onItemSelected(index, action);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        SMSTheme.primaryColor.withOpacity(0.15),
                        SMSTheme.secondaryColor.withOpacity(0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? SMSTheme.primaryColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              SMSTheme.primaryColor,
                              SMSTheme.secondaryColor,
                            ],
                          )
                        : null,
                    color: isSelected ? null : SMSTheme.neutralGray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : SMSTheme.neutralGray600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? SMSTheme.primaryColor
                          : SMSTheme.textPrimaryLight,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SMSTheme.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: SMSTheme.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SMSTheme.neutralGray50,
        border: Border(
          top: BorderSide(
            color: SMSTheme.neutralGray200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Help & Support
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SMSTheme.neutralGray200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: SMSTheme.neutralGray600,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: SMSTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from the system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: SMSTheme.neutralGray600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}