import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../../models/student_model.dart';
import '../../../config/theme.dart';
import '../student_detail_screen.dart';

/// 🎯 PURPOSE: Beautiful card showing student summary
/// 📝 WHAT IT SHOWS: Avatar, name, grades, attendance, actions
/// 🔧 HOW TO USE: StudentCard(student: myStudent, onViewAttendance: () {})
class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback? onViewDetails;
  final VoidCallback? onViewAttendance;
  final VoidCallback? onPayFees;

  const StudentCard({
    super.key,
    required this.student,
    this.onViewDetails,
    this.onViewAttendance,
    this.onPayFees,
  });

  @override
  Widget build(BuildContext context) {
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
              // 👤 STUDENT HEADER
              _buildStudentHeader(),
              const SizedBox(height: 20),
              
              // 📊 PERFORMANCE METRICS
              _buildPerformanceMetrics(context),
              const SizedBox(height: 16),
              
              // 🎯 ACTION BUTTONS
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 👤 Builds student header with avatar, info, and GPA
  Widget _buildStudentHeader() {
    return Row(
      children: [
        // 📸 AVATAR WITH STATUS RING
        _buildAvatarWithStatusRing(),
        const SizedBox(width: 16),
        
        // ℹ️ STUDENT INFO
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
        
        // 🏆 GPA BADGE
        _buildGPABadge(),
      ],
    );
  }

  /// 📸 Avatar with colored ring showing attendance status
  Widget _buildAvatarWithStatusRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 🎨 STATUS RING
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
        // 👤 ACTUAL AVATAR
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
                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
                  )
                : _buildAvatarFallback(),
          ),
        ),
      ],
    );
  }

  /// 🎨 Creates fallback avatar with student initials
  Widget _buildAvatarFallback() {
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

  /// 🏆 Creates GPA badge with color coding
  Widget _buildGPABadge() {
    return Container(
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
    );
  }

  /// 📊 Builds performance metrics with responsive layout
  Widget _buildPerformanceMetrics(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 400) {
          // 📱 WIDE SCREEN: Side by side
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
          // 📱 NARROW SCREEN: Stacked
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
    );
  }

  /// 📊 Creates a single metric card
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

  /// 🎯 Builds action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton('View Details', Icons.visibility, () {
          if (onViewDetails != null) {
            onViewDetails!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDetailScreen(student: student),
              ),
            );
          }
        }),
        _buildActionButton('Attendance', Icons.calendar_today, onViewAttendance),
        _buildActionButton('Pay Fees', Icons.payment, onPayFees),
      ],
    );
  }

  /// 🔘 Creates a single action button
  Widget _buildActionButton(String label, IconData icon, VoidCallback? onTap) {
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

  // 🎨 COLOR HELPER METHODS

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 95) return SMSTheme.progressExcellent;
    if (percentage >= 85) return SMSTheme.progressGood;
    if (percentage >= 75) return SMSTheme.progressAverage;
    return SMSTheme.progressPoor;
  }

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
}