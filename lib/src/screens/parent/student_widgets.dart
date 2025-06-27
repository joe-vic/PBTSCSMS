import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../models/student_model.dart';
import '../../config/theme.dart';
import 'student_detail_screen.dart';

class StudentSpotlightSection extends StatelessWidget {
  final List<StudentModel> students;

  const StudentSpotlightSection({
    Key? key,
    required this.students,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedHeader(),
        const SizedBox(height: 16),
        _buildStudentGrid(),
      ],
    );
  }

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
                    color: SMSTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: SMSTheme.spotlightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${students.length} ${students.length == 1 ? 'student' : 'students'} enrolled',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_calculateAverageGPA().toStringAsFixed(1)} GPA',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildStudentGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Better responsive design with proper aspect ratios
        if (constraints.maxWidth > 800) {
          // Desktop: 3 columns with good spacing
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75, // Taller cards for better design
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildBeautifulStudentCard(
                  context, students[index], index, 'desktop');
            },
          );
        } else if (constraints.maxWidth > 600) {
          // Tablet: 2 columns
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8, // Good ratio for tablets
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildBeautifulStudentCard(
                  context, students[index], index, 'tablet');
            },
          );
        } else {
          // Mobile: Single column with horizontal cards
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMobileStudentCard(context, students[index], index),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildBeautifulStudentCard(BuildContext context, StudentModel student,
      int index, String deviceType) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SMSTheme.cardColor,
                    SMSTheme.spotlightBackground,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SMSTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: SMSTheme.spotlightBorder,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Student Avatar with beautiful proportions
                    _buildStudentAvatar(student),
                    const SizedBox(height: 20),

                    // Student Name with proper spacing
                    Text(
                      student.name,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: deviceType == 'desktop' ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: SMSTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Grade Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SMSTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SMSTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${student.grade} • ${student.className}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SMSTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Attendance Progress
                    _buildAttendanceProgress(student),
                    const SizedBox(height: 24),

                    // View Details Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _navigateToStudentDetails(context, student),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SMSTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'View Details',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileStudentCard(
      BuildContext context, StudentModel student, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SMSTheme.cardColor,
                    SMSTheme.spotlightBackground,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: SMSTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: SMSTheme.spotlightBorder,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar on the left
                    _buildMobileAvatar(student),
                    const SizedBox(width: 16),

                    // Content in the middle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: SMSTheme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SMSTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${student.grade} • ${student.className}',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: SMSTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMobileAttendanceProgress(student),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Button on the right
                    ElevatedButton(
                      onPressed: () =>
                          _navigateToStudentDetails(context, student),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SMSTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentAvatar(StudentModel student) {
    final attendanceColor =
        _getAttendanceStatusColor(student.attendance.percentage);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Status Ring
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: attendanceColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: attendanceColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 0),
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getAvatarGradient(student.name),
          ),
          child: ClipOval(
            child: student.profileImage != null
                ? Image.network(
                    student.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarFallback(student),
                  )
                : _buildAvatarFallback(student),
          ),
        ),
        // GPA Badge
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMSTheme.successColor, SMSTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: SMSTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${student.academics.gpa.toStringAsFixed(1)}',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 10,
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

  Widget _buildMobileAvatar(StudentModel student) {
    final attendanceColor =
        _getAttendanceStatusColor(student.attendance.percentage);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: attendanceColor, width: 2),
            gradient: _getAvatarGradient(student.name),
          ),
          child: ClipOval(
            child: student.profileImage != null
                ? Image.network(
                    student.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildMobileAvatarFallback(student),
                  )
                : _buildMobileAvatarFallback(student),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${student.academics.gpa.toStringAsFixed(1)}',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 8,
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

  Widget _buildAvatarFallback(StudentModel student) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getAvatarGradient(student.name),
      ),
      child: Center(
        child: Text(
          student.name.split(' ').map((n) => n[0]).take(2).join(),
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAvatarFallback(StudentModel student) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getAvatarGradient(student.name),
      ),
      child: Center(
        child: Text(
          student.name.split(' ').map((n) => n[0]).take(2).join(),
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceProgress(StudentModel student) {
    final currentMonth = _getCurrentMonthAttendance(student);
    final percentage =
        currentMonth?.percentage ?? student.attendance.percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Month Attendance',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _getAttendanceStatusColor(percentage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percentage / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: _getProgressGradient(percentage),
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (currentMonth != null)
          Text(
            '${currentMonth.present}P • ${currentMonth.absent}A • ${currentMonth.late}L',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 11,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildMobileAttendanceProgress(StudentModel student) {
    final currentMonth = _getCurrentMonthAttendance(student);
    final percentage =
        currentMonth?.percentage ?? student.attendance.percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendance',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getAttendanceStatusColor(percentage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percentage / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: _getProgressGradient(percentage),
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.cardColor,
            SMSTheme.spotlightBackground,
          ],
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
          color: SMSTheme.spotlightBorder,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
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

  // Helper Methods remain the same
  void _navigateToStudentDetails(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailScreen(student: student),
      ),
    );
  }

  double _calculateAverageGPA() {
    if (students.isEmpty) return 0.0;
    return students.map((s) => s.academics.gpa).reduce((a, b) => a + b) /
        students.length;
  }

  MonthlyAttendance? _getCurrentMonthAttendance(StudentModel student) {
    final now = DateTime.now();
    return student.attendance.monthlyRecords
            .where((m) =>
                m.month == _getMonthName(now.month) && m.year == now.year)
            .isNotEmpty
        ? student.attendance.monthlyRecords.firstWhere(
            (m) => m.month == _getMonthName(now.month) && m.year == now.year)
        : null;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Color _getAttendanceStatusColor(double percentage) {
    if (percentage >= 95) return SMSTheme.progressExcellent;
    if (percentage >= 85) return SMSTheme.progressGood;
    if (percentage >= 75) return SMSTheme.progressAverage;
    return SMSTheme.progressPoor;
  }

  List<Color> _getProgressGradient(double percentage) {
    if (percentage >= 95)
      return [SMSTheme.progressExcellent, SMSTheme.successColor];
    if (percentage >= 85)
      return [SMSTheme.progressGood, SMSTheme.progressExcellent];
    if (percentage >= 75)
      return [SMSTheme.progressAverage, SMSTheme.progressGood];
    return [SMSTheme.progressPoor, SMSTheme.progressAverage];
  }

  LinearGradient _getAvatarGradient(String name) {
    final gradients = [
      LinearGradient(colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor]),
      LinearGradient(colors: [SMSTheme.successColor, SMSTheme.primaryColor]),
      LinearGradient(colors: [SMSTheme.warningColor, SMSTheme.successColor]),
      LinearGradient(colors: [SMSTheme.accentColor, SMSTheme.warningColor]),
    ];

    final index = name.hashCode % gradients.length;
    return gradients[index];
  }
}
