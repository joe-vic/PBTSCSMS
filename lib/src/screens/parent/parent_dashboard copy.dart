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

// Enhanced ParentDashboard with comprehensive student management features
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Home',
    'Students',
    'Payments',
    'Attendance',
    'Reports',
    'Calendar'
  ];
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _notificationCount = 3;
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Enhanced data loading with student performance data
  Future<void> _loadDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock announcements
    _announcements = [
      {
        'title': 'School Holidays Announced',
        'content': 'The school will be closed from May 25 to June 2 for mid-term break.',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'priority': 'high',
      },
      {
        'title': 'Parent-Teacher Meeting',
        'content': 'Parent-Teacher meetings will be held on June 5. Please schedule your appointments.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'priority': 'medium',
      },
      {
        'title': 'Annual School Day',
        'content': 'The Annual School Day celebrations will be held on June 15. All parents are invited.',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'priority': 'low',
      },
    ];

    // Mock student data with comprehensive information
    _students = [
      {
        'id': 'STU001',
        'name': 'John Smith',
        'grade': 'Grade 10',
        'class': '10-A',
        'profileImage': null,
        'attendance': {
          'percentage': 95.5,
          'daysPresent': 172,
          'totalDays': 180,
          'lastAttendance': DateTime.now().subtract(const Duration(days: 1)),
        },
        'academics': {
          'gpa': 3.8,
          'lastExamScore': 88.5,
          'lastQuizScore': 92.0,
          'rank': 5,
          'totalStudents': 45,
        },
        'fees': {
          'totalDue': 15000.0,
          'paid': 12000.0,
          'pending': 3000.0,
          'nextDueDate': DateTime.now().add(const Duration(days: 15)),
        },
        'behavior': {
          'rating': 'Excellent',
          'disciplinaryActions': 0,
          'teacherComments': 'Very well-behaved and participative student.',
        },
        'recentActivities': [
          'Scored 95% in Mathematics Test',
          'Participated in Science Fair',
          'Absent on May 15, 2024',
        ],
      },
      {
        'id': 'STU002',
        'name': 'Emma Johnson',
        'grade': 'Grade 8',
        'class': '8-B',
        'profileImage': null,
        'attendance': {
          'percentage': 89.2,
          'daysPresent': 160,
          'totalDays': 180,
          'lastAttendance': DateTime.now(),
        },
        'academics': {
          'gpa': 3.6,
          'lastExamScore': 82.3,
          'lastQuizScore': 87.5,
          'rank': 8,
          'totalStudents': 42,
        },
        'fees': {
          'totalDue': 12000.0,
          'paid': 12000.0,
          'pending': 0.0,
          'nextDueDate': DateTime.now().add(const Duration(days: 30)),
        },
        'behavior': {
          'rating': 'Good',
          'disciplinaryActions': 1,
          'teacherComments': 'Shows improvement in class participation.',
        },
        'recentActivities': [
          'Won 2nd place in Art Competition',
          'Completed all assignments this week',
          'Late arrival on May 12, 2024',
        ],
      },
    ];

    setState(() => _isLoading = false);
  }

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
          backgroundColor: SMSTheme.successColor),
    );
  }

  // Enhanced quick action button with better styling
  Widget _buildQuickActionButton(
      IconData icon, String label, Color backgroundColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced student card with comprehensive information
  Widget _buildStudentCard(Map<String, dynamic> student) {
    final attendance = student['attendance'] as Map<String, dynamic>;
    final academics = student['academics'] as Map<String, dynamic>;
    final fees = student['fees'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, SMSTheme.primaryColor.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: SMSTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      student['name'].toString().split(' ').map((n) => n[0]).take(2).join(),
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'],
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${student['grade']} • ${student['class']}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          'Student ID: ${student['id']}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getGPAColor(academics['gpa']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getGPAColor(academics['gpa'])),
                    ),
                    child: Text(
                      'GPA ${academics['gpa']}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getGPAColor(academics['gpa']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Performance Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Attendance',
                      '${attendance['percentage'].toStringAsFixed(1)}%',
                      Icons.calendar_today,
                      _getAttendanceColor(attendance['percentage']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Last Exam',
                      '${academics['lastExamScore']}%',
                      Icons.quiz,
                      _getScoreColor(academics['lastExamScore']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Fees Due',
                      '₹${fees['pending'].toInt()}',
                      Icons.payment,
                      fees['pending'] > 0 ? SMSTheme.errorColor : SMSTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton('View Details', Icons.visibility, () {
                    _showStudentDetails(student);
                  }),
                  _buildActionButton('Attendance', Icons.calendar_today, () {
                    _tabController.animateTo(3);
                  }),
                  _buildActionButton('Pay Fees', Icons.payment, () {
                    _tabController.animateTo(2);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 10,
              color: SMSTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: SMSTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: SMSTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: SMSTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Student details modal
  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student['name']} - Detailed Report',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailSection('Academic Performance', [
                      'GPA: ${student['academics']['gpa']}',
                      'Class Rank: ${student['academics']['rank']}/${student['academics']['totalStudents']}',
                      'Last Exam Score: ${student['academics']['lastExamScore']}%',
                      'Last Quiz Score: ${student['academics']['lastQuizScore']}%',
                    ]),
                    _buildDetailSection('Attendance Record', [
                      'Overall Attendance: ${student['attendance']['percentage']}%',
                      'Days Present: ${student['attendance']['daysPresent']}/${student['attendance']['totalDays']}',
                      'Last Attended: ${DateFormat('MMM dd, yyyy').format(student['attendance']['lastAttendance'])}',
                    ]),
                    _buildDetailSection('Fee Information', [
                      'Total Due: ₹${student['fees']['totalDue']}',
                      'Amount Paid: ₹${student['fees']['paid']}',
                      'Pending: ₹${student['fees']['pending']}',
                      'Next Due Date: ${DateFormat('MMM dd, yyyy').format(student['fees']['nextDueDate'])}',
                    ]),
                    _buildDetailSection('Behavior & Discipline', [
                      'Overall Rating: ${student['behavior']['rating']}',
                      'Disciplinary Actions: ${student['behavior']['disciplinaryActions']}',
                      'Teacher Comments: ${student['behavior']['teacherComments']}',
                    ]),
                    _buildDetailSection('Recent Activities', 
                      (student['recentActivities'] as List).cast<String>()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: SMSTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SMSTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SMSTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Color helper methods
  Color _getGPAColor(double gpa) {
    if (gpa >= 3.5) return SMSTheme.successColor;
    if (gpa >= 3.0) return SMSTheme.secondaryColor;
    return SMSTheme.errorColor;
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return SMSTheme.successColor;
    if (percentage >= 75) return SMSTheme.secondaryColor;
    return SMSTheme.errorColor;
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return SMSTheme.successColor;
    if (score >= 70) return SMSTheme.secondaryColor;
    return SMSTheme.errorColor;
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    Color priorityColor;
    switch (announcement['priority']) {
      case 'high':
        priorityColor = SMSTheme.errorColor;
        break;
      case 'medium':
        priorityColor = SMSTheme.secondaryColor;
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
                    color: priorityColor,
                    shape: BoxShape.circle
                  )
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement['title'],
                    style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: SMSTheme.textPrimaryColor
                    )
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement['content'],
              style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor)
            ),
            const SizedBox(height: 8),
            Text(
              'Posted on ${DateFormat('MMMM d, yyyy').format(announcement['date'])}',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: SMSTheme.textSecondaryColor
              )
            ),
          ],
        ),
      ),
    );
  }

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
                borderRadius: BorderRadius.circular(10)
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_notificationCount',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center
              ),
            ),
          ),
      ],
    );
  }

  void _viewNotifications() {
    setState(() => _notificationCount = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications viewed'),
        backgroundColor: SMSTheme.primaryColor
      )
    );
  }

  // Enhanced responsive summary stats for mobile
 // Advanced Student Cards with Flip Animation, Mood Rings & Gamification
 
 // Mobile-optimized main summary stats with better spacing
