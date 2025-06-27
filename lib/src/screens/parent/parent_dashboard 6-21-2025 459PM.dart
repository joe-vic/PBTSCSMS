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
import '../../models/student_model.dart';
import 'student_widgets.dart';
import 'student_detail_screen.dart';

// Enhanced ParentDashboard with comprehensive DepEd-based student management features
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
  
  List<Map<String, dynamic>> _announcements = [];
  List<StudentModel> _students = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _events = [];
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
    super.dispose();
  }

  // Enhanced data loading with comprehensive DepEd-based student data
  Future<void> _loadDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock announcements
    _announcements = [
      {
        'title': 'DepEd Order: Face-to-Face Classes Resume',
        'content': 'All schools will resume full face-to-face classes starting next week. Health protocols will remain in place.',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'priority': 'high',
      },
      {
        'title': 'Parent-Teacher Conference Schedule',
        'content': 'Quarterly parent-teacher meetings will be held on June 5-7. Please coordinate with your child\'s advisers.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'priority': 'medium',
      },
      {
        'title': 'National Achievement Test (NAT)',
        'content': 'Grade 6 and Grade 10 students will take the NAT on June 20-21. Review schedules have been posted.',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'priority': 'high',
      },
    ];

    // Create comprehensive StudentModel objects with DepEd-based data
    _students = [
      _createStudentModel(
        id: 'LRN-123456789012',
        name: 'John Smith',
        grade: 'Grade 10',
        className: '10-Einstein',
      ),
      _createStudentModel(
        id: 'LRN-123456789013',
        name: 'Emma Johnson',
        grade: 'Grade 8',
        className: '8-Newton',
      ),
    ];

    // DepEd-based payment structure
    _payments = [
      {
        'id': 'PAY2024001',
        'studentId': 'LRN-123456789012',
        'studentName': 'John Smith',
        'amount': 2500.0,
        'type': 'Miscellaneous Fee',
        'dueDate': DateTime.now().add(const Duration(days: 15)),
        'status': 'pending',
        'description': 'Q2 Miscellaneous Fee (Laboratory, Library, Computer)',
        'breakdown': {
          'Laboratory Fee': 800.0,
          'Library Fee': 500.0,
          'Computer Fee': 700.0,
          'Sports Fee': 300.0,
          'Maintenance Fee': 200.0,
        }
      },
      {
        'id': 'PAY2024002',
        'studentId': 'LRN-123456789012',
        'studentName': 'John Smith',
        'amount': 2000.0,
        'type': 'Miscellaneous Fee',
        'dueDate': DateTime.now().subtract(const Duration(days: 30)),
        'status': 'paid',
        'description': 'Q1 Miscellaneous Fee',
        'paidDate': DateTime.now().subtract(const Duration(days: 25)),
        'receiptNumber': 'OR-2024-001234',
      },
      {
        'id': 'PAY2024003',
        'studentId': 'LRN-123456789013',
        'studentName': 'Emma Johnson',
        'amount': 1800.0,
        'type': 'Project Fee',
        'dueDate': DateTime.now().add(const Duration(days: 7)),
        'status': 'pending',
        'description': 'Science Fair Project Materials',
      },
    ];

    // School calendar events based on DepEd calendar
    _events = [
      {
        'id': 'EVT001',
        'title': 'First Quarter Examination',
        'date': DateTime.now().add(const Duration(days: 10)),
        'endDate': DateTime.now().add(const Duration(days: 12)),
        'time': '7:30 AM - 4:30 PM',
        'location': 'All Classrooms',
        'type': 'academic',
        'description': 'First quarter examinations for all grade levels',
      },
      {
        'id': 'EVT002',
        'title': 'Science and Mathematics Festival',
        'date': DateTime.now().add(const Duration(days: 20)),
        'endDate': DateTime.now().add(const Duration(days: 21)),
        'time': '8:00 AM - 5:00 PM',
        'location': 'School Gymnasium',
        'type': 'event',
        'description': 'Annual Science and Mathematics Festival showcasing student projects',
      },
      {
        'id': 'EVT003',
        'title': 'Semestral Break',
        'date': DateTime.now().add(const Duration(days: 25)),
        'endDate': DateTime.now().add(const Duration(days: 32)),
        'time': 'All Day',
        'location': 'School Closed',
        'type': 'holiday',
        'description': 'Semestral break - no classes',
      },
      {
        'id': 'EVT004',
        'title': 'Parent-Teacher Conference',
        'date': DateTime.now().add(const Duration(days: 35)),
        'time': '8:00 AM - 12:00 PM',
        'location': 'Respective Classrooms',
        'type': 'meeting',
        'description': 'Quarterly parent-teacher meetings to discuss student progress',
      },
      {
        'id': 'EVT005',
        'title': 'National Achievement Test (NAT)',
        'date': DateTime.now().add(const Duration(days: 40)),
        'endDate': DateTime.now().add(const Duration(days: 41)),
        'time': '8:00 AM - 12:00 PM',
        'location': 'Testing Centers',
        'type': 'assessment',
        'description': 'National Achievement Test for Grade 6 and 10 students',
      },
    ];

    setState(() => _isLoading = false);
  }

  StudentModel _createStudentModel({
    required String id,
    required String name,
    required String grade,
    required String className,
  }) {
    // Create realistic monthly attendance records
    final monthlyRecords = [
      MonthlyAttendance(
        month: 'June',
        year: 2024,
        present: name == 'John Smith' ? 18 : 17,
        absent: name == 'John Smith' ? 1 : 2,
        late: name == 'John Smith' ? 1 : 1,
        dailyRecords: [],
      ),
      MonthlyAttendance(
        month: 'July',
        year: 2024,
        present: name == 'John Smith' ? 21 : 19,
        absent: name == 'John Smith' ? 0 : 1,
        late: name == 'John Smith' ? 1 : 2,
        dailyRecords: [],
      ),
      MonthlyAttendance(
        month: 'August',
        year: 2024,
        present: name == 'John Smith' ? 20 : 18,
        absent: name == 'John Smith' ? 1 : 2,
        late: name == 'John Smith' ? 1 : 2,
        dailyRecords: [],
      ),
    ];

    // Create quarter records based on DepEd grading system
    final quarters = [
      QuarterRecord(quarter: 1, grade: 88.5, exams: [], quizzes: [], projects: []),
      QuarterRecord(quarter: 2, grade: 90.0, exams: [], quizzes: [], projects: []),
    ];

    // Create subject records based on K-12 curriculum
    final subjects = grade == 'Grade 10' ? [
      SubjectRecord(subject: 'English', teacher: 'Ms. Garcia', currentGrade: 88.5, quarterGrades: []),
      SubjectRecord(subject: 'Filipino', teacher: 'Mrs. Santos', currentGrade: 92.0, quarterGrades: []),
      SubjectRecord(subject: 'Mathematics', teacher: 'Mr. Cruz', currentGrade: 85.5, quarterGrades: []),
      SubjectRecord(subject: 'Science', teacher: 'Ms. Reyes', currentGrade: 90.0, quarterGrades: []),
      SubjectRecord(subject: 'Araling Panlipunan', teacher: 'Mr. Dela Cruz', currentGrade: 87.0, quarterGrades: []),
      SubjectRecord(subject: 'Values Education', teacher: 'Mrs. Lopez', currentGrade: 95.0, quarterGrades: []),
      SubjectRecord(subject: 'PE and Health', teacher: 'Coach Martinez', currentGrade: 93.0, quarterGrades: []),
      SubjectRecord(subject: 'TLE - ICT', teacher: 'Mr. Fernandez', currentGrade: 89.0, quarterGrades: []),
    ] : [
      SubjectRecord(subject: 'English', teacher: 'Ms. Hernandez', currentGrade: 86.0, quarterGrades: []),
      SubjectRecord(subject: 'Filipino', teacher: 'Mrs. Morales', currentGrade: 90.5, quarterGrades: []),
      SubjectRecord(subject: 'Mathematics', teacher: 'Mr. Villanueva', currentGrade: 82.3, quarterGrades: []),
      SubjectRecord(subject: 'Science', teacher: 'Ms. Castro', currentGrade: 87.5, quarterGrades: []),
      SubjectRecord(subject: 'Araling Panlipunan', teacher: 'Mr. Torres', currentGrade: 85.0, quarterGrades: []),
      SubjectRecord(subject: 'Values Education', teacher: 'Mrs. Ramos', currentGrade: 94.0, quarterGrades: []),
      SubjectRecord(subject: 'PE and Health', teacher: 'Coach Silva', currentGrade: 91.0, quarterGrades: []),
      SubjectRecord(subject: 'TLE - HE', teacher: 'Mrs. Valdez', currentGrade: 88.0, quarterGrades: []),
    ];

    // Create DepEd card with proper subjects
    final depEdCard = DepEdCard(
      learnerReferenceNumber: id,
      schoolYear: '2023-2024',
      track: grade == 'Grade 10' ? 'Academic Track' : 'N/A',
      strand: grade == 'Grade 10' ? 'STEM' : 'N/A',
      coreSubjects: {
        'English': 88.0,
        'Filipino': 92.0,
        'Mathematics': 85.0,
        'Science': 90.0,
        'Araling Panlipunan': 87.0,
      },
      appliedSubjects: {
        'PE and Health': 95.0,
        'Values Education': 93.0,
      },
      specializedSubjects: grade == 'Grade 10' ? {
        'Pre-Calculus': 89.0,
        'General Chemistry': 91.0,
        'General Physics': 88.0,
      } : {},
    );

    return StudentModel(
      id: id,
      name: name,
      grade: grade,
      className: className,
      profileImage: null,
      attendance: AttendanceRecord(
        percentage: name == 'John Smith' ? 95.5 : 89.2,
        daysPresent: name == 'John Smith' ? 172 : 160,
        totalDays: 180,
        lastAttendance: DateTime.now().subtract(const Duration(days: 1)),
        monthlyRecords: monthlyRecords,
      ),
      academics: AcademicRecord(
        gpa: name == 'John Smith' ? 3.8 : 3.6,
        lastExamScore: name == 'John Smith' ? 88.5 : 82.3,
        lastQuizScore: name == 'John Smith' ? 92.0 : 87.5,
        rank: name == 'John Smith' ? 5 : 8,
        totalStudents: name == 'John Smith' ? 45 : 42,
        quarters: quarters,
        subjects: subjects,
      ),
      fees: FeesRecord(
        totalDue: name == 'John Smith' ? 15000.0 : 12000.0,
        paid: name == 'John Smith' ? 12000.0 : 12000.0,
        pending: name == 'John Smith' ? 3000.0 : 0.0,
        nextDueDate: DateTime.now().add(const Duration(days: 15)),
        paymentHistory: [],
      ),
      behavior: BehaviorRecord(
        rating: name == 'John Smith' ? 'Excellent' : 'Good',
        disciplinaryActions: name == 'John Smith' ? 0 : 1,
        teacherComments: name == 'John Smith' 
            ? 'Very well-behaved and participative student. Shows excellent leadership qualities.'
            : 'Shows improvement in class participation. Good attitude towards learning.',
      ),
      recentActivities: name == 'John Smith' ? [
        'Scored 95% in Mathematics Test',
        'Participated in Science Fair',
        'Won 1st place in Quiz Bee',
        'Completed Science Project ahead of deadline',
      ] : [
        'Won 2nd place in Art Competition',
        'Completed all assignments this week',
        'Participated in English Drama',
        'Improved attendance this month',
      ],
      depEdCard: depEdCard,
    );
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

  // FIXED: Enhanced student card with proper overflow handling
  Widget _buildStudentCard(StudentModel student) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              SMSTheme.cardColor,
              SMSTheme.spotlightBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: SMSTheme.spotlightBorder,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIXED: Student Header Row with proper constraints
              Row(
                children: [
                  // Student Avatar with Status Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getAttendanceColor(student.attendance.percentage),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getAttendanceColor(student.attendance.percentage).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ClipOval(
                          child: student.profileImage != null
                              ? Image.network(
                                  student.profileImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(student),
                                )
                              : _buildAvatarFallback(student),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // FIXED: Student Info with proper flex constraints
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SMSTheme.textPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.grade} • ${student.className}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            color: SMSTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'LRN: ${student.id}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // GPA Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getGPAColor(student.academics.gpa).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getGPAColor(student.academics.gpa)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'GPA',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _getGPAColor(student.academics.gpa),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${student.academics.gpa}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getGPAColor(student.academics.gpa),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // FIXED: Performance Metrics Row with responsive layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 400) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Attendance',
                            '${student.attendance.percentage.toStringAsFixed(1)}%',
                            Icons.calendar_today,
                            _getAttendanceColor(student.attendance.percentage),
                            '${student.attendance.daysPresent}/${student.attendance.totalDays} days',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Last Exam',
                            '${student.academics.lastExamScore}%',
                            Icons.quiz,
                            _getScoreColor(student.academics.lastExamScore),
                            'Rank ${student.academics.rank}/${student.academics.totalStudents}',
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildMetricCard(
                          'Attendance',
                          '${student.attendance.percentage.toStringAsFixed(1)}%',
                          Icons.calendar_today,
                          _getAttendanceColor(student.attendance.percentage),
                          '${student.attendance.daysPresent}/${student.attendance.totalDays} days',
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          'Last Exam',
                          '${student.academics.lastExamScore}%',
                          Icons.quiz,
                          _getScoreColor(student.academics.lastExamScore),
                          'Rank ${student.academics.rank}/${student.academics.totalStudents}',
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // FIXED: Action Buttons Row with proper wrapping
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionButton('View Details', Icons.visibility, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDetailScreen(student: student),
                      ),
                    );
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

  Widget _buildAvatarFallback(StudentModel student) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          student.name.split(' ').map((n) => n[0]).take(2).join(),
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // FIXED: Enhanced metric card with better overflow handling
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 10,
                color: SMSTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 9,
                color: SMSTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
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

  // COMPREHENSIVE DEPED-BASED PAYMENTS TAB
  Widget _buildPaymentsTab() {
    double totalPending = _payments
        .where((p) => p['status'] == 'pending' || p['status'] == 'overdue')
        .fold(0.0, (sum, p) => sum + p['amount']);
    
    double totalPaid = _payments
        .where((p) => p['status'] == 'paid')
        .fold(0.0, (sum, p) => sum + p['amount']);

    return SingleChildScrollView(
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
          const SizedBox(height: 8),
          Text(
            'Manage miscellaneous and other school fees as per DepEd guidelines',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textSecondaryColor
            )
          ),
          const SizedBox(height: 24),
          
          // Payment Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildPaymentSummaryCard(
                  'Total Pending',
                  '₱${totalPending.toStringAsFixed(0)}',
                  Icons.pending_actions,
                  SMSTheme.errorColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPaymentSummaryCard(
                  'Total Paid',
                  '₱${totalPaid.toStringAsFixed(0)}',
                  Icons.check_circle,
                  SMSTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // DepEd Fee Structure Information
          _buildDepEdFeeStructure(),
          const SizedBox(height: 24),
          
          // Payment History
          Text(
            'Payment History & Billing',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 16),
          
          ..._payments.map((payment) => _buildPaymentCard(payment)).toList(),
          
          const SizedBox(height: 24),
          
          // Payment Guidelines
          _buildPaymentGuidelines(),
        ],
      ),
    );
  }

  Widget _buildDepEdFeeStructure() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DepEd Approved Fee Structure (SY 2023-2024)',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeeBreakdown(),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    final fees = [
      {'name': 'Laboratory Fee', 'amount': '₱800.00', 'description': 'Science laboratory equipment and materials'},
      {'name': 'Library Fee', 'amount': '₱500.00', 'description': 'Books, references, and library maintenance'},
      {'name': 'Computer Fee', 'amount': '₱700.00', 'description': 'Computer laboratory and ICT equipment'},
      {'name': 'Sports Fee', 'amount': '₱300.00', 'description': 'Sports equipment and facilities'},
      {'name': 'Maintenance Fee', 'amount': '₱200.00', 'description': 'School building and facilities maintenance'},
    ];

    return Column(
      children: fees.map((fee) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee['name']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      fee['description']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                fee['amount']!,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentGuidelines() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SMSTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Guidelines',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            '• Fees are payable quarterly as per DepEd schedule',
            '• No student shall be denied admission for inability to pay fees',
            '• Payment can be made through the school cashier or authorized payment centers',
            '• Official receipts must be kept for record purposes',
            '• Late payment penalties may apply after grace period',
            '• Financial assistance is available for qualified students',
          ].map((guideline) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              guideline,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              color: SMSTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payment['status']) {
      case 'paid':
        statusColor = SMSTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = SMSTheme.secondaryColor;
        statusIcon = Icons.schedule;
        break;
      case 'overdue':
        statusColor = SMSTheme.errorColor;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = SMSTheme.textSecondaryColor;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        payment['studentName'],
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        payment['description'],
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${payment['amount'].toStringAsFixed(0)}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          payment['status'].toString().toUpperCase(),
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (payment['breakdown'] != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fee Breakdown:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...(payment['breakdown'] as Map<String, double>).entries.map((entry) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 11,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '₱${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(payment['dueDate'])}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 12,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                      if (payment['receiptNumber'] != null)
                        Text(
                          'OR No: ${payment['receiptNumber']}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 11,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                if (payment['status'] == 'pending' || payment['status'] == 'overdue')
                  ElevatedButton(
                    onPressed: () => _processPayment(payment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SMSTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Pay Now',
                      style: TextStyle(fontFamily: 'Poppins',fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // COMPREHENSIVE DEPED-BASED ATTENDANCE TAB
  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DepEd Attendance Monitoring',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 8),
          Text(
            'Track student attendance as per DepEd Order No. 8, s. 2015',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textSecondaryColor
            )
          ),
          const SizedBox(height: 24),
          
          // Attendance Overview
          _buildAttendanceOverview(),
          const SizedBox(height: 24),
          
          // Monthly Attendance Summary
          Text(
            'Monthly Attendance Summary',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 16),
          
          ..._students.map((student) => _buildAttendanceCard(student)).toList(),
          
          const SizedBox(height: 24),
          
          // Attendance Guidelines
          _buildAttendanceGuidelines(),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverview() {
    double familyAttendance = _students.isNotEmpty
        ? _students.map((s) => s.attendance.percentage).reduce((a, b) => a + b) / _students.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Family Attendance Rate',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${familyAttendance.toStringAsFixed(1)}%',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            familyAttendance >= 95 ? 'Excellent Attendance!' :
            familyAttendance >= 85 ? 'Good Attendance' :
            familyAttendance >= 75 ? 'Needs Improvement' : 'Poor Attendance',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: SMSTheme.primaryColor,
                  radius: 25,
                  child: Text(
                    student.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${student.grade} • ${student.className}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(student.attendance.percentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getAttendanceColor(student.attendance.percentage)),
                  ),
                  child: Text(
                    '${student.attendance.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(student.attendance.percentage),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Monthly Breakdown
            Text(
              'Monthly Breakdown (Current School Year)',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: student.attendance.monthlyRecords.length,
                itemBuilder: (context, index) {
                  final month = student.attendance.monthlyRecords[index];
                  return Container(
                    width: 85,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getAttendanceColor(month.percentage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getAttendanceColor(month.percentage).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getAttendanceColor(month.percentage).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Month Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getAttendanceColor(month.percentage).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            month.month.substring(0, 3),
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getAttendanceColor(month.percentage),
                            ),
                          ),
                        ),
                        
                        // Percentage
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${month.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getAttendanceColor(month.percentage),
                            ),
                          ),
                        ),
                        
                        // Attendance Details
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'P:',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: SMSTheme.successColor,
                                  ),
                                ),
                                Text(
                                  '${month.present}',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: SMSTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'A:',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: SMSTheme.errorColor,
                                  ),
                                ),
                                Text(
                                  '${month.absent}',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: SMSTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'L:',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: SMSTheme.warningColor,
                                  ),
                                ),
                                Text(
                                  '${month.late}',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: SMSTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Attendance Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Days Present: ${student.attendance.daysPresent}/${student.attendance.totalDays}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      'Last Attended: ${DateFormat('MMM dd').format(student.attendance.lastAttendance)}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: student.attendance.percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAttendanceColor(student.attendance.percentage),
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceGuidelines() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'DepEd Attendance Guidelines',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '• Students must attend at least 80% of classes to be promoted',
            '• Tardiness of 15 minutes or more is considered absence',
            '• Excused absences require proper documentation',
            '• Parents will be notified of excessive absences',
            '• Perfect attendance awards given at year-end',
            '• Medical certificates required for health-related absences',
          ].map((guideline) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              guideline,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  // COMPREHENSIVE DEPED-BASED REPORTS TAB
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DepEd K-12 Academic Reports',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 8),
          Text(
            'Comprehensive academic progress reports based on K-12 curriculum',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textSecondaryColor
            )
          ),
          const SizedBox(height: 24),
          
          // Academic Performance Overview
          _buildAcademicOverview(),
          const SizedBox(height: 24),
          
          // Student Report Cards
          Text(
            'Individual Student Reports',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 16),
          
          ..._students.map((student) => _buildReportCard(student)).toList(),
          
          const SizedBox(height: 24),
          
          // Grading System Information
          _buildGradingSystemInfo(),
        ],
      ),
    );
  }

  Widget _buildAcademicOverview() {
    double familyGPA = _students.isNotEmpty
        ? _students.map((s) => s.academics.gpa).reduce((a, b) => a + b) / _students.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SMSTheme.successColor, SMSTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.successColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Family Academic Performance',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${familyGPA.toStringAsFixed(1)}/4.0',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getGPADescription(familyGPA),
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: SMSTheme.primaryColor,
                  radius: 25,
                  child: Text(
                    student.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${student.grade} • ${student.className}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        'LRN: ${student.id}',
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
                    color: _getGPAColor(student.academics.gpa).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getGPAColor(student.academics.gpa)),
                  ),
                  child: Text(
                    'GPA: ${student.academics.gpa}',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getGPAColor(student.academics.gpa),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Subject Grades
            Text(
              'Subject Performance (Current Quarter)',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            ...student.academics.subjects.map((subject) => _buildSubjectGrade(subject)).toList(),
            
            const SizedBox(height: 16),
            
            // Academic Metrics
            Row(
              children: [
                Expanded(
                  child: _buildReportMetric(
                    'Class Rank',
                    '${student.academics.rank}/${student.academics.totalStudents}',
                    Icons.leaderboard,
                    SMSTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReportMetric(
                    'Last Exam',
                    '${student.academics.lastExamScore}%',
                    Icons.quiz,
                    _getScoreColor(student.academics.lastExamScore),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReportMetric(
                    'Last Quiz',
                    '${student.academics.lastQuizScore}%',
                    Icons.assignment,
                    _getScoreColor(student.academics.lastQuizScore),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // View Full Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailScreen(student: student),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SMSTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.assessment, size: 20),
                label: Text(
                  'View Complete Report Card',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectGrade(SubjectRecord subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getSubjectColor(subject.subject),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subject,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subject.teacher,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(subject.currentGrade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${subject.currentGrade.toStringAsFixed(1)}',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(subject.currentGrade),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 10,
                color: SMSTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingSystemInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grade_outlined, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'DepEd K-12 Grading System',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGradeScale(),
        ],
      ),
    );
  }

  Widget _buildGradeScale() {
    final gradeScale = [
      {'range': '90-100', 'description': 'Outstanding', 'remark': 'Exceeded expectations'},
      {'range': '85-89', 'description': 'Very Satisfactory', 'remark': 'Exceeded minimum expectations'},
      {'range': '80-84', 'description': 'Satisfactory', 'remark': 'Met minimum expectations'},
      {'range': '75-79', 'description': 'Fairly Satisfactory', 'remark': 'Close to meeting expectations'},
      {'range': 'Below 75', 'description': 'Did Not Meet Expectations', 'remark': 'Needs improvement'},
    ];

    return Column(
      children: gradeScale.map((grade) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  grade['range']!,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade['description']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      grade['remark']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 10,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // COMPREHENSIVE DEPED-BASED CALENDAR TAB
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DepEd School Calendar',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 8),
          Text(
            'Official school calendar based on DepEd Order No. 7, s. 2024',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textSecondaryColor
            )
          ),
          const SizedBox(height: 24),
          
          // Current School Year Info
          _buildSchoolYearInfo(),
          const SizedBox(height: 24),
          
          // Upcoming Events
          Text(
            'Upcoming School Events',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor
            )
          ),
          const SizedBox(height: 16),
          
          ..._events.map((event) => _buildEventCard(event)).toList(),
          
          const SizedBox(height: 24),
          
          // Academic Calendar Overview
          _buildAcademicCalendarOverview(),
        ],
      ),
    );
  }

  Widget _buildSchoolYearInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'School Year 2023-2024',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSchoolYearStat('Classes Started', 'August 29, 2023'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSchoolYearStat('Classes End', 'July 5, 2024'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSchoolYearStat('Total School Days', '200 days'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSchoolYearStat('Current Quarter', '2nd Quarter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolYearStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    Color eventColor;
    IconData eventIcon;
    
    switch (event['type']) {
      case 'academic':
        eventColor = SMSTheme.primaryColor;
        eventIcon = Icons.school;
        break;
      case 'event':
        eventColor = SMSTheme.successColor;
        eventIcon = Icons.event;
        break;
      case 'holiday':
        eventColor = SMSTheme.errorColor;
        eventIcon = Icons.beach_access;
        break;
      case 'meeting':
        eventColor = SMSTheme.warningColor;
        eventIcon = Icons.meeting_room;
        break;
      case 'assessment':
        eventColor = Colors.purple;
        eventIcon = Icons.assignment;
        break;
      default:
        eventColor = SMSTheme.textSecondaryColor;
        eventIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: eventColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(eventIcon, color: eventColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'],
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: SMSTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['endDate'] != null 
                              ? '${DateFormat('MMM dd').format(event['date'])} - ${DateFormat('MMM dd, yyyy').format(event['endDate'])}'
                              : '${DateFormat('MMM dd, yyyy').format(event['date'])} • ${event['time']}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: SMSTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'],
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
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

  Widget _buildAcademicCalendarOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.teal[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Academic Calendar Highlights',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuarterSchedule(),
        ],
      ),
    );
  }

  Widget _buildQuarterSchedule() {
    final quarters = [
      {
        'quarter': '1st Quarter',
        'start': 'Aug 29, 2023',
        'end': 'Oct 27, 2023',
        'status': 'completed'
      },
      {
        'quarter': '2nd Quarter', 
        'start': 'Oct 30, 2023',
        'end': 'Jan 12, 2024',
        'status': 'current'
      },
      {
        'quarter': '3rd Quarter',
        'start': 'Jan 15, 2024',
        'end': 'Mar 22, 2024',
        'status': 'upcoming'
      },
      {
        'quarter': '4th Quarter',
        'start': 'Mar 25, 2024',
        'end': 'July 5, 2024',
        'status': 'upcoming'
      },
    ];

    return Column(
      children: quarters.map((quarter) {
        Color statusColor;
        IconData statusIcon;
        
        switch (quarter['status']) {
          case 'completed':
            statusColor = SMSTheme.successColor;
            statusIcon = Icons.check_circle;
            break;
          case 'current':
            statusColor = SMSTheme.warningColor;
            statusIcon = Icons.play_circle_filled;
            break;
          default:
            statusColor = SMSTheme.textSecondaryColor;
            statusIcon = Icons.schedule;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quarter['quarter']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '${quarter['start']} - ${quarter['end']}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quarter['status']!.toUpperCase(),
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods for processing payments
  void _processPayment(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Payment', style: TextStyle(fontFamily: 'Poppins',)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${payment['studentName']}', style: TextStyle(fontFamily: 'Poppins',)),
            Text('Amount: ₱${payment['amount']}', style: TextStyle(fontFamily: 'Poppins',)),
            Text('Description: ${payment['description']}', style: TextStyle(fontFamily: 'Poppins',)),
            const SizedBox(height: 12),
            Text(
              'Note: Payment will be processed through the school cashier or authorized payment centers.',
              style: TextStyle(fontFamily: 'Poppins',fontSize: 12, color: SMSTheme.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins',)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment request submitted. Please pay at the school cashier.'),
                  backgroundColor: SMSTheme.successColor,
                ),
              );
            },
            child: Text('Proceed', style: TextStyle(fontFamily: 'Poppins',)),
          ),
        ],
      ),
    );
  }

  // Add this helper method for the StudentDetailScreen compatibility
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 95) return SMSTheme.progressExcellent;
    if (percentage >= 85) return SMSTheme.progressGood;
    if (percentage >= 75) return SMSTheme.progressAverage;
    return SMSTheme.progressPoor;
  }

  // Helper color methods
  Color _getGPAColor(double gpa) {
    if (gpa >= 3.5) return SMSTheme.successColor;
    if (gpa >= 3.0) return SMSTheme.secondaryColor;
    return SMSTheme.errorColor;
  }

 

  Color _getScoreColor(double score) {
    if (score >= 85) return SMSTheme.successColor;
    if (score >= 70) return SMSTheme.secondaryColor;
    return SMSTheme.errorColor;
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      SMSTheme.primaryColor,
      SMSTheme.successColor,
      SMSTheme.warningColor,
      SMSTheme.accentColor,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.orange,
    ];
    final index = subject.hashCode % colors.length;
    return colors[index];
  }

  String _getGPADescription(double gpa) {
    if (gpa >= 3.5) return 'Outstanding Performance';
    if (gpa >= 3.0) return 'Very Good Performance';
    if (gpa >= 2.5) return 'Good Performance';
    if (gpa >= 2.0) return 'Satisfactory Performance';
    return 'Needs Improvement';
  }

  // Keep existing methods for announcements, notifications, etc.
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement['content'],
              style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildSummaryStats() {
    if (_students.isEmpty) {
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

    return StudentSpotlightSection(students: _students);
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
                  Flexible(
                    child: Text(
                      'Welcome, ${authProvider.user?.email ?? 'Parent'}',
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.white70,
                        fontSize: 14
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
              title: Text('Students', style: TextStyle(fontFamily: 'Poppins',)),
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
              title: Text('Calendar', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(5);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.settings, color: SMSTheme.textSecondaryColor),
              title: Text('Settings', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Settings feature coming soon'),
                    backgroundColor: SMSTheme.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: SMSTheme.textSecondaryColor),
              title: Text('Help & Support', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Help feature coming soon'),
                    backgroundColor: SMSTheme.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: SMSTheme.errorColor),
              title: Text('Logout', style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
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
          ),
          
          // Tab Content
          Expanded(
            child: _isLoading
                ? Center(
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
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHomeTab(),
                      _buildStudentsTab(),
                      _buildPaymentsTab(),
                      _buildAttendanceTab(),
                      _buildReportsTab(),
                      _buildCalendarTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // HOME TAB - Dashboard Overview
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
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
          ),
          const SizedBox(height: 24),
          
          // Student Summary
          _buildSummaryStats(),
          const SizedBox(height: 24),
          
          // Announcements Section
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
          
          ..._announcements.take(3).map((announcement) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAnnouncementCard(announcement),
          )).toList(),
          
          const SizedBox(height: 24),
          
          // Quick Actions
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
              // Responsive grid based on screen width
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
                  _buildQuickActionCard(
                    'View Grades',
                    'Check academic performance',
                    Icons.grade,
                    SMSTheme.successColor,
                    () => _tabController.animateTo(4),
                  ),
                  _buildQuickActionCard(
                    'Pay Fees',
                    'Manage school payments',
                    Icons.payment,
                    SMSTheme.warningColor,
                    () => _tabController.animateTo(2),
                  ),
                  _buildQuickActionCard(
                    'Attendance',
                    'Track school attendance',
                    Icons.calendar_today,
                    SMSTheme.primaryColor,
                    () => _tabController.animateTo(3),
                  ),
                  _buildQuickActionCard(
                    'Calendar',
                    'View school events',
                    Icons.event,
                    SMSTheme.accentColor,
                    () => _tabController.animateTo(5),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 11,
                    color: SMSTheme.textSecondaryColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STUDENTS TAB - Enhanced with proper overflow handling
  Widget _buildStudentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Students',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Monitor your children\'s academic progress',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Add student feature coming soon'),
                      backgroundColor: SMSTheme.primaryColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SMSTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Student',
                  style: TextStyle(fontFamily: 'Poppins',fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_students.isEmpty)
            _buildSummaryStats()
          else
            ..._students.map((student) => _buildStudentCard(student)).toList(),
        ],
      ),
    );
  }
}