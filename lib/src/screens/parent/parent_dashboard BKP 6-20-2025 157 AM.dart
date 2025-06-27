import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'edit_enrollment_screen.dart';
import '../../models/enrollment.dart';
import '../../services/firestore_service.dart';
import '../../config/theme.dart';
import 'enrollment_form_screen.dart';

// ParentDashboard widget serves as the main dashboard for parents
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

// State class for ParentDashboard with tab navigation and data management
class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // List of tabs for navigation
  final List<String> _tabs = [
    'Home',
    'Enrollments',
    'Messaging',
    'Payments',
    'Attendance',
    'Calendar'
  ];
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller and load dashboard data
    _tabController = TabController(length: _tabs.length, vsync: this);
    _notificationCount = 3; // Simulated notification count
    _loadDashboardData();
  }

  @override
  void dispose() {
    // Clean up controllers
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Loads mock dashboard data with a simulated delay
  Future<void> _loadDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    _announcements = [
      {
        'title': 'School Holidays Announced',
        'content':
            'The school will be closed from May 25 to June 2 for mid-term break.',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'priority': 'high',
      },
      {
        'title': 'Parent-Teacher Meeting',
        'content':
            'Parent-Teacher meetings will be held on June 5. Please schedule your appointments.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'priority': 'medium',
      },
      {
        'title': 'Annual School Day',
        'content':
            'The Annual School Day celebrations will be held on June 15. All parents are invited.',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'priority': 'low',
      },
    ];
    setState(() => _isLoading = false);
  }

  // Logs out the user and navigates to the login screen
  Future<void> _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: SMSTheme.accentColor),
    );
  }

  // Builds a quick action button with an icon and label
  Widget _buildQuickActionButton(
      IconData icon, String label, Color backgroundColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 4), // Reduced padding
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24), // Smaller icon
            const SizedBox(height: 6), // Reduced spacing
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 10, // Smaller font
              ),
              maxLines: 1, // Ensure single line
              overflow: TextOverflow.ellipsis, // Add ellipsis if needed
            ),
          ],
        ),
      ),
    );
  }

  // Builds an announcement card with priority-based styling
  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    Color priorityColor;
    switch (announcement['priority']) {
      case 'high':
        priorityColor = SMSTheme.errorColor;
        break;
      case 'medium':
        priorityColor = SMSTheme.accentColor;
        break;
      default:
        priorityColor = SMSTheme.successColor;
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: priorityColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(announcement['title'],
                      style: TextStyle(fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: SMSTheme.textPrimaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(announcement['content'],
                style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor)),
            const SizedBox(height: 8),
            Text(
                'Posted on ${DateFormat('MMMM d, yyyy').format(announcement['date'])}',
                style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: SMSTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  // Builds a notification icon with a badge for unread notifications
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
                  borderRadius: BorderRadius.circular(10)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$_notificationCount',
                  style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  // Handles viewing notifications and clears the notification count
  void _viewNotifications() {
    setState(() => _notificationCount = 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Notifications viewed'),
        backgroundColor: SMSTheme.primaryColor));
  }

  // Returns status color based on enrollment status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return SMSTheme.accentColor;
      case 'approved':
        return SMSTheme.successColor;
      case 'rejected':
        return SMSTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  // Returns payment status color
  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return SMSTheme.successColor;
      case 'unpaid':
        return SMSTheme.errorColor;
      case 'partial':
        return SMSTheme.accentColor;
      default:
        return Colors.grey;
    }
  }

  // Converts a string to proper case
  String _toProperCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  // Formats full name from student info map
  String _formatFullName(Map<String, dynamic> info) {
    // Add debugging to see what data we're receiving
    print('DEBUG - Student info received: $info');

    final lastName = (info['lastName'] as String? ?? '').trim();
    final firstName = (info['firstName'] as String? ?? '').trim();
    final middleName = (info['middleName'] as String? ?? '').trim();

    print(
        'DEBUG - Parsed names: lastName="$lastName", firstName="$firstName", middleName="$middleName"');

    // Check if we have any names at all
    if (lastName.isEmpty && firstName.isEmpty) {
      print('WARNING - Both first and last names are empty');
      return 'Name not available';
    }

    // Build the full name
    String fullName = '';
    if (lastName.isNotEmpty) {
      fullName = lastName;
      if (firstName.isNotEmpty) {
        fullName += ', $firstName';
        if (middleName.isNotEmpty) {
          fullName += ' $middleName';
        }
      }
    } else if (firstName.isNotEmpty) {
      // Only first name available
      fullName = firstName;
      if (middleName.isNotEmpty) {
        fullName += ' $middleName';
      }
    }

    print('DEBUG - Final formatted name: "$fullName"');
    return fullName.trim();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final parentId = authProvider.user?.uid;

    // Check if user is logged in
    if (parentId == null) {
      return const Center(child: Text('Please log in to view this page'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard',
            style: TextStyle(fontFamily: 'Poppins',
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: SMSTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
              icon: _buildNotificationIcon(), onPressed: _viewNotifications),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 40, color: SMSTheme.primaryColor)),
                  const SizedBox(height: 12),
                  Text('Parent Menu',
                      style: TextStyle(fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                        'Welcome, ${authProvider.user?.email ?? 'Parent'}',
                        style: TextStyle(fontFamily: 'Poppins',
                            color: Colors.white70, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: SMSTheme.primaryColor),
              title: Text('Dashboard', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.school, color: SMSTheme.primaryColor),
              title: Text('Enrollments', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: SMSTheme.primaryColor),
              title: Text('Enroll a Student', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EnrollmentFormScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Logout', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: SMSTheme.primaryColor, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
              isScrollable: true,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Home Tab
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: SMSTheme.primaryColor))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      SMSTheme.primaryColor,
                                      SMSTheme.accentColor
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: SMSTheme.primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome, Parent!',
                                      style: TextStyle(fontFamily: 'Poppins',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Track progress and stay updated with activities.',
                                      style: TextStyle(fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9)),
                                      maxLines: 2),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    EnrollmentFormScreen())),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor:
                                                SMSTheme.primaryColor,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8)),
                                        child: Text('New Enrollment',
                                            style: TextStyle(fontFamily: 'Poppins',
                                                fontSize: 12)),
                                      ),
                                      TextButton.icon(
                                        onPressed: _viewNotifications,
                                        icon: const Icon(
                                            Icons.notifications_outlined,
                                            size: 18),
                                        label: Text('$_notificationCount',
                                            style: TextStyle(fontFamily: 'Poppins',
                                                fontSize: 12)),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Quick Actions Section
                            Text('Quick Actions',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: SMSTheme.textPrimaryColor)),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8, // Reduced spacing
                              crossAxisSpacing: 8, // Reduced spacing
                              childAspectRatio:
                                  0.9, // Control width/height ratio
                              children: [
                                _buildQuickActionButton(
                                    Icons.payment,
                                    'Pay Fees',
                                    SMSTheme.primaryColor,
                                    () => _tabController.animateTo(3)),
                                _buildQuickActionButton(Icons.event_note,
                                    'Exams', SMSTheme.secondaryColor, () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Exam schedule feature coming soon'),
                                          backgroundColor:
                                              SMSTheme.primaryColor));
                                }),
                                _buildQuickActionButton(Icons.assignment,
                                    'Homework', SMSTheme.accentColor, () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Homework tracker feature coming soon'),
                                          backgroundColor:
                                              SMSTheme.primaryColor));
                                }),
                                _buildQuickActionButton(
                                    Icons.message,
                                    'Message',
                                    SMSTheme.primaryColor.withBlue(150),
                                    () => _tabController.animateTo(2)),
                              ],
                            ),

                            const SizedBox(height: 24),
                            // Announcements Section
                            Text('Announcements',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: SMSTheme.textPrimaryColor)),
                            const SizedBox(height: 12),
                            ..._announcements
                                .map((announcement) =>
                                    _buildAnnouncementCard(announcement))
                                .toList(),
                            const SizedBox(height: 24),
                            // Student Summary Section
                            Text('Student Summary',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: SMSTheme.textPrimaryColor)),
                            const SizedBox(height: 12),

                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('enrollments')
                                  .where('parentId', isEqualTo: parentId)
                                  .orderBy('createdAt',
                                      descending: true) // Add ordering
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  print(
                                      'ERROR in enrollments stream: ${snapshot.error}');
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Icon(Icons.person_off,
                                              size: 48,
                                              color: SMSTheme.primaryColor
                                                  .withOpacity(0.5)),
                                          const SizedBox(height: 16),
                                          Text('No students enrolled yet',
                                              style: TextStyle(fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  color: SMSTheme
                                                      .textSecondaryColor)),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        EnrollmentFormScreen())),
                                            child: Text('Enroll a Student',
                                                style: TextStyle(fontFamily: 'Poppins',)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final enrollments = snapshot.data!.docs
                                    .map((doc) {
                                      try {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        print(
                                            'DEBUG - Raw enrollment document: ${doc.id} = $data');

                                        final enrollment =
                                            Enrollment.fromMap(data);
                                        print(
                                            'DEBUG - Parsed enrollment: ${enrollment.enrollmentId}, studentInfo: ${enrollment.studentInfo}');

                                        return enrollment;
                                      } catch (e) {
                                        print(
                                            'ERROR parsing enrollment ${doc.id}: $e');
                                        print('Document data: ${doc.data()}');
                                        return null;
                                      }
                                    })
                                    .whereType<Enrollment>()
                                    .toList();

                                if (enrollments.isEmpty) {
                                  return Center(
                                      child: Text('No valid enrollments found',
                                          style: TextStyle(fontFamily: 'Poppins',)));
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: enrollments.length,
                                  itemBuilder: (context, index) {
                                    final enrollment = enrollments[index];
                                    final studentName =
                                        _formatFullName(enrollment.studentInfo);

                                    // Additional debug info for each enrollment
                                    print(
                                        'DEBUG - Enrollment ${index}: ID=${enrollment.enrollmentId}, Name="$studentName"');

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                            backgroundColor: SMSTheme
                                                .primaryColor
                                                .withOpacity(0.2),
                                            child: Icon(Icons.person,
                                                color: SMSTheme.primaryColor)),
                                        title: Text(studentName,
                                            style: TextStyle(fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    SMSTheme.textPrimaryColor)),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${enrollment.studentInfo['gradeLevel'] ?? 'N/A'} • ${_toProperCase(enrollment.status)}',
                                                style: TextStyle(fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    color: SMSTheme
                                                        .textSecondaryColor)),
                                            // Add enrollment ID for debugging
                                            Text(
                                                'ID: ${enrollment.enrollmentId}',
                                                style: TextStyle(fontFamily: 'Poppins',
                                                    fontSize: 10,
                                                    color:
                                                        Colors.grey.shade500)),
                                          ],
                                        ),
                                        trailing: Chip(
                                          label: Text(
                                              _toProperCase(
                                                  enrollment.paymentStatus),
                                              style: TextStyle(fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  color: Colors.white)),
                                          backgroundColor:
                                              _getPaymentStatusColor(
                                                  enrollment.paymentStatus),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 0),
                                        ),
                                        onTap: () =>
                                            _tabController.animateTo(1),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                // Placeholder tabs (to be implemented)
                Container(
                    color: Colors.grey[100],
                    child: const SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: []))),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: [])),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [])),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [])),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [])),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => EnrollmentFormScreen())),
        backgroundColor: SMSTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Enroll a Student',
      ),
    );
  }
}
