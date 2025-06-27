import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_provider.dart' as LocalAuthProvider;
import 'admin_settings_screen.dart';
import '../auth/login_screen.dart';
import '../../config/theme.dart';
import 'fee_management_screen.dart';
// Add these imports at the top of the file
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

// Import for mobile only
import 'dart:io' show File;
import 'package:path_provider/path_provider.dart';
// Import for web only

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation Controllers
  late AnimationController _panelController;
  late AnimationController _fabController;
  late AnimationController _refreshController;

  // Animations
  late Animation<double> _panelAnimation;
  late Animation<double> _overlayAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _refreshAnimation;

  // Navigation & UI State
  bool _isPanelOpen = false;
  int _selectedNavIndex = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Dashboard Data - Core metrics
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalCourses = 0;
  int _pendingEnrollments = 0;

  // Enhanced Analytics Data
  late TabController _tabController;
  int totalEnrollments = 0;
  int activeEnrollments = 0;
  double totalRevenue = 0.0;
  double pendingPayments = 0.0;
  double thisMonthRevenue = 0.0;
  double lastMonthRevenue = 0.0;

  // Activity & Distribution Data
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> enhancedActivities = [];
  Map<String, int> _studentsByGradeLevel = {};
  Map<String, double> monthlyRevenue = {};
  Map<String, int> paymentStatusCount = {};

  // Performance Metrics
  DateTime? _lastRefreshTime;
  Map<String, dynamic> _performanceMetrics = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    // Panel animation for side navigation
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOutCubicEmphasized,
    );
    _overlayAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeInOut),
    );

    // FAB animation
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    // Refresh animation
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    // Tab controller for enhanced interface
    _tabController = TabController(length: 4, vsync: this);

    // Add listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
  }

  void _initializeData() {
    _fetchDashboardData();
    _loadEnhancedAnalytics();
  }

  @override
  void dispose() {
    _panelController.dispose();
    _fabController.dispose();
    _refreshController.dispose();
    _tabController.dispose();
    super.dispose();
  }

//<-- PART 2
  // ENHANCED DATA MANAGEMENT METHODS

  Future<void> _fetchDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isRefreshing = true;
      });
    }

    try {
      _refreshController.forward();

      // Parallel data fetching for better performance
      final results = await Future.wait([
        _fetchStudentData(),
        _fetchTeacherData(),
        _fetchCourseData(),
        _fetchEnrollmentData(),
        _fetchActivityData(),
      ]);

      if (mounted) {
        setState(() {
          final studentData = results[0] as Map<String, dynamic>;
          _totalStudents = studentData['count'] as int;
          _studentsByGradeLevel =
              studentData['distribution'] as Map<String, int>;
          _totalTeachers = results[1] as int;
          _totalCourses = results[2] as int;
          _pendingEnrollments = results[3] as int;
          _recentActivities = results[4] as List<Map<String, dynamic>>;
          _lastRefreshTime = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
        });
      }

      await _refreshController.reverse();
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        _showErrorSnackBar('Failed to load dashboard data. Please try again.');
      }
    }
  }

  Future<Map<String, dynamic>> _fetchStudentData() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      Map<String, int> distribution = {};
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final gradeLevel = data['gradeLevel'] as String? ?? 'Unassigned';
        distribution[gradeLevel] = (distribution[gradeLevel] ?? 0) + 1;
      }

      return {
        'count': studentsSnapshot.docs.length,
        'distribution': distribution,
      };
    } catch (e) {
      debugPrint('Error fetching student data: $e');
      return {
        'count': 0,
        'distribution': <String, int>{},
      };
    }
  }

  Future<int> _fetchTeacherData() async {
    try {
      final teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      return teachersSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching teacher data: $e');
      return 0;
    }
  }

  Future<int> _fetchCourseData() async {
    try {
      final coursesSnapshot = await _firestore.collection('courses').get();
      return coursesSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching course data: $e');
      return 0;
    }
  }

  Future<int> _fetchEnrollmentData() async {
    try {
      final pendingSnapshot = await _firestore
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .get();
      return pendingSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching enrollment data: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActivityData() async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return activitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'Unknown',
          'description': data['description'] ?? 'Unknown action',
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Unknown user',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching activity data: $e');
      return [];
    }
  }

  // ENHANCED ANALYTICS METHODS

  Future<void> _loadEnhancedAnalytics() async {
    try {
      await Future.wait([
        _loadFinancialMetrics(),
        _loadEnrollmentMetrics(),
        _loadEnhancedActivities(),
        _loadPerformanceMetrics(),
      ]);
    } catch (e) {
      debugPrint('Error loading enhanced analytics: $e');
    }
  }

  Future<void> _loadFinancialMetrics() async {
    try {
      final paymentsSnapshot = await _firestore.collection('payments').get();

      double currentTotal = 0.0;
      double pendingTotal = 0.0;
      double currentMonthTotal = 0.0;
      double lastMonthTotal = 0.0;

      Map<String, int> statusCount = {};

      final now = DateTime.now();
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String? ?? 'unknown';
        final paymentDate = (data['paymentDate'] as Timestamp?)?.toDate();

        // Count by status
        statusCount[status] = (statusCount[status] ?? 0) + 1;

        if (status == 'completed') {
          currentTotal += amount;

          if (paymentDate != null) {
            // Current month
            if (paymentDate.isAfter(
                startOfCurrentMonth.subtract(const Duration(days: 1)))) {
              currentMonthTotal += amount;
            }
            // Last month
            else if (paymentDate.isAfter(
                    startOfLastMonth.subtract(const Duration(days: 1))) &&
                paymentDate
                    .isBefore(endOfLastMonth.add(const Duration(days: 1)))) {
              lastMonthTotal += amount;
            }
          }
        } else if (status == 'pending') {
          pendingTotal += amount;
        }
      }

      if (mounted) {
        setState(() {
          totalRevenue = currentTotal;
          pendingPayments = pendingTotal;
          thisMonthRevenue = currentMonthTotal;
          lastMonthRevenue = lastMonthTotal;
          paymentStatusCount = statusCount;
        });
      }

      await _loadMonthlyRevenue();
    } catch (e) {
      debugPrint('Error loading financial metrics: $e');
    }
  }

  Future<void> _loadMonthlyRevenue() async {
    try {
      final now = DateTime.now();
      Map<String, double> revenue = {};

      // Load last 6 months of data
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormat('MMM yyyy').format(month);

        final startOfMonth =
            Timestamp.fromDate(DateTime(month.year, month.month, 1));
        final endOfMonth = Timestamp.fromDate(
            DateTime(month.year, month.month + 1, 0, 23, 59, 59));

        final query = await _firestore
            .collection('payments')
            .where('paymentDate', isGreaterThanOrEqualTo: startOfMonth)
            .where('paymentDate', isLessThanOrEqualTo: endOfMonth)
            .where('status', isEqualTo: 'completed')
            .get();

        double monthTotal = 0.0;
        for (var doc in query.docs) {
          monthTotal += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        }

        revenue[monthKey] = monthTotal;
      }

      if (mounted) {
        setState(() {
          monthlyRevenue = revenue;
        });
      }
    } catch (e) {
      debugPrint('Error loading monthly revenue: $e');
    }
  }

  Future<void> _loadEnrollmentMetrics() async {
    try {
      final enrollmentsSnapshot =
          await _firestore.collection('enrollments').get();
      final total = enrollmentsSnapshot.docs.length;

      final currentYear = DateTime.now().year;
      final active = enrollmentsSnapshot.docs.where((doc) {
        final schoolYear = doc.data()['schoolYear'] as String?;
        return schoolYear?.contains(currentYear.toString()) ?? false;
      }).length;

      if (mounted) {
        setState(() {
          totalEnrollments = total;
          activeEnrollments = active;
        });
      }
    } catch (e) {
      debugPrint('Error loading enrollment metrics: $e');
    }
  }

  Future<void> _loadEnhancedActivities() async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Get recent enrollments with student details
      final enrollmentsQuery = await _firestore
          .collection('enrollments')
          .orderBy('enrollmentDate', descending: true)
          .limit(5)
          .get();

      for (var doc in enrollmentsQuery.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String?;

        String studentName = 'Unknown Student';
        if (studentId != null) {
          try {
            final studentDoc =
                await _firestore.collection('students').doc(studentId).get();
            if (studentDoc.exists) {
              final studentData = studentDoc.data()!;
              studentName =
                  '${studentData['firstName']} ${studentData['lastName']}';
            }
          } catch (e) {
            debugPrint('Error getting student name: $e');
          }
        }

        activities.add({
          'type': 'enrollment',
          'title': 'New Enrollment',
          'description': '$studentName enrolled in ${data['gradeLevel']}',
          'timestamp': data['enrollmentDate'],
          'icon': Icons.person_add_rounded,
          'color': SMSTheme.successColor,
          'priority': 'high',
        });
      }

      // Get recent payments
      final paymentsQuery = await _firestore
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .limit(5)
          .get();

      for (var doc in paymentsQuery.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        activities.add({
          'type': 'payment',
          'title': 'Payment Received',
          'description': 'Amount: ₱${NumberFormat('#,##0.00').format(amount)}',
          'timestamp': data['paymentDate'],
          'icon': Icons.payments_rounded,
          'color': SMSTheme.primaryColor,
          'priority': 'medium',
        });
      }

      // Sort by timestamp and priority
      activities.sort((a, b) {
        final timestampComparison = (b['timestamp'] as Timestamp)
            .compareTo(a['timestamp'] as Timestamp);
        if (timestampComparison != 0) return timestampComparison;

        // Secondary sort by priority
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        return (priorityOrder[a['priority']] ?? 2)
            .compareTo(priorityOrder[b['priority']] ?? 2);
      });

      if (mounted) {
        setState(() {
          enhancedActivities = activities.take(8).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading enhanced activities: $e');
    }
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Calculate various performance metrics
      final metrics = {
        'dataLoadTime': stopwatch.elapsedMilliseconds,
        'totalRecords': _totalStudents + _totalTeachers + _totalCourses,
        'lastUpdateTime': DateTime.now().toIso8601String(),
        'systemHealth':
            'excellent', // This could be calculated based on various factors
      };

      if (mounted) {
        setState(() {
          _performanceMetrics = metrics;
        });
      }

      stopwatch.stop();
    } catch (e) {
      debugPrint('Error loading performance metrics: $e');
    }
  }
  //<< --- PART 3
