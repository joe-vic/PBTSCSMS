import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/student_model.dart';
import '../widgets/metric_cards.dart';
import '../services/parent_data_service.dart';

/// 🎯 PURPOSE: DepEd-compliant attendance monitoring tab
/// 📝 WHAT IT SHOWS: Attendance overview, monthly breakdown, guidelines
/// 🔧 HOW TO USE: AttendanceTab()
class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  // 📊 DATA VARIABLES
  final ParentDataService _dataService = ParentDataService();
  List<StudentModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  /// 📥 Loads attendance data
  Future<void> _loadAttendanceData() async {
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
            content: Text('Error loading attendance: $e'),
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
      onRefresh: _loadAttendanceData,
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
            
            // 📊 ATTENDANCE OVERVIEW
            _buildAttendanceOverview(),
            const SizedBox(height: 24),
            
            // 📅 MONTHLY ATTENDANCE
            _buildMonthlyAttendanceSection(),
            const SizedBox(height: 24),
            
            // ℹ️ ATTENDANCE GUIDELINES
            _buildAttendanceGuidelines(),
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
            'Loading Attendance...',
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
          'DepEd Attendance Monitoring',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track student attendance as per DepEd Order No. 8, s. 2015',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 📊 Builds family attendance overview
  Widget _buildAttendanceOverview() {
    if (_students.isEmpty) {
      return _buildEmptyAttendance();
    }

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
            _getAttendanceDescription(familyAttendance),
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
              _buildOverviewStat('Avg Days Present', 
                  '${(_students.map((s) => s.attendance.daysPresent).reduce((a, b) => a + b) / _students.length).toStringAsFixed(0)}',
                  Colors.white),
              _buildOverviewStat('School Days', '180', Colors.white),
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

  /// 🫙 Shows empty attendance state
  Widget _buildEmptyAttendance() {
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
              Icons.calendar_today_outlined,
              size: 48,
              color: SMSTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Attendance Records',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendance records will appear here once students are enrolled',
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

  /// 📅 Builds monthly attendance section
  Widget _buildMonthlyAttendanceSection() {
    if (_students.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Attendance Summary',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._students.map((student) => _buildAttendanceCard(student)).toList(),
      ],
    );
  }

  /// 👤 Builds individual student attendance card
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
            
            // 📊 MONTHLY BREAKDOWN
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
                  return _buildMonthCard(month);
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // 📈 PROGRESS BAR
            _buildAttendanceProgress(student),
          ],
        ),
      ),
    );
  }

  /// 📅 Builds individual month card
  Widget _buildMonthCard(MonthlyAttendance month) {
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
          // 📅 MONTH HEADER
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
          
          // 📊 PERCENTAGE
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
          
          // 📋 DETAILS
          Column(
            children: [
              _buildMonthDetail('P:', '${month.present}', SMSTheme.successColor),
              _buildMonthDetail('A:', '${month.absent}', SMSTheme.errorColor),
              _buildMonthDetail('L:', '${month.late}', SMSTheme.warningColor),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Builds month detail row
  Widget _buildMonthDetail(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 📈 Builds attendance progress bar
  Widget _buildAttendanceProgress(StudentModel student) {
    return Column(
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
    );
  }

  /// ℹ️ Builds DepEd attendance guidelines
  Widget _buildAttendanceGuidelines() {
    return InfoCard(
      title: 'DepEd Attendance Guidelines',
      color: Colors.amber,
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  // 🎨 HELPER METHODS

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 95) return SMSTheme.progressExcellent;
    if (percentage >= 85) return SMSTheme.progressGood;
    if (percentage >= 75) return SMSTheme.progressAverage;
    return SMSTheme.progressPoor;
  }

  String _getAttendanceDescription(double percentage) {
    if (percentage >= 95) return 'Excellent Attendance!';
    if (percentage >= 85) return 'Good Attendance';
    if (percentage >= 75) return 'Needs Improvement';
    return 'Poor Attendance';
  }
}