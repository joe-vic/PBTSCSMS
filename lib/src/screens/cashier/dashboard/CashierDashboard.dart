// lib/screens/cashier/dashboard/cashier_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';

// Import your other screens
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../../../config/theme.dart';
import '../PaymentEntryScreen.dart';
import '../DailyCollectionsScreen.dart';
import '../TransactionSummaryScreen.dart';
import '../ReceiptGenerationScreen.dart';
import '../StudentsPaymentHistoryScreen.dart';
import '../ExpensesTrackerScreen.dart';
import '../enrollment/screens/enrollment_screen.dart'; // New enrollment screen

// Import the new components we created
import 'models/dashboard_data.dart';
import 'services/dashboard_data_service.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/dashboard_stats_components.dart';
import 'widgets/quick_actions_components.dart';
import 'widgets/weekly_chart_card.dart';
import 'widgets/recent_transactions_components.dart';
import 'widgets/dashboard_drawer_components.dart';

/// 🎯 This is your MAIN dashboard screen - now much cleaner!
/// Think of it as the "remote control" that controls all the smaller parts
class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  _CashierDashboardState createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard>
    with SingleTickerProviderStateMixin {
  // 🎯 SIMPLIFIED STATE VARIABLES
  // Instead of 20+ variables, we now have just a few!

  bool _isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;
  late Animation<double> _overlayAnimation;
  int _selectedDrawerIndex = 0;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _darkMode = false;

  // The star of the show - our dashboard data!
  DashboardData _dashboardData = DashboardData.empty();

  // Our helper service
  final DashboardDataService _dataService = DashboardDataService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPreferences();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  /// 🎯 Set up the drawer sliding animation
  void _initializeAnimations() {
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );
    _overlayAnimation =
        Tween<double>(begin: 0.0, end: 0.5).animate(_drawerAnimation);
  }

  /// 🎯 Load user's saved preferences (like dark mode)
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkMode = prefs.getBool('darkMode') ?? false;
      });
    } catch (e) {
      print('❌ Error loading preferences: $e');
    }
  }

  /// 🎯 Save user's preferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _darkMode);
    } catch (e) {
      print('❌ Error saving preferences: $e');
    }
  }

  /// 🎯 Get all the dashboard data using our service
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await _dataService.fetchDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// 🎯 Open/close the side drawer
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  /// 🎯 Toggle between light and dark mode
  void _toggleTheme() {
    setState(() {
      _darkMode = !_darkMode;
      _saveUserPreferences();
    });
  }

  /// 🎯 Log out the user
  Future<void> _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logged out successfully'),
        backgroundColor: SMSTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 🎯 Handle drawer navigation item selection
  void _onDrawerItemSelected(int index) {
    setState(() {
      _selectedDrawerIndex = index;
    });

    // Navigate based on index
    switch (index) {
      case 0: // Dashboard - already here
        break;
      case 1: // Record Payment
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentEntryScreen()),
        );
        break;
      case 2: // Walk-in Enrollment
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CashierEnrollmentScreenImpl()),
        );
        break;
      case 3: // Generate Receipt
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ReceiptGenerationScreen()),
        );
        break;
      case 4: // Daily Collections
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DailyCollectionsScreen()),
        );
        break;
      case 5: // Transaction Summary
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const TransactionSummaryScreen()),
        );
        break;
      case 6: // Student Payment History
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const StudentsPaymentHistoryScreen()),
        );
        break;
      case 7: // Expenses Tracker
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ExpensesTrackerScreen()),
        );
        break;
    }
  }

  /// 🎯 Create drawer navigation items
  List<DrawerItem> _getNavigationItems() {
    return [
      DrawerItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        onTap: () => _onDrawerItemSelected(0),
      ),
      DrawerItem(
        title: 'Record Payment',
        icon: Icons.payment,
        onTap: () => _onDrawerItemSelected(1),
      ),
      DrawerItem(
        title: 'Walk-in Enrollment',
        icon: Icons.add_circle,
        onTap: () => _onDrawerItemSelected(2),
      ),
      DrawerItem(
        title: 'Generate Receipt',
        icon: Icons.receipt,
        onTap: () => _onDrawerItemSelected(3),
      ),
      DrawerItem(
        title: 'Daily Collections',
        icon: Icons.savings,
        onTap: () => _onDrawerItemSelected(4),
      ),
      DrawerItem(
        title: 'Transaction Summary',
        icon: Icons.assessment,
        onTap: () => _onDrawerItemSelected(5),
      ),
      DrawerItem(
        title: 'Student Payment History',
        icon: Icons.school,
        onTap: () => _onDrawerItemSelected(6),
      ),
      DrawerItem(
        title: 'Expenses Tracker',
        icon: Icons.account_balance_wallet,
        onTap: () => _onDrawerItemSelected(7),
      ),
    ];
  }

  /// 🎯 Create drawer settings items
  List<DrawerItem> _getSettingsItems() {
    return [
      DrawerItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        onTap: () => showDialog(
          context: context,
          builder: (context) => SettingsDialog(
            darkMode: _darkMode,
            onToggleTheme: _toggleTheme,
          ),
        ),
      ),
      DrawerItem(
        title: 'Help & Support',
        icon: Icons.help_outline,
        onTap: () => showDialog(
          context: context,
          builder: (context) => HelpDialog(darkMode: _darkMode),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userName = user?.displayName?.split(' ').first ?? 'Cashier';
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    // 🎯 Apply theme colors
    final colorScheme = _darkMode
        ? ColorScheme.dark(
            primary: SMSTheme.primaryColor,
            secondary: SMSTheme.accentColor,
            surface: Colors.grey.shade900,
            background: Colors.black,
          )
        : ColorScheme.light(
            primary: SMSTheme.primaryColor,
            secondary: SMSTheme.accentColor,
            surface: Colors.white,
            background: SMSTheme.backgroundColor,
          );

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme),
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: Stack(
          children: [
            // 🎯 MAIN CONTENT AREA
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _darkMode
                      ? [Colors.black, Colors.grey.shade900]
                      : [SMSTheme.backgroundColor, Colors.white],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 🎯 TOP APP BAR
                    DashboardAppBar(
                      userName: userName,
                      darkMode: _darkMode,
                      unreadNotifications:
                          0, // TODO: Connect to notification service
                      onMenuPressed: _toggleDrawer,
                      onNotificationsPressed: () {
                        // TODO: Show notifications panel
                      },
                      onThemeToggle: _toggleTheme,
                      onProfilePressed: () {
                        // TODO: Show profile menu
                      },
                    ),

                    // 🎯 MAIN SCROLLABLE CONTENT
                    Expanded(
                      child: _buildMainContent(isLargeScreen),
                    ),
                  ],
                ),
              ),
            ),

            // 🎯 DRAWER OVERLAY (darkens background when drawer is open)
            if (_isDrawerOpen)
              GestureDetector(
                onTap: _toggleDrawer,
                child: FadeTransition(
                  opacity: _overlayAnimation,
                  child: Container(color: Colors.black),
                ),
              ),

            // 🎯 ANIMATED DRAWER (slides in from left)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isDrawerOpen ? 0 : -300,
              top: 0,
              bottom: 0,
              width: 300,
              child: DashboardDrawer(
                darkMode: _darkMode,
                selectedIndex: _selectedDrawerIndex,
                onCloseDrawer: _toggleDrawer,
                onItemSelected: _onDrawerItemSelected,
                onLogout: _logout,
                onToggleTheme: _toggleTheme,
                navigationItems: _getNavigationItems(),
                settingsItems: _getSettingsItems(),
              ),
            ),
          ],
        ),

        // 🎯 FLOATING ACTION BUTTON (Record Payment)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PaymentEntryScreen()),
            );
          },
          backgroundColor: SMSTheme.primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Record Payment',
              style: TextStyle(color: Colors.white)),
          tooltip: 'Record New Payment',
        ),
      ),
    );
  }

  /// 🎯 Build the main scrollable content
  Widget _buildMainContent(bool isLargeScreen) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _darkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: SMSTheme.primaryColor,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎯 DASHBOARD STATS (the 3 number cards)
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: DashboardStatsGrid(
                    data: _dashboardData,
                    darkMode: _darkMode,
                    onTodayCollectionsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DailyCollectionsScreen()),
                    ),
                    onWeeklyCollectionsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const TransactionSummaryScreen()),
                    ),
                    onTodayTransactionsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DailyCollectionsScreen()),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🎯 MONTHLY PROGRESS BAR
                FadeInUp(
                  delay: const Duration(milliseconds: 50),
                  duration: const Duration(milliseconds: 500),
                  child: MonthlyProgressCard(
                    data: _dashboardData,
                    darkMode: _darkMode,
                  ),
                ),

                const SizedBox(height: 20),

                // 🎯 QUICK ACTIONS GRID
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: QuickActionsGrid(
                    darkMode: _darkMode,
                    onRecordPayment: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PaymentEntryScreen()),
                    ),
                    onGenerateReceipt: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ReceiptGenerationScreen()),
                    ),
                    onDailyCollections: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DailyCollectionsScreen()),
                    ),
                    onTransactionSummary: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const TransactionSummaryScreen()),
                    ),
                    onStudentPayments: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const StudentsPaymentHistoryScreen()),
                    ),
                    onExpensesTracker: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ExpensesTrackerScreen()),
                    ),
                    onWalkInEnrollment: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const CashierEnrollmentScreenImpl()),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🎯 WEEKLY COLLECTIONS CHART
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 500),
                  child: WeeklyChartCard(
                    weeklyData: _dashboardData.weeklyCollectionSpots,
                    darkMode: _darkMode,
                  ),
                ),

                const SizedBox(height: 20),

                // 🎯 RECENT TRANSACTIONS
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: RecentTransactionsCard(
                    transactions: _dashboardData.recentTransactions,
                    darkMode: _darkMode,
                    onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const TransactionSummaryScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🎯 Show loading spinner
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard data...',
            style: TextStyle(
              color: _darkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
