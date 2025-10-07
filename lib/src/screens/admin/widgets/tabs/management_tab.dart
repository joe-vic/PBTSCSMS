import 'package:flutter/material.dart';
import 'package:school_management_system/src/config/theme.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),
          
          // System Management
          _buildSystemManagement(context),
          const SizedBox(height: 28),
          
          // User Management
          _buildUserManagement(context),
          const SizedBox(height: 28),
          
          // Data Management
          _buildDataManagement(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Configure and manage system settings',
              style: TextStyle(
                fontSize: 14,
                color: SMSTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('System Configuration', Icons.settings_rounded),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildManagementCard(
              context,
              'User Management',
              Icons.people_rounded,
              [Color(0xFF3B82F6), Color(0xFF2563EB)],
              '24 users',
              () => _navigateToUserManagement(context),
            ),
            _buildManagementCard(
              context,
              'Fee Configuration',
              Icons.monetization_on_rounded,
              [Color(0xFF10B981), Color(0xFF059669)],
              '12 schemes',
              () => _navigateToFeeManagement(context),
            ),
            _buildManagementCard(
              context,
              'System Settings',
              Icons.settings_suggest_rounded,
              [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              '8 modules',
              () => _navigateToSystemSettings(context),
            ),
            _buildManagementCard(
              context,
              'Backup & Restore',
              Icons.backup_rounded,
              [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              'Last: Today',
              () => _createBackup(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SMSTheme.primaryColor.withOpacity(0.1),
                SMSTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: SMSTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('Active Users', Icons.people_outline_rounded),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _navigateToUserManagement(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add User'),
              style: TextButton.styleFrom(
                foregroundColor: SMSTheme.primaryColor,
                backgroundColor: SMSTheme.primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildUserListItem(
                'John Doe',
                'Administrator',
                Icons.admin_panel_settings_rounded,
                Color(0xFF3B82F6),
                'admin@pbts.edu',
                true,
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildUserListItem(
                'Jane Smith',
                'Teacher',
                Icons.school_rounded,
                Color(0xFF10B981),
                'jane.smith@pbts.edu',
                true,
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildUserListItem(
                'Mike Johnson',
                'Teacher',
                Icons.school_rounded,
                Color(0xFF10B981),
                'mike.johnson@pbts.edu',
                true,
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildUserListItem(
                'Sarah Wilson',
                'Accountant',
                Icons.account_balance_wallet_rounded,
                SMSTheme.primaryColor,
                'sarah.wilson@pbts.edu',
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(
    String name,
    String role,
    IconData icon,
    Color color,
    String email,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? SMSTheme.successLight 
                            : SMSTheme.neutralGray200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? SMSTheme.successDark 
                                  : SMSTheme.neutralGray600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Active' : 'Offline',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive 
                                  ? SMSTheme.successDark 
                                  : SMSTheme.neutralGray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$role • $email',
                  style: TextStyle(
                    fontSize: 13,
                    color: SMSTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 20),
                onPressed: () {},
                color: SMSTheme.primaryColor,
                tooltip: 'Edit User',
                style: IconButton.styleFrom(
                  backgroundColor: SMSTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () {},
                color: SMSTheme.neutralGray600,
                tooltip: 'More Options',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Data Operations', Icons.storage_rounded),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDataAction(
                'Export All Data',
                'Download complete database export',
                Icons.download_rounded,
                Color(0xFF3B82F6),
                () => _exportData(context),
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildDataAction(
                'Import Data',
                'Upload and import data from file',
                Icons.upload_rounded,
                Color(0xFF10B981),
                () => _importData(context),
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildDataAction(
                'Clear Cache',
                'Remove temporary files and data',
                Icons.cleaning_services_rounded,
                SMSTheme.primaryColor,
                () => _clearCache(context),
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildDataAction(
                'System Logs',
                'View system activity and error logs',
                Icons.list_alt_rounded,
                Color(0xFF8B5CF6),
                () => _viewLogs(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataAction(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: SMSTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: SMSTheme.neutralGray400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserManagementPage()),
    );
  }

  void _navigateToFeeManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeeManagementPage()),
    );
  }

  void _navigateToSystemSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SystemSettingsPage()),
    );
  }

  void _createBackup(BuildContext context) {
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
                color: SMSTheme.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: SMSTheme.successDark,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Backup Created'),
          ],
        ),
        content: const Text('Your data has been backed up successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
            style: TextButton.styleFrom(
              foregroundColor: SMSTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    _showSnackBar(context, 'Data export started!', Icons.download_rounded);
  }

  void _importData(BuildContext context) {
    _showSnackBar(context, 'Import data feature coming soon!', Icons.info_rounded);
  }

  void _clearCache(BuildContext context) {
    _showSnackBar(context, 'Cache cleared successfully!', Icons.check_circle_rounded);
  }

  void _viewLogs(BuildContext context) {
    _showSnackBar(context, 'System logs opened!', Icons.list_alt_rounded);
  }

  void _showSnackBar(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: SMSTheme.neutralGray800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Placeholder pages
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: SMSTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('User Management Page - Under Development'),
      ),
    );
  }
}

class FeeManagementPage extends StatelessWidget {
  const FeeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Configuration'),
        backgroundColor: SMSTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Fee Management Page - Under Development'),
      ),
    );
  }
}

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: SMSTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('System Settings Page - Under Development'),
      ),
    );
  }
}