// HELPER METHODS & UI UTILITIES

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: SMSTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _fetchDashboardData(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: SMSTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoDialog(String title, String message,
      {VoidCallback? onAction, String? actionText}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SMSTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline_rounded,
                  color: SMSTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: SMSTheme.textSecondaryColor,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onAction != null && actionText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  String _calculateCompletionRate() {
    final total = (paymentStatusCount['completed'] ?? 0) +
        (paymentStatusCount['pending'] ?? 0);
    if (total == 0) return '0.0';
    final rate = ((paymentStatusCount['completed'] ?? 0) / total * 100);
    return rate.toStringAsFixed(1);
  }

  String _calculateGrowthRate() {
    if (lastMonthRevenue == 0) return '0.0';
    final growth =
        ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100);
    return growth.toStringAsFixed(1);
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 30) {
      return DateFormat('MMM d, yyyy').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getMetricColor(String metricType, double value) {
    switch (metricType) {
      case 'revenue':
        return value > 0 ? SMSTheme.successColor : SMSTheme.textSecondaryColor;
      case 'growth':
        return value > 0
            ? SMSTheme.successColor
            : value < 0
                ? SMSTheme.errorColor
                : SMSTheme.textSecondaryColor;
      case 'completion':
        return value > 80
            ? SMSTheme.successColor
            : value > 60
                ? Colors.orange
                : SMSTheme.errorColor;
      default:
        return SMSTheme.primaryColor;
    }
  }

  // NAVIGATION & INTERACTION METHODS

  void _togglePanel() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPanelOpen = !_isPanelOpen;
      if (_isPanelOpen) {
        _panelController.forward();
      } else {
        _panelController.reverse();
      }
    });
  }

  void _onFabPressed() async {
    HapticFeedback.mediumImpact();
    _fabController.forward().then((_) => _fabController.reverse());

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminSettingsScreen(tab: 'add'),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    HapticFeedback.selectionClick();
    await Future.wait([
      _fetchDashboardData(),
      _loadEnhancedAnalytics(),
    ]);
    _showSuccessSnackBar('Dashboard updated successfully');
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: SMSTheme.errorColor),
            const SizedBox(width: 12),
            const Text('Confirm Logout'),
          ],
        ),
        content: const Text(
            'Are you sure you want to logout from the admin dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.errorColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await Provider.of<LocalAuthProvider.AuthProvider>(context,
                listen: false)
            .signOut();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );

          _showSuccessSnackBar('Logged out successfully');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to logout. Please try again.');
      }
    }
  }

  // RESPONSIVE DESIGN HELPERS

  bool _isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 1200;
  bool _isMediumScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  int _getCrossAxisCount(BuildContext context) {
    if (_isLargeScreen(context)) return 4;
    if (_isMediumScreen(context)) return 3;
    return 2;
  }

  double _getCardAspectRatio(BuildContext context) {
    if (_isLargeScreen(context)) return 1.4;
    if (_isMediumScreen(context)) return 1.3;
    return 1.2;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    if (_isLargeScreen(context)) return const EdgeInsets.all(24);
    if (_isMediumScreen(context)) return const EdgeInsets.all(20);
    return const EdgeInsets.all(16);
  }

  // THEME & STYLING HELPERS

  BoxDecoration _getCardDecoration({Color? borderColor, double? elevation}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: borderColor != null
          ? Border.all(color: borderColor.withOpacity(0.2), width: 1)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: elevation ?? 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ],
    );
  }

  TextStyle _getCardTitleStyle() {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: SMSTheme.textPrimaryColor,
      letterSpacing: -0.5,
    );
  }

  TextStyle _getCardSubtitleStyle() {
    return TextStyle(
      fontSize: 14,
      color: SMSTheme.textSecondaryColor,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle _getMetricValueStyle({Color? color}) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: color ?? SMSTheme.textPrimaryColor,
      letterSpacing: -1,
      height: 1,
    );
  }

  // ANIMATION HELPERS

  Widget _buildAnimatedCard({
    required Widget child,
    required int index,
    Duration? delay,
  }) {
    return FadeInUp(
      delay: delay ?? Duration(milliseconds: 100 * index),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  Widget _buildShimmerEffect({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
  //<< --- PART 4

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final user = Provider.of<LocalAuthProvider.AuthProvider>(context).user;
    final userName = user?.displayName?.split(' ').first ?? 'Admin';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Main Content
          _buildMainContent(context, userName),

          // Navigation Panel Overlay
          if (_isPanelOpen)
            GestureDetector(
              onTap: _togglePanel,
              child: FadeTransition(
                opacity: _overlayAnimation,
                child: Container(
                  color: Colors.black,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),

          // Navigation Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubicEmphasized,
            left: _isPanelOpen ? 0 : -320,
            top: 0,
            bottom: 0,
            width: 320,
            child: _buildNavigationPanel(context),
          ),
        ],
      ),

      // Enhanced Floating Action Button
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _onFabPressed,
          backgroundColor: SMSTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          highlightElevation: 12,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Quick Add',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMainContent(BuildContext context, String userName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Colors.white],
          stops: [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Enhanced App Bar
            _buildEnhancedAppBar(context, userName),

            // Modern Tab Bar
            _buildModernTabBar(),

            // Content Area
            Expanded(
              child: _isLoading
                  ? _buildEnhancedLoadingIndicator()
                  : TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildOverviewTab(context),
                        _buildAnalyticsTab(context),
                        _buildManagementTab(context),
                        _buildReportsTab(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(BuildContext context, String userName) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsivePadding(context).left,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu Button
          Container(
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: AnimatedRotation(
                turns: _isPanelOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 350),
                child: Icon(
                  _isPanelOpen ? Icons.close_rounded : Icons.menu_rounded,
                  color: SMSTheme.primaryColor,
                ),
              ),
              onPressed: _togglePanel,
              tooltip: _isPanelOpen ? 'Close Menu' : 'Open Menu',
            ),
          ),

          const SizedBox(width: 16),

          // Logo and Title
          Expanded(
            child: Row(
              children: [
                // Logo Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: SMSTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Title and Subtitle
                if (!_isSmallScreen(context))
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PBTS Admin Dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: SMSTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Refresh Button
              Container(
                decoration: BoxDecoration(
                  color: _isRefreshing
                      ? SMSTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: RotationTransition(
                    turns: _refreshAnimation,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: _isRefreshing
                          ? SMSTheme.primaryColor
                          : SMSTheme.textSecondaryColor,
                    ),
                  ),
                  onPressed: _isRefreshing ? null : _refreshDashboard,
                  tooltip: 'Refresh Dashboard',
                ),
              ),

              const SizedBox(width: 8),

              // Notifications
              _buildNotificationButton(),

              const SizedBox(width: 8),

              // User Profile
              _buildUserProfileButton(context, userName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: SMSTheme.textSecondaryColor,
            ),
            onPressed: () => _showNotificationsDialog(context),
            tooltip: 'Notifications',
          ),
        ),
        if (_pendingEnrollments > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: SMSTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: SMSTheme.errorColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _pendingEnrollments > 9 ? '9+' : _pendingEnrollments.toString(),
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

  Widget _buildUserProfileButton(BuildContext context, String userName) {
    return GestureDetector(
      onTap: () => _showProfileOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SMSTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: SMSTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: SMSTheme.primaryColor,
              radius: 16,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (!_isSmallScreen(context)) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi, $userName',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: SMSTheme.textPrimaryColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 12,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: SMSTheme.textSecondaryColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          labelColor: SMSTheme.primaryColor,
          unselectedLabelColor: SMSTheme.textSecondaryColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            _buildModernTab(Icons.dashboard_rounded, 'Overview'),
            _buildModernTab(Icons.analytics_rounded, 'Analytics'),
            _buildModernTab(Icons.settings_rounded, 'Management'),
            _buildModernTab(Icons.assessment_rounded, 'Reports'),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTab(IconData icon, String text) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          if (!_isSmallScreen(context)) ...[
            const SizedBox(width: 8),
            Text(text),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading dashboard data...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the latest information',
            style: TextStyle(
              fontSize: 14,
              color: SMSTheme.textSecondaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  //<< --- PART 5

// OVERVIEW TAB - Main Dashboard Content

  Widget _buildOverviewTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: SMSTheme.primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: _getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildAnimatedCard(
              index: 0,
              child: _buildWelcomeSection(context),
            ),

            const SizedBox(height: 24),

            // Key Metrics
            _buildAnimatedCard(
              index: 1,
              child: _buildKeyMetrics(context),
            ),

            const SizedBox(height: 24),

            // Main Content Grid
            if (_isLargeScreen(context))
              _buildLargeScreenLayout(context)
            else
              _buildSmallScreenLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final growthRate = _calculateGrowthRate();
    final isPositiveGrowth = double.tryParse(growthRate)?.isNegative == false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: _isLargeScreen(context) ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s your school\'s performance overview for today.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: _isLargeScreen(context) ? 48 : 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildQuickStatChip(
                  icon: Icons.trending_up_rounded,
                  label: 'Growth Rate',
                  value: '${growthRate.startsWith('-') ? '' : '+'}$growthRate%',
                  isPositive: isPositiveGrowth,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Payment Success',
                  value: '${_calculateCompletionRate()}%',
                  isPositive: double.tryParse(_calculateCompletionRate())! > 80,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatChip(
                  icon: Icons.calendar_month_rounded,
                  label: 'Current Period',
                  value: DateFormat('MMM yyyy').format(DateTime.now()),
                  isPositive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Key Performance Indicators',
              style: _getCardTitleStyle().copyWith(fontSize: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SMSTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SMSTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live Data',
                    style: TextStyle(
                      color: SMSTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _getCardAspectRatio(context),
          children: [
            _buildEnhancedMetricCard(
              title: 'Total Students',
              value: _totalStudents.toString(),
              icon: Icons.school_rounded,
              color: const Color(0xFF3B82F6),
              subtitle: 'Active registrations',
              trend: '+12% this month',
              onTap: () => _navigateToTab('students'),
            ),
            _buildEnhancedMetricCard(
              title: 'Active Enrollments',
              value: activeEnrollments.toString(),
              icon: Icons.how_to_reg_rounded,
              color: const Color(0xFF10B981),
              subtitle: 'Current academic year',
              trend: '+8% this quarter',
              onTap: () => _navigateToTab('enrollment'),
            ),
            _buildEnhancedMetricCard(
              title: 'Total Revenue',
              value: '₱${NumberFormat('#,##0').format(totalRevenue)}',
              icon: Icons.monetization_on_rounded,
              color: const Color(0xFF8B5CF6),
              subtitle: 'Lifetime earnings',
              trend: '+15% this month',
              onTap: () => _tabController.animateTo(3),
            ),
            _buildEnhancedMetricCard(
              title: 'This Month',
              value: '₱${NumberFormat('#,##0').format(thisMonthRevenue)}',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFEF4444),
              subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
              trend: _calculateGrowthRate() + '%',
              onTap: () => _tabController.animateTo(1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String trend,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _getCardDecoration(borderColor: color),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend.startsWith('+')
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 12,
                          color: trend.startsWith('+')
                              ? SMSTheme.successColor
                              : SMSTheme.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: trend.startsWith('+')
                                ? SMSTheme.successColor
                                : SMSTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Value
              Text(
                value,
                style: _getMetricValueStyle(color: color),
              ),

              const SizedBox(height: 4),

              // Title and Subtitle
              Text(
                title,
                style: _getCardTitleStyle().copyWith(fontSize: 16),
              ),

              Text(
                subtitle,
                style: _getCardSubtitleStyle().copyWith(fontSize: 12),
              ),

              const SizedBox(height: 16),

              // Action Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: color, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (60%)
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildAnimatedCard(
                index: 2,
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 24),
              _buildAnimatedCard(
                index: 3,
                child: _buildDistributionChart(context),
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Right Column (40%)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildAnimatedCard(
                index: 4,
                child: _buildEnhancedRecentActivities(context),
              ),
              const SizedBox(height: 24),
              _buildAnimatedCard(
                index: 5,
                child: _buildSchoolCalendar(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context) {
    return Column(
      children: [
        _buildAnimatedCard(
          index: 2,
          child: _buildQuickActions(context),
        ),
        const SizedBox(height: 24),
        _buildAnimatedCard(
          index: 3,
          child: _buildEnhancedRecentActivities(context),
        ),
        const SizedBox(height: 24),
        _buildAnimatedCard(
          index: 4,
          child: _buildDistributionChart(context),
        ),
        const SizedBox(height: 24),
        _buildAnimatedCard(
          index: 5,
          child: _buildSchoolCalendar(context),
        ),
      ],
    );
  }

  void _navigateToTab(String tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSettingsScreen(tab: tab),
      ),
    );
  }

  //<< --- PART 6

// QUICK ACTIONS SECTION

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: _getCardTitleStyle()),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your school resources efficiently',
                    style: _getCardSubtitleStyle(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SMSTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: SMSTheme.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _isLargeScreen(context)
                ? 4
                : _isMediumScreen(context)
                    ? 3
                    : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                title: 'Students',
                subtitle: 'Manage students',
                icon: Icons.school_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => _navigateToTab('students'),
                badge: _totalStudents.toString(),
              ),
              _buildActionCard(
                title: 'Teachers',
                subtitle: 'Manage teachers',
                icon: Icons.person_rounded,
                color: const Color(0xFF10B981),
                onTap: () => _navigateToTab('teachers'),
                badge: _totalTeachers.toString(),
              ),
              _buildActionCard(
                title: 'Courses',
                subtitle: 'Manage courses',
                icon: Icons.book_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => _navigateToTab('courses'),
                badge: _totalCourses.toString(),
              ),
              _buildActionCard(
                title: 'Enrollment',
                subtitle: 'Manage enrollment',
                icon: Icons.how_to_reg_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => _navigateToTab('enrollment'),
                badge: _pendingEnrollments > 0
                    ? _pendingEnrollments.toString()
                    : null,
                isUrgent: _pendingEnrollments > 0,
              ),
              _buildActionCard(
                title: 'Fee Management',
                subtitle: 'Configure fees',
                icon: Icons.monetization_on_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FeeManagementScreen()),
                ),
              ),
              _buildActionCard(
                title: 'Grade Levels',
                subtitle: 'Manage grades',
                icon: Icons.grade_rounded,
                color: const Color(0xFF06B6D4),
                onTap: () => _navigateToTab('gradeLevels'),
              ),
              _buildActionCard(
                title: 'Subjects',
                subtitle: 'Manage subjects',
                icon: Icons.subject_rounded,
                color: const Color(0xFFEC4899),
                onTap: () => _navigateToTab('subjects'),
              ),
              _buildActionCard(
                title: 'Reports',
                subtitle: 'View reports',
                icon: Icons.analytics_rounded,
                color: const Color(0xFF6366F1),
                onTap: () => _tabController.animateTo(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool isUrgent = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent
                ? SMSTheme.errorColor.withOpacity(0.3)
                : color.withOpacity(0.2),
            width: isUrgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isUrgent ? SMSTheme.errorColor : color).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent ? SMSTheme.errorColor : color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Title and subtitle
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.textSecondaryColor,
                ),
              ),

              const SizedBox(height: 12),

              // Action indicator
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ENHANCED RECENT ACTIVITIES

  Widget _buildEnhancedRecentActivities(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Activities', style: _getCardTitleStyle()),
                  const SizedBox(height: 4),
                  Text(
                    'Latest system activities and updates',
                    style: _getCardSubtitleStyle(),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAllActivities(context),
                icon: Icon(Icons.history_rounded,
                    size: 16, color: SMSTheme.primaryColor),
                label: Text(
                  'View All',
                  style: TextStyle(
                    color: SMSTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (enhancedActivities.isEmpty && _recentActivities.isEmpty)
            _buildEmptyActivitiesState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enhancedActivities.isNotEmpty
                  ? math.min(enhancedActivities.length, 6)
                  : math.min(_recentActivities.length, 6),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (enhancedActivities.isNotEmpty) {
                  return _buildEnhancedActivityItem(enhancedActivities[index]);
                } else {
                  return _buildLegacyActivityItem(_recentActivities[index]);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivitiesState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Recent Activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activities will appear here as they happen',
              style: TextStyle(
                fontSize: 12,
                color: SMSTheme.textSecondaryColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActivityItem(Map<String, dynamic> activity) {
    final priority = activity['priority'] as String? ?? 'low';
    final color = activity['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (priority == 'high')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SMSTheme.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIGH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: SMSTheme.textSecondaryColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: SMSTheme.textSecondaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(activity['timestamp'] as Timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: SMSTheme.textSecondaryColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyActivityItem(Map<String, dynamic> activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: SMSTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['userName'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTimeAgo(activity['timestamp'] as DateTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: SMSTheme.textSecondaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllActivities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Activities',
                      style: _getCardTitleStyle().copyWith(fontSize: 20),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Activities list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  itemCount: enhancedActivities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildEnhancedActivityItem(enhancedActivities[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //<< --- PART 7

// ENHANCED DISTRIBUTION CHART

  Widget _buildDistributionChart(BuildContext context) {
    final gradeLevels = _studentsByGradeLevel.entries.toList();
    gradeLevels.sort((a, b) => a.key.compareTo(b.key));

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Distribution', style: _getCardTitleStyle()),
                  const SizedBox(height: 4),
                  Text('Distribution across grade levels',
                      style: _getCardSubtitleStyle()),
                ],
              ),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.more_vert_rounded,
                      color: SMSTheme.textSecondaryColor),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) => _handleChartAction(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download_rounded, size: 18),
                        SizedBox(width: 12),
                        Text('Export Chart'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 12),
                        Text('Refresh Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18),
                        SizedBox(width: 12),
                        Text('View Details'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_studentsByGradeLevel.isEmpty)
            _buildEmptyChartState()
          else
            Column(
              children: [
                // Chart Section
                SizedBox(
                  height: 280,
                  child: Row(
                    children: [
                      // Pie Chart
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sections:
                                List.generate(gradeLevels.length, (index) {
                              final gradeLevel = gradeLevels[index];
                              final color = colors[index % colors.length];
                              final percentage = (_totalStudents > 0)
                                  ? (gradeLevel.value / _totalStudents) * 100
                                  : 0.0;

                              return PieChartSectionData(
                                color: color,
                                value: gradeLevel.value.toDouble(),
                                title: '${percentage.toStringAsFixed(1)}%',
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              );
                            }),
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            startDegreeOffset: -90,
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Legend
                      if (!_isSmallScreen(context))
                        Expanded(
                          flex: 2,
                          child: _buildChartLegend(gradeLevels, colors),
                        ),
                    ],
                  ),
                ),

                // Mobile Legend
                if (_isSmallScreen(context)) ...[
                  const SizedBox(height: 24),
                  _buildMobileLegend(gradeLevels, colors),
                ],

                const SizedBox(height: 24),

                // Summary Stats
                _buildChartSummary(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Distribution Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Student distribution will appear here',
              style: TextStyle(
                fontSize: 12,
                color: SMSTheme.textSecondaryColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(
      List<MapEntry<String, int>> gradeLevels, List<Color> colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(gradeLevels.length, (index) {
          final gradeLevel = gradeLevels[index];
          final color = colors[index % colors.length];
          final percentage = (_totalStudents > 0)
              ? (gradeLevel.value / _totalStudents) * 100
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gradeLevel.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${gradeLevel.value} students (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileLegend(
      List<MapEntry<String, int>> gradeLevels, List<Color> colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(gradeLevels.length, (index) {
        final gradeLevel = gradeLevels[index];
        final color = colors[index % colors.length];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                gradeLevel.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${gradeLevel.value})',
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChartSummary() {
    final totalGradeLevels = _studentsByGradeLevel.length;
    final averagePerGrade =
        totalGradeLevels > 0 ? (_totalStudents / totalGradeLevels).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SMSTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Students', _totalStudents.toString()),
          _buildSummaryItem('Grade Levels', totalGradeLevels.toString()),
          _buildSummaryItem('Average/Grade', averagePerGrade.toString()),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: SMSTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  void _handleChartAction(String action) {
    switch (action) {
      case 'export':
        _showSuccessSnackBar('Chart export feature coming soon!');
        break;
      case 'refresh':
        _fetchDashboardData();
        break;
      case 'details':
        _showChartDetails();
        break;
    }
  }

  void _showChartDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text('Student Distribution Details', style: _getCardTitleStyle()),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _studentsByGradeLevel.entries.map((entry) {
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: SMSTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value} students',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ENHANCED SCHOOL CALENDAR

  Widget _buildSchoolCalendar(BuildContext context) {
    final now = DateTime.now();
    final upcomingEvents = _getUpcomingEvents(now);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('School Calendar', style: _getCardTitleStyle()),
                  const SizedBox(height: 4),
                  Text('Upcoming events and schedules',
                      style: _getCardSubtitleStyle()),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showFullCalendar(context),
                icon: Icon(Icons.calendar_month_rounded,
                    size: 16, color: SMSTheme.primaryColor),
                label: Text(
                  'View Calendar',
                  style: TextStyle(
                    color: SMSTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Current Month Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SMSTheme.primaryColor.withOpacity(0.1),
                  SMSTheme.accentColor.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SMSTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(now),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${upcomingEvents.length} upcoming events',
                        style: TextStyle(
                          fontSize: 14,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Events List
          if (upcomingEvents.isEmpty)
            _buildNoEventsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(upcomingEvents.length, 4),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildEventItem(upcomingEvents[index]),
            ),

          const SizedBox(height: 20),

          // Add Event Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddEventDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Event'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SMSTheme.primaryColor,
                side: BorderSide(color: SMSTheme.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUpcomingEvents(DateTime now) {
    return [
      {
        'title': 'First Quarter Exams',
        'date': DateTime(now.year, now.month, now.day + 15),
        'color': const Color(0xFFEF4444),
        'type': 'exam',
        'description': 'Quarterly assessment for all grade levels',
      },
      {
        'title': 'Parent-Teacher Conference',
        'date': DateTime(now.year, now.month, now.day + 8),
        'color': const Color(0xFF3B82F6),
        'type': 'meeting',
        'description': 'Quarterly progress discussion',
      },
      {
        'title': 'Science Fair',
        'date': DateTime(now.year, now.month, now.day + 3),
        'color': const Color(0xFF10B981),
        'type': 'event',
        'description': 'Annual science exhibition',
      },
      {
        'title': 'National Heroes Day',
        'date': DateTime(now.year, now.month, now.day + 21),
        'color': const Color(0xFF8B5CF6),
        'type': 'holiday',
        'description': 'National holiday - No classes',
      },
      {
        'title': 'Sports Festival',
        'date': DateTime(now.year, now.month, now.day + 28),
        'color': const Color(0xFFF59E0B),
        'type': 'event',
        'description': 'Inter-grade sports competition',
      },
    ];
  }

  Widget _buildNoEventsState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No Upcoming Events',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final eventDate = event['date'] as DateTime;
    final now = DateTime.now();
    final daysDifference =
        eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    final color = event['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Date container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(eventDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(eventDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEventUrgencyColor(daysDifference)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getEventTimeText(daysDifference),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getEventUrgencyColor(daysDifference),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE').format(eventDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventUrgencyColor(int daysDifference) {
    if (daysDifference == 0) return SMSTheme.errorColor;
    if (daysDifference <= 3) return const Color(0xFFF59E0B);
    if (daysDifference <= 7) return SMSTheme.primaryColor;
    return SMSTheme.textSecondaryColor;
  }

  String _getEventTimeText(int daysDifference) {
    if (daysDifference == 0) return 'Today';
    if (daysDifference == 1) return 'Tomorrow';
    if (daysDifference <= 7) return 'In $daysDifference days';
    return 'In ${(daysDifference / 7).ceil()} weeks';
  }

  void _showFullCalendar(BuildContext context) {
    _showSuccessSnackBar('Full calendar view coming soon!');
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SMSTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event_rounded, color: SMSTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text('Add School Event'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description_rounded),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded),
                        const SizedBox(width: 12),
                        Text(DateFormat('MMMM d, yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar(
                    'Event "${titleController.text}" added to calendar');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }

  //<< --- PART 8
// ANALYTICS TAB - Advanced Data Visualization

  Widget _buildAnalyticsTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Header
          _buildAnimatedCard(
            index: 0,
            child: _buildAnalyticsHeader(),
          ),

          const SizedBox(height: 24),

          // Financial Analytics
          _buildAnimatedCard(
            index: 1,
            child: _buildFinancialAnalytics(),
          ),

          const SizedBox(height: 24),

          // Performance Metrics Grid
          if (_isLargeScreen(context))
            _buildAnalyticsGrid()
          else
            _buildAnalyticsColumn(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics & Insights',
                      style: TextStyle(
                        fontSize: _isLargeScreen(context) ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprehensive data analysis and performance metrics for informed decision-making.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: _isLargeScreen(context) ? 48 : 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Key Insights Row
          Row(
            children: [
              Expanded(
                child: _buildInsightChip(
                  icon: Icons.trending_up_rounded,
                  label: 'Revenue Growth',
                  value: '${_calculateGrowthRate()}%',
                  isPositive: double.tryParse(_calculateGrowthRate())! >= 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightChip(
                  icon: Icons.school_rounded,
                  label: 'Total Enrolled',
                  value: activeEnrollments.toString(),
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightChip(
                  icon: Icons.assessment_rounded,
                  label: 'Success Rate',
                  value: '${_calculateCompletionRate()}%',
                  isPositive: double.tryParse(_calculateCompletionRate())! > 80,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAnalytics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue Analytics', style: _getCardTitleStyle()),
                  const SizedBox(height: 4),
                  Text('Monthly revenue trends and payment analytics',
                      style: _getCardSubtitleStyle()),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SMSTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: SMSTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Real-time',
                      style: TextStyle(
                        color: SMSTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Revenue Chart
          if (monthlyRevenue.isNotEmpty)
            _buildRevenueChart()
          else
            _buildEmptyRevenueChart(),

          const SizedBox(height: 24),

          // Payment Status Analytics
          _buildPaymentStatusAnalytics(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final entries = monthlyRevenue.entries.toList();
    final maxRevenue = monthlyRevenue.values.isNotEmpty
        ? monthlyRevenue.values.reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Revenue Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Revenue',
                    style: TextStyle(
                      fontSize: 12,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final height =
                    maxRevenue > 0 ? (entry.value / maxRevenue) * 180 : 0.0;
                final isCurrentMonth = entry.key
                    .contains(DateFormat('MMM yyyy').format(DateTime.now()));

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Value label
                    Text(
                      '₱${NumberFormat.compact().format(entry.value)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: SMSTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Bar
                    Container(
                      width: 28,
                      height: height + 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isCurrentMonth
                              ? [SMSTheme.accentColor, SMSTheme.primaryColor]
                              : [
                                  SMSTheme.primaryColor.withOpacity(0.7),
                                  SMSTheme.accentColor.withOpacity(0.7)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: SMSTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Month label
                    Text(
                      entry.key.split(' ')[0],
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrentMonth
                            ? SMSTheme.primaryColor
                            : SMSTheme.textSecondaryColor,
                        fontWeight: isCurrentMonth
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRevenueChart() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Revenue Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Revenue data will appear here once payments are processed',
              style: TextStyle(
                fontSize: 12,
                color: SMSTheme.textSecondaryColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusAnalytics() {
    final totalPayments =
        paymentStatusCount.values.fold(0, (sum, count) => sum + count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Status Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (totalPayments == 0)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No payment data available',
                style: TextStyle(
                  color: SMSTheme.textSecondaryColor,
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildPaymentStatusCard(
                  'Completed',
                  paymentStatusCount['completed'] ?? 0,
                  totalPayments,
                  SMSTheme.successColor,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStatusCard(
                  'Pending',
                  paymentStatusCount['pending'] ?? 0,
                  totalPayments,
                  const Color(0xFFF59E0B),
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentStatusCard(
                  'Failed',
                  paymentStatusCount['failed'] ?? 0,
                  totalPayments,
                  SMSTheme.errorColor,
                  Icons.error_rounded,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentStatusCard(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildAnimatedCard(
                index: 2,
                child: _buildMonthlyComparison(),
              ),
              const SizedBox(height: 24),
              _buildAnimatedCard(
                index: 3,
                child: _buildPerformanceMetrics(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildAnimatedCard(
            index: 4,
            child: _buildQuickStats(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsColumn() {
    return Column(
      children: [
        _buildAnimatedCard(
          index: 2,
          child: _buildMonthlyComparison(),
        ),
        const SizedBox(height: 24),
        _buildAnimatedCard(
          index: 3,
          child: _buildPerformanceMetrics(),
        ),
        const SizedBox(height: 24),
        _buildAnimatedCard(
          index: 4,
          child: _buildQuickStats(),
        ),
      ],
    );
  }

  Widget _buildMonthlyComparison() {
    final growthRate = double.tryParse(_calculateGrowthRate()) ?? 0.0;
    final isPositiveGrowth = growthRate >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Comparison', style: _getCardTitleStyle()),
          const SizedBox(height: 4),
          Text('Current vs previous month performance',
              style: _getCardSubtitleStyle()),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildComparisonMetric(
                  'This Month',
                  '₱${NumberFormat('#,##0').format(thisMonthRevenue)}',
                  SMSTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonMetric(
                  'Last Month',
                  '₱${NumberFormat('#,##0').format(lastMonthRevenue)}',
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPositiveGrowth
                  ? SMSTheme.successColor.withOpacity(0.1)
                  : SMSTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPositiveGrowth
                    ? SMSTheme.successColor.withOpacity(0.2)
                    : SMSTheme.errorColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPositiveGrowth
                        ? SMSTheme.successColor
                        : SMSTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPositiveGrowth
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isPositiveGrowth ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPositiveGrowth
                              ? SMSTheme.successColor
                              : SMSTheme.errorColor,
                        ),
                      ),
                      Text(
                        isPositiveGrowth
                            ? 'Growth from last month'
                            : 'Decline from last month',
                        style: TextStyle(
                          fontSize: 12,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Metrics', style: _getCardTitleStyle()),
          const SizedBox(height: 4),
          Text('System performance and data insights',
              style: _getCardSubtitleStyle()),
          const SizedBox(height: 20),
          _buildMetricRow('Completion Rate', '${_calculateCompletionRate()}%'),
          _buildMetricRow('Active Enrollments', '$activeEnrollments'),
          _buildMetricRow(
              'Total Records', '${_performanceMetrics['totalRecords'] ?? 0}'),
          _buildMetricRow('System Health',
              '${_performanceMetrics['systemHealth'] ?? 'Good'}'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Statistics', style: _getCardTitleStyle()),
          const SizedBox(height: 20),
          _buildQuickStatItem(
            'Revenue Today',
            '₱${NumberFormat('#,##0').format(thisMonthRevenue / 30)}',
            Icons.today_rounded,
            SMSTheme.primaryColor,
          ),
          _buildQuickStatItem(
            'New Students',
            '+${(_totalStudents * 0.12).round()}',
            Icons.person_add_rounded,
            SMSTheme.successColor,
          ),
          _buildQuickStatItem(
            'Pending Items',
            _pendingEnrollments.toString(),
            Icons.pending_actions_rounded,
            _pendingEnrollments > 0 ? SMSTheme.errorColor : Colors.grey,
          ),
          _buildQuickStatItem(
            'Success Rate',
            '${_calculateCompletionRate()}%',
            Icons.check_circle_rounded,
            SMSTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  //<< --- PART 9
// MANAGEMENT TAB - System Management & Configuration

  Widget _buildManagementTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Management Header
          _buildAnimatedCard(
            index: 0,
            child: _buildManagementHeader(),
          ),

          const SizedBox(height: 24),

          // Management Grid
          _buildAnimatedCard(
            index: 1,
            child: _buildManagementGrid(),
          ),

          const SizedBox(height: 24),

          // System Status
          _buildAnimatedCard(
            index: 2,
            child: _buildSystemStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade600,
            Colors.indigo.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade600.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Management',
                  style: TextStyle(
                    fontSize: _isLargeScreen(context) ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure system settings, manage users, and maintain data integrity.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Administrator Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.settings_applications_rounded,
              size: _isLargeScreen(context) ? 48 : 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Management Tools', style: _getCardTitleStyle()),
          const SizedBox(height: 4),
          Text('Comprehensive tools for system administration',
              style: _getCardSubtitleStyle()),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildManagementCard(
                'User Management',
                'Manage admin users and permissions',
                Icons.people_alt_rounded,
                const Color(0xFF3B82F6),
                () => _showUserManagement(),
              ),
              _buildManagementCard(
                'Database Backup',
                'Create and restore backups',
                Icons.backup_rounded,
                const Color(0xFF10B981),
                () => _createBackup(),
              ),
              _buildManagementCard(
                'Fee Configuration',
                'Configure tuition and fees',
                Icons.monetization_on_rounded,
                const Color(0xFFF59E0B),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FeeManagementScreen()),
                ),
              ),
              _buildManagementCard(
                'System Logs',
                'View system activity logs',
                Icons.list_alt_rounded,
                const Color(0xFF8B5CF6),
                () => _showSystemLogs(),
              ),
              _buildManagementCard(
                'Data Import/Export',
                'Import or export data',
                Icons.import_export_rounded,
                const Color(0xFF06B6D4),
                () => _showDataManagement(),
              ),
              _buildManagementCard(
                'System Settings',
                'Configure system preferences',
                Icons.settings_rounded,
                const Color(0xFFEC4899),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const AdminSettingsScreen(tab: 'settings')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: SMSTheme.textSecondaryColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Configure',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Status', style: _getCardTitleStyle()),
                  const SizedBox(height: 4),
                  Text('Real-time system health monitoring',
                      style: _getCardSubtitleStyle()),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SMSTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: SMSTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All Systems Operational',
                      style: TextStyle(
                        color: SMSTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildStatusRow(
                'Database Connection',
                'Connected',
                SMSTheme.successColor,
                Icons.check_circle_rounded,
                '99.9% uptime',
              ),
              _buildStatusRow(
                'Authentication Service',
                'Active',
                SMSTheme.successColor,
                Icons.verified_user_rounded,
                'Secure connection',
              ),
              _buildStatusRow(
                'File Storage',
                'Available',
                SMSTheme.successColor,
                Icons.cloud_done_rounded,
                '85% capacity used',
              ),
              _buildStatusRow(
                'Email Service',
                'Operational',
                SMSTheme.successColor,
                Icons.email_rounded,
                'Queue: 0 pending',
              ),
              _buildStatusRow(
                'Last Backup',
                DateFormat('MMM d, yyyy')
                    .format(DateTime.now().subtract(const Duration(hours: 6))),
                const Color(0xFFF59E0B),
                Icons.backup_rounded,
                '6 hours ago',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Performance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        'All services are running optimally. Last maintenance: ${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 7)))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String status,
    Color color,
    IconData icon,
    String? subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // REPORTS TAB - Data Export & Reporting

  Widget _buildReportsTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: _getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reports Header
          _buildAnimatedCard(
            index: 0,
            child: _buildReportsHeader(),
          ),

          const SizedBox(height: 24),

          // Report Categories
          _buildAnimatedCard(
            index: 1,
            child: _buildReportCategories(),
          ),

          const SizedBox(height: 24),

          // Quick Export Options
          _buildAnimatedCard(
            index: 2,
            child: _buildQuickExportOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade600,
            Colors.green.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade600.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: TextStyle(
                    fontSize: _isLargeScreen(context) ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate comprehensive reports and export data for analysis.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Export Ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Multiple Formats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.assessment_rounded,
              size: _isLargeScreen(context) ? 48 : 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategories() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Reports', style: _getCardTitleStyle()),
          const SizedBox(height: 4),
          Text('Choose from various report categories',
              style: _getCardSubtitleStyle()),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildReportCard(
                'Student Enrollment Report',
                'Comprehensive enrollment statistics and trends',
                Icons.school_rounded,
                const Color(0xFF3B82F6),
                () => _generateReport('enrollment'),
                badges: ['Excel', 'PDF', 'CSV'],
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Financial Summary Report',
                'Revenue analysis, payment status, and financial overview',
                Icons.monetization_on_rounded,
                const Color(0xFF10B981),
                () => _generateReport('financial'),
                badges: ['Excel', 'PDF'],
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Grade Level Analysis',
                'Student distribution and performance across grade levels',
                Icons.analytics_rounded,
                const Color(0xFFEF4444),
                () => _generateReport('grade_analysis'),
                badges: ['Excel', 'PDF', 'Chart'],
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Payment Status Report',
                'Outstanding payments and collection analysis',
                Icons.payment_rounded,
                const Color(0xFF8B5CF6),
                () => _generateReport('payments'),
                badges: ['Excel', 'PDF'],
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Teacher Performance Report',
                'Teacher workload and performance metrics',
                Icons.person_rounded,
                const Color(0xFFF59E0B),
                () => _generateReport('teachers'),
                badges: ['Excel', 'PDF'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onGenerate, {
    List<String>? badges,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onGenerate();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: SMSTheme.textSecondaryColor,
                        height: 1.3,
                      ),
                    ),
                    if (badges != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: badges
                            .map((badge) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: SMSTheme.textSecondaryColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickExportOptions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Export', style: _getCardTitleStyle()),
          const SizedBox(height: 4),
          Text('Export current data instantly', style: _getCardSubtitleStyle()),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickExportButton(
                  'Export All Students',
                  Icons.school_rounded,
                  SMSTheme.primaryColor,
                  () => _quickExport('students'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickExportButton(
                  'Export Payments',
                  Icons.payment_rounded,
                  SMSTheme.successColor,
                  () => _quickExport('payments'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  // Helper methods for management and reports
  void _showUserManagement() =>
      _showSuccessSnackBar('User management feature coming soon!');
  // Replace the existing _createBackup() method with this enhanced version
  Future<void> _createBackup() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creating Backup...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we export your data',
                        style: TextStyle(
                          fontSize: 12,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Perform the backup
      final backupData = await _exportFirestoreData();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Save the backup file
      await _saveBackupFile(backupData);

      _showSuccessSnackBar('Database backup completed successfully!');
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Backup error: $e');
      _showErrorSnackBar('Failed to create backup: ${e.toString()}');
    }
  }

  // Add this method after the _createBackup() method
  Future<Map<String, dynamic>> _exportFirestoreData() async {
    final Map<String, dynamic> backupData = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.0.0',
      'schoolName': 'PBTS School Management System',
    };

    try {
      // Get all collection names from your Firestore
      final List<String> collectionNames = [
        'adminSettings',
        'branches',
        'courses',
        'enrolled_students',
        'enrollments',
        'expenses',
        'fees',
        'gradeLevels',
        'payments',
        'settings',
        'strands',
        'student_fees',
        'students',
        'subjects',
        'users',
      ];

      // Backup each collection with subcollections
      for (String collectionName in collectionNames) {
        print('Backing up collection: $collectionName');
        backupData[collectionName] = await _exportCollection(collectionName);
      }

      // Add summary statistics
      backupData['summary'] = {
        'totalCollections': collectionNames.length,
        'exportedCollections': backupData.keys
            .where((key) =>
                key != 'exportDate' &&
                key != 'version' &&
                key != 'schoolName' &&
                key != 'summary')
            .length,
        'totalStudents': (backupData['students'] as List?)?.length ?? 0,
        'totalUsers': (backupData['users'] as List?)?.length ?? 0,
        'totalEnrollments': (backupData['enrollments'] as List?)?.length ?? 0,
        'totalPayments': (backupData['payments'] as List?)?.length ?? 0,
      };

      print('Backup completed successfully');
      return backupData;
    } catch (e) {
      debugPrint('Error exporting Firestore data: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _exportCollection(
      String collectionPath) async {
    try {
      final collectionRef = _firestore.collection(collectionPath);
      final snapshot = await collectionRef.get();

      List<Map<String, dynamic>> documents = [];

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> documentData = {
          'id': doc.id,
          'data': _convertFirestoreData(doc.data() as Map<String, dynamic>),
          'subcollections': <String, List<Map<String, dynamic>>>{},
        };

        // Get subcollections for this document
        final subcollections = await _getSubcollections(doc.reference);
        if (subcollections.isNotEmpty) {
          documentData['subcollections'] = subcollections;
        }

        documents.add(documentData);
      }

      return documents;
    } catch (e) {
      debugPrint('Error exporting collection $collectionPath: $e');
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getSubcollections(
      DocumentReference docRef) async {
    Map<String, List<Map<String, dynamic>>> subcollections = {};

    try {
      // Common subcollection names you might have
      List<String> possibleSubcollections = [
        'feeConfiguration',
        'paymentConfiguration',
        'paymentSchemes',
        'tuitionConfiguration',
        'miscFees',
        'gradeLevels',
        'subjects',
        'enrollments',
        'payments',
        'activities',
        'notifications',
      ];

      for (String subcolName in possibleSubcollections) {
        try {
          final subcolRef = docRef.collection(subcolName);
          final subcolSnapshot = await subcolRef.get();

          if (subcolSnapshot.docs.isNotEmpty) {
            List<Map<String, dynamic>> subcolDocs = [];

            for (QueryDocumentSnapshot subDoc in subcolSnapshot.docs) {
              Map<String, dynamic> subDocumentData = {
                'id': subDoc.id,
                'data': _convertFirestoreData(
                    subDoc.data() as Map<String, dynamic>),
              };

              // Check for nested subcollections (up to 2 levels deep)
              final nestedSubcollections =
                  await _getSubcollections(subDoc.reference);
              if (nestedSubcollections.isNotEmpty) {
                subDocumentData['subcollections'] = nestedSubcollections;
              }

              subcolDocs.add(subDocumentData);
            }

            subcollections[subcolName] = subcolDocs;
            print(
                'Found subcollection: $subcolName with ${subcolDocs.length} documents');
          }
        } catch (e) {
          // Subcollection doesn't exist, continue
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error getting subcollections: $e');
    }

    return subcollections;
  }

// Add this method to properly convert Firestore data types
  Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
    Map<String, dynamic> convertedData = {};

    data.forEach((key, value) {
      if (value is Timestamp) {
        convertedData[key] = {
          '_firestore_type': 'timestamp',
          'value': value.toDate().toIso8601String(),
        };
      } else if (value is GeoPoint) {
        convertedData[key] = {
          '_firestore_type': 'geopoint',
          'latitude': value.latitude,
          'longitude': value.longitude,
        };
      } else if (value is DocumentReference) {
        convertedData[key] = {
          '_firestore_type': 'reference',
          'path': value.path,
        };
      } else if (value is List) {
        convertedData[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertFirestoreData(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        convertedData[key] = _convertFirestoreData(value);
      } else {
        convertedData[key] = value;
      }
    });

    return convertedData;
  }

// Add this method after the _exportFirestoreData() method
  Future<void> _saveBackupFile(Map<String, dynamic> backupData) async {
    try {
      // Convert to pretty JSON
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(backupData);
      final bytes = utf8.encode(jsonString);

      // Generate filename with timestamp
      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'PBTS_Backup_$timestamp.json';

      if (kIsWeb) {
        // For web - use file_picker to save file
        await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup File',
          fileName: fileName,
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        _showInfoDialog(
          'Backup Saved',
          'Backup file saved successfully!\n\nFilename: $fileName',
        );
      } else {
        // For mobile platforms, save to documents directory
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);

        _showInfoDialog(
          'Backup Saved',
          'Backup file saved successfully!\n\nLocation: ${file.path}\nFilename: $fileName',
        );
      }
    } catch (e) {
      debugPrint('Error saving backup file: $e');
      rethrow;
    }
  }

  void _showSystemLogs() =>
      _showSuccessSnackBar('System logs feature coming soon!');
  void _showDataManagement() =>
      _showSuccessSnackBar('Data management feature coming soon!');
  void _generateReport(String reportType) => _showInfoDialog(
        'Generate Report',
        'Generating $reportType report. This may take a few moments.',
        onAction: () =>
            _showSuccessSnackBar('$reportType report generated successfully!'),
        actionText: 'Download',
      );
  void _quickExport(String dataType) =>
      _showSuccessSnackBar('Exporting $dataType data...');

  //<< --- PART 10
// ENHANCED NAVIGATION PANEL

  Widget _buildNavigationPanel(BuildContext context) {
    final user = Provider.of<LocalAuthProvider.AuthProvider>(context).user;
    final userEmail = user?.email ?? 'admin@pbts.edu.ph';
    final userName = user?.displayName ?? 'Admin User';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Enhanced User Profile Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: SMSTheme.primaryColor,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Administrator',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
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
            ),

            // Enhanced Navigation Menu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // Dashboard
                    _buildNavItem(
                      title: 'Dashboard',
                      icon: Icons.dashboard_rounded,
                      isSelected: _selectedNavIndex == 0,
                      onTap: () => _selectNavItem(0, () => _togglePanel()),
                    ),

                    _buildNavDivider('ACADEMICS'),

                    _buildNavItem(
                      title: 'Grade Levels',
                      icon: Icons.grade_rounded,
                      isSelected: _selectedNavIndex == 1,
                      onTap: () => _selectNavItem(
                          1, () => _navigateToSettings('gradeLevels')),
                    ),
                    _buildNavItem(
                      title: 'Subjects',
                      icon: Icons.book_rounded,
                      isSelected: _selectedNavIndex == 2,
                      onTap: () => _selectNavItem(
                          2, () => _navigateToSettings('subjects')),
                    ),
                    _buildNavItem(
                      title: 'Strands',
                      icon: Icons.category_rounded,
                      isSelected: _selectedNavIndex == 3,
                      onTap: () => _selectNavItem(
                          3, () => _navigateToSettings('strands')),
                    ),
                    _buildNavItem(
                      title: 'Courses',
                      icon: Icons.menu_book_rounded,
                      isSelected: _selectedNavIndex == 4,
                      onTap: () => _selectNavItem(
                          4, () => _navigateToSettings('courses')),
                    ),

                    _buildNavDivider('ORGANIZATION'),

                    _buildNavItem(
                      title: 'Students',
                      icon: Icons.school_rounded,
                      isSelected: _selectedNavIndex == 5,
                      onTap: () => _selectNavItem(
                          5, () => _navigateToSettings('students')),
                    ),
                    _buildNavItem(
                      title: 'Teachers',
                      icon: Icons.people_rounded,
                      isSelected: _selectedNavIndex == 6,
                      onTap: () => _selectNavItem(
                          6, () => _navigateToSettings('teachers')),
                    ),
                    _buildNavItem(
                      title: 'Branches',
                      icon: Icons.business_rounded,
                      isSelected: _selectedNavIndex == 7,
                      onTap: () => _selectNavItem(
                          7, () => _navigateToSettings('branches')),
                    ),
                    _buildNavItem(
                      title: 'Rooms',
                      icon: Icons.meeting_room_rounded,
                      isSelected: _selectedNavIndex == 8,
                      onTap: () =>
                          _selectNavItem(8, () => _navigateToSettings('rooms')),
                    ),
                    _buildNavItem(
                      title: 'Enrollment',
                      icon: Icons.how_to_reg_rounded,
                      isSelected: _selectedNavIndex == 9,
                      onTap: () => _selectNavItem(
                          9, () => _navigateToSettings('enrollment')),
                      badge: _pendingEnrollments > 0
                          ? _pendingEnrollments.toString()
                          : null,
                    ),

                    _buildNavDivider('FINANCIAL'),

                    _buildNavItem(
                      title: 'Fee Management',
                      icon: Icons.monetization_on_rounded,
                      isSelected: _selectedNavIndex == 10,
                      onTap: () =>
                          _selectNavItem(10, () => _navigateToFeeManagement()),
                    ),
                    _buildNavItem(
                      title: 'Payment Reports',
                      icon: Icons.payment_rounded,
                      isSelected: _selectedNavIndex == 11,
                      onTap: () =>
                          _selectNavItem(11, () => _tabController.animateTo(3)),
                    ),

                    _buildNavDivider('SYSTEM'),

                    _buildNavItem(
                      title: 'Settings',
                      icon: Icons.settings_rounded,
                      isSelected: _selectedNavIndex == 12,
                      onTap: () => _selectNavItem(
                          12, () => _navigateToSettings('settings')),
                    ),
                    _buildNavItem(
                      title: 'User Management',
                      icon: Icons.admin_panel_settings_rounded,
                      isSelected: _selectedNavIndex == 13,
                      onTap: () =>
                          _selectNavItem(13, () => _showUserManagement()),
                    ),
                    _buildNavItem(
                      title: 'System Logs',
                      icon: Icons.list_alt_rounded,
                      isSelected: _selectedNavIndex == 14,
                      onTap: () => _selectNavItem(14, () => _showSystemLogs()),
                    ),
                    _buildNavItem(
                      title: 'Quick Backup',
                      icon: Icons.backup_rounded,
                      isSelected: _selectedNavIndex == 15,
                      onTap: () => _selectNavItem(15, () => _createBackup()),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SMSTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Version Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'PBTS Admin v2.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? SMSTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? SMSTheme.primaryColor : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color:
                isSelected ? SMSTheme.primaryColor : SMSTheme.textPrimaryColor,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SMSTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: SMSTheme.errorColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: SMSTheme.primaryColor.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        dense: true,
        horizontalTitleGap: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildNavDivider(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.folder_rounded,
              size: 12,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SMSTheme.textSecondaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            height: 1,
            width: 20,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  void _selectNavItem(int index, VoidCallback action) {
    setState(() => _selectedNavIndex = index);
    _togglePanel();
    action();
  }

  void _navigateToSettings(String tab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminSettingsScreen(tab: tab)),
    );
  }

  void _navigateToFeeManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeeManagementScreen()),
    );
  }

  // ENHANCED DIALOG METHODS

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Notifications List
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNotificationItem(
                      icon: Icons.person_add_rounded,
                      title: 'New Enrollment Requests',
                      message:
                          '$_pendingEnrollments pending enrollment requests need review',
                      time: 'Today',
                      isUnread: _pendingEnrollments > 0,
                      color: SMSTheme.errorColor,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToSettings('enrollment');
                      },
                    ),
                    _buildNotificationItem(
                      icon: Icons.payment_rounded,
                      title: 'Payment Update',
                      message:
                          'Monthly revenue has increased by ${_calculateGrowthRate()}%',
                      time: '2 hours ago',
                      isUnread: true,
                      color: SMSTheme.successColor,
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(1);
                      },
                    ),
                    _buildNotificationItem(
                      icon: Icons.event_rounded,
                      title: 'Upcoming Event',
                      message:
                          'Parent-Teacher Conference scheduled for next week',
                      time: 'Yesterday',
                      isUnread: false,
                      color: Colors.blue,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildNotificationItem(
                      icon: Icons.backup_rounded,
                      title: 'System Backup',
                      message: 'Automated backup completed successfully',
                      time: '3 days ago',
                      isUnread: false,
                      color: SMSTheme.primaryColor,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Mark All Read'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SMSTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('View All'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? color.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? color.withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isUnread ? color : SMSTheme.textSecondaryColor,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    final user =
        Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false)
            .user;
    final userEmail = user?.email ?? 'admin@pbts.edu.ph';
    final userName = user?.displayName ?? 'Admin User';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 32,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: SMSTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: SMSTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: SMSTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'System Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: SMSTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Profile Options
              Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.account_circle_rounded,
                    title: 'My Profile',
                    subtitle: 'View and edit profile information',
                    onTap: () {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Profile settings coming soon!');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.settings_rounded,
                    title: 'System Settings',
                    subtitle: 'Configure system preferences',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToSettings('settings');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: SMSTheme.textSecondaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: SMSTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: SMSTheme.textSecondaryColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: SMSTheme.textSecondaryColor,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SMSTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.help_outline_rounded,
                  color: SMSTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            const Text('Help & Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need assistance with the PBTS Admin Dashboard?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
                Icons.email_rounded, 'Email Support', 'support@pbts.edu.ph'),
            _buildHelpItem(
                Icons.phone_rounded, 'Phone Support', '+63 (123) 456-7890'),
            _buildHelpItem(
                Icons.book_rounded, 'Documentation', 'View Admin User Guide',
                isLink: true),
            _buildHelpItem(Icons.video_library_rounded, 'Video Tutorials',
                'Watch training videos',
                isLink: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle,
      {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color:
                  isLink ? SMSTheme.primaryColor : SMSTheme.textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLink
                        ? SMSTheme.primaryColor
                        : SMSTheme.textSecondaryColor,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('About PBTS Admin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PBTS School Management System',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 2.0.0',
              style: TextStyle(
                fontSize: 14,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A comprehensive school management system designed to streamline administrative tasks, manage student records, and provide insightful analytics.',
              style: TextStyle(
                fontSize: 14,
                color: SMSTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built with Flutter • Powered by Firebase\nLast Updated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// END OF ADMIN DASHBOARD ENHANCED CODE
