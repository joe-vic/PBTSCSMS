import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/student_model.dart';
import '../widgets/announcement_card.dart';
import '../widgets/metric_cards.dart';
import '../services/parent_data_service.dart';
import '../student_widgets.dart';

/// 🎯 PURPOSE: Home dashboard tab for parents
/// 📝 WHAT IT SHOWS: Welcome, student summary, announcements, quick actions
/// 🔧 HOW TO USE: HomeTab(tabController: myTabController)
class HomeTab extends StatefulWidget {
  final TabController? tabController;
  
  const HomeTab({
    super.key,
    this.tabController,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 📊 DATA VARIABLES
  final ParentDataService _dataService = ParentDataService();
  List<Map<String, dynamic>> _announcements = [];
  List<StudentModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  /// 📥 Loads all data needed for home tab
  Future<void> _loadHomeData() async {
    try {
      setState(() => _isLoading = true);
      
      // 🔄 Load data in parallel for faster loading
      final results = await Future.wait([
        _dataService.getAnnouncements(),
        _dataService.getStudents(),
      ]);
      
      setState(() {
        _announcements = results[0] as List<Map<String, dynamic>>;
        _students = results[1] as List<StudentModel>;
        _isLoading = false;
      });
    } catch (e) {
      // 🚨 Handle errors gracefully
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: SMSTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      color: SMSTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 WELCOME SECTION
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            
            // 👨‍👩‍👧‍👦 STUDENT SUMMARY
            _buildStudentSummary(),
            const SizedBox(height: 24),
            
            // 📢 ANNOUNCEMENTS SECTION
            _buildAnnouncementsSection(),
            const SizedBox(height: 24),
            
            // ⚡ QUICK ACTIONS
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  /// ⏳ Shows loading spinner
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Dashboard...',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 👋 Builds welcome section with gradient background
  Widget _buildWelcomeSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? 'Parent';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Parent Portal',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hello, $userEmail',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay connected with your child\'s educational journey',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.family_restroom,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// 👨‍👩‍👧‍👦 Builds student summary or empty state
  Widget _buildStudentSummary() {
    if (_students.isEmpty) {
      return _buildEmptyStudentsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Students',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => widget.tabController?.animateTo(1),
              child: Text(
                'View All',
                style: TextStyle(fontFamily: 'Poppins',
                  color: SMSTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 📊 Show student spotlight
        StudentSpotlightSection(students: _students),
      ],
    );
  }

  /// 🫙 Shows empty state when no students
  Widget _buildEmptyStudentsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, SMSTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: SMSTheme.primaryColor.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMSTheme.primaryColor, SMSTheme.primaryColor.withBlue(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SMSTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Students Yet',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your educational journey by\nenrolling your first student',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 📢 Builds announcements section
  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'School Announcements',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('View all announcements'),
                    backgroundColor: SMSTheme.primaryColor,
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(fontFamily: 'Poppins',
                  color: SMSTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 📝 Show first 3 announcements
        ..._announcements.take(3).map((announcement) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnnouncementCard(
            announcement: announcement,
            onTap: () => _showAnnouncementDetails(announcement),
          ),
        )).toList(),
        
        if (_announcements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 32,
                    color: SMSTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No announcements yet',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// ⚡ Builds quick actions grid
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            // 📱 Responsive grid
            int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            double childAspectRatio = constraints.maxWidth > 600 ? 1.1 : 1.3;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children: [
                QuickActionCard(
                  title: 'View Grades',
                  subtitle: 'Check academic performance',
                  icon: Icons.grade,
                  color: SMSTheme.successColor,
                  onTap: () => widget.tabController?.animateTo(4),
                ),
                QuickActionCard(
                  title: 'Pay Fees',
                  subtitle: 'Manage school payments',
                  icon: Icons.payment,
                  color: SMSTheme.warningColor,
                  onTap: () => widget.tabController?.animateTo(2),
                ),
                QuickActionCard(
                  title: 'Attendance',
                  subtitle: 'Track school attendance',
                  icon: Icons.calendar_today,
                  color: SMSTheme.primaryColor,
                  onTap: () => widget.tabController?.animateTo(3),
                ),
                QuickActionCard(
                  title: 'Calendar',
                  subtitle: 'View school events',
                  icon: Icons.event,
                  color: SMSTheme.accentColor,
                  onTap: () => widget.tabController?.animateTo(5),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 📖 Shows announcement details in dialog
  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          announcement['title'] ?? 'Announcement',
          style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement['content'] ?? 'No content available.',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            const SizedBox(height: 12),
            Text(
              'Priority: ${announcement['priority']?.toString().toUpperCase() ?? 'NORMAL'}',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontFamily: 'Poppins',)),
          ),
        ],
      ),
    );
  }
}