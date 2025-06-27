import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../config/theme.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDetailScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Overview',
    'Academics',
    'Attendance',
    'DepEd Card',
    'Behavior'
  ];

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
    return Scaffold(
      backgroundColor: SMSTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.student.name,
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareStudentReport(),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _printStudentReport(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Header Card
          _buildStudentHeader(),
          
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
              labelStyle: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAcademicsTab(),
                _buildAttendanceTab(),
                _buildDepEdCardTab(),
                _buildBehaviorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.primaryColor,
            SMSTheme.secondaryColor,
          ],
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
          // Student Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.student.profileImage != null
                  ? Image.network(
                      widget.student.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildHeaderAvatarFallback(),
                    )
                  : _buildHeaderAvatarFallback(),
            ),
          ),
          const SizedBox(width: 16),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.student.grade} • ${widget.student.className}',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${widget.student.id}',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Quick Stats
          Column(
            children: [
              _buildQuickStat('GPA', widget.student.academics.gpa.toStringAsFixed(1)),
              const SizedBox(height: 8),
              _buildQuickStat('Attendance', '${widget.student.attendance.percentage.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.student.name.split(' ').map((n) => n[0]).take(2).join(),
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 400) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Academic Performance',
                        '${widget.student.academics.gpa}/4.0',
                        Icons.school_rounded,
                        SMSTheme.primaryColor,
                        'Rank ${widget.student.academics.rank}/${widget.student.academics.totalStudents}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Attendance Rate',
                        '${widget.student.attendance.percentage.toStringAsFixed(1)}%',
                        Icons.calendar_today_rounded,
                        _getAttendanceColor(widget.student.attendance.percentage),
                        '${widget.student.attendance.daysPresent}/${widget.student.attendance.totalDays} days',
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSummaryCard(
                      'Academic Performance',
                      '${widget.student.academics.gpa}/4.0',
                      Icons.school_rounded,
                      SMSTheme.primaryColor,
                      'Rank ${widget.student.academics.rank}/${widget.student.academics.totalStudents}',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Attendance Rate',
                      '${widget.student.attendance.percentage.toStringAsFixed(1)}%',
                      Icons.calendar_today_rounded,
                      _getAttendanceColor(widget.student.attendance.percentage),
                      '${widget.student.attendance.daysPresent}/${widget.student.attendance.totalDays} days',
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 400) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Fees Status',
                        widget.student.fees.pending > 0 ? '₱${widget.student.fees.pending.toStringAsFixed(0)}' : 'Paid',
                        Icons.payment_rounded,
                        widget.student.fees.pending > 0 ? SMSTheme.errorColor : SMSTheme.successColor,
                        widget.student.fees.pending > 0 ? 'Pending' : 'All Clear',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Behavior Rating',
                        widget.student.behavior.rating,
                        Icons.star_rounded,
                        _getBehaviorColor(widget.student.behavior.rating),
                        '${widget.student.behavior.disciplinaryActions} actions',
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSummaryCard(
                      'Fees Status',
                      widget.student.fees.pending > 0 ? '₱${widget.student.fees.pending.toStringAsFixed(0)}' : 'Paid',
                      Icons.payment_rounded,
                      widget.student.fees.pending > 0 ? SMSTheme.errorColor : SMSTheme.successColor,
                      widget.student.fees.pending > 0 ? 'Pending' : 'All Clear',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Behavior Rating',
                      widget.student.behavior.rating,
                      Icons.star_rounded,
                      _getBehaviorColor(widget.student.behavior.rating),
                      '${widget.student.behavior.disciplinaryActions} actions',
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Recent Activities
          _buildSectionTitle('Recent Activities'),
          const SizedBox(height: 12),
          _buildRecentActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildAcademicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quarter Performance
          _buildSectionTitle('Quarterly Performance'),
          const SizedBox(height: 12),
          _buildQuarterlyPerformance(),
          const SizedBox(height: 24),
          
          // Subject Performance
          _buildSectionTitle('Subject Performance'),
          const SizedBox(height: 12),
          _buildSubjectPerformance(),
          const SizedBox(height: 24),
          
          // Recent Exams & Quizzes
          _buildSectionTitle('Recent Assessments'),
          const SizedBox(height: 12),
          _buildRecentAssessments(),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Attendance Overview
          _buildSectionTitle('Monthly Attendance'),
          const SizedBox(height: 12),
          _buildMonthlyAttendance(),
          const SizedBox(height: 24),
          
          // Attendance Calendar
          _buildSectionTitle('Attendance Calendar'),
          const SizedBox(height: 12),
          _buildAttendanceCalendar(),
        ],
      ),
    );
  }

  Widget _buildDepEdCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DepEd Card Header
          _buildDepEdCardHeader(),
          const SizedBox(height: 20),
          
          // Core Subjects
          _buildSectionTitle('Core Subjects'),
          const SizedBox(height: 12),
          _buildSubjectGrades(widget.student.depEdCard.coreSubjects, 'Core'),
          const SizedBox(height: 20),
          
          // Applied Subjects
          if (widget.student.depEdCard.appliedSubjects.isNotEmpty) ...[
            _buildSectionTitle('Applied Subjects'),
            const SizedBox(height: 12),
            _buildSubjectGrades(widget.student.depEdCard.appliedSubjects, 'Applied'),
            const SizedBox(height: 20),
          ],
          
          // Specialized Subjects
          if (widget.student.depEdCard.specializedSubjects.isNotEmpty) ...[
            _buildSectionTitle('Specialized Subjects'),
            const SizedBox(height: 12),
            _buildSubjectGrades(widget.student.depEdCard.specializedSubjects, 'Specialized'),
          ],
        ],
      ),
    );
  }

  Widget _buildBehaviorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Behavior Summary
          _buildBehaviorSummary(),
          const SizedBox(height: 24),
          
          // Teacher Comments
          _buildSectionTitle('Teacher Comments'),
          const SizedBox(height: 12),
          _buildTeacherComments(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 10,
              color: SMSTheme.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: SMSTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildRecentActivitiesList() {
    return Container(
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
        children: widget.student.recentActivities.map((activity) {
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
                      color: SMSTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuarterlyPerformance() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          final quarter = index + 1;
          final grade = 85.0 + (index * 2.5); // Sample grades
          
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SMSTheme.quarterColors[index].withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: SMSTheme.quarterColors[index].withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SMSTheme.quarterColors[index].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Quarter $quarter',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SMSTheme.quarterColors[index],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${grade.toStringAsFixed(1)}%',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(grade),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGradeRemarks(grade),
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: grade / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(_getGradeColor(grade)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectPerformance() {
    final subjects = [
      {'name': 'Mathematics', 'grade': 88.5, 'teacher': 'Ms. Garcia'},
      {'name': 'Science', 'grade': 92.0, 'teacher': 'Mr. Santos'},
      {'name': 'English', 'grade': 85.5, 'teacher': 'Mrs. Cruz'},
      {'name': 'Filipino', 'grade': 90.0, 'teacher': 'Mr. Reyes'},
    ];

    return Column(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name'] as String,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      subject['teacher'] as String,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
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
    );
  }

  Widget _buildRecentAssessments() {
    final assessments = [
      {'type': 'Exam', 'subject': 'Mathematics', 'score': 95, 'maxScore': 100, 'date': DateTime.now().subtract(Duration(days: 5))},
      {'type': 'Quiz', 'subject': 'Science', 'score': 18, 'maxScore': 20, 'date': DateTime.now().subtract(Duration(days: 10))},
      {'type': 'Project', 'subject': 'English', 'score': 45, 'maxScore': 50, 'date': DateTime.now().subtract(Duration(days: 15))},
    ];

    return Column(
      children: assessments.map((assessment) {
        final percentage = (assessment['score'] as int) / (assessment['maxScore'] as int) * 100;
        
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getAssessmentTypeColor(assessment['type'] as String).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAssessmentTypeIcon(assessment['type'] as String),
                  color: _getAssessmentTypeColor(assessment['type'] as String),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${assessment['type']} - ${assessment['subject']}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(assessment['date'] as DateTime),
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
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
                    '${assessment['score']}/${assessment['maxScore']}',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: SMSTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _getGradeColor(percentage),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // FIXED: Monthly Attendance with proper overflow handling
  Widget _buildMonthlyAttendance() {
    return SizedBox(
      height: 140, // Increased height to prevent overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.student.attendance.monthlyRecords.length,
        itemBuilder: (context, index) {
          final month = widget.student.attendance.monthlyRecords[index];
          
          return Container(
            width: 100, // Increased width for better fit
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16), // Increased padding
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
              border: Border.all(
                color: _getAttendanceColor(month.percentage).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Month Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(month.percentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      month.month.substring(0, 3),
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
                
                // Percentage with proper sizing
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${month.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(month.percentage),
                    ),
                  ),
                ),
                
                // Attendance details with constrained layout
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'P: ${month.present}', 
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 10, 
                            color: SMSTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'A: ${month.absent}', 
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 10, 
                            color: SMSTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'L: ${month.late}', 
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 10, 
                            color: SMSTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // FIXED: Enhanced Attendance Calendar with proper layout
  Widget _buildAttendanceCalendar() {
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
        mainAxisSize: MainAxisSize.min, // Important: prevents overflow
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SMSTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: SMSTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Attendance Calendar Feature',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Interactive calendar will be implemented here showing daily attendance status',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textSecondaryColor,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SMSTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCalendarLegend('Present', SMSTheme.successColor),
                _buildCalendarLegend('Absent', SMSTheme.errorColor),
                _buildCalendarLegend('Late', SMSTheme.warningColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend(String label, Color color) {
    return Row(
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
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 11,
            color: SMSTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDepEdCardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0), // DepEd Blue
            const Color(0xFF0D47A1), // Darker Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
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
                  Icons.card_membership_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Department of Education',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'REPORT CARD',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'School Year: ${widget.student.depEdCard.schoolYear}',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (widget.student.depEdCard.learnerReferenceNumber.isNotEmpty)
            Text(
              'LRN: ${widget.student.depEdCard.learnerReferenceNumber}',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrades(Map<String, double> subjects, String category) {
    return Container(
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
        children: subjects.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SMSTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(entry.value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getGradeColor(entry.value).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    entry.value.toStringAsFixed(0),
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(entry.value),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBehaviorSummary() {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBehaviorColor(widget.student.behavior.rating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: _getBehaviorColor(widget.student.behavior.rating),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Rating',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      widget.student.behavior.rating,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getBehaviorColor(widget.student.behavior.rating),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.student.behavior.disciplinaryActions == 0 
                      ? SMSTheme.successColor.withOpacity(0.1)
                      : SMSTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.student.behavior.disciplinaryActions} Actions',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.student.behavior.disciplinaryActions == 0 
                        ? SMSTheme.successColor
                        : SMSTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherComments() {
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
              Icon(
                Icons.format_quote_rounded,
                color: SMSTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Teacher\'s Comments',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.student.behavior.teacherComments,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: SMSTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 95) return SMSTheme.progressExcellent;
    if (percentage >= 85) return SMSTheme.progressGood;
    if (percentage >= 75) return SMSTheme.progressAverage;
    return SMSTheme.progressPoor;
  }

  Color _getBehaviorColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return SMSTheme.progressExcellent;
      case 'good':
        return SMSTheme.progressGood;
      case 'satisfactory':
        return SMSTheme.progressAverage;
      default:
        return SMSTheme.progressPoor;
    }
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return SMSTheme.progressExcellent;
    if (grade >= 85) return SMSTheme.progressGood;
    if (grade >= 75) return SMSTheme.progressAverage;
    return SMSTheme.progressPoor;
  }

  String _getGradeRemarks(double grade) {
    if (grade >= 90) return 'Outstanding';
    if (grade >= 85) return 'Very Satisfactory';
    if (grade >= 80) return 'Satisfactory';
    if (grade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  Color _getSubjectColor(String subject) {
    final colors = SMSTheme.subjectColors;
    final index = subject.hashCode % colors.length;
    return colors[index];
  }

  Color _getAssessmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return SMSTheme.errorColor;
      case 'quiz':
        return SMSTheme.warningColor;
      case 'project':
        return SMSTheme.primaryColor;
      default:
        return SMSTheme.textSecondaryColor;
    }
  }

  IconData _getAssessmentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Icons.assignment_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'project':
        return Icons.work_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  void _shareStudentReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  void _printStudentReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Print functionality will be implemented'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }
}