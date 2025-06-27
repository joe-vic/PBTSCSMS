import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ← Make sure this points to your real login_screen.dart
import '../auth/login_screen.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SMSTheme.backgroundColorLight,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => _showProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          _buildDashboardTab(),
          _buildLearningTab(),
          _buildAssignmentsTab(),
          _buildGradesTab(),
          _buildLibraryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Learning';
      case 2:
        return 'Assignments';
      case 3:
        return 'Grades';
      case 4:
        return 'Library';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: SMSTheme.primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade_rounded),
            label: 'Grades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  // DASHBOARD TAB
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildTodaySchedule(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
          const SizedBox(height: 20),
          _buildUpcomingDeadlines(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
                  'Welcome back, Juan!',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to continue your learning journey?',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Grade 10 - Einstein',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: const DecorationImage(
                image: NetworkImage('https://via.placeholder.com/80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'GPA', '3.8', Icons.school_rounded, SMSTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Attendance', '96%',
                    Icons.calendar_today_rounded, SMSTheme.successColor)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Courses', '8', Icons.book_rounded, SMSTheme.warningColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Assignments', '3',
                    Icons.assignment_rounded, SMSTheme.errorColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              color: SMSTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final todayClasses = [
      {
        'subject': 'Mathematics',
        'time': '8:00 AM',
        'teacher': 'Ms. Garcia',
        'room': 'Room 101'
      },
      {
        'subject': 'Science',
        'time': '10:00 AM',
        'teacher': 'Mr. Santos',
        'room': 'Lab 2'
      },
      {
        'subject': 'English',
        'time': '1:00 PM',
        'teacher': 'Mrs. Cruz',
        'room': 'Room 205'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: todayClasses.map((classInfo) {
              return _buildScheduleItem(
                classInfo['subject']!,
                classInfo['time']!,
                classInfo['teacher']!,
                classInfo['room']!,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
      String subject, String time, String teacher, String room) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getSubjectColor(subject).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSubjectIcon(subject),
              color: _getSubjectColor(subject),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  teacher,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: SMSTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  room,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    color: SMSTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SMSTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LEARNING TAB (LMS)
  Widget _buildLearningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLearningProgress(),
          const SizedBox(height: 20),
          _buildActiveCourses(),
          const SizedBox(height: 20),
          _buildRecentLessons(),
          const SizedBox(height: 20),
          _buildStudyTime(),
        ],
      ),
    );
  }

  Widget _buildLearningProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
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
              Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Learning Progress',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '75%',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Overall Progress',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '24h',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Study Time',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCourses() {
    final courses = [
      {
        'name': 'Mathematics',
        'progress': 0.8,
        'lessons': '12/15',
        'color': SMSTheme.primaryColor
      },
      {
        'name': 'Science',
        'progress': 0.6,
        'lessons': '9/15',
        'color': SMSTheme.successColor
      },
      {
        'name': 'English',
        'progress': 0.9,
        'lessons': '14/15',
        'color': SMSTheme.warningColor
      },
      {
        'name': 'Filipino',
        'progress': 0.7,
        'lessons': '10/14',
        'color': SMSTheme.errorColor
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Courses',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: courses.map((course) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (course['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getSubjectIcon(course['name'] as String),
                          color: course['color'] as Color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['name'] as String,
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: SMSTheme.textPrimaryLight,
                              ),
                            ),
                            Text(
                              '${course['lessons']} lessons completed',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 12,
                                color: SMSTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${((course['progress'] as double) * 100).toInt()}%',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: course['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: course['progress'] as double,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation(course['color'] as Color),
                    minHeight: 6,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentLessons() {
    final lessons = [
      {
        'title': 'Quadratic Equations',
        'subject': 'Mathematics',
        'duration': '45 min',
        'completed': true
      },
      {
        'title': 'Photosynthesis',
        'subject': 'Science',
        'duration': '30 min',
        'completed': true
      },
      {
        'title': 'Essay Writing',
        'subject': 'English',
        'duration': '60 min',
        'completed': false
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Lessons',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: lessons.map((lesson) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: lesson['completed'] as bool
                      ? SMSTheme.successColor.withOpacity(0.3)
                      : SMSTheme.warningColor.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    lesson['completed'] as bool
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_rounded,
                    color: lesson['completed'] as bool
                        ? SMSTheme.successColor
                        : SMSTheme.warningColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson['title'] as String,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SMSTheme.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${lesson['subject']} • ${lesson['duration']}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!(lesson['completed'] as bool))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: SMSTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: SMSTheme.warningColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ASSIGNMENTS TAB
  Widget _buildAssignmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssignmentStats(),
          const SizedBox(height: 20),
          _buildPendingAssignments(),
          const SizedBox(height: 20),
          _buildSubmittedAssignments(),
        ],
      ),
    );
  }

  Widget _buildAssignmentStats() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Pending', '3', Icons.pending_actions_rounded,
                SMSTheme.errorColor)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Submitted', '12', Icons.check_circle_rounded,
                SMSTheme.successColor)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Graded', '10', Icons.grade_rounded, SMSTheme.primaryColor)),
      ],
    );
  }

  Widget _buildPendingAssignments() {
    final assignments = [
      {
        'title': 'Math Problem Set 5',
        'subject': 'Mathematics',
        'due': 'Tomorrow',
        'urgent': true
      },
      {
        'title': 'Science Lab Report',
        'subject': 'Science',
        'due': 'Friday',
        'urgent': false
      },
      {
        'title': 'English Essay',
        'subject': 'English',
        'due': 'Next Week',
        'urgent': false
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Assignments',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: assignments.map((assignment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: assignment['urgent'] as bool
                      ? SMSTheme.errorColor.withOpacity(0.3)
                      : SMSTheme.primaryColor.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(assignment['subject'] as String)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: _getSubjectColor(assignment['subject'] as String),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['title'] as String,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SMSTheme.textPrimaryLight,
                          ),
                        ),
                        Text(
                          assignment['subject'] as String,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: assignment['urgent'] as bool
                              ? SMSTheme.errorColor.withOpacity(0.1)
                              : SMSTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          assignment['due'] as String,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: assignment['urgent'] as bool
                                ? SMSTheme.errorColor
                                : SMSTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (assignment['urgent'] as bool)
                        Text(
                          'URGENT',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.errorColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmittedAssignments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Submitted',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: SMSTheme.successColor, size: 48),
              const SizedBox(height: 12),
              Text(
                'All caught up!',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.textPrimaryLight,
                ),
              ),
              Text(
                'You\'ve submitted all recent assignments',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  color: SMSTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // GRADES TAB
  Widget _buildGradesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGradeOverview(),
          const SizedBox(height: 20),
          _buildSubjectGrades(),
          const SizedBox(height: 20),
          _buildRecentGrades(),
        ],
      ),
    );
  }

  Widget _buildGradeOverview() {
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
                  'Current GPA',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '3.8',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Rank 5 of 45 students',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                '+0.2 from last quarter',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrades() {
    final subjects = [
      {'name': 'Mathematics', 'grade': 88.5, 'trend': 'up'},
      {'name': 'Science', 'grade': 92.0, 'trend': 'up'},
      {'name': 'English', 'grade': 85.5, 'trend': 'down'},
      {'name': 'Filipino', 'grade': 90.0, 'trend': 'up'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Grades',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: subjects.map((subject) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(subject['name'] as String),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject['name'] as String,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Icon(
                    subject['trend'] == 'up'
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: subject['trend'] == 'up'
                        ? SMSTheme.successColor
                        : SMSTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(subject['grade'] as double).toStringAsFixed(1)}%',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(subject['grade'] as double),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentGrades() {
    final recentGrades = [
      {'assignment': 'Math Quiz 4', 'grade': 95, 'date': '3 days ago'},
      {'assignment': 'Science Project', 'grade': 88, 'date': '1 week ago'},
      {'assignment': 'English Essay', 'grade': 92, 'date': '1 week ago'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Grades',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: recentGrades.map((grade) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade['assignment'] as String,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SMSTheme.textPrimaryLight,
                          ),
                        ),
                        Text(
                          grade['date'] as String,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getGradeColor(grade['grade'] as int)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${grade['grade']}%',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(grade['grade'] as int),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // LIBRARY TAB
  Widget _buildLibraryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildLibraryCategories(),
          const SizedBox(height: 20),
          _buildRecentBooks(),
          const SizedBox(height: 20),
          _buildRecommended(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: SMSTheme.textSecondaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search books, resources...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontFamily: 'Poppins',
                  color: SMSTheme.textSecondaryLight,
                ),
              ),
            ),
          ),
          Icon(Icons.filter_list_rounded, color: SMSTheme.textSecondaryLight),
        ],
      ),
    );
  }

  Widget _buildLibraryCategories() {
    final categories = [
      {'name': 'Textbooks', 'icon': Icons.menu_book_rounded, 'count': 24},
      {'name': 'References', 'icon': Icons.library_books_rounded, 'count': 156},
      {'name': 'E-books', 'icon': Icons.book_rounded, 'count': 89},
      {'name': 'Videos', 'icon': Icons.play_circle_rounded, 'count': 43},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse Library',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: SMSTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SMSTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${category['count']} items',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      color: SMSTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentBooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Accessed',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: SMSTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: SMSTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.book_rounded,
                            color: SMSTheme.primaryColor,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Math Textbook ${index + 1}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildRecommended() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: SMSTheme.primaryColor, size: 48),
              const SizedBox(height: 12),
              Text(
                'Coming Soon!',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.textPrimaryLight,
                ),
              ),
              Text(
                'Personalized recommendations based on your learning progress',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  color: SMSTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // HELPER METHODS
  Widget _buildRecentActivity() {
    final activities = [
      'Completed Math Quiz 4 - 95%',
      'Submitted Science Lab Report',
      'Watched English Grammar Video',
      'Downloaded Filipino Reading Materials',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SMSTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activity,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          color: SMSTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlines() {
    final deadlines = [
      {'task': 'Math Problem Set 5', 'due': 'Tomorrow', 'urgent': true},
      {'task': 'Science Lab Report', 'due': 'Friday', 'urgent': false},
      {'task': 'English Presentation', 'due': 'Next Week', 'urgent': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Deadlines',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: deadlines.map((deadline) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: deadline['urgent'] as bool
                      ? SMSTheme.errorColor.withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    deadline['urgent'] as bool
                        ? Icons.warning_rounded
                        : Icons.schedule_rounded,
                    color: deadline['urgent'] as bool
                        ? SMSTheme.errorColor
                        : SMSTheme.textSecondaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      deadline['task'] as String,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        color: SMSTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    deadline['due'] as String,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: deadline['urgent'] as bool
                          ? SMSTheme.errorColor
                          : SMSTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudyTime() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: SMSTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Study Time This Week',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '24h 32m',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Total Time',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '3h 42m',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.successColor,
                      ),
                    ),
                    Text(
                      'Daily Average',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      SMSTheme.primaryColor,
      SMSTheme.successColor,
      SMSTheme.warningColor,
      SMSTheme.errorColor,
      const Color(0xFF9b59b6),
      const Color(0xFF1abc9c),
    ];
    return colors[subject.hashCode % colors.length];
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'english':
        return Icons.language_rounded;
      case 'filipino':
        return Icons.translate_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  Color _getGradeColor(num grade) {
    if (grade >= 90) return SMSTheme.successColor;
    if (grade >= 85) return SMSTheme.primaryColor;
    if (grade >= 75) return SMSTheme.warningColor;
    return SMSTheme.errorColor;
  }

  void _showNotifications() {
    // Implement notifications
  }

  void _showProfile() {
    // Implement profile
  }
}
