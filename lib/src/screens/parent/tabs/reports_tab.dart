import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/student_model.dart';
import '../widgets/metric_cards.dart';
import '../services/parent_data_service.dart';
import '../student_detail_screen.dart';

/// 🎯 PURPOSE: DepEd K-12 academic reports and grades tab
/// 📝 WHAT IT SHOWS: Academic performance, report cards, grading system
/// 🔧 HOW TO USE: ReportsTab()
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  // 📊 DATA VARIABLES
  final ParentDataService _dataService = ParentDataService();
  List<StudentModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  /// 📥 Loads reports data
  Future<void> _loadReportsData() async {
    try {
      setState(() => _isLoading = true);
      
      final students = await _dataService.getStudents();
      
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
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
      onRefresh: _loadReportsData,
      color: SMSTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📋 HEADER
            _buildHeaderSection(),
            const SizedBox(height: 24),
            
            // 📊 ACADEMIC OVERVIEW
            _buildAcademicOverview(),
            const SizedBox(height: 24),
            
            // 📑 STUDENT REPORTS
            _buildStudentReportsSection(),
            const SizedBox(height: 24),
            
            // ℹ️ GRADING SYSTEM INFO
            _buildGradingSystemInfo(),
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
            'Loading Reports...',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Builds header section
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DepEd K-12 Academic Reports',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Comprehensive academic progress reports based on K-12 curriculum',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 📊 Builds family academic performance overview
  Widget _buildAcademicOverview() {
    if (_students.isEmpty) {
      return _buildEmptyReports();
    }

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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOverviewStat('Students', '${_students.length}', Colors.white),
              _buildOverviewStat('Avg Rank', 
                  '${(_students.map((s) => s.academics.rank).reduce((a, b) => a + b) / _students.length).toStringAsFixed(0)}',
                  Colors.white),
              _buildOverviewStat('Quarter', '2nd', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Builds overview stat
  Widget _buildOverviewStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// 🫙 Shows empty reports state
  Widget _buildEmptyReports() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 48,
              color: SMSTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Academic Reports',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Academic reports will appear here once students are enrolled',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📑 Builds student reports section
  Widget _buildStudentReportsSection() {
    if (_students.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Student Reports',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._students.map((student) => _buildReportCard(student)).toList(),
      ],
    );
  }

  /// 📑 Builds individual student report card
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
            // 👤 STUDENT HEADER
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
            
            // 📚 SUBJECT GRADES
            Text(
              'Subject Performance (Current Quarter)',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            ...student.academics.subjects.take(4).map((subject) => _buildSubjectGrade(subject)).toList(),
            
            if (student.academics.subjects.length > 4)
              Center(
                child: TextButton(
                  onPressed: () => _showAllSubjects(student),
                  child: Text(
                    'View All ${student.academics.subjects.length} Subjects',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: SMSTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 📊 ACADEMIC METRICS
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
            
            // 📋 VIEW FULL REPORT BUTTON
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

  /// 📚 Builds subject grade row
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

  /// 📊 Builds report metric card
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

  /// ℹ️ Builds DepEd grading system information
  Widget _buildGradingSystemInfo() {
    return InfoCard(
      title: 'DepEd K-12 Grading System',
      color: Colors.green,
      icon: Icons.grade_outlined,
      child: _buildGradeScale(),
    );
  }

  /// 📊 Builds grade scale
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

  /// 📚 Show all subjects dialog
  void _showAllSubjects(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${student.name} - All Subjects',
          style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: student.academics.subjects.length,
            itemBuilder: (context, index) {
              final subject = student.academics.subjects[index];
              return _buildSubjectGrade(subject);
            },
          ),
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

  // 🎨 HELPER METHODS

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
}