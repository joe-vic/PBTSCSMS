import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../config/theme.dart';

// 📁 IMPORT THE SEPARATED TABS
import 'tabs/home_tab.dart';
import 'tabs/students_tab.dart';      // Create these next
import 'tabs/payments_tab.dart';      // Create these next
import 'tabs/attendance_tab.dart';    // Create these next
import 'tabs/reports_tab.dart';       // Create these next
import 'tabs/calendar_tab.dart';      // Create these next


/// 🎯 PURPOSE: Main parent dashboard with tab navigation
/// 📝 WHAT IT DOES: Manages tabs, drawer, logout - NO UI business logic!
/// 🔧 HOW TO USE: Just the main container - tabs handle their own content
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  
  // 📋 TAB CONFIGURATION
  late TabController _tabController;
  final List<String> _tabs = [
    'Home',
    'Students', 
    'Payments',
    'Attendance',
    'Reports',
    'Calendar'
  ];
  
  // 🔔 SIMPLE STATE
  int _notificationCount = 3; // This will come from a service later

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final parentId = authProvider.user?.uid;

    // 🚨 CHECK LOGIN STATE
    if (parentId == null) {
      return const Center(child: Text('Please log in to view this page'));
    }

    return Scaffold(
      // 📱 APP BAR
      appBar: _buildAppBar(),
      
      // 🍔 DRAWER MENU
      drawer: _buildDrawer(authProvider),
      
      // 📄 MAIN CONTENT
      body: Column(
        children: [
          // 📂 TAB BAR
          _buildTabBar(),
          
          // 📋 TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HomeTab(tabController: _tabController),                    // Replace with StudentsTab() 
                StudentsTab( ), // Use StudentsTab() when ready
                PaymentsTab(),
                AttendanceTab(),
                ReportsTab(),
                CalendarTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Builds the app bar with notifications
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Parent Dashboard',
        style: TextStyle(fontFamily: 'Poppins',
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: SMSTheme.primaryColor,
      elevation: 0,
      actions: [
        // 🔔 NOTIFICATIONS
        IconButton(
          icon: _buildNotificationIcon(),
          onPressed: _viewNotifications,
        ),
        // 🔍 SEARCH
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Search feature coming soon'),
                backgroundColor: SMSTheme.primaryColor,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 🔔 Builds notification icon with badge
  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        const Icon(Icons.notifications_outlined, size: 26),
        if (_notificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: SMSTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_notificationCount',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// 📂 Builds the tab bar
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: SMSTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.map((tab) => Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tab,
              style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
            ),
          ),
        )).toList(),
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
      ),
    );
  }

  /// 🍔 Builds the navigation drawer
  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 🎨 DRAWER HEADER
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: SMSTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Parent Portal',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: Text(
                    'Welcome, ${authProvider.user?.email ?? 'Parent'}',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 📋 NAVIGATION ITEMS
          ..._buildDrawerItems(),
          
          const Divider(),
          
          // ⚙️ SETTINGS & LOGOUT
          ..._buildDrawerFooterItems(authProvider),
        ],
      ),
    );
  }

  /// 📋 Builds main navigation drawer items
  List<Widget> _buildDrawerItems() {
    final items = [
      {'icon': Icons.home, 'title': 'Dashboard', 'index': 0},
      {'icon': Icons.school, 'title': 'Students', 'index': 1},
      {'icon': Icons.payment, 'title': 'Payments', 'index': 2},
      {'icon': Icons.calendar_today, 'title': 'Attendance', 'index': 3},
      {'icon': Icons.assessment, 'title': 'Reports', 'index': 4},
      {'icon': Icons.event, 'title': 'Calendar', 'index': 5},
    ];

    return items.map((item) => ListTile(
      leading: Icon(item['icon'] as IconData, color: SMSTheme.primaryColor),
      title: Text(item['title'] as String, style: TextStyle(fontFamily: 'Poppins',)),
      onTap: () {
        Navigator.pop(context);
        _tabController.animateTo(item['index'] as int);
      },
    )).toList();
  }

  /// ⚙️ Builds drawer footer items (settings, help, logout)
  List<Widget> _buildDrawerFooterItems(AuthProvider authProvider) {
    return [
      ListTile(
        leading: Icon(Icons.settings, color: SMSTheme.textSecondaryColor),
        title: Text('Settings', style: TextStyle(fontFamily: 'Poppins',)),
        onTap: () {
          Navigator.pop(context);
          _showComingSoon('Settings');
        },
      ),
      ListTile(
        leading: Icon(Icons.help, color: SMSTheme.textSecondaryColor),
        title: Text('Help & Support', style: TextStyle(fontFamily: 'Poppins',)),
        onTap: () {
          Navigator.pop(context);
          _showComingSoon('Help');
        },
      ),
      ListTile(
        leading: Icon(Icons.logout, color: SMSTheme.errorColor),
        title: Text(
          'Logout',
          style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.errorColor),
        ),
        onTap: () {
          Navigator.pop(context);
          _logout(authProvider);
        },
      ),
    ];
  }

  /// 📄 Temporary placeholder for tabs not yet separated
  Widget _buildPlaceholderTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: SMSTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '$tabName Tab',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This tab will be separated into its own file.\nComing soon!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(0), // Go back to Home
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Go to Home',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 ACTION METHODS

  /// 🔔 Handles notification viewing
  void _viewNotifications() {
    setState(() => _notificationCount = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications viewed'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  /// ⏰ Shows "coming soon" message
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  /// 🚪 Handles user logout
  Future<void> _logout(AuthProvider authProvider) async {
    try {
      await authProvider.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: SMSTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: SMSTheme.errorColor,
          ),
        );
      }
    }
  }
}