Widget _buildSummaryStats() {
  if (_students.isEmpty) {
    return _buildEmptyState();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Mobile-optimized Header
      _buildAnimatedHeader(),
      const SizedBox(height: 12), // Reduced spacing for mobile
      
      // Advanced Student Cards with better mobile support
      _buildAdvancedStudentGrid(),
    ],
  );
}

// Animated header
Widget _buildAnimatedHeader() {
  return TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 800),
    tween: Tween(begin: 0.0, end: 1.0),
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  SMSTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SMSTheme.primaryColor.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: SMSTheme.primaryColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Theme-aligned Icon with Glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SMSTheme.primaryColor, SMSTheme.primaryColor.withBlue(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: SMSTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Spotlight',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_students.length} ${_students.length == 1 ? 'student' : 'students'} • Tap to flip cards',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 12,
                          color: SMSTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Family GPA Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SMSTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SMSTheme.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: SMSTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_calculateFamilyGPA().toStringAsFixed(1)} GPA',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SMSTheme.successColor,
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
    },
  );
}

// Mobile-optimized student grid with better overflow handling
Widget _buildAdvancedStudentGrid() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // More responsive grid calculation
      int crossAxisCount;
      double childAspectRatio;
      
      if (constraints.maxWidth > 800) {
        crossAxisCount = 3;
        childAspectRatio = 0.8;
      } else if (constraints.maxWidth > 600) {
        crossAxisCount = 2;
        childAspectRatio = 0.85;
      } else {
        crossAxisCount = constraints.maxWidth > 400 ? 2 : 1; // Single column for very small screens
        childAspectRatio = constraints.maxWidth > 400 ? 0.9 : 1.1; // Better ratio for single column
      }
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: constraints.maxWidth > 600 ? 16 : 12,
          mainAxisSpacing: constraints.maxWidth > 600 ? 16 : 12,
        ),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          return _buildFlipCard(_students[index], index);
        },
      );
    },
  );
}
// Flip card with front and back
Widget _buildFlipCard(Map<String, dynamic> student, int index) {
  return StatefulBuilder(
    builder: (context, setState) {
      bool isFlipped = false;
      
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 600 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isFlipped = !isFlipped;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  transformAlignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(isFlipped ? 3.14159 : 0),
                  child: isFlipped ? _buildCardBack(student) : _buildCardFront(student),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildCardFront(Map<String, dynamic> student) {
  final academics = student['academics'] as Map<String, dynamic>;
  final attendance = student['attendance'] as Map<String, dynamic>;
  
  return LayoutBuilder(
    builder: (context, constraints) {
      // Adjust padding and font sizes based on available space
      double cardPadding = constraints.maxWidth > 200 ? 12 : 8;
      double titleFontSize = constraints.maxWidth > 200 ? 14 : 12;
      double subtitleFontSize = constraints.maxWidth > 200 ? 9 : 8;
      
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              SMSTheme.cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SMSTheme.primaryColor.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: SMSTheme.primaryColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Student Photo with flexible sizing
              _buildMobileOptimizedPhoto(student, academics['gpa']),
              SizedBox(height: cardPadding * 0.7),
              
              // Student Name with proper overflow handling
              Flexible(
                child: Text(
                  student['name'],
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.textPrimaryColor,
                  ),
                  maxLines: 2, // Allow 2 lines for longer names
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: cardPadding * 0.25),
              
              // Grade badge with flexible width
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 200 ? 6 : 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SMSTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SMSTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    student['grade'],
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: SMSTheme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: cardPadding * 0.7),
              
              // Level Progress with flexible layout
              Flexible(
                child: _buildUltraCompactLevelProgress(academics['gpa']),
              ),
              SizedBox(height: cardPadding * 0.7),
              
              // Achievement Showcase with fixed height to prevent overflow
              SizedBox(
                height: constraints.maxWidth > 200 ? 35 : 30,
                child: _buildMiniAchievementShowcase(student),
              ),
              SizedBox(height: cardPadding * 0.5),
              
              // Flip hint with responsive sizing
              if (constraints.maxWidth > 150) // Only show on larger cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flip,
                      size: constraints.maxWidth > 200 ? 10 : 8,
                      color: SMSTheme.textSecondaryColor,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Tap to flip',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: constraints.maxWidth > 200 ? 8 : 7,
                        color: SMSTheme.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}

// 3. Fixed back card with better space management
Widget _buildCardBack(Map<String, dynamic> student) {
  final attendance = student['attendance'] as Map<String, dynamic>;
  final academics = student['academics'] as Map<String, dynamic>;
  final fees = student['fees'] as Map<String, dynamic>;
  
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()..rotateY(3.14159),
    child: LayoutBuilder(
      builder: (context, constraints) {
        double cardPadding = constraints.maxWidth > 200 ? 12 : 8;
        double fontSize = constraints.maxWidth > 200 ? 10 : 9;
        double titleFontSize = constraints.maxWidth > 200 ? 12 : 10;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SMSTheme.primaryColor.withOpacity(0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SMSTheme.primaryColor.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: SMSTheme.primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with flexible layout
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: SMSTheme.primaryColor,
                      size: constraints.maxWidth > 200 ? 16 : 14,
                    ),
                    SizedBox(width: 6),
                    Expanded( // Prevent overflow
                      child: Text(
                        'Performance',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cardPadding * 0.8),
                
                // Stats with proper spacing
                Flexible(
                  child: Column(
                    children: [
                      _buildCompactStatItem('🎯 GPA', '${academics['gpa']}', _getGPAColor(academics['gpa'])),
                      SizedBox(height: cardPadding * 0.6),
                      _buildCompactStatItem('📅 Attendance', '${attendance['percentage'].toStringAsFixed(1)}%', _getAttendanceColor(attendance['percentage'])),
                      SizedBox(height: cardPadding * 0.6),
                      _buildCompactStatItem('📝 Last Exam', '${academics['lastExamScore']}%', _getScoreColor(academics['lastExamScore'])),
                      SizedBox(height: cardPadding * 0.6),
                      _buildCompactStatItem('💳 Fees', fees['pending'] > 0 ? '₱${fees['pending'].toStringAsFixed(0)} pending' : 'All Paid', fees['pending'] > 0 ? SMSTheme.errorColor : SMSTheme.successColor),
                    ],
                  ),
                ),
                SizedBox(height: cardPadding * 0.8),
                
                // Recent Activity with constrained height
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(cardPadding * 0.8),
                    decoration: BoxDecoration(
                      color: SMSTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: SMSTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timeline,
                              size: constraints.maxWidth > 200 ? 12 : 10,
                              color: SMSTheme.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Recent Activity',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: SMSTheme.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            (student['recentActivities'] as List).first,
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: fontSize - 1,
                              color: SMSTheme.textSecondaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: cardPadding * 0.8),
                
                // View Details Button with flexible layout
                Flexible(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showStudentDetails(student),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SMSTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: cardPadding * 0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, size: constraints.maxWidth > 200 ? 12 : 10),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'View Details',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
// Compact stat item for mobile back card
 Widget _buildCompactStatItem(String label, String value, Color color, [double? fontSize]) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: fontSize ?? 10,
            color: SMSTheme.textSecondaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Expanded(
        flex: 1,
        child: Text(
          value,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: fontSize ?? 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

// 5. Fixed achievement showcase with better overflow handling
Widget _buildMiniAchievementShowcase(Map<String, dynamic> student) {
  final achievements = _getStudentAchievements(student);
  
  return LayoutBuilder(
    builder: (context, constraints) {
      double fontSize = constraints.maxWidth > 200 ? 7 : 6;
      double emojiSize = constraints.maxWidth > 200 ? 10 : 9;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Achievements',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: constraints.maxWidth > 200 ? 10 : 9,
              fontWeight: FontWeight.w600,
              color: SMSTheme.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length > 3 ? 3 : achievements.length, // Limit items
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 4),
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.4, // Prevent badges from being too wide
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: achievements[index]['colors'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: achievements[index]['colors'][0].withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        achievements[index]['emoji'],
                        style: TextStyle(fontSize: emojiSize),
                      ),
                      SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          achievements[index]['title'],
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
// Mobile-optimized photo with mood ring (Ultra compact)
Widget _buildMobileOptimizedPhoto(Map<String, dynamic> student, double gpa) {
  final moodColor = _getMoodColor(student);
  
  return Stack(
    alignment: Alignment.center,
    children: [
      // Simplified Mood Ring - Smaller size
      Container(
        width: 55, // Further reduced
        height: 55, // Further reduced
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: moodColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: moodColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      // Student Photo - Smaller size
      Container(
        width: 48, // Further reduced
        height: 48, // Further reduced
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: student['profileImage'] != null
              ? Image.network(
                  student['profileImage'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildMobileAvatarFallback(student),
                )
              : _buildMobileAvatarFallback(student),
        ),
      ),
      // Level Badge - Smaller size
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          width: 18, // Further reduced
          height: 18, // Further reduced
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${_calculateLevel(gpa)}',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 8, // Further reduced
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// Ultra compact level progress bar
Widget _buildUltraCompactLevelProgress(double gpa) {
  final level = _calculateLevel(gpa);
  final progress = (gpa - level) / 1.0;
  
  return LayoutBuilder(
    builder: (context, constraints) {
      double fontSize = constraints.maxWidth > 200 ? 10 : 8;
      double subtitleFontSize = constraints.maxWidth > 200 ? 8 : 7;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Level $level',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  'Next: ${level + 1}',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: subtitleFontSize,
                    color: SMSTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              level >= 3 ? Colors.green : level >= 2 ? Colors.orange : Colors.red,
            ),
            minHeight: constraints.maxWidth > 200 ? 4 : 3,
          ),
        ],
      );
    },
  );
}
 
// Mobile avatar fallback (Ultra compact)
Widget _buildMobileAvatarFallback(Map<String, dynamic> student) {

  final themeGradients = [
      [SMSTheme.primaryColor, SMSTheme.primaryColor.withBlue(200)],
      [SMSTheme.successColor, SMSTheme.primaryColor],
      [SMSTheme.primaryColor, SMSTheme.secondaryColor],
      [SMSTheme.secondaryColor, SMSTheme.primaryColor.withGreen(180)],
    ];
    
  final gradientIndex = student['name'].hashCode % themeGradients.length;
    
    return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: themeGradients[gradientIndex],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        student['name'].toString().split(' ').map((n) => n[0]).take(2).join(),
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 16, // Much smaller for mobile
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// Compact Level Progress Bar (Gamified)
Widget _buildLevelProgress(double gpa, double attendance) {
  final level = _calculateLevel(gpa);
  final progress = (gpa - level) / 1.0; // Progress to next level
  
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Level $level',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 11, // Smaller font
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          Text(
            'Next: ${level + 1}',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 9, // Smaller font
              color: SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4), // Reduced spacing
      LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          level >= 3 ? Colors.green : level >= 2 ? Colors.orange : Colors.red,
        ),
        minHeight: 5, // Reduced height from 6 to 5
      ),
    ],
  );
}

// Compact Achievement Showcase (Reduced Height)
Widget _buildCompactAchievementShowcase(Map<String, dynamic> student) {
  final achievements = _getStudentAchievements(student);
  
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 11, // Smaller font
            fontWeight: FontWeight.w600,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6), // Reduced spacing
        SizedBox(
          height: 30, // Reduced height from 40 to 30
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 6), // Reduced margin
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Reduced padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: achievements[index]['colors'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15), // Smaller radius
                  boxShadow: [
                    BoxShadow(
                      color: achievements[index]['colors'][0].withOpacity(0.3),
                      blurRadius: 3, // Reduced blur
                      offset: const Offset(0, 1), // Reduced offset
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      achievements[index]['emoji'],
                      style: const TextStyle(fontSize: 12), // Smaller emoji
                    ),
                    const SizedBox(width: 3), // Reduced spacing
                    Text(
                      achievements[index]['title'],
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 8, // Smaller font
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
}

// Stat item for back card
Widget _buildStatItem(String label, String value, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 12,
          color: SMSTheme.textSecondaryColor,
        ),
      ),
      Text(
        value,
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

// Avatar fallback with theme gradients (Compact Version)
Widget _buildAvatarFallback(Map<String, dynamic> student) {
  final themeGradients = [
    [SMSTheme.primaryColor, SMSTheme.primaryColor.withBlue(200)],
    [SMSTheme.successColor, SMSTheme.primaryColor],
    [SMSTheme.primaryColor, SMSTheme.secondaryColor],
    [SMSTheme.secondaryColor, SMSTheme.primaryColor.withGreen(180)],
  ];
  
  final gradientIndex = student['name'].hashCode % themeGradients.length;
  
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: themeGradients[gradientIndex],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        student['name'].toString().split(' ').map((n) => n[0]).take(2).join(),
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 20, // Reduced from 24 to fit smaller photo
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// Empty state
Widget _buildEmptyState() {
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

// Helper methods
double _calculateFamilyGPA() {
  if (_students.isEmpty) return 0.0;
  return _students
      .map((s) => s['academics']['gpa'] as double)
      .reduce((a, b) => a + b) / _students.length;
}

Color _getMoodColor(Map<String, dynamic> student) {
  final gpa = student['academics']['gpa'] as double;
  final attendance = student['attendance']['percentage'] as double;
  final fees = student['fees']['pending'] as double;
  
  // Great performance
  if (gpa >= 3.5 && attendance >= 90 && fees == 0) {
    return Colors.green; // Green: Excellent
  }
  // Good performance with minor concerns
  else if (gpa >= 3.0 && attendance >= 80) {
    return Colors.orange; // Yellow/Orange: Minor concerns
  }
  // Needs attention
  else {
    return Colors.red; // Red: Needs attention
  }
}

int _calculateLevel(double gpa) {
  return (gpa).floor().clamp(1, 4);
}

List<Map<String, dynamic>> _getStudentAchievements(Map<String, dynamic> student) {
  List<Map<String, dynamic>> achievements = [];
  
  final gpa = student['academics']['gpa'] as double;
  final attendance = student['attendance']['percentage'] as double;
  
  if (gpa >= 3.5) {
    achievements.add({
      'emoji': '🏆',
      'title': 'Honor Roll',
      'colors': [Colors.amber, Colors.orange],
    });
  }
  
  if (attendance >= 95) {
    achievements.add({
      'emoji': '🎯',
      'title': 'Perfect Attendance',
      'colors': [Colors.green, Colors.teal],
    });
  }
  
  if (gpa >= 4.0) {
    achievements.add({
      'emoji': '⭐',
      'title': 'Star Student',
      'colors': [Colors.purple, Colors.blue],
    });
  }
  
  // Add default if no achievements
  if (achievements.isEmpty) {
    achievements.add({
      'emoji': '📚',
      'title': 'Student',
      'colors': [Colors.grey, Colors.blueGrey],
    });
  }
  
  return achievements;
}

 

// Note: _getGPAColor and _getAttendanceColor methods are already defined in your existing code
// Compact Photo with Mood Ring (Status Glow)
Widget _buildMoodRingPhoto(Map<String, dynamic> student, double gpa) {
  final moodColor = _getMoodColor(student);
  
  return Stack(
    alignment: Alignment.center,
    children: [
      // Animated Mood Ring - Smaller size
      TweenAnimationBuilder<double>(
        duration: const Duration(seconds: 2),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Container(
            width: 70, // Reduced from 80
            height: 70, // Reduced from 80
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: moodColor,
                width: 2.5, // Slightly thinner border
              ),
              boxShadow: [
                BoxShadow(
                  color: moodColor.withOpacity(0.4 + (0.3 * value)),
                  blurRadius: 10 + (6 * value), // Reduced blur
                  offset: const Offset(0, 0),
                  spreadRadius: 1.5 * value, // Reduced spread
                ),
              ],
            ),
          );
        },
      ),
      // Student Photo - Smaller size
      Container(
        width: 60, // Reduced from 70
        height: 60, // Reduced from 70
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: student['profileImage'] != null
              ? Image.network(
                  student['profileImage'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(student),
                )
              : _buildAvatarFallback(student),
        ),
      ),
      // Level Badge - Smaller size
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 20, // Reduced from 24
          height: 20, // Reduced from 24
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 3, // Reduced blur
                offset: const Offset(0, 1), // Reduced offset
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${_calculateLevel(gpa)}',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 9, // Smaller font
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
 
 
Widget _buildEnhancedStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          
          // Value
          Text(
            value,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          
          // Label
          Text(
            label,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SMSTheme.textPrimaryColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 10,
              color: SMSTheme.textSecondaryColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final parentId = authProvider.user?.uid;

    if (parentId == null) {
      return const Center(child: Text('Please log in to view this page'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Parent Dashboard',
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w600
          )
        ),
        backgroundColor: SMSTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: _buildNotificationIcon(),
            onPressed: _viewNotifications
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
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
                      color: SMSTheme.primaryColor
                    )
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Parent Portal',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600
                    )
                  ),
                  Text(
                    'Welcome, ${authProvider.user?.email ?? 'Parent'}',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 14
                    ),
                    overflow: TextOverflow.ellipsis,
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
              leading: Icon(Icons.people, color: SMSTheme.primaryColor),
              title: Text('My Students', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.payment, color: SMSTheme.primaryColor),
              title: Text('Payments', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: SMSTheme.primaryColor),
              title: Text('Attendance', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(3);
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment, color: SMSTheme.primaryColor),
              title: Text('Reports', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(4);
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: SMSTheme.primaryColor),
              title: Text('Enroll New Student', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EnrollmentFormScreen())
                );
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
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2)
                )
              ]
            ),
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
                // Home Tab - Enhanced with comprehensive overview
                _isLoading ? 
                  const Center(child: CircularProgressIndicator(color: SMSTheme.primaryColor)) :
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: SMSTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4)
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back, Parent!',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                )
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stay connected with your child\'s educational journey',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9)
                                )
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EnrollmentFormScreen())
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text('Enroll Student', style: TextStyle(fontFamily: 'Poppins',fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: SMSTheme.primaryColor,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _viewNotifications,
                                    icon: const Icon(Icons.notifications_outlined, size: 18),
                                    label: Text('$_notificationCount New', style: TextStyle(fontFamily: 'Poppins',fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12)
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Family Overview Stats
                        _buildSummaryStats(),
                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.textPrimaryColor
                          )
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildQuickActionButton(
                              Icons.payment,
                              'Pay Fees',
                              SMSTheme.primaryColor,
                              () => _tabController.animateTo(2)
                            ),
                            _buildQuickActionButton(
                              Icons.calendar_today,
                              'Attendance',
                              SMSTheme.secondaryColor,
                              () => _tabController.animateTo(3)
                            ),
                            _buildQuickActionButton(
                              Icons.assessment,
                              'Reports',
                              SMSTheme.primaryColor.withRed(150),
                              () => _tabController.animateTo(4)
                            ),
                            _buildQuickActionButton(
                              Icons.event,
                              'Calendar',
                              SMSTheme.successColor,
                              () => _tabController.animateTo(5)
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Recent Announcements
                        Text(
                          'Important Announcements',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.textPrimaryColor
                          )
                        ),
                        const SizedBox(height: 16),
                        ..._announcements.map((announcement) => _buildAnnouncementCard(announcement)).toList(),
                      ],
                    ),
                  ),
                
                // Students Tab - Comprehensive student information
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Students',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: SMSTheme.textPrimaryColor
                            )
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EnrollmentFormScreen())
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('Add Student', style: TextStyle(fontFamily: 'Poppins',fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SMSTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_students.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: SMSTheme.primaryColor.withOpacity(0.5)
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Students Enrolled',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: SMSTheme.textSecondaryColor
                                )
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start by enrolling your first student',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: SMSTheme.textSecondaryColor
                                )
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EnrollmentFormScreen())
                                ),
                                child: Text('Enroll Student', style: TextStyle(fontFamily: 'Poppins',)),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._students.map((student) => _buildStudentCard(student)).toList(),
                    ],
                  ),
                ),
                
                // Payments Tab - Enhanced payment overview
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Management',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor
                        )
                      ),
                      const SizedBox(height: 24),
                      // Add payment summary and student-wise fee breakdown here
                      Center(
                        child: Text(
                          'Payment functionality will be implemented here',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 16,
                            color: SMSTheme.textSecondaryColor
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Attendance Tab - Student attendance overview
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Overview',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor
                        )
                      ),
                      const SizedBox(height: 24),
                      // Add attendance charts and details here
                      Center(
                        child: Text(
                          'Attendance tracking will be implemented here',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 16,
                            color: SMSTheme.textSecondaryColor
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Reports Tab - Academic reports and progress
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Reports',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor
                        )
                      ),
                      const SizedBox(height: 24),
                      // Add report cards and progress tracking here
                      Center(
                        child: Text(
                          'Academic reports will be implemented here',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 16,
                            color: SMSTheme.textSecondaryColor
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Calendar Tab - School events and schedules
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'School Calendar',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor
                        )
                      ),
                      const SizedBox(height: 24),
                      // Add calendar widget and events here
                      Center(
                        child: Text(
                          'School calendar will be implemented here',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 16,
                            color: SMSTheme.textSecondaryColor
                          )
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnrollmentFormScreen())
        ),
        backgroundColor: SMSTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Enroll a Student',
      ),
    );
  }
}