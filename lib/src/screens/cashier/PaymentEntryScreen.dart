import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme.dart';
import 'dart:async';

class PaymentEntryScreen extends StatefulWidget {
  final String? studentId;

  const PaymentEntryScreen({super.key, this.studentId});

  @override
  _PaymentEntryScreenState createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentType = 'Tuition Fee';
  String _paymentMethod = 'Cash';
  bool _isScholar = false;
  int _familyMemberCount = 1;
  List<Map<String, dynamic>> _fees = [];
  double _totalFee = 0.0;
  double _familyDiscount = 0.0;
  Map<String, dynamic>? _studentInfo;
  bool _isSubmitting = false;
  bool _isLoadingStudent = false;
  bool _showStudentList = false;
  List<Map<String, dynamic>> _studentSearchResults = [];
  Timer? _debounce;

  // List of payment types and methods
  final List<String> _paymentTypes = [
    'Tuition Fee',
    'Downpayment',
    'Full Payment',
    'Registration',
    'Uniform',
    'Books',
    'Miscellaneous'
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Online Transfer',
    'Credit Card',
    'Debit Card',
    'Check',
    'Scholarship',
    'Installment'
  ];
  // Helper function to get the maximum between two doubles
  double max(double a, double b) {
    return a > b ? a : b;
  }

// Helper function to format student name
  String _formatStudentName(Map<String, dynamic> data) {
    final lastName = data['lastName'] as String? ?? '';
    final firstName = data['firstName'] as String? ?? '';
    final middleName = data['middleName'] as String? ?? '';
    final mi = middleName.isNotEmpty ? ' ${middleName[0]}.' : '';
    return '$lastName, $firstName$mi'.trim();
  }

// Helper function to determine student type
  String _determineStudentType(Map<String, dynamic> data) {
    final gradeLevel = data['gradeLevel'] as String? ?? '';
    final isVoucherBeneficiary = data['isVoucherBeneficiary'] as bool? ?? false;

    if (gradeLevel == 'Grade 11' || gradeLevel == 'Grade 12') {
      return isVoucherBeneficiary ? 'VoucherBeneficiary' : 'Payee';
    } else {
      return 'Payee';
    }
  }

