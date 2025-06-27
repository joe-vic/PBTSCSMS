import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/student_model.dart';
import '../widgets/student_card.dart';
import '../services/parent_data_service.dart';

/// 🎯 PURPOSE: Students management tab
/// 📝 WHAT IT SHOWS: List of enrolled students with their info
/// 🔧 HOW TO USE: StudentsTab(tabController: myTabController)
class StudentsTab extends StatefulWidget {
  final TabController? tabController;
  
  const StudentsTab({
    super.key,
    this.tabController,
  });

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  // 📊 DATA VARIABLES
  final ParentDataService _dataService = ParentDataService();
  List<StudentModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  /// 📥 Loads student data
  Future<void> _loadStudents() async {
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
            content: Text('Error loading students: $e'),
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
      onRefresh: _loadStudents,
      color: SMSTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📋 HEADER SECTION
            _buildHeaderSection(),
            const SizedBox(height: 24),
            
            // 👨‍🎓 STUDENTS LIST
            if (_students.isEmpty)
              _buildEmptyState()
            else
              _buildStudentsList(),
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
            'Loading Students...',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Builds header with title and add student button
  Widget _buildHeaderSection() {
    return Row(
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
              if (_students.isNotEmpty)
                Text(
                  '${_students.length} student${_students.length == 1 ? '' : 's'} enrolled',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddStudentDialog,
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
    );
  }

  /// 🫙 Shows empty state when no students
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
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
            padding: const EdgeInsets.all(24),
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
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Students Enrolled Yet',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start your educational journey by\nenrolling your first student',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              color: SMSTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddStudentDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: Text(
              'Add Your First Student',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👨‍🎓 Builds the list of students
  Widget _buildStudentsList() {
    return Column(
      children: _students.map((student) => StudentCard(
        student: student,
        onViewDetails: () => _viewStudentDetails(student),
        onViewAttendance: () => _viewStudentAttendance(student),
        onPayFees: () => _payStudentFees(student),
      )).toList(),
    );
  }

  /// 📖 View student details
  void _viewStudentDetails(StudentModel student) {
    // Navigate to student detail screen
    // This would be implemented with the existing StudentDetailScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${student.name}'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  /// 📅 View student attendance
  void _viewStudentAttendance(StudentModel student) {
    // Navigate to attendance tab
    widget.tabController?.animateTo(3);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing attendance for ${student.name}'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  /// 💰 Pay student fees
  void _payStudentFees(StudentModel student) {
    // Navigate to payments tab
    widget.tabController?.animateTo(2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Managing fees for ${student.name}'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  /// ➕ Show add student dialog
  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Student',
          style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 48,
              color: SMSTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Student enrollment feature will be available soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact the school administration for enrollment assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(fontFamily: 'Poppins',)),
          ),
        ],
      ),
    );
  }
}