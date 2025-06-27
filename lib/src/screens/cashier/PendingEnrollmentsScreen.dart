import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';  // ADD THIS
import '../../config/theme.dart';
import 'enrollment/screens/enrollment_screen.dart';
// import 'CashierEnrollmentScreen.dart';


class PendingEnrollmentsScreen extends StatefulWidget {
  const PendingEnrollmentsScreen({super.key});

  @override
  _PendingEnrollmentsScreenState createState() => _PendingEnrollmentsScreenState();
}




class _PendingEnrollmentsScreenState extends State<PendingEnrollmentsScreen> {
  // Search and filter state
  String _searchQuery = '';
  String _selectedGradeFilter = 'All';
  String _selectedCourseFilter = 'All';
  bool _canFetchEnrollments = false; // State variable to control stream activation

  bool _isRefreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  String _formatFullName(Map<String, dynamic> info) {
    final lastName = info['lastName'] as String? ?? '';
    final firstName = info['firstName'] as String? ?? '';
    final middleName = info['middleName'] as String? ?? '';
    return '$lastName, $firstName${middleName.isNotEmpty ? ' $middleName' : ''}'.trim();
  }
 



 

  // Method to process pending enrollment (opens cashier screen with pre-filled data)
  void _processPendingEnrollment(Map<String, dynamic> enrollmentData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashierEnrollmentScreenImpl(
          // isWalkIn: false,                           // Not a walk-in, it's processing pending
          // pendingEnrollmentId: enrollmentData['id'], // Pass the pending enrollment ID
          // pendingEnrollmentData: enrollmentData,     // Pass the data to pre-fill
        ),
      ),
    );
  }


  // Method to show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          title: Text(
            'Search Students',
            style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
          ),
         content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search by:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Student name (e.g., "Juan Dela Cruz")\n• Enrollment ID (e.g., "PBTS-BIL-2025-4299")',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => tempQuery = value,
                decoration: InputDecoration(
                  hintText: 'Enter student name or enrollment ID...',
                  hintStyle: TextStyle(fontFamily: 'Poppins',fontSize: 14),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(fontFamily: 'Poppins',),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
              ),
              child: Text(
                'Search',
                style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempGradeFilter = _selectedGradeFilter;
        String tempCourseFilter = _selectedCourseFilter;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Filter Enrollments',
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade Level:',
                    style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempGradeFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['All', 'NKP', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12', 'College']
                        .map((grade) => DropdownMenuItem(
                              value: grade,
                              child: Text(grade, style: TextStyle(fontFamily: 'Poppins',)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        tempGradeFilter = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Course:',
                    style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempCourseFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['All', 'BSIT', 'BSBA', 'BSED', 'BEED', 'Other']
                        .map((course) => DropdownMenuItem(
                              value: course,
                              child: Text(course, style: TextStyle(fontFamily: 'Poppins',)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        tempCourseFilter = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedGradeFilter = 'All';
                      _selectedCourseFilter = 'All';
                      _searchQuery = '';
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(fontFamily: 'Poppins',color: Colors.orange.shade600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGradeFilter = tempGradeFilter;
                      _selectedCourseFilter = tempCourseFilter;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SMSTheme.primaryColor,
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Enhanced refresh method with loading state
  Future<void> _refreshEnrollments() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _canFetchEnrollments = false;
    });
    
    try {
      // Clear filters when refreshing
      _searchQuery = '';
      _selectedGradeFilter = 'All';
      _selectedCourseFilter = 'All';
      
      // Wait a bit to ensure the stream resets
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _canFetchEnrollments = true;
      });
      
      // Wait a bit more to show the refresh
      await Future.delayed(const Duration(milliseconds: 500));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Enrollments refreshed successfully!',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            ],
          ),
          backgroundColor: SMSTheme.successColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to refresh: $e',
            style: TextStyle(fontFamily: 'Poppins',),
          ),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // Method to view enrollment details (read-only)
 
  // ===================================================================
  // COMPLETE ENHANCED ENROLLMENT DETAILS MODAL IMPLEMENTATION
  // ===================================================================

  // Main method to view enrollment details (responsive)
  void _viewEnrollmentDetails(Map<String, dynamic> enrollmentData) {
  showDialog(
    context: context,
    builder: (context) {
      // Get screen dimensions for responsive design
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isDesktop = screenWidth > 768;
      final isTablet = screenWidth > 480 && screenWidth <= 768;
      final isMobile = screenWidth <= 480;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.all(isDesktop ? 64 : 16),
        child: Container(
          width: isDesktop
              ? screenWidth * 0.6  // Increased width for better desktop experience
              : isTablet
                  ? screenWidth * 0.85
                  : screenWidth,
          height: isDesktop ? screenHeight * 0.8 : screenHeight * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // ===== ENHANCED HEADER =====
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SMSTheme.primaryColor,
                      SMSTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_ind,
                      color: Colors.white,
                      size: isDesktop ? 28 : 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //FOR VIEWING ENROLLMENT DETAILS
                          //HEADER TEXT
                          Text(
                            'Enrollment Details',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 24 : 20,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ID: ${enrollmentData['id'] ?? 'N/A'}',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: isDesktop ? 14 : 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white, size: isDesktop ? 28 : 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== CONTENT AREA =====
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: isDesktop
                      ? Row( // Desktop: Two-column layout
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildLeftColumnEnhanced(enrollmentData, isDesktop),
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildRightColumnEnhanced(enrollmentData, isDesktop),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView( // Mobile/Tablet: Single column
                          physics: BouncingScrollPhysics(),
                          child: _buildSingleColumnEnhanced(enrollmentData, isDesktop),
                        ),
                ),
              ),

              // ===== ENHANCED ACTION BUTTONS =====
              Container(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: isDesktop
                    ? Row( // Desktop: Horizontal buttons
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, size: 18),
                            label: Text('Close'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _processPendingEnrollment(enrollmentData);
                            },
                            icon: Icon(Icons.check_circle, size: 18),
                            label: Text('Process Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SMSTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 2,
                            ),
                          ),
                        ],
                      )
                    : Row( // Mobile: Full-width buttons
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _processPendingEnrollment(enrollmentData);
                              },
                              icon: Icon(Icons.check_circle, size: 18),
                              label: Text('Process Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SMSTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // ===================================================================
  // ENHANCED COLUMN LAYOUTS
  // ===================================================================

  // Enhanced single column (mobile/tablet)
  Widget _buildSingleColumnEnhanced(Map<String, dynamic> enrollmentData, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Information Card - USING NEW METHOD
        _buildStudentInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Address Information Card - KEEP EXISTING
        _buildInfoCard(
          title: 'Address Information',
          icon: Icons.home,
          color: Colors.orange,
          children: [
            _buildAddressCard(enrollmentData['studentInfo']?['address']),
          ],
        ),
        SizedBox(height: 16),
        
        // Educational Background Card - USING NEW METHOD
        _buildEducationalInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Payment Information Card - USING NEW METHOD
        _buildPaymentInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Parent/Guardian Information Card - USING NEW METHOD
        _buildParentInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Submission & Status Information Card - USING NEW METHOD
        _buildSubmissionInfoCardFixed(enrollmentData),
      ],
    );
  }
  
  // Enhanced left column (desktop)
  Widget _buildLeftColumnEnhanced(Map<String, dynamic> enrollmentData, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Information Card - USING NEW METHOD
        _buildStudentInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Address Information Card - KEEP EXISTING
        _buildInfoCard(
          title: 'Address Information',
          icon: Icons.home,
          color: Colors.orange,
          children: [
            _buildAddressCard(enrollmentData['studentInfo']?['address']),
          ],
        ),
        SizedBox(height: 16),
        
        // Educational Background Card - USING NEW METHOD
        _buildEducationalInfoCardFixed(enrollmentData),
      ],
    );
  }
  
  // Enhanced right column (desktop)
  Widget _buildRightColumnEnhanced(Map<String, dynamic> enrollmentData, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Information Card - USING NEW METHOD
        _buildPaymentInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Parent/Guardian Information Card - USING NEW METHOD
        _buildParentInfoCardFixed(enrollmentData),
        SizedBox(height: 16),
        
        // Submission & Status Information Card - USING NEW METHOD
        _buildSubmissionInfoCardFixed(enrollmentData),
      ],
    );
  }


    // ===================================================================
    // ENHANCED UI COMPONENTS
    // ===================================================================

    // Main info card component
    Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

    // Enhanced detail row with icon
    Widget _buildEnhancedDetailRow(String label, dynamic value, IconData icon) {
        String displayValue = _formatValueToString(value);
        
        // Skip empty or meaningless values
        if (displayValue == 'N/A' || displayValue.isEmpty) {
          return SizedBox.shrink();
        }
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: Colors.grey.shade600),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      displayValue,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    
    // Special payment card
    Widget _buildPaymentCard(String amount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.attach_money, color: Colors.green.shade700, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount Due',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '₱$amount',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    
    Widget _buildStudentInfoCardFixed(Map<String, dynamic> enrollmentData) {
      final studentInfo = enrollmentData['studentInfo'] ?? {};
      
      return _buildInfoCard(
        title: 'Student Information',
        icon: Icons.person,
        color: Colors.blue,
        children: [
          _buildEnhancedDetailRow(
            'Full Name', 
            _formatFullName(studentInfo), 
            Icons.badge
          ),
          _buildEnhancedDetailRow(
            'Enrollment ID', 
            enrollmentData['id'] ?? enrollmentData['enrollmentId'] ?? 'N/A', 
            Icons.fingerprint
          ),
          _buildEnhancedDetailRow(
            'Grade Level', 
            studentInfo['gradeLevel'] ?? 'N/A', 
            Icons.school
          ),
          _buildEnhancedDetailRow(
            'Branch', 
            studentInfo['branch'] ?? 'N/A', 
            Icons.location_on
          ),
          if (studentInfo['strand']?.isNotEmpty ?? false)
            _buildEnhancedDetailRow(
              'Strand', 
              studentInfo['strand'], 
              Icons.timeline
            ),
          if (studentInfo['course']?.isNotEmpty ?? false)
            _buildEnhancedDetailRow(
              'Course', 
              studentInfo['course'], 
              Icons.library_books
            ),
          _buildEnhancedDetailRow(
            'Gender', 
            studentInfo['gender'] ?? 'N/A', 
            Icons.wc
          ),
          _buildEnhancedDetailRow(
            'Date of Birth', 
            _formatValueToString(studentInfo['dateOfBirth']), 
            Icons.cake
          ),
          _buildEnhancedDetailRow(
            'Place of Birth', 
            studentInfo['placeOfBirth'] ?? 'N/A', 
            Icons.place
          ),
          if (studentInfo['religion']?.isNotEmpty ?? false)
            _buildEnhancedDetailRow(
              'Religion', 
              studentInfo['religion'], 
              Icons.church
            ),
          if (studentInfo['height']?.isNotEmpty ?? false)
            _buildEnhancedDetailRow(
              'Height', 
              studentInfo['height'], 
              Icons.height
            ),
          if (studentInfo['weight']?.isNotEmpty ?? false)
            _buildEnhancedDetailRow(
              'Weight', 
              studentInfo['weight'], 
              Icons.monitor_weight
            ),
        ],
      );
    }
    
    // Status card with badge
    Widget _buildStatusCard(String status) {
    Color statusColor = status == 'PENDING' 
        ? Colors.orange 
        : status == 'APPROVED' 
            ? Colors.green 
            : Colors.red;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, color: statusColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    // Address card with special formatting
    Widget _buildAddressCard(Map<String, dynamic>? address) {
    String fullAddress = '';
    if (address != null) {
  List<String> addressParts = [
    address['streetAddress']?.toString() ?? '',
    address['barangay']?.toString() ?? '',
    address['municipality']?.toString() ?? '',
    address['province']?.toString() ?? '',
  ].where((part) => part.isNotEmpty).toList();

      fullAddress = addressParts.join(', ');
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Address',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  fullAddress.isNotEmpty ? fullAddress : 'No address provided',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    
    // Enhanced parent/guardian info card
    Widget _buildParentInfoCardFixed(Map<String, dynamic> enrollmentData) {
        final parentInfo = enrollmentData['parentInfo'] ?? {};
        
        return _buildInfoCard(
          title: 'Parent/Guardian Information',
          icon: Icons.family_restroom,
          color: Colors.teal,
          children: [
            // Primary Contact (Root Level) - This is the main guardian/contact person
            if (parentInfo['firstName']?.isNotEmpty ?? false) ...[
              Text(
                'Primary Contact/Guardian',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 8),
              _buildEnhancedDetailRow(
                'Name', 
                _formatFullName(parentInfo), 
                Icons.person
              ),
              _buildEnhancedDetailRow(
                'Contact', 
                parentInfo['contact'] ?? 'N/A', 
                Icons.phone
              ),
              _buildEnhancedDetailRow(
                'Relationship', 
                parentInfo['relationship'] ?? 'N/A', 
                Icons.family_restroom
              ),
              if (parentInfo['facebook']?.isNotEmpty ?? false)
                _buildEnhancedDetailRow(
                  'Facebook', 
                  parentInfo['facebook'], 
                  Icons.facebook
                ),
              SizedBox(height: 16),
            ],
            
            // Alternative: Check for primaryContact object
            if (parentInfo['primaryContact'] != null && (parentInfo['firstName']?.isEmpty ?? true)) ...[
              Text(
                'Primary Contact/Guardian',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 8),
              _buildEnhancedDetailRow(
                'Name', 
                _formatFullName(parentInfo['primaryContact'] ?? {}), 
                Icons.person
              ),
              _buildEnhancedDetailRow(
                'Contact', 
                parentInfo['primaryContact']?['contact'] ?? 'N/A', 
                Icons.phone
              ),
              _buildEnhancedDetailRow(
                'Relationship', 
                parentInfo['primaryContact']?['relationship'] ?? 'N/A', 
                Icons.family_restroom
              ),
              if (parentInfo['primaryContact']?['facebook']?.isNotEmpty ?? false)
                _buildEnhancedDetailRow(
                  'Facebook', 
                  parentInfo['primaryContact']?['facebook'], 
                  Icons.facebook
                ),
              SizedBox(height: 16),
            ],
            
            // Father's Information
            if (parentInfo['father'] != null) ...[
              Text(
                'Father\'s Information',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 8),
              _buildEnhancedDetailRow(
                'Father\'s Name', 
                _formatFullName(parentInfo['father'] ?? {}), 
                Icons.person
              ),
              _buildEnhancedDetailRow(
                'Father\'s Contact', 
                parentInfo['father']?['contact'] ?? 'N/A', 
                Icons.phone
              ),
              if (parentInfo['father']?['occupation']?.isNotEmpty ?? false)
                _buildEnhancedDetailRow(
                  'Father\'s Occupation', 
                  parentInfo['father']?['occupation'], 
                  Icons.work
                ),
              if (parentInfo['father']?['facebook']?.isNotEmpty ?? false)
                _buildEnhancedDetailRow(
                  'Father\'s Facebook', 
                  parentInfo['father']?['facebook'], 
                  Icons.facebook
                ),
              SizedBox(height: 16),
            ],
            
            // Mother's Information
            if (parentInfo['mother'] != null) ...[
              Text(
                'Mother\'s Information',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 8),
              _buildEnhancedDetailRow(
                'Mother\'s Name', 
                _formatFullName(parentInfo['mother'] ?? {}), 
                Icons.person
              ),
              _buildEnhancedDetailRow(
                'Mother\'s Contact', 
                parentInfo['mother']?['contact'] ?? 'N/A', 
                Icons.phone
              ),
              if (parentInfo['mother']?['occupation']?.isNotEmpty ?? false)
                _buildEnhancedDetailRow(
                  'Mother\'s Occupation', 
                  parentInfo['mother']?['occupation'], 
                  Icons.work
                ),
              if (parentInfo['mother']?['facebook']?.isNotEmpty ?? false)
                _buildEnhancedDetailRow(
                  'Mother\'s Facebook', 
                  parentInfo['mother']?['facebook'], 
                  Icons.facebook
                ),
            ],
          ],
        );
      }


  // Educational info card with fixed structure
  Widget _buildEducationalInfoCardFixed(Map<String, dynamic> enrollmentData) {
    final educationalInfo = enrollmentData['educationalInfo'] ?? {};
    
    return _buildInfoCard(
      title: 'Educational Background',
      icon: Icons.history_edu,
      color: Colors.purple,
      children: [
        _buildEnhancedDetailRow(
          'Academic Year', 
          educationalInfo['academicYear'] ?? enrollmentData['academicYear'] ?? 'N/A', 
          Icons.calendar_today
        ),
        _buildEnhancedDetailRow(
          'Grade Level', 
          educationalInfo['gradeLevel'] ?? 'N/A', 
          Icons.school
        ),
        if (educationalInfo['course']?.isNotEmpty ?? false)
          _buildEnhancedDetailRow(
            'Course', 
            educationalInfo['course'], 
            Icons.library_books
          ),
        if (educationalInfo['strand']?.isNotEmpty ?? false)
          _buildEnhancedDetailRow(
            'Strand', 
            educationalInfo['strand'], 
            Icons.timeline
          ),
        if (educationalInfo['collegeYearLevel']?.isNotEmpty ?? false)
          _buildEnhancedDetailRow(
            'Year Level', 
            educationalInfo['collegeYearLevel'], 
            Icons.grade
          ),
        _buildEnhancedDetailRow(
          'Semester', 
          educationalInfo['semesterType'] ?? 'N/A', 
          Icons.schedule
        ),
        _buildEnhancedDetailRow(
          'Branch', 
          educationalInfo['branch'] ?? 'N/A', 
          Icons.location_on
        ),
        if (educationalInfo['lastSchoolName']?.isNotEmpty ?? false)
          _buildEnhancedDetailRow(
            'Last School', 
            educationalInfo['lastSchoolName'], 
            Icons.school_outlined
          ),
        if (educationalInfo['lastSchoolAddress']?.isNotEmpty ?? false)
          _buildEnhancedDetailRow(
            'Last School Address', 
            educationalInfo['lastSchoolAddress'], 
            Icons.location_city
          ),
        _buildEnhancedDetailRow(
          'Voucher Beneficiary', 
          (educationalInfo['isVoucherBeneficiary'] ?? false) ? 'Yes' : 'No', 
          Icons.card_giftcard
        ),
      ],
    );
  }

  // Payment info card with fixed structure
  Widget _buildPaymentInfoCardFixed(Map<String, dynamic> enrollmentData) {
      final paymentInfo = enrollmentData['paymentInfo'] ?? {};
      
      return _buildInfoCard(
        title: 'Payment Information',
        icon: Icons.payment,
        color: Colors.red,
        children: [
          // Main amount card
          _buildPaymentCard(
            (paymentInfo['totalAmountDue'] ?? 0.0).toString()
          ),
          SizedBox(height: 12),
          
          // Payment details
          _buildEnhancedDetailRow(
            'Payment Scheme', 
            paymentInfo['paymentScheme'] ?? 'N/A', 
            Icons.credit_card
          ),
          _buildEnhancedDetailRow(
            'Fee Source', 
            paymentInfo['feeSource'] ?? 'N/A', 
            Icons.source
          ),
          _buildEnhancedDetailRow(
            'Selected Payment Type', 
            paymentInfo['selectedPaymentType'] ?? 'N/A', 
            Icons.payment
          ),
          _buildEnhancedDetailRow(
            'Balance Remaining', 
            '₱${(paymentInfo['balanceRemaining'] ?? 0.0).toStringAsFixed(2)}', 
            Icons.account_balance_wallet
          ),
          _buildEnhancedDetailRow(
            'Initial Payment', 
            '₱${(paymentInfo['initialPaymentAmount'] ?? 0.0).toStringAsFixed(2)}', 
            Icons.payments
          ),
          
          // Fee breakdown
          if (paymentInfo['fees'] != null || paymentInfo['feeBreakdown'] != null) ...[
            SizedBox(height: 12),
            Text(
              'Fee Breakdown',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8),
            ...((paymentInfo['fees'] ?? paymentInfo['feeBreakdown'] ?? {}) as Map<String, dynamic>)
                .entries
                .map((entry) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontFamily: 'Poppins',fontSize: 12),
                      ),
                      Text(
                        '₱${(entry.value ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      );
    }
  
  // Submission info card with fixed structure
  Widget _buildSubmissionInfoCardFixed(Map<String, dynamic> enrollmentData) {
      final metadata = enrollmentData['metadata'] ?? {};
      final workflow = enrollmentData['workflow'] ?? {};
      
      return _buildInfoCard(
        title: 'Submission & Status Information',
        icon: Icons.info,
        color: Colors.indigo,
        children: [
          // Status
          _buildStatusCard(enrollmentData['status'] ?? 'PENDING'),
          SizedBox(height: 12),
          
          // Submission details
          _buildEnhancedDetailRow(
            'Submitted At', 
            _formatValueToString(enrollmentData['submittedAt']), 
            Icons.schedule
          ),
          _buildEnhancedDetailRow(
            'Created At', 
            _formatValueToString(enrollmentData['createdAt']), 
            Icons.create
          ),
          _buildEnhancedDetailRow(
            'Updated At', 
            _formatValueToString(enrollmentData['updatedAt']), 
            Icons.update
          ),
          _buildEnhancedDetailRow(
            'Submitted By', 
            enrollmentData['submittedByEmail'] ?? 'N/A', 
            Icons.person
          ),
          _buildEnhancedDetailRow(
            'Source', 
            enrollmentData['source'] ?? 'N/A', 
            Icons.source
          ),
          _buildEnhancedDetailRow(
            'Is Online Enrollment', 
            (enrollmentData['isOnlineEnrollment'] ?? false) ? 'Yes' : 'No', 
            Icons.computer
          ),
          
          // Workflow information
          if (workflow.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Workflow Information',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            SizedBox(height: 8),
            _buildEnhancedDetailRow(
              'Current Stage', 
              workflow['currentStage'] ?? 'N/A', 
              Icons.timeline
            ),
            _buildEnhancedDetailRow(
              'Next Stage', 
              workflow['nextStage'] ?? 'N/A', 
              Icons.next_plan
            ),
          ],
          
          // Metadata information
          if (metadata.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Additional Information',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            SizedBox(height: 8),
            _buildEnhancedDetailRow(
              'Submission Method', 
              metadata['submissionMethod'] ?? 'N/A', 
              Icons.input
            ),
            _buildEnhancedDetailRow(
              'Device Info', 
              metadata['deviceInfo'] ?? 'N/A', 
              Icons.devices
            ),
            _buildEnhancedDetailRow(
              'Branch Code', 
              metadata['branchCode'] ?? 'N/A', 
              Icons.business
            ),
            _buildEnhancedDetailRow(
              'Version', 
              metadata['version'] ?? 'N/A', 
              Icons.info
            ),
          ],
          
          // Needs Review Flag
          if (enrollmentData['needsReview'] == true) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This enrollment needs review',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
  
  // Method to confirm and delete enrollment
  void _confirmDeleteEnrollment(Map<String, dynamic> enrollmentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Enrollment',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this enrollment?',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student: ${_formatFullName(enrollmentData['studentInfo'] ?? {})}',
                    style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Grade: ${enrollmentData['studentInfo']?['gradeLevel'] ?? 'N/A'}',
                    style: TextStyle(fontFamily: 'Poppins',fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await _deleteEnrollment(enrollmentData['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }



  // Method to actually delete the enrollment from Firestore
  Future<void> _deleteEnrollment(String enrollmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(enrollmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Enrollment deleted successfully',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            ],
          ),
          backgroundColor: SMSTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting enrollment: $e',
            style: TextStyle(fontFamily: 'Poppins',),
          ),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

  // Verify authentication and role
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('User not authenticated');
    return Theme(
      data: SMSTheme.getTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Enrollments'),
        ),
        body: const Center(child: Text('User not authenticated')),
      ),
    );
  }
  print('Authenticated user ID: ${user.uid}');

  return Theme(
    data: SMSTheme.getTheme(),
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Enrollments',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'Search Students',
          ),
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter Enrollments',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshEnrollments(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SMSTheme.backgroundColor, Color(0xFFFFF7EB)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                print('Error fetching user doc: ${userSnapshot.error}');
                return Center(
                    child: Text(
                        'Error fetching user profile: ${userSnapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium));
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                print('User document does not exist for UID: ${user.uid}');
                return const Center(child: Text('User profile not found'));
              }

              final userRole = userSnapshot.data!.data() as Map<String, dynamic>;
              final role = userRole['role'] ?? 'none';
              print('User role: $role');
              if (!['admin', 'registrar', 'cashier'].contains(role)) {
                print('User does not have permission to view enrollments');
                return const Center(
                    child: Text('Permission denied: Insufficient role'));
              }

              // Set state to allow StreamBuilder to start fetching
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_canFetchEnrollments) {
                  setState(() {
                    _canFetchEnrollments = true;
                  });
                }
              });

              return StreamBuilder<QuerySnapshot>(
                stream: _canFetchEnrollments
                    ? FirebaseFirestore.instance
                        .collection('enrollments')
                        .where('status', isEqualTo: 'pending')
                        .snapshots()
                    : null,
                builder: (context, snapshot) {
                  print('Snapshot state: ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Snapshot error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${snapshot.error}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _canFetchEnrollments = false;
                                _canFetchEnrollments = true;
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print('No pending enrollments in enrollments collection');
                    return Center(
                        child: Text('No pending enrollments found.',
                            style: Theme.of(context).textTheme.bodyMedium));
                  }

                  final allEnrollments = snapshot.data!.docs;
                  print('Found ${allEnrollments.length} enrollments: ${allEnrollments.map((e) => e.data()).toList()}');

                  // Filter enrollments based on search and filter criteria
                  final filteredEnrollments = allEnrollments.where((enrollment) {
                    final enrollmentData = enrollment.data() as Map<String, dynamic>;
                    final studentInfo = enrollmentData['studentInfo'] ?? {};
                    
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final fullName = _formatFullName(studentInfo).toLowerCase();
                      final enrollmentId = enrollment.id.toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      
                      // Search in both student name and enrollment ID
                      if (!fullName.contains(query) && !enrollmentId.contains(query)) {
                        return false;
                      }
                    }
                    
                    // Grade level filter
                    if (_selectedGradeFilter != 'All') {
                      final gradeLevel = studentInfo['gradeLevel'] ?? '';
                      if (gradeLevel != _selectedGradeFilter) {
                        return false;
                      }
                    }
                    
                    // Course filter
                    if (_selectedCourseFilter != 'All') {
                      final course = studentInfo['course'] ?? '';
                      if (_selectedCourseFilter == 'Other') {
                        if (['BSIT', 'BSBA', 'BSED', 'BEED'].contains(course)) {
                          return false;
                        }
                      } else if (course != _selectedCourseFilter) {
                        return false;
                      }
                    }
                    
                    return true;
                  }).toList();
                  
                  return Column(
                    children: [
                      // Summary Statistics Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              SMSTheme.primaryColor,
                              SMSTheme.primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: SMSTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                                    'Total Pending',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${allEnrollments.length}',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (filteredEnrollments.length != allEnrollments.length) ...[
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white30,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filtered Results',
                                      style: TextStyle(fontFamily: 'Poppins',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${filteredEnrollments.length}',
                                      style: TextStyle(fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Icon(
                              Icons.pending_actions,
                              color: Colors.white70,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                      
                      // Filter status bar
                      if (_searchQuery.isNotEmpty || _selectedGradeFilter != 'All' || _selectedCourseFilter != 'All')
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SMSTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, 
                                  color: SMSTheme.primaryColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Active filters applied',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: SMSTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedGradeFilter = 'All';
                                    _selectedCourseFilter = 'All';
                                  });
                                },
                                child: Text(
                                  'Clear All',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: SMSTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // ListView with RefreshIndicator
                      Expanded(
                        child: RefreshIndicator(
                          key: _refreshIndicatorKey,
                          onRefresh: _refreshEnrollments,
                          color: SMSTheme.primaryColor,
                          child: filteredEnrollments.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _searchQuery.isNotEmpty || _selectedGradeFilter != 'All' || _selectedCourseFilter != 'All'
                                                ? Icons.search_off
                                                : Icons.inbox_outlined,
                                            size: 64,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchQuery.isNotEmpty || _selectedGradeFilter != 'All' || _selectedCourseFilter != 'All'
                                                ? 'No enrollments found'
                                                : 'No pending enrollments',
                                            style: TextStyle(fontFamily: 'Poppins',
                                              fontSize: 16,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _searchQuery.isNotEmpty || _selectedGradeFilter != 'All' || _selectedCourseFilter != 'All'
                                                ? 'Try adjusting your search or filters'
                                                : 'Pull down to refresh',
                                            style: TextStyle(fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredEnrollments.length,
                                  itemBuilder: (context, index) {
                                    final enrollment = filteredEnrollments[index];
                                    final enrollmentData =
                                        enrollment.data() as Map<String, dynamic>;
                                    
                                    final enrollmentDataWithId = {
                                      ...enrollmentData,
                                      'id': enrollment.id,
                                    };

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      child: InkWell(
                                        onTap: () => _processPendingEnrollment(enrollmentDataWithId),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  // Student avatar
                                                  CircleAvatar(
                                                    radius: 25,
                                                    backgroundColor: SMSTheme.primaryColor.withOpacity(0.1),
                                                    child: Text(
                                                      '${enrollmentData['studentInfo']?['firstName']?[0] ?? ''}${enrollmentData['studentInfo']?['lastName']?[0] ?? ''}'
                                                          .toUpperCase(),
                                                      style: TextStyle(fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.bold,
                                                        color: SMSTheme.primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  
                                                  // Student info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          _formatFullName(enrollmentData['studentInfo'] ?? {}),
                                                          style: TextStyle(fontFamily: 'Poppins',
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Grade: ${enrollmentData['studentInfo']?['gradeLevel'] ?? 'N/A'}',
                                                          style: TextStyle(fontFamily: 'Poppins',
                                                            fontSize: 14,
                                                            color: Colors.grey.shade700,
                                                          ),
                                                        ),
                                                        Text(
                                                          'ID: ${enrollmentDataWithId['id']}',
                                                          style: TextStyle(fontFamily: 'Poppins',
                                                            fontSize: 12,
                                                            color: Colors.blue.shade600,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        if (enrollmentData['studentInfo']?['strand']?.isNotEmpty ?? false)
                                                          Text(
                                                            'Strand: ${enrollmentData['studentInfo']?['strand']}',
                                                            style: TextStyle(fontFamily: 'Poppins',
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        if (enrollmentData['studentInfo']?['course']?.isNotEmpty ?? false)
                                                          Text(
                                                            'Course: ${enrollmentData['studentInfo']?['course']}',
                                                            style: TextStyle(fontFamily: 'Poppins',
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  
                                                  // Actions menu
                                                  PopupMenuButton<String>(
                                                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                                                    onSelected: (value) {
                                                      switch (value) {
                                                        case 'process':
                                                          _processPendingEnrollment(enrollmentDataWithId);
                                                          break;
                                                        case 'view_details':
                                                          _viewEnrollmentDetails(enrollmentDataWithId);
                                                          break;
                                                        case 'delete':
                                                          _confirmDeleteEnrollment(enrollmentDataWithId);
                                                          break;
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'process',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.payment, color: SMSTheme.primaryColor, size: 20),
                                                            SizedBox(width: 8),
                                                            Text('Process Enrollment', style: TextStyle(fontFamily: 'Poppins',)),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'view_details',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.visibility, color: Colors.blue, size: 20),
                                                            SizedBox(width: 8),
                                                            Text('View Details', style: TextStyle(fontFamily: 'Poppins',)),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete, color: Colors.red, size: 20),
                                                            SizedBox(width: 8),
                                                            Text('Delete', style: TextStyle(fontFamily: 'Poppins',)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 12),
                                              
                                              // Status and action row
                                              Row(
                                                children: [
                                                  // Status badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'PENDING',
                                                      style: TextStyle(fontFamily: 'Poppins',
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  
                                                  const Spacer(),
                                                  
                                                  // Quick process button
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: SMSTheme.primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: SMSTheme.primaryColor.withOpacity(0.3)),
                                                    ),
                                                    child: InkWell(
                                                      onTap: () => _processPendingEnrollment(enrollmentDataWithId),
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.payment, 
                                                              color: SMSTheme.primaryColor, size: 16),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            'PROCESS NOW',
                                                            style: TextStyle(fontFamily: 'Poppins',
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: SMSTheme.primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshEnrollments,
        backgroundColor: SMSTheme.primaryColor,
        icon: Icon(
          _isRefreshing ? Icons.refresh : Icons.refresh,
          color: Colors.white,
        ),
        label: Text(
          _isRefreshing ? 'Refreshing...' : 'Refresh',
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

  //HERE IS THE CODE
  // Helper method to safely convert any value to string
    String _formatValueToString(dynamic value) {
      if (value == null) return 'N/A';
      
      if (value is Timestamp) {
        try {
          return DateFormat('MMM dd, yyyy - hh:mm a').format(value.toDate());
        } catch (e) {
          return 'Invalid Date';
        }
      }
      
      if (value is DateTime) {
        try {
          return DateFormat('MMM dd, yyyy - hh:mm a').format(value);
        } catch (e) {
          return 'Invalid Date';
        }
      }
      
      if (value is Map<String, dynamic>) {
        // Handle special map cases like address
        if (value.containsKey('streetAddress') || value.containsKey('barangay')) {
          return _formatAddress(value);
        }
        return 'Complex Object';
      }
      
      if (value is List) {
        if (value.isEmpty) return 'None';
        return '${value.length} items';
      }
          
      if (value is bool) {
        return value ? 'Yes' : 'No';
      }
      
      if (value is num) {
        if (value == 0) return '0';
        return value.toString();
      }
      
      String stringValue = value.toString().trim();
      if (stringValue.isEmpty) return 'N/A';
      
      return stringValue;
    }
    
    // Helper method to format address
    String _formatAddress(Map<String, dynamic>? address) {
      if (address == null) return 'No address provided';
      
      List<String> addressParts = [
        address['streetAddress']?.toString().trim() ?? '',
        address['barangay']?.toString().trim() ?? '',
        address['municipality']?.toString().trim() ?? '',
        address['province']?.toString().trim() ?? '',
      ].where((part) => part.isNotEmpty).toList();

      if (addressParts.isEmpty) return 'No address provided';
      
      return addressParts.join(', ');
    }
}

// The rest of the code (EnrollmentDetailsScreen) remains unchanged
class EnrollmentDetailsScreen extends StatefulWidget {
  final String enrollmentId;
  final Map<String, dynamic> enrollmentData;

  const EnrollmentDetailsScreen(
      {super.key, required this.enrollmentId, required this.enrollmentData});

  @override
  _EnrollmentDetailsScreenState createState() => _EnrollmentDetailsScreenState();
}

class _EnrollmentDetailsScreenState extends State<EnrollmentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _paymentRecorded = false;
  double _paymentAmount = 0.0;
  String _paymentType = 'Downpayment'; // Options: Downpayment, Full, Partial

  // Controllers for editable fields
  late TextEditingController _studentFirstNameController;
  late TextEditingController _studentLastNameController;
  late TextEditingController _studentMiddleNameController;
  late TextEditingController _gradeLevelController;
  late TextEditingController _strandController;
  late TextEditingController _courseController;
  late TextEditingController _parentFirstNameController;
  late TextEditingController _parentLastNameController;
  late TextEditingController _parentContactController;
  late TextEditingController _parentFacebookController;
  late TextEditingController _paymentAmountController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _studentFirstNameController = TextEditingController(
        text: widget.enrollmentData['studentInfo']?['firstName'] ?? '');
    _studentLastNameController = TextEditingController(
        text: widget.enrollmentData['studentInfo']?['lastName'] ?? '');
    _studentMiddleNameController = TextEditingController(
        text: widget.enrollmentData['studentInfo']?['middleName'] ?? '');
    _gradeLevelController = TextEditingController(
        text: widget.enrollmentData['studentInfo']?['gradeLevel'] ?? '');
    _strandController = TextEditingController(
        text: widget.enrollmentData['studentInfo']?['strand'] ?? '');
    _courseController = TextEditingController(
        text: widget.enrollmentData['studentInfo']?['course'] ?? '');
    _parentFirstNameController = TextEditingController(
        text: widget.enrollmentData['parentInfo']?['firstName'] ?? '');
    _parentLastNameController = TextEditingController(
        text: widget.enrollmentData['parentInfo']?['lastName'] ?? '');
    _parentContactController = TextEditingController(
        text: widget.enrollmentData['parentInfo']?['contact'] ?? '');
    _parentFacebookController = TextEditingController(
        text: widget.enrollmentData['parentInfo']?['facebook'] ?? '');
    _paymentAmountController = TextEditingController();
  }




  @override
  void dispose() {
    _studentFirstNameController.dispose();
    _studentLastNameController.dispose();
    _studentMiddleNameController.dispose();
    _gradeLevelController.dispose();
    _strandController.dispose();
    _courseController.dispose();
    _parentFirstNameController.dispose();
    _parentLastNameController.dispose();
    _parentContactController.dispose();
    _parentFacebookController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  String _formatFullName(Map<String, dynamic> info) {
    final lastName = info['lastName'] as String? ?? '';
    final firstName = info['firstName'] as String? ?? '';
    final middleName = info['middleName'] as String? ?? '';
    return '$lastName, $firstName${middleName.isNotEmpty ? ' $middleName' : ''}'.trim();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseFirestore.instance
            .collection('enrollments')
            .doc(widget.enrollmentId)
            .update({
          'studentInfo': {
            'firstName': _studentFirstNameController.text,
            'lastName': _studentLastNameController.text,
            'middleName': _studentMiddleNameController.text,
            'gradeLevel': _gradeLevelController.text,
            'strand': _strandController.text,
            'course': _courseController.text,
          },
          'parentInfo': {
            'firstName': _parentFirstNameController.text,
            'lastName': _parentLastNameController.text,
            'contact': _parentContactController.text,
            'facebook': _parentFacebookController.text,
          },
        });

        setState(() {
          _isEditing = false;
          widget.enrollmentData['studentInfo'] = {
            'firstName': _studentFirstNameController.text,
            'lastName': _studentLastNameController.text,
            'middleName': _studentMiddleNameController.text,
            'gradeLevel': _gradeLevelController.text,
            'strand': _strandController.text,
            'course': _courseController.text,
          };
          widget.enrollmentData['parentInfo'] = {
            'firstName': _parentFirstNameController.text,
            'lastName': _parentLastNameController.text,
            'contact': _parentContactController.text,
            'facebook': _parentFacebookController.text,
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enrollment details updated successfully'),
            backgroundColor: SMSTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating enrollment: $e'),
            backgroundColor: SMSTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

 Future<void> _recordPayment() async {
  try {
    // Verify authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    print('Authenticated user ID: ${user.uid}');

    // Verify user role
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) {
      print('User document does not exist for UID: ${user.uid}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User profile not found in users collection'),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    final userRole = userDoc.data()?['role'] ?? 'none';
    print('User role: $userRole');
    if (!['admin', 'registrar', 'cashier'].contains(userRole)) {
      print('User does not have permission to record payments');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permission denied: Insufficient role'),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Check scholarship status
    bool isScholar = widget.enrollmentData['isScholar'] ?? false;
    double scholarshipPercentage = (widget.enrollmentData['scholarshipPercentage'] as num?)?.toDouble() ?? 0.0;
    String scholarshipType = widget.enrollmentData['scholarshipType'] ?? '';

    // Determine the student's level and type
    final studentInfo = widget.enrollmentData['studentInfo'] ?? {};
    final gradeLevel = studentInfo['gradeLevel'] ?? '';
    final course = studentInfo['course'] ?? '';
    final semester = studentInfo['semester'] ?? '1st';
    String studentType = 'Payee';
    if (gradeLevel == 'Grade 11' || gradeLevel == 'Grade 12') {
      studentType = studentInfo['isVoucherBeneficiary'] == true ? 'VoucherBeneficiary' : 'Payee';
    }

    // Fetch the applicable fee
    double totalFee = 0.0;
    double idFee = 0.0;
    double booksFee = 0.0;
    double otherFeesTotal = 0.0;
    double miscFeesTotal = 0.0;
    if (course.isNotEmpty) {
      final feeDoc = await FirebaseFirestore.instance
          .collection('fees')
          .doc('college_${course}_$semester')
          .get();
      if (feeDoc.exists) {
        final data = feeDoc.data() as Map<String, dynamic>;
        totalFee = (data['baseFee'] as num?)?.toDouble() ?? 0.0;
        idFee = (data['additionalFees']['idFee'] as num?)?.toDouble() ?? 0.0;
        booksFee = (data['additionalFees']['booksFee'] as num?)?.toDouble() ?? 0.0;
        otherFeesTotal = (data['additionalFees']['otherFees'] as List?)?.fold<double>(
                0.0, (double sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0)) ??
            0.0;
        miscFeesTotal = (data['miscellaneousFees']['collegeMisc'] as List?)?.fold<double>(
                0.0, (num sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0)) ??
            0.0;
      }
    } else {
      String feeDocId = 'gradeLevel_$gradeLevel';
      if (gradeLevel == 'Grade 11' || gradeLevel == 'Grade 12') {
        feeDocId = 'gradeLevel_${gradeLevel}_$studentType';
      }
      final feeDoc = await FirebaseFirestore.instance
          .collection('fees')
          .doc(feeDocId)
          .get();
      if (feeDoc.exists) {
        final data = feeDoc.data() as Map<String, dynamic>;
        totalFee = (data['baseFee'] as num?)?.toDouble() ?? 0.0;
        idFee = (data['additionalFees']['idFee'] as num?)?.toDouble() ?? 0.0;
        booksFee = (data['additionalFees']['booksFee'] as num?)?.toDouble() ?? 0.0;
        otherFeesTotal = (data['additionalFees']['otherFees'] as List?)?.fold<double>(
                0.0, (double sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0)) ??
            0.0;
        String miscField = gradeLevel == 'NKP'
            ? 'nkpMisc'
            : gradeLevel.startsWith('Grade')
                ? '${gradeLevel.toLowerCase().replaceAll(' ', '')}Misc'
                : 'shsMisc';
        miscFeesTotal = (data['miscellaneousFees'][miscField] as List?)?.fold<double>(
                0.0, (double sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0)) ??
            0.0;
      }
    }

    double totalAdditionalFees = idFee + booksFee + otherFeesTotal;
    double grandTotalFee = totalFee + totalAdditionalFees + miscFeesTotal;

    // Apply scholarship discount to base fee only
    double effectiveBaseFee = totalFee * (1 - scholarshipPercentage);
    double effectiveAdditionalFees = totalAdditionalFees;
    double effectiveMiscFees = miscFeesTotal;
    double effectiveGrandTotal = effectiveBaseFee + effectiveAdditionalFees + effectiveMiscFees;

    double totalPaid = 0.0;
    double balance = effectiveGrandTotal;

    if (isScholar && scholarshipPercentage == 1.0) {
      print('Updating enrollment with scholarship: ${widget.enrollmentId}');
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(widget.enrollmentId)
          .update({
        'status': 'paid',
        'totalFee': grandTotalFee,
        'effectiveBaseFee': effectiveBaseFee,
        'effectiveAdditionalFees': effectiveAdditionalFees,
        'effectiveMiscFees': effectiveMiscFees,
        'effectiveGrandTotal': effectiveGrandTotal,
        'totalPaid': grandTotalFee,
        'balance': 0.0,
      });

      print('Adding payment record for scholarship: ${widget.enrollmentId}');
      await FirebaseFirestore.instance.collection('payments').add({
        'enrollmentId': widget.enrollmentId,
        'studentInfo': {
          'name': _formatFullName(studentInfo),
          'gradeLevel': gradeLevel,
          'course': course,
          'semester': semester,
          'studentType': studentType,
        },
        'parentName': _formatFullName(widget.enrollmentData['parentInfo'] ?? {}), // Add parent name
        'amount': 0.0,
        'paymentType': 'Scholarship',
        'scholarshipType': scholarshipType,
        'timestamp': Timestamp.now(),
        'totalFee': grandTotalFee,
        'effectiveBaseFee': effectiveBaseFee,
        'effectiveAdditionalFees': effectiveAdditionalFees,
        'effectiveMiscFees': effectiveMiscFees,
        'effectiveGrandTotal': effectiveGrandTotal,
        'totalPaid': grandTotalFee,
        'balance': 0.0,
      });

      setState(() {
        _paymentRecorded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enrollment marked as paid due to scholarship'),
          backgroundColor: SMSTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      if (_paymentAmountController.text.isEmpty ||
          double.tryParse(_paymentAmountController.text) == null ||
          double.parse(_paymentAmountController.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid payment amount'),
            backgroundColor: SMSTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      _paymentAmount = double.parse(_paymentAmountController.text);

      final paymentQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('enrollmentId', isEqualTo: widget.enrollmentId)
          .get();
      totalPaid = paymentQuery.docs
          .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      totalPaid += _paymentAmount;

      balance = effectiveGrandTotal - totalPaid;

      print('Adding payment record: ${widget.enrollmentId}, amount: $_paymentAmount');
      await FirebaseFirestore.instance.collection('payments').add({
        'enrollmentId': widget.enrollmentId,
        'studentInfo': {
          'name': _formatFullName(studentInfo),
          'gradeLevel': gradeLevel,
          'course': course,
          'semester': semester,
          'studentType': studentType,
        },
        'parentName': _formatFullName(widget.enrollmentData['parentInfo'] ?? {}), // Add parent name
        'amount': _paymentAmount,
        'paymentType': _paymentType,
        'scholarshipType': isScholar ? scholarshipType : null,
        'timestamp': Timestamp.now(),
        'totalFee': grandTotalFee,
        'effectiveBaseFee': effectiveBaseFee,
        'effectiveAdditionalFees': effectiveAdditionalFees,
        'effectiveMiscFees': effectiveMiscFees,
        'effectiveGrandTotal': effectiveGrandTotal,
        'totalPaid': totalPaid,
        'balance': balance,
      });

      print('Updating enrollment: ${widget.enrollmentId}, status: ${balance <= 0 ? 'paid' : 'pending'}');
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(widget.enrollmentId)
          .update({
        'status': balance <= 0 ? 'paid' : 'pending',
        'totalFee': grandTotalFee,
        'effectiveBaseFee': effectiveBaseFee,
        'effectiveAdditionalFees': effectiveAdditionalFees,
        'effectiveMiscFees': effectiveMiscFees,
        'effectiveGrandTotal': effectiveGrandTotal,
        'totalPaid': totalPaid,
        'balance': balance,
      });

      setState(() {
        _paymentRecorded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment recorded successfully'),
          backgroundColor: SMSTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  } catch (e) {
    print('Error recording payment (detailed): $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error recording payment: $e'),
        backgroundColor: SMSTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}


  Future<void> _printAndApprove() async {
    try {
      // Move to enrolled_students
      await FirebaseFirestore.instance
          .collection('enrolled_students')
          .doc(widget.enrollmentId)
          .set({
        'studentId': widget.enrollmentId,
        'name': _formatFullName(widget.enrollmentData['studentInfo']),
        'gradeLevel': widget.enrollmentData['studentInfo']?['gradeLevel'] ?? '',
        'enrollmentDate': Timestamp.now(),
      });

      // Delete from enrollments
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(widget.enrollmentId)
          .delete();

      // Simulate printing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Printing enrollment form for ${_formatFullName(widget.enrollmentData['studentInfo'])}'),
          backgroundColor: SMSTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving enrollment: $e'),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    final enrollmentData = widget.enrollmentData;

    return Theme(
      data: SMSTheme.getTheme(),
      child: Scaffold(
       appBar: AppBar(
          title: const Text('Enrollment Details'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SMSTheme.backgroundColor, Color(0xFFFFF7EB)],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Information
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Information',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            if (_isEditing) ...[
                              TextFormField(
                                controller: _studentFirstNameController,
                                decoration: const InputDecoration(
                                    labelText: 'First Name'),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a first name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _studentLastNameController,
                                decoration: const InputDecoration(
                                    labelText: 'Last Name'),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a last name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _studentMiddleNameController,
                                decoration: const InputDecoration(
                                    labelText: 'Middle Name'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _gradeLevelController,
                                decoration: const InputDecoration(
                                    labelText: 'Grade Level'),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a grade level'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _strandController,
                                decoration: const InputDecoration(
                                    labelText: 'Strand (if applicable)'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _courseController,
                                decoration: const InputDecoration(
                                    labelText: 'Course (if applicable)'),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(Icons.person,
                                        size: 40, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatFullName(
                                              enrollmentData['studentInfo'] ??
                                                  {}),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Grade: ${enrollmentData['studentInfo']?['gradeLevel'] ?? 'N/A'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if (enrollmentData['studentInfo']
                                                    ?['strand']
                                                ?.isNotEmpty ??
                                            false)
                                          Text(
                                            'Strand: ${enrollmentData['studentInfo']?['strand']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (enrollmentData['studentInfo']
                                                    ?['course']
                                                ?.isNotEmpty ??
                                            false)
                                          Text(
                                            'Course: ${enrollmentData['studentInfo']?['course']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parent/Guardian Information
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent/Guardian Information',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            if (_isEditing) ...[
                              TextFormField(
                                controller: _parentFirstNameController,
                                decoration: const InputDecoration(
                                    labelText: 'First Name'),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a first name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _parentLastNameController,
                                decoration: const InputDecoration(
                                    labelText: 'Last Name'),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a last name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _parentContactController,
                                decoration:
                                    const InputDecoration(labelText: 'Contact'),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a contact number'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _parentFacebookController,
                                decoration: const InputDecoration(
                                    labelText: 'Facebook (optional)'),
                              ),
                            ] else ...[
                              Text(
                                'Name: ${_formatFullName(enrollmentData['parentInfo'] ?? {})}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contact: ${enrollmentData['parentInfo']?['contact'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (enrollmentData['parentInfo']?['facebook']
                                      ?.isNotEmpty ??
                                  false)
                                Text(
                                  'Facebook: ${enrollmentData['parentInfo']?['facebook']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Contacts (if any)
                    if (enrollmentData['additionalContacts']?.isNotEmpty ??
                        false) ...[
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Contacts',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(
                                (enrollmentData['additionalContacts']
                                        as List<dynamic>)
                                    .length,
                                (index) {
                                  final contact =
                                      enrollmentData['additionalContacts']
                                          [index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contact ${index + 1} (${contact['relationship']})',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Text(
                                          'Name: ${_formatFullName(contact)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          'Contact: ${contact['contact'] ?? 'N/A'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if (contact['facebook']?.isNotEmpty ??
                                            false)
                                          Text(
                                            'Facebook: ${contact['facebook']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Payment Section
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            if (_paymentRecorded) ...[
                              Text(
                                'Payment Recorded: ₱${_paymentAmount.toStringAsFixed(2)} ($_paymentType)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color:
                                            SMSTheme.successColor),
                              ),
                            ] else ...[
                              DropdownButtonFormField<String>(
                                value: _paymentType,
                                decoration: const InputDecoration(
                                    labelText: 'Payment Type'),
                                items: ['Downpayment', 'Full', 'Partial']
                                    .map((type) => DropdownMenuItem(
                                        value: type, child: Text(type)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _paymentType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _paymentAmountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  prefixText: '₱ ',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) <= 0) {
                                    return 'Please enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _recordPayment,
                                  child: const Text('Record Payment'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    if (_isEditing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                // Reset controllers to original values
                                _studentFirstNameController.text =
                                    widget.enrollmentData['studentInfo']
                                            ?['firstName'] ??
                                        '';
                                _studentLastNameController.text =
                                    widget.enrollmentData['studentInfo']
                                            ?['lastName'] ??
                                        '';
                                _studentMiddleNameController.text =
                                    widget.enrollmentData['studentInfo']
                                            ?['middleName'] ??
                                        '';
                                _gradeLevelController.text =
                                    widget.enrollmentData['studentInfo']
                                            ?['gradeLevel'] ??
                                        '';
                                _strandController.text =
                                    widget.enrollmentData['studentInfo']
                                            ?['strand'] ??
                                        '';
                                _courseController.text =
                                    widget.enrollmentData['studentInfo']
                                            ?['course'] ??
                                        '';
                                _parentFirstNameController.text =
                                    widget.enrollmentData['parentInfo']
                                            ?['firstName'] ??
                                        '';
                                _parentLastNameController.text =
                                    widget.enrollmentData['parentInfo']
                                            ?['lastName'] ??
                                        '';
                                _parentContactController.text =
                                    widget.enrollmentData['parentInfo']
                                            ?['contact'] ??
                                        '';
                                _parentFacebookController.text =
                                    widget.enrollmentData['parentInfo']
                                            ?['facebook'] ??
                                        '';
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _saveChanges,
                            child: const Text('Save Changes'),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: ElevatedButton(
                          onPressed: _paymentRecorded ? _printAndApprove : null,
                          child: const Text('Print and Approve'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}