  // Define the fee item widget here for proper reference
  Widget _buildFeeItem(String name, double amount, NumberFormat currencyFormat,
      {bool isDiscount = false}) {
    final Color textColor = isDiscount ? Colors.green.shade700 : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: textColor),
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Define the fee skeleton loader widget here for proper reference
  Widget _buildFeeSkeletonLoader() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loading Fee Details...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Skeleton Loading Items
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Total Skeleton
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Define the empty fees placeholder widget here for proper reference
  Widget _buildEmptyFeesPlaceholder() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Fee Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Search for a student to view fee details',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to setup fee structure if user has permissions
                // This could be added in the future
              },
              icon: const Icon(Icons.settings),
              label: const Text('Fee Structure Setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // If a studentId was passed, populate the form
    if (widget.studentId != null) {
      _studentIdController.text = widget.studentId!;
      _fetchStudentInfo(widget.studentId!);
    }

    _studentIdController.addListener(() {
      setState(() {
        _showStudentList = false;
      });
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_searchController.text.length > 2) {
          _searchStudents(_searchController.text);
        } else {
          setState(() {
            _studentSearchResults = [];
            _showStudentList = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    _notesController.dispose();
    _debounce?.cancel(); // Cancel any active debounce timer
    super.dispose();
  }

  Future<void> _searchStudents(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoadingStudent = true;
      _showStudentList = true;
    });

    try {
      List<Map<String, dynamic>> results = [];
      Set<String> processedIds = {};

      // First search directly in the students collection
      final QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .limit(20)
          .get();

      print(
          'Retrieved ${studentsSnapshot.docs.length} students to search through');

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final studentId = doc.id;

        // Extract search fields
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final fullName = '$firstName $lastName'.toLowerCase();

        // Check if this matches our search query
        final queryLower = query.toLowerCase();
        if ((fullName.contains(queryLower) ||
                lastName.toLowerCase().contains(queryLower) ||
                firstName.toLowerCase().contains(queryLower) ||
                studentId.contains(query)) &&
            !processedIds.contains(studentId)) {
          processedIds.add(studentId);
          results.add({
            'id': studentId,
            'studentId': studentId,
            'fullName': '$lastName, $firstName',
            'firstName': firstName,
            'lastName': lastName,
            'gradeLevel': data['gradeLevel'] ?? '',
            'course': data['course'] ?? '',
          });
        }
      }

      // If no results from students, try searching in enrollments
      if (results.isEmpty) {
        final QuerySnapshot enrollmentsSnapshot = await FirebaseFirestore
            .instance
            .collection('enrollments')
            .where('status', whereIn: ['pending', 'partial', 'paid'])
            .limit(20)
            .get();

        print(
            'Retrieved ${enrollmentsSnapshot.docs.length} enrollments to search through');

        for (var doc in enrollmentsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if studentInfo exists and is a Map
          if (data['studentInfo'] == null || !(data['studentInfo'] is Map)) {
            continue;
          }

          final studentInfo = data['studentInfo'] as Map<String, dynamic>;
          final studentId = doc.id; // Using enrollment ID as student ID

          // Extract search fields
          final firstName = studentInfo['firstName'] ?? '';
          final lastName = studentInfo['lastName'] ?? '';
          final fullName = '$firstName $lastName'.toLowerCase();

          // Check if this matches our search query
          final queryLower = query.toLowerCase();
          if ((fullName.contains(queryLower) ||
                  lastName.toLowerCase().contains(queryLower) ||
                  firstName.toLowerCase().contains(queryLower) ||
                  studentId.contains(query)) &&
              !processedIds.contains(studentId)) {
            processedIds.add(studentId);
            results.add({
              'id': studentId,
              'studentId': studentId,
              'fullName': '$lastName, $firstName',
              'firstName': firstName,
              'lastName': lastName,
              'gradeLevel': studentInfo['gradeLevel'] ?? '',
              'course': studentInfo['course'] ?? '',
            });
          }
        }
      }

      // Lastly, try searching in users collection if it has student records
      if (results.isEmpty) {
        final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .limit(20)
            .get();

        print('Retrieved ${usersSnapshot.docs.length} users to search through');

        for (var doc in usersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentId = data['studentId'] ?? doc.id;

          if (processedIds.contains(studentId)) continue;

          // Extract search fields - user structure might be different
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          // Also try fullName field in case it exists
          final storedFullName = data['fullName'] ?? '';
          final fullName = storedFullName.isNotEmpty
              ? storedFullName.toLowerCase()
              : '$firstName $lastName'.toLowerCase();

          // Check if this matches our search query
          final queryLower = query.toLowerCase();
          if (fullName.contains(queryLower) ||
              lastName.toLowerCase().contains(queryLower) ||
              firstName.toLowerCase().contains(queryLower) ||
              studentId.contains(query)) {
            processedIds.add(studentId);
            results.add({
              'id': studentId,
              'studentId': studentId,
              'fullName': storedFullName.isNotEmpty
                  ? storedFullName
                  : '$lastName, $firstName',
              'firstName': firstName,
              'lastName': lastName,
              'gradeLevel': data['gradeLevel'] ?? '',
              'course': data['course'] ?? '',
            });
          }
        }
      }

      setState(() {
        _studentSearchResults = results;
        _isLoadingStudent = false;
      });

      print('Found ${results.length} student matches for query: $query');

      // If no results were found, show a helpful message
      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No students found matching "$query"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error in student search: $e');
      if (mounted) {
        setState(() {
          _isLoadingStudent = false;
          _studentSearchResults = [];
        });

        // Add more descriptive error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching students: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchStudentInfo(String studentId) async {
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid student ID'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    setState(() {
      _isLoadingStudent = true;
    });

    try {
      // First check in students collection (primary location for student data)
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentSnapshot.exists) {
        final studentData = studentSnapshot.data() as Map<String, dynamic>;

        // Process student data
        setState(() {
          _studentInfo = {
            'name': _formatStudentName(studentData),
            'firstName': studentData['firstName'] ?? '',
            'lastName': studentData['lastName'] ?? '',
            'middleName': studentData['middleName'] ?? '',
            'gradeLevel': studentData['gradeLevel'] ?? '',
            'course': studentData['course'] ?? '',
            'semester': studentData['semester'] ?? '1st',
            'studentType': _determineStudentType(studentData),
            'isScholar': studentData['isScholar'] ?? false,
          };
          _isScholar = studentData['isScholar'] ?? false;
          _isLoadingStudent = false;
        });

        await _fetchFees(
          _studentInfo!['gradeLevel'] ?? '',
          _studentInfo!['course'] ?? '',
          _studentInfo!['semester'] ?? '1st',
          _studentInfo!['studentType'] ?? 'Payee',
        );

        return _studentInfo;
      }

      // If not found in students, check enrollments collection
      final enrollmentSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(studentId)
          .get();

      if (enrollmentSnapshot.exists) {
        final enrollmentData =
            enrollmentSnapshot.data() as Map<String, dynamic>;
        final studentInfo = enrollmentData['studentInfo'] ?? {};

        setState(() {
          _studentInfo = {
            'name': _formatFullName(studentInfo),
            'firstName': studentInfo['firstName'] ?? '',
            'lastName': studentInfo['lastName'] ?? '',
            'middleName': studentInfo['middleName'] ?? '',
            'gradeLevel': studentInfo['gradeLevel'] ?? '',
            'course': studentInfo['course'] ?? '',
            'semester': studentInfo['semester'] ?? '1st',
            'studentType': _determineStudentType(studentInfo),
            'isScholar': enrollmentData['isScholar'] ?? false,
          };
          _isScholar = enrollmentData['isScholar'] ?? false;
          _isLoadingStudent = false;
        });

        await _fetchFees(
          _studentInfo!['gradeLevel'] ?? '',
          _studentInfo!['course'] ?? '',
          _studentInfo!['semester'] ?? '1st',
          _studentInfo!['studentType'] ?? 'Payee',
        );

        return _studentInfo;
      }

      // If not found in enrollments either, check users collection for students
      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        // Try with direct ID match as last resort
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _studentInfo = {
              'name': userData['fullName'] ?? _formatStudentName(userData),
              'firstName': userData['firstName'] ?? '',
              'lastName': userData['lastName'] ?? '',
              'middleName': userData['middleName'] ?? '',
              'gradeLevel': userData['gradeLevel'] ?? '',
              'course': userData['course'] ?? '',
              'semester': userData['semester'] ?? '1st',
              'studentType': _determineStudentType(userData),
              'isScholar': userData['isScholar'] ?? false,
            };
            _isScholar = userData['isScholar'] ?? false;
            _isLoadingStudent = false;
          });

          await _fetchFees(
            _studentInfo!['gradeLevel'] ?? '',
            _studentInfo!['course'] ?? '',
            _studentInfo!['semester'] ?? '1st',
            _studentInfo!['studentType'] ?? 'Payee',
          );

          return _studentInfo;
        }

        // No student record found in any collection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student with ID $studentId not found'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _studentInfo = null;
          _isLoadingStudent = false;
        });
        return null;
      }

      // Process user data if found as a student user
      final userData = userQuery.docs.first.data() as Map<String, dynamic>;

      setState(() {
        _studentInfo = {
          'name': userData['fullName'] ?? _formatStudentName(userData),
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'middleName': userData['middleName'] ?? '',
          'gradeLevel': userData['gradeLevel'] ?? '',
          'course': userData['course'] ?? '',
          'semester': userData['semester'] ?? '1st',
          'studentType': _determineStudentType(userData),
          'isScholar': userData['isScholar'] ?? false,
        };
        _isScholar = userData['isScholar'] ?? false;
        _isLoadingStudent = false;
      });

      await _fetchFees(
        _studentInfo!['gradeLevel'] ?? '',
        _studentInfo!['course'] ?? '',
        _studentInfo!['semester'] ?? '1st',
        _studentInfo!['studentType'] ?? 'Payee',
      );

      return _studentInfo;
    } catch (e) {
      print('Error fetching student info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading student data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _studentInfo = null;
        _isLoadingStudent = false;
      });
      return null;
    }
  }

  String _formatFullName(Map<String, dynamic> info) {
    final lastName = info['lastName'] as String? ?? '';
    final firstName = info['firstName'] as String? ?? '';
    final middleName = info['middleName'] as String? ?? '';
    final mi = middleName.isNotEmpty ? ' ${middleName[0]}.' : '';
    return '$lastName, $firstName$mi'.trim();
  }

  // Enhanced fee fetching with better fallbacks
  Future<void> _fetchFees(String gradeLevel, String course, String semester,
      String studentType) async {
    try {
      // Check if required parameters are available
      if (gradeLevel.isEmpty && course.isEmpty) {
        setState(() {
          _fees = [];
          _totalFee = 0.0;
          _familyDiscount = 0.0;
        });
        print('Warning: Missing grade level and course information');

        // Set some default fee categories even if amounts are unknown
        setState(() {
          _fees = [
            {'name': 'Tuition Fee', 'amount': 0.0},
            {'name': 'Miscellaneous', 'amount': 0.0},
          ];
        });
        return;
      }

      // Construct fee document ID based on level or course
      String docId;
      if (course.isNotEmpty) {
        // College student
        docId = '${course}_$semester';
      } else if (gradeLevel.contains('Grade')) {
        // K-12 student
        docId = '${gradeLevel}_$studentType';
      } else {
        // Default/other
        docId = gradeLevel;
      }

      final feeDoc =
          await FirebaseFirestore.instance.collection('fees').doc(docId).get();

      if (feeDoc.exists) {
        final data = feeDoc.data() as Map<String, dynamic>?;
        if (data == null) {
          // Handle null data case
          _setDefaultFees();
          return;
        }

        // Successfully found fee document
        setState(() {
          // Extract fees array if available
          if (data['fees'] is List) {
            _fees = (data['fees'] as List<dynamic>).map((fee) {
              if (fee is Map<String, dynamic>) return fee;
              return {'name': 'Unknown Fee', 'amount': 0.0};
            }).toList();
          } else {
            // Create fees from components if direct fees not available
            _fees = [];
            if (data['baseFee'] != null)
              _fees.add({
                'name': 'Tuition Fee',
                'amount': (data['baseFee'] as num).toDouble()
              });
            if (data['miscFee'] != null)
              _fees.add({
                'name': 'Miscellaneous',
                'amount': (data['miscFee'] as num).toDouble()
              });
            if (data['labFee'] != null)
              _fees.add({
                'name': 'Laboratory',
                'amount': (data['labFee'] as num).toDouble()
              });
            // Add any other fees that might be present
          }

          // Calculate total fee based on payment method and scholarship status
          _totalFee = _isScholar
              ? _fees.fold<double>(
                      0.0,
                      (sum, fee) =>
                          sum + ((fee['amount'] as num?)?.toDouble() ?? 0.0)) *
                  (1 - (_scholarshipPercentage() / 100))
              : _paymentMethod == 'Cash'
                  ? (data['cashAmount'] as num?)?.toDouble() ??
                      _calculateTotalFromFees()
                  : (data['installmentAmount'] as num?)?.toDouble() ??
                      _calculateTotalFromFees() *
                          1.1; // 10% more for installment

          // Calculate family discount if applicable
          final discountRules =
              data['discountRules'] as Map<String, dynamic>? ?? {};
          final threshold =
              (discountRules['familyThreshold'] as num?)?.toInt() ?? 3;
          final discountAmount =
              (discountRules['familyDiscountAmount'] as num?)?.toDouble() ??
                  500.0;
          _familyDiscount =
              _familyMemberCount >= threshold ? discountAmount : 0.0;
          _totalFee -= _familyDiscount;

          // Set suggested amount based on payment type
          if (_amountController.text.isEmpty) {
            if (_paymentType == 'Downpayment') {
              _amountController.text =
                  (_totalFee * 0.3).toStringAsFixed(2); // 30% for downpayment
            } else if (_paymentType == 'Full Payment') {
              _amountController.text = _totalFee.toStringAsFixed(2);
            }
          }
        });
      } else {
        // Fee document not found - try a generic fallback
        final fallbackDoc = await FirebaseFirestore.instance
            .collection('fees')
            .doc('default')
            .get();

        if (fallbackDoc.exists) {
          final data = fallbackDoc.data() as Map<String, dynamic>?;
          _processFeeData(data);
        } else {
          // No fallback found, use defaults
          _setDefaultFees();
        }
      }
    } catch (e) {
      print('Error fetching fees: $e');
      // Create a default fee structure if error occurs
      _setDefaultFees();
    }
  }

  // Helper to set default fees
  void _setDefaultFees() {
    setState(() {
      // Create reasonable default values
      _fees = [
        {'name': 'Tuition Fee', 'amount': 5000.0},
        {'name': 'Miscellaneous Fee', 'amount': 1000.0},
        {'name': 'Development Fee', 'amount': 500.0},
      ];
      _totalFee = 6500.0;
      _familyDiscount = _familyMemberCount >= 3 ? 500.0 : 0.0;
      _totalFee -= _familyDiscount;

      // Set suggested amount
      if (_amountController.text.isEmpty) {
        if (_paymentType == 'Downpayment') {
          _amountController.text = (_totalFee * 0.3).toStringAsFixed(2);
        } else if (_paymentType == 'Full Payment') {
          _amountController.text = _totalFee.toStringAsFixed(2);
        }
      }
    });
  }

  // Helper to process fee data
  void _processFeeData(Map<String, dynamic>? data) {
    if (data == null) {
      _setDefaultFees();
      return;
    }

    setState(() {
      if (data['fees'] is List) {
        _fees = (data['fees'] as List<dynamic>).map((fee) {
          if (fee is Map<String, dynamic>) return fee;
          return {'name': 'Unknown Fee', 'amount': 0.0};
        }).toList();
      } else {
        _fees = [];
        if (data['baseFee'] != null)
          _fees.add({
            'name': 'Tuition Fee',
            'amount': (data['baseFee'] as num).toDouble()
          });
        if (data['miscFee'] != null)
          _fees.add({
            'name': 'Miscellaneous',
            'amount': (data['miscFee'] as num).toDouble()
          });
      }

      _totalFee = _calculateTotalFromFees();
      _familyDiscount = _familyMemberCount >= 3 ? 500.0 : 0.0;
      _totalFee -= _familyDiscount;
    });
  }

  // Helper to calculate total from fees
  double _calculateTotalFromFees() {
    return _fees.fold<double>(
        0.0, (sum, fee) => sum + ((fee['amount'] as num?)?.toDouble() ?? 0.0));
  }

  // Helper to determine scholarship percentage
  double _scholarshipPercentage() {
    // Return scholarship percentage based on student information
    // This could be enhanced with more sophisticated logic
    return 100.0; // Default to full scholarship (100%)
  }

  Future<void> _recordPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Verify authentication
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _showErrorSnackbar('User not authenticated');
          return;
        }

        // Verify user role
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          _showErrorSnackbar('User profile not found');
          return;
        }

        final userRole = userDoc.data()?['role'] ?? 'none';
        final cashierName = userDoc.data()?['fullName'] ?? 'Unknown';

        if (!['admin', 'registrar', 'cashier'].contains(userRole)) {
          _showErrorSnackbar('Permission denied: Insufficient role');
          return;
        }

        if (_studentInfo == null) {
          _showErrorSnackbar('Student information not found');
          return;
        }

        // Refresh fee information to ensure it's current
        await _fetchFees(
          _studentInfo!['gradeLevel'] ?? '',
          _studentInfo!['course'] ?? '',
          _studentInfo!['semester'] ?? '1st',
          _studentInfo!['studentType'] ?? 'Payee',
        );

        // Handle scholarship case
        if (_isScholar && _paymentMethod == 'Scholarship') {
          await _processScholarshipPayment(user.uid, cashierName);
        } else {
          await _processRegularPayment(user.uid, cashierName);
        }
      } catch (e) {
        print('Error recording payment: $e');
        _showErrorSnackbar('Error recording payment: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  // Process a scholarship payment
  Future<void> _processScholarshipPayment(
      String userId, String cashierName) async {
    try {
      // Update enrollment record
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(_studentIdController.text)
          .update({
        'status': 'paid',
        'totalFee': _totalFee,
        'paymentMethod': 'Scholarship',
        'isScholar': true,
        'totalPaid': _totalFee,
        'balance': 0.0,
        'familyDiscount': _familyDiscount,
        'lastUpdated': Timestamp.now(),
        'updatedBy': userId,
      });

      // Create payment record
      final paymentRef =
          await FirebaseFirestore.instance.collection('payments').add({
        'studentId': _studentIdController.text,
        'studentInfo': {
          'firstName': _studentInfo!['firstName'],
          'lastName': _studentInfo!['lastName'],
          'middleName': _studentInfo!['middleName'],
          'gradeLevel': _studentInfo!['gradeLevel'],
          'course': _studentInfo!['course'],
          'semester': _studentInfo!['semester'],
          'studentType': _studentInfo!['studentType'],
        },
        'amount': 0.0,
        'paymentType': 'Scholarship',
        'paymentMethod': 'Scholarship',
        'timestamp': Timestamp.now(),
        'totalFee': _totalFee,
        'totalPaid': _totalFee,
        'balance': 0.0,
        'familyDiscount': _familyDiscount,
        'feesBreakdown': _fees,
        'cashierId': userId,
        'cashierName': cashierName,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : 'Scholarship payment - full coverage',
        'receiptGenerated': false,
      });

      _showSuccessSnackbar('Enrollment marked as paid due to scholarship');

      // Show payment receipt
      if (mounted) {
        _showPaymentSuccessDialog(
            paymentRef.id, 0.0, 'Scholarship', 'Scholarship');
      }

      _clearForm();
    } catch (e) {
      print('Error processing scholarship payment: $e');
      _showErrorSnackbar('Error processing scholarship: $e');
    }
  }

  // Process a regular payment
  Future<void> _processRegularPayment(String userId, String cashierName) async {
    try {
      if (_amountController.text.isEmpty ||
          double.tryParse(_amountController.text) == null ||
          double.parse(_amountController.text) <= 0) {
        _showErrorSnackbar('Please enter a valid payment amount');
        return;
      }

      double amount = double.parse(_amountController.text);

      // Check if the amount is within allowable range
      if (_paymentType == 'Full Payment' && amount < _totalFee) {
        _showErrorSnackbar('Full payment amount must equal the total fee');
        return;
      }

      if (_paymentType == 'Downpayment' && amount < (_totalFee * 0.3)) {
        _showErrorSnackbar('Downpayment must be at least 30% of the total fee');
        return;
      }

      if (amount > _totalFee) {
        _showErrorSnackbar('Payment amount cannot exceed total fee');
        return;
      }

      // Get existing payments if any
      final existingPayments = await FirebaseFirestore.instance
          .collection('payments')
          .where('studentId', isEqualTo: _studentIdController.text)
          .get();

      double previouslyPaid = 0.0;
      for (var doc in existingPayments.docs) {
        previouslyPaid += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Calculate balance considering previous payments
      double balance = _totalFee - (previouslyPaid + amount);

      // Create payment record
      final paymentRef =
          await FirebaseFirestore.instance.collection('payments').add({
        'studentId': _studentIdController.text,
        'studentInfo': {
          'firstName': _studentInfo!['firstName'],
          'lastName': _studentInfo!['lastName'],
          'middleName': _studentInfo!['middleName'],
          'gradeLevel': _studentInfo!['gradeLevel'],
          'course': _studentInfo!['course'],
          'semester': _studentInfo!['semester'],
          'studentType': _studentInfo!['studentType'],
        },
        'amount': amount,
        'paymentType': _paymentType,
        'paymentMethod': _paymentMethod,
        'timestamp': Timestamp.now(),
        'totalFee': _totalFee,
        'previouslyPaid': previouslyPaid,
        'totalPaid': previouslyPaid + amount,
        'balance': balance,
        'familyDiscount': _familyDiscount,
        'feesBreakdown': _fees,
        'cashierId': userId,
        'cashierName': cashierName,
        'notes': _notesController.text,
        'receiptGenerated': false,
      });
      // Update the enrollment record
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(_studentIdController.text)
          .update({
        'status': balance <= 0 ? 'paid' : 'partial',
        'totalFee': _totalFee,
        'paymentMethod': _paymentMethod,
        'isScholar': false,
        'totalPaid': previouslyPaid + amount,
        'balance': balance,
        'familyDiscount': _familyDiscount,
        'lastUpdated': Timestamp.now(),
        'updatedBy': userId,
      });

      // Create activity log
      await FirebaseFirestore.instance.collection('activities').add({
        'type': 'payment',
        'description':
            'Payment of ${NumberFormat.currency(symbol: '₱').format(amount)} received for ${_studentInfo!["firstName"]} ${_studentInfo!["lastName"]}',
        'userId': userId,
        'userName': cashierName,
        'studentId': _studentIdController.text,
        'timestamp': Timestamp.now(),
        'amount': amount,
        'paymentType': _paymentType,
      });

      _showSuccessSnackbar('Payment recorded successfully');

      // Show payment receipt
      if (mounted) {
        _showPaymentSuccessDialog(
            paymentRef.id, amount, _paymentType, _paymentMethod);
      }

      _clearForm();
    } catch (e) {
      print('Error processing regular payment: $e');
      _showErrorSnackbar('Error processing payment: $e');
    }
  }

  void _clearForm() {
    setState(() {
      _studentIdController.clear();
      _amountController.clear();
      _searchController.clear();
      _notesController.clear();
      _studentInfo = null;
      _fees = [];
      _totalFee = 0.0;
      _familyDiscount = 0.0;
      _isScholar = false;
      _familyMemberCount = 1;
      _paymentMethod = 'Cash';
      _paymentType = 'Tuition Fee';
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    setState(() {
      _isSubmitting = false;
    });
  }

  void _showPaymentSuccessDialog(String paymentId, double amount,
      String paymentType, String paymentMethod) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Payment Successful'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'A payment of ${currencyFormat.format(amount)} has been recorded for:'),
              const SizedBox(height: 16),
              Text(
                _studentInfo?['name'] ?? 'Unknown Student',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text('ID: ${_studentIdController.text}'),
              const SizedBox(height: 16),
              Text('Payment Type: $paymentType'),
              Text('Payment Method: $paymentMethod'),
              Text('Receipt Number: $paymentId'),
              if (_notesController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes: ${_notesController.text}'),
              ],
              const SizedBox(height: 16),
              const Text('Would you like to print the receipt?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear form and set up for a new payment for the same student
              setState(() {
                String currentStudentId = _studentIdController.text;
                _clearForm();
                _studentIdController.text = currentStudentId;
                _fetchStudentInfo(currentStudentId);
              });
            },
            child: const Text('New Payment'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print Receipt'),
            onPressed: () {
              Navigator.of(context).pop();
              // Implement receipt printing
              _printReceipt(paymentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(String paymentId) async {
    try {
      // Update receipt status in the database
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .update({'receiptGenerated': true});

      // In a real implementation, this would call a receipt printing API
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Printing receipt...'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to receipt view screen if available
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (context) => ReceiptViewScreen(paymentId: paymentId),
              // ));
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      print('Error printing receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing receipt: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to recent payments history
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (context) => RecentPaymentsScreen(),
              // ));
            },
            tooltip: 'Recent Payments',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
            tooltip: 'Clear form',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SMSTheme.backgroundColor, Colors.white],
          ),
        ),
        child: SafeArea(
          child: isLargeScreen
              ? _buildWideLayout(currencyFormat)
              : _buildNarrowLayout(currencyFormat),
        ),
      ),
    );
  }

  Widget _buildWideLayout(NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Student info and payment form
          Expanded(
            flex: 6,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildPaymentForm(currencyFormat),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Right side: Fee breakdown and summary
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Student Info Card
                if (_studentInfo != null)
                  FadeInRight(
                    duration: const Duration(milliseconds: 500),
                    child: _buildStudentInfoCard(),
                  ),

                if (_studentInfo != null) const SizedBox(height: 24),

                // Fee Breakdown Card
                Expanded(
                  child: _fees.isNotEmpty
                      ? FadeInRight(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 200),
                          child: _buildFeeBreakdownCard(currencyFormat),
                        )
                      : _studentInfo != null
                          ? _buildFeeSkeletonLoader()
                          : _buildEmptyFeesPlaceholder(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(NumberFormat currencyFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          if (_studentInfo != null)
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _buildStudentInfoCard(),
            ),

          if (_studentInfo != null) const SizedBox(height: 16),

          // Payment Form Card
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildPaymentForm(currencyFormat),
            ),
          ),

          const SizedBox(height: 16),

          // Fee Breakdown Card
          if (_fees.isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: _buildFeeBreakdownCard(currencyFormat),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(NumberFormat currencyFormat) {
    return SingleChildScrollView(
        child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // Student Information Section
          Text(
            'Student Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: SMSTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Student ID with Search
          TextFormField(
            controller: _studentIdController,
            decoration: InputDecoration(
              labelText: 'Student ID',
              hintText: 'Enter student ID number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.badge),
              suffixIcon: _isLoadingStudent
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (_studentIdController.text.isNotEmpty) {
                          _fetchStudentInfo(_studentIdController.text);
                        }
                      },
                    ),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter a student ID' : null,
            onFieldSubmitted: (value) {
              if (value.isNotEmpty) {
                _fetchStudentInfo(value);
              }
            },
          ),

          const SizedBox(height: 16),

          // Search by Name - with fixed height container for dropdown
          Container(
            height: _showStudentList
                ? 250
                : 80, // Adjust height based on dropdown visibility
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Student',
                    hintText: 'Search by name or ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _studentSearchResults = [];
                                _showStudentList = false;
                              });
                            },
                          )
                        : null,
                  ),
                ),

                // Search Results Dropdown - Scrollable with fixed height
                if (_showStudentList && _studentSearchResults.isNotEmpty)
                  Expanded(
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(top: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _studentSearchResults.length,
                        itemBuilder: (context, index) {
                          final student = _studentSearchResults[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor:
                                  SMSTheme.primaryColor.withOpacity(0.1),
                              radius: 16,
                              child: Text(
                                student['firstName']?.isNotEmpty == true
                                    ? student['firstName'][0].toUpperCase()
                                    : 'S',
                                style: TextStyle(
                                  color: SMSTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              student['fullName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            subtitle: Text(
                              'ID: ${student['studentId']} • ${student['gradeLevel'] ?? student['course'] ?? 'N/A'}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            onTap: () {
                              _studentIdController.text = student['studentId'];
                              _fetchStudentInfo(student['studentId']);
                              _searchController.clear();
                              setState(() {
                                _showStudentList = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment Information Section
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: SMSTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Payment Type Dropdown
          DropdownButtonFormField<String>(
            value: _paymentType,
            decoration: InputDecoration(
              labelText: 'Payment Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: _paymentTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _paymentType = newValue;
                  // Set suggested amount based on payment type
                  if (_paymentType == 'Downpayment') {
                    _amountController.text =
                        (_totalFee * 0.3).toStringAsFixed(2);
                  } else if (_paymentType == 'Full Payment') {
                    _amountController.text = _totalFee.toStringAsFixed(2);
                  }
                });
              }
            },
            validator: (value) =>
                value == null ? 'Please select a payment type' : null,
          ),

          const SizedBox(height: 16),

          // Payment Method Dropdown
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.payments),
            ),
            items: _paymentMethods.map((String method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _paymentMethod = newValue;
                  // If payment method is Scholarship, update form accordingly
                  if (_paymentMethod == 'Scholarship') {
                    _isScholar = true;
                    _amountController.text =
                        "0.00"; // Scholarship typically means no payment
                  } else if (_paymentMethod == 'Installment') {
                    // For installment, you might want to recalculate based on different terms
                    _amountController.text =
                        (_totalFee * 0.3).toStringAsFixed(2); // 30% downpayment
                  }
                });
              }
            },
            validator: (value) =>
                value == null ? 'Please select a payment method' : null,
          ),

          const SizedBox(height: 16),

          // Payment Amount
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              hintText: 'Enter amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money),
              prefixText: '₱ ',
              suffixIcon: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Show payment information/guidelines
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Payment Guidelines'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '• Full Payment: ₱${_totalFee.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          Text(
                              '• Minimum Downpayment: ₱${(_totalFee * 0.3).toStringAsFixed(2)} (30%)'),
                          const SizedBox(height: 8),
                          Text(
                              '• Family Discount Applied: ₱${_familyDiscount.toStringAsFixed(2)}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Notes Field
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Enter any additional notes or reference numbers',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.note),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _recordPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...'),
                      ],
                    )
                  : const Text('Record Payment'),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStudentInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: SMSTheme.primaryColor.withOpacity(0.1),
                  radius: 24,
                  child: Text(
                    _studentInfo!['firstName']?.isNotEmpty == true
                        ? _studentInfo!['firstName'][0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      fontSize: 20,
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
                        _studentInfo!['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Student ID: ${_studentIdController.text}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isScholar)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Scholar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Grade/Level',
                    _studentInfo!['gradeLevel'] ?? 'N/A',
                    Icons.grade,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Course',
                    _studentInfo!['course'] ?? 'N/A',
                    Icons.school,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Semester',
                    _studentInfo!['semester'] ?? '1st',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Student Type',
                    _studentInfo!['studentType'] ?? 'Regular',
                    Icons.person,
                  ),
                ),
              ],
            ),

            // Add Family Members count (with ability to edit)
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Members Enrolled:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: _familyMemberCount > 1
                          ? () {
                              setState(() {
                                _familyMemberCount--;
                                _fetchFees(
                                  _studentInfo!['gradeLevel'] ?? '',
                                  _studentInfo!['course'] ?? '',
                                  _studentInfo!['semester'] ?? '1st',
                                  _studentInfo!['studentType'] ?? 'Payee',
                                );
                              });
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: SMSTheme.primaryColor,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_familyMemberCount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () {
                        setState(() {
                          _familyMemberCount++;
                          _fetchFees(
                            _studentInfo!['gradeLevel'] ?? '',
                            _studentInfo!['course'] ?? '',
                            _studentInfo!['semester'] ?? '1st',
                            _studentInfo!['studentType'] ?? 'Payee',
                          );
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: SMSTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
            if (_familyMemberCount >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Family discount applied: ₱${_familyDiscount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SMSTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdownCard(NumberFormat currencyFormat) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SMSTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _paymentMethod,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: SMSTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fee Items List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._fees
                        .map((fee) => _buildFeeItem(
                              fee['name'],
                              fee['amount'].toDouble(),
                              currencyFormat,
                            ))
                        .toList(),

                    if (_familyDiscount > 0) ...[
                      const Divider(height: 24),
                      _buildFeeItem(
                        'Family Discount',
                        -_familyDiscount,
                        currencyFormat,
                        isDiscount: true,
                      ),
                    ],

                    const Divider(height: 24),

                    // Total Fee
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Fee:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          currencyFormat.format(_totalFee),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isScholar
                                ? Colors.green.shade700
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Payment amount to be recorded
                    if (!_isScholar &&
                        _amountController.text.isNotEmpty &&
                        double.tryParse(_amountController.text) != null) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            currencyFormat
                                .format(double.parse(_amountController.text)),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Remaining balance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Remaining Balance:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            currencyFormat.format(max(
                                0.0,
                                _totalFee -
                                    double.parse(_amountController.text))),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_isScholar) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scholarship Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  Text(
                                    'All fees covered by scholarship',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
