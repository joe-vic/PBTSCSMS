import 'dart:async';
import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import 'class_management_screen.dart';
import 'package:intl/intl.dart';

// Design Constants
const double kSpacing = 24.0;
const double kRadius = 12.0;
const double kIconSize = 24.0;

// Semantic Labels
const String kDashboardSemanticLabel = 'Teacher Dashboard';
const String kClassesSemanticLabel = 'Class Management';
const String kScheduleSemanticLabel = 'Schedule';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  _TeacherDashboardScreenState createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final ClassService _classService = ClassService();
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<ClassModel>? _cachedClasses;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Theme getters
  ThemeData get theme => Theme.of(context);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Responsive breakpoints
  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  bool get isDesktop => MediaQuery.of(context).size.width >= 1200;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.user?.uid ?? '';

      if (teacherId.isEmpty) {
        throw Exception('Teacher ID not found');
      }

      await _classService
          .getTeacherClasses(teacherId)
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to load classes'),
          )
          .then((classes) {
        if (mounted) {
          setState(() {
            _cachedClasses = classes;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      _errorMessage = null;
    });
    await _initializeData();
  }

  Future<void> _archiveClass(ClassModel classModel) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Archive Class',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to archive this class?',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens when you archive a class:',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildArchiveInfoItem(
                    'The class will be moved to the archived section',
                    Icons.archive,
                  ),
                  _buildArchiveInfoItem(
                    'All student records and data will be preserved',
                    Icons.save,
                  ),
                  _buildArchiveInfoItem(
                    'You can restore the class at any time',
                    Icons.restore,
                  ),
                  _buildArchiveInfoItem(
                    'Students will no longer see this class in their dashboard',
                    Icons.visibility_off,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
            ),
            child: Text(
              'Archive',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
          ),
        ],
      ),
    );

    if (shouldArchive == true) {
      try {
        await _classService.archiveClass(classModel.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Class archived successfully',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
              backgroundColor: Colors.green,
            ),
          );
          await _initializeData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to archive class: ${e.toString()}',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildArchiveInfoItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherId = authProvider.user?.uid ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Text(
          'Teacher Dashboard',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        elevation: 0,
        actions: [
          if (_isLoading)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _retryLoading,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text(
              authProvider.user?.displayName?.substring(0, 1).toUpperCase() ??
                  'T',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: !isDesktop ? _buildDrawer(authProvider) : null,
      body: Row(
        children: [
          if (isDesktop) _buildDrawer(authProvider),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: _buildBody(teacherId),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassManagementScreen(
                      mode: ClassManagementMode.create,
                    ),
                  ),
                );
              },
              backgroundColor: SMSTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: Text(
                'Create Class',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: SMSTheme.primaryColor,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  authProvider.user?.displayName
                          ?.substring(0, 1)
                          .toUpperCase() ??
                      'T',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: SMSTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              accountName: Text(
                authProvider.user?.displayName ?? 'Teacher',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              accountEmail: Text(
                authProvider.user?.email ?? '',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.class_,
                    title: 'Classes',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_today,
                    title: 'Schedule',
                    index: 2,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Logout',
                      style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Confirm Logout',
                            style: TextStyle(fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600),
                          ),
                          content: Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(fontFamily: 'Poppins',),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontFamily: 'Poppins',),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                'Logout',
                                style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await authProvider.signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? SMSTheme.primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'Poppins',
          color: isSelected ? SMSTheme.primaryColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: SMSTheme.primaryColor.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (!MediaQuery.of(context).size.width.isFinite) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildBody(String teacherId) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryLoading,
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(teacherId);
      case 1:
        return _buildClassesContent(teacherId);
      case 2:
        return _buildScheduleContent();
      default:
        return _buildDashboardContent(teacherId);
    }
  }

  Widget _buildDashboardContent(String teacherId) {
    if (_cachedClasses == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeClasses = _cachedClasses!.where((c) => !c.isArchived).toList();

    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildStatsCards(activeClasses),
            const SizedBox(height: 24),
            _buildRecentClasses(activeClasses),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    String greeting;
    if (now.hour < 12) {
      greeting = 'Good morning';
    } else if (now.hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      child: Container(
        padding: const EdgeInsets.all(kSpacing),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'user_avatar',
                  child: CircleAvatar(
                    backgroundColor: colorScheme.onPrimary.withOpacity(0.24),
                    radius: 28,
                    child: Text(
                      Provider.of<AuthProvider>(context)
                              .user
                              ?.displayName
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'T',
                      style: TextStyle(fontFamily: 'Poppins',
                        color: colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
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
                        greeting,
                        style: TextStyle(fontFamily: 'Poppins',
                          color: colorScheme.onPrimary.withOpacity(0.87),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Provider.of<AuthProvider>(context).user?.displayName ??
                            'Teacher',
                        style: TextStyle(fontFamily: 'Poppins',
                          color: colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(fontFamily: 'Poppins',
                    color: colorScheme.onPrimary.withOpacity(0.87),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(kRadius / 2),
                  ),
                  child: Text(
                    DateFormat('h:mm a').format(DateTime.now()),
                    style: TextStyle(fontFamily: 'Poppins',
                      color: colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<ClassModel> classes) {
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
    final stats = [
      _StatsData(
        title: 'Total Classes',
        value: classes.length.toString(),
        icon: Icons.class_,
        color: colorScheme.primary,
        description: 'Active classes you are teaching',
      ),
      _StatsData(
        title: 'Total Students',
        value: classes
            .fold(0, (sum, cls) => sum + cls.studentIds.length)
            .toString(),
        icon: Icons.people,
        color: colorScheme.secondary,
        description: 'Students enrolled in your classes',
      ),
      _StatsData(
        title: 'Homeroom Classes',
        value: classes.where((cls) => cls.isHomeroom).length.toString(),
        icon: Icons.home,
        color: colorScheme.tertiary,
        description: 'Classes where you are the homeroom teacher',
      ),
      _StatsData(
        title: 'Subject Classes',
        value: classes.where((cls) => !cls.isHomeroom).length.toString(),
        icon: Icons.book,
        color: Color(0xFF9C27B0), // Purple
        description: 'Subject-specific classes you teach',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * kSpacing) /
                crossAxisCount;
        final aspectRatio = cardWidth / 140; // Fixed height of 140

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: kSpacing,
            mainAxisSpacing: kSpacing,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index]),
        );
      },
    );
  }

  Widget _buildStatCard(_StatsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Icon(
                  data.icon,
                  size: kIconSize,
                  color: data.color,
                  semanticLabel: '${data.title} icon',
                ),
              ),
              Tooltip(
                message: data.description,
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: data.color,
            ),
          ),
          Text(
            data.title,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentClasses(List<ClassModel> classes) {
    final recentClasses = classes.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Classes',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Switch to Classes tab
                });
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: SMSTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: SMSTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentClasses.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No classes yet',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassManagementScreen(
                          mode: ClassManagementMode.create,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SMSTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Create Your First Class',
                    style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentClasses.length,
            itemBuilder: (context, index) {
              final cls = recentClasses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassManagementScreen(
                          mode: ClassManagementMode.view,
                          classModel: cls,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cls.isHomeroom
                                ? Colors.orange.shade100
                                : Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cls.isHomeroom ? Icons.home : Icons.book,
                            color: cls.isHomeroom
                                ? Colors.orange.shade700
                                : Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cls.name,
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Grade ${cls.gradeLevel} - Section ${cls.section}',
                                style: TextStyle(fontFamily: 'Poppins',
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cls.studentIds.length} students',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) async {
                            switch (value) {
                              case 'view':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClassManagementScreen(
                                      mode: ClassManagementMode.view,
                                      classModel: cls,
                                    ),
                                  ),
                                );
                                break;
                              case 'edit':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClassManagementScreen(
                                      mode: ClassManagementMode.edit,
                                      classModel: cls,
                                    ),
                                  ),
                                );
                                break;
                              case 'archive':
                                await _archiveClass(cls);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View Details',
                                    style: TextStyle(fontFamily: 'Poppins',),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit Class',
                                    style: TextStyle(fontFamily: 'Poppins',),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  const Icon(Icons.archive),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Archive Class',
                                    style: TextStyle(fontFamily: 'Poppins',),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildClassesContent(String teacherId) {
    if (_cachedClasses == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeClasses = _cachedClasses!.where((c) => !c.isArchived).toList();
    final archivedClasses = _cachedClasses!.where((c) => c.isArchived).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Class Management',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassManagementScreen(
                                mode: ClassManagementMode.create,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Create Class',
                          style: TextStyle(fontFamily: 'Poppins',),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SMSTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.class_),
                          const SizedBox(width: 8),
                          Text(
                            'Active Classes (${activeClasses.length})',
                            style: TextStyle(fontFamily: 'Poppins',),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.archive),
                          const SizedBox(width: 8),
                          Text(
                            'Archived (${archivedClasses.length})',
                            style: TextStyle(fontFamily: 'Poppins',),
                          ),
                        ],
                      ),
                    ),
                  ],
                  labelColor: SMSTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: SMSTheme.primaryColor,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildClassList(activeClasses, false),
                _buildClassList(archivedClasses, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(List<ClassModel> classes, bool isArchived) {
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.class_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: kSpacing),
            Text(
              isArchived ? 'No archived classes' : 'No active classes',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArchived
                  ? 'Archived classes will appear here'
                  : 'Create a new class to get started',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isArchived) ...[
              const SizedBox(height: kSpacing),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassManagementScreen(
                        mode: ClassManagementMode.create,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(
                  'Create Class',
                  style: TextStyle(fontFamily: 'Poppins',),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeData,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(kSpacing),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: kSpacing),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassManagementScreen(
                      mode: ClassManagementMode.view,
                      classModel: cls,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(kRadius),
              child: Padding(
                padding: const EdgeInsets.all(kSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildClassTypeIcon(cls),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cls.name,
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Grade ${cls.gradeLevel} - Section ${cls.section}',
                                style: TextStyle(fontFamily: 'Poppins',
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildClassActions(cls, isArchived),
                      ],
                    ),
                    const SizedBox(height: kSpacing),
                    const Divider(height: 1),
                    const SizedBox(height: kSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildClassStat(
                          'Students',
                          cls.studentIds.length.toString(),
                          Icons.people,
                        ),
                        _buildClassStat(
                          'Type',
                          cls.isHomeroom ? 'Homeroom' : 'Subject',
                          cls.isHomeroom ? Icons.home : Icons.book,
                        ),
                        if (isArchived)
                          _buildClassStat(
                            'Archived',
                            cls.archivedAt != null
                                ? DateFormat('MMM d, y').format(cls.archivedAt!)
                                : 'Unknown',
                            Icons.calendar_today,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassTypeIcon(ClassModel cls) {
    final color = cls.isHomeroom ? colorScheme.tertiary : colorScheme.secondary;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Icon(
        cls.isHomeroom ? Icons.home : Icons.book,
        color: color,
        size: kIconSize,
        semanticLabel: cls.isHomeroom ? 'Homeroom class' : 'Subject class',
      ),
    );
  }

  Widget _buildClassActions(ClassModel cls, bool isArchived) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      tooltip: 'More options',
      onSelected: (value) async {
        switch (value) {
          case 'view':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassManagementScreen(
                  mode: ClassManagementMode.view,
                  classModel: cls,
                ),
              ),
            );
            break;
          case 'edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassManagementScreen(
                  mode: ClassManagementMode.edit,
                  classModel: cls,
                ),
              ),
            );
            break;
          case 'archive':
            if (isArchived) {
              await _restoreClass(cls);
            } else {
              await _archiveClass(cls);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: _buildPopupMenuItem(
            icon: Icons.visibility,
            text: 'View Details',
          ),
        ),
        if (!isArchived)
          PopupMenuItem(
            value: 'edit',
            child: _buildPopupMenuItem(
              icon: Icons.edit,
              text: 'Edit Class',
            ),
          ),
        PopupMenuItem(
          value: 'archive',
          child: _buildPopupMenuItem(
            icon: isArchived ? Icons.unarchive : Icons.archive,
            text: isArchived ? 'Restore Class' : 'Archive Class',
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenuItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: kIconSize,
          color: colorScheme.onSurface.withOpacity(0.87),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(fontFamily: 'Poppins',
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
      ],
    );
  }

  Future<void> _restoreClass(ClassModel cls) async {
    try {
      await _classService.restoreClass(cls.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Class restored successfully',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _initializeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to restore class: ${e.toString()}',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildClassStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleContent() {
    return Container(
      padding: const EdgeInsets.all(kSpacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(kSpacing),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: kSpacing),
                Text(
                  'Schedule Management Coming Soon',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'re working on bringing you a better way to manage your class schedules.',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeaturePreview(
                      icon: Icons.calendar_month,
                      title: 'Calendar View',
                      description: 'Visual weekly and monthly schedule views',
                    ),
                    const SizedBox(width: kSpacing),
                    _buildFeaturePreview(
                      icon: Icons.schedule,
                      title: 'Time Management',
                      description:
                          'Easy class scheduling and conflict detection',
                    ),
                    const SizedBox(width: kSpacing),
                    _buildFeaturePreview(
                      icon: Icons.notifications_active,
                      title: 'Reminders',
                      description:
                          'Automated notifications for classes and events',
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

  Widget _buildFeaturePreview({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String description;

  const _StatsData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.description,
  });
}
