import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import 'ReceiptGenerationScreen.dart';

class StudentsPaymentHistoryScreen extends StatefulWidget {
  final String? studentId;
  
  const StudentsPaymentHistoryScreen({Key? key, this.studentId}) : super(key: key);

  @override
  _StudentsPaymentHistoryScreenState createState() => _StudentsPaymentHistoryScreenState();
}

class _StudentsPaymentHistoryScreenState extends State<StudentsPaymentHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _darkMode = false;
  
  // Search and filter state
  String _searchQuery = '';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  Map<String, dynamic>? _selectedStudent;
  
  // Payment history
  List<Map<String, dynamic>> _paymentHistory = [];
  List<Map<String, dynamic>> _filteredPaymentHistory = [];
  
  // Strict limits for performance
  final int _studentLimit = 10; // Reduced from 100
  final int _paymentLimit = 5; // Strict limit on payments
  
  // Firestore batch management
  DocumentSnapshot? _lastStudentDocument;
  bool _hasMoreStudents = false;
  DocumentSnapshot? _lastPaymentDocument;
  bool _hasMorePayments = false;
  
  // Add debug info
  String _debugInfo = 'Screen loaded';
  
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  
  @override
  void initState() {
    super.initState();
    _addDebugLog('initState called');
    _loadUserPreferences();
    
    // If studentId was passed, load that student directly
    if (widget.studentId != null) {
      _addDebugLog('Loading student by ID: ${widget.studentId}');
      _loadStudentById(widget.studentId!);
    } else {
      // Load students list with strict limits
      _addDebugLog('Loading student list');
      _loadStudents();
    }
  }
  
  // Debug helper method
  void _addDebugLog(String message) {
    print('DEBUG: $message');
    setState(() {
      _debugInfo = message;
    });
  }
  
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkMode = prefs.getBool('darkMode') ?? false;
      });
      _addDebugLog('User preferences loaded');
    } catch (e) {
      _addDebugLog('Error loading user preferences: $e');
    }
  }
  
  Future<void> _loadStudents() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    _addDebugLog('Loading students...');
    
    try {
      // Use a very strict limit for performance
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .orderBy('lastName')
          .limit(_studentLimit)
          .get()
          .timeout(const Duration(seconds: 10)); // Add timeout
      
      _addDebugLog('Student data received. Count: ${studentsSnapshot.docs.length}');
      
      List<Map<String, dynamic>> students = [];
      
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        students.add({
          'id': doc.id,
          'firstName': data['firstName'] ?? '',
          'middleName': data['middleName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'gradeLevel': data['gradeLevel'] ?? '',
          'status': data['status'] ?? 'Active',
          'studentNumber': data['studentNumber'] ?? '',
          'section': data['section'] ?? '',
        });
      }
      
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
        _lastStudentDocument = studentsSnapshot.docs.isNotEmpty 
            ? studentsSnapshot.docs.last 
            : null;
        _hasMoreStudents = studentsSnapshot.docs.length >= _studentLimit;
      });
      
      _addDebugLog('Student list loaded successfully');
    } catch (e) {
      _addDebugLog('Error loading students: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load students: $e';
      });
    }
  }
  
  Future<void> _loadStudentById(String studentId) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    _addDebugLog('Loading student by ID: $studentId');
    
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get()
          .timeout(const Duration(seconds: 5)); // Add timeout
      
      if (studentDoc.exists) {
        _addDebugLog('Student found');
        final data = studentDoc.data() as Map<String, dynamic>;
        
        // Create student object
        final Map<String, dynamic> student = {
          'id': studentDoc.id,
          'firstName': data['firstName'] ?? '',
          'middleName': data['middleName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'gradeLevel': data['gradeLevel'] ?? '',
          'status': data['status'] ?? 'Active',
          'studentNumber': data['studentNumber'] ?? '',
          'section': data['section'] ?? '',
        };
        
        setState(() {
          _selectedStudent = student;
          _isLoading = false;
        });
        
        // Load payment history for this student (limited)
        _loadPaymentHistory(studentId);
      } else {
        _addDebugLog('Student not found');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Student not found with ID: $studentId';
        });
      }
    } catch (e) {
      _addDebugLog('Error loading student: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load student data: $e';
      });
    }
  }
  
  Future<void> _loadPaymentHistory(String studentId) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _paymentHistory = []; // Clear existing data
      _filteredPaymentHistory = [];
    });
    
    _addDebugLog('Loading payment history...');
    
    try {
      // Use very strict limit for performance
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .limit(_paymentLimit) // Use strict limit
          .get()
          .timeout(const Duration(seconds: 10)); // Add timeout
      
      _addDebugLog('Payment data received. Count: ${paymentsSnapshot.docs.length}');
      
      List<Map<String, dynamic>> payments = [];
      
      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        try {
          payments.add({
            'id': doc.id,
            'amount': (data['amount'] as num).toDouble(),
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
            'paymentMethod': data['paymentMethod'] ?? 'Cash',
            'paymentType': data['paymentType'] ?? 'Tuition Fee',
            'receiptNumber': data['receiptNumber'] ?? '',
            'receiptGenerated': data['receiptGenerated'] ?? false,
            'remarks': data['remarks'] ?? '',
            'processedBy': data['processedBy'] ?? '',
          });
        } catch (e) {
          _addDebugLog('Error processing payment document: $e');
          // Skip this document if there's an error
        }
      }
      
      setState(() {
        _paymentHistory = payments;
        _filteredPaymentHistory = payments;
        _isLoading = false;
        _lastPaymentDocument = paymentsSnapshot.docs.isNotEmpty 
            ? paymentsSnapshot.docs.last 
            : null;
        _hasMorePayments = paymentsSnapshot.docs.length >= _paymentLimit;
      });
      
      _addDebugLog('Payment history loaded successfully');
    } catch (e) {
      _addDebugLog('Error loading payment history: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load payment history: $e';
      });
    }
  }
  
  void _searchStudents(String query) {
    _addDebugLog('Searching students: $query');
    
    setState(() {
      _searchQuery = query;
      
      // Simple client-side filtering with strict limit
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final fullName = '${student['lastName']} ${student['firstName']} ${student['middleName']}'.toLowerCase();
          final studentNumber = student['studentNumber'].toString().toLowerCase();
          
          return fullName.contains(query.toLowerCase()) || 
                 studentNumber.contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  void _selectStudent(Map<String, dynamic> student) {
    _addDebugLog('Student selected: ${student['id']}');
    
    setState(() {
      _selectedStudent = student;
    });
    
    // Load payment history for selected student
    _loadPaymentHistory(student['id']);
  }
  
  @override
  Widget build(BuildContext context) {
    // Apply theme based on dark mode preference
    final colorScheme = _darkMode 
        ? ColorScheme.dark(
            primary: SMSTheme.primaryColor,
            secondary: SMSTheme.accentColor,
            surface: Colors.grey.shade900,
            background: Colors.black,
          )
        : ColorScheme.light(
            primary: SMSTheme.primaryColor,
            secondary: SMSTheme.accentColor,
            surface: Colors.white,
            background: SMSTheme.backgroundColor,
          );

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Payment History'),
          backgroundColor: SMSTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () async {
                setState(() {
                  _darkMode = !_darkMode;
                });
                
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('darkMode', _darkMode);
                } catch (e) {
                  print('Error saving dark mode preference: $e');
                }
              },
              tooltip: _darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _darkMode 
                  ? [Colors.black, Colors.grey.shade900] 
                  : [SMSTheme.backgroundColor, Colors.white],
            ),
          ),
          child: Column(
            children: [
              // Debug info banner (only in development)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange,
                width: double.infinity,
                child: Text(
                  'DEBUG: $_debugInfo',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              
              Expanded(
                child: _hasError
                    ? _buildErrorView()
                    : _isLoading
                        ? _buildLoadingIndicator()
                        : _selectedStudent == null
                            ? _buildStudentSearchArea()
                            : _buildStudentDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.studentId != null) {
                _loadStudentById(widget.studentId!);
              } else {
                _loadStudents();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: SMSTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading data...',
            style: TextStyle(
              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentSearchArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search student by name or ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchStudents('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: _darkMode ? Colors.grey.shade800 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _searchStudents,
          ),
          
          const SizedBox(height: 16),
          
          // Student count
          Text(
            'Students (${_filteredStudents.length}${_hasMoreStudents ? "+" : ""})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Students list
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No students found'
                          : 'No results for "$_searchQuery"',
                      style: TextStyle(
                        color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStudents.length + (_hasMoreStudents ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _filteredStudents.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: _loadMoreStudents,
                              child: const Text('Load More'),
                            ),
                          ),
                        );
                      }
                      
                      final student = _filteredStudents[index];
                      return _buildStudentListItem(student);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadMoreStudents() async {
    _addDebugLog('Loading more students...');
    
    if (_isLoading || !_hasMoreStudents || _lastStudentDocument == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final moreStudentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .orderBy('lastName')
          .startAfterDocument(_lastStudentDocument!)
          .limit(_studentLimit)
          .get();
      
      List<Map<String, dynamic>> moreStudents = [];
      
      for (var doc in moreStudentsSnapshot.docs) {
        final data = doc.data();
        moreStudents.add({
          'id': doc.id,
          'firstName': data['firstName'] ?? '',
          'middleName': data['middleName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'gradeLevel': data['gradeLevel'] ?? '',
          'status': data['status'] ?? 'Active',
          'studentNumber': data['studentNumber'] ?? '',
          'section': data['section'] ?? '',
        });
      }
      
      setState(() {
        _students.addAll(moreStudents);
        
        // If there's a search query, filter the new students too
        if (_searchQuery.isEmpty) {
          _filteredStudents = _students;
        } else {
          _searchStudents(_searchQuery); // Re-apply the search
        }
        
        _lastStudentDocument = moreStudentsSnapshot.docs.isNotEmpty 
            ? moreStudentsSnapshot.docs.last 
            : _lastStudentDocument;
        _hasMoreStudents = moreStudentsSnapshot.docs.length >= _studentLimit;
        _isLoading = false;
      });
      
      _addDebugLog('Loaded ${moreStudentsSnapshot.docs.length} more students');
    } catch (e) {
      _addDebugLog('Error loading more students: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildStudentListItem(Map<String, dynamic> student) {
    return Card(
      elevation: 1, // Reduced elevation for performance
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: _darkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => _selectStudent(student),
        leading: CircleAvatar(
          backgroundColor: SMSTheme.primaryColor,
          child: Text(
            student['firstName'].isNotEmpty ? student['firstName'][0].toUpperCase() : 'S',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${student['lastName']}, ${student['firstName']} ${student['middleName']}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          'ID: ${student['studentNumber']} | Grade: ${student['gradeLevel']}',
          style: TextStyle(
            color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: student['status'] == 'Active' 
                ? Colors.green.withOpacity(0.1) 
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            student['status'] ?? 'Active',
            style: TextStyle(
              color: student['status'] == 'Active' ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStudentDetails() {
    return Column(
      children: [
        // Student header
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    _selectedStudent = null;
                    _paymentHistory = [];
                    _filteredPaymentHistory = [];
                  });
                  _addDebugLog('Returned to student list');
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedStudent!['lastName']}, ${_selectedStudent!['firstName']} ${_selectedStudent!['middleName']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${_selectedStudent!['studentNumber']} | Grade: ${_selectedStudent!['gradeLevel']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedStudent!['status'] == 'Active' 
                      ? Colors.green 
                      : Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _selectedStudent!['status'] ?? 'Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Payment summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _darkMode ? Colors.grey.shade900.withOpacity(0.8) : Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment History (${_filteredPaymentHistory.length}${_hasMorePayments ? "+" : ""})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                ),
              ),
              Text(
                'Total: ${currencyFormat.format(_calculateTotalAmount())}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        
        // Payment list
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
                  ),
                )
              : _filteredPaymentHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No payment records found',
                            style: TextStyle(
                              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPaymentHistory.length + (_hasMorePayments ? 1 : 0),
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        if (index >= _filteredPaymentHistory.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: _loadMorePayments,
                                child: const Text('Load More Payments'),
                              ),
                            ),
                          );
                        }
                        
                        final payment = _filteredPaymentHistory[index];
                        return _buildPaymentHistoryItem(payment);
                      },
                    ),
        ),
      ],
    );
  }
  
  double _calculateTotalAmount() {
    double total = 0;
    for (var payment in _filteredPaymentHistory) {
      total += payment['amount'];
    }
    return total;
  }
  
  Future<void> _loadMorePayments() async {
    _addDebugLog('Loading more payments...');
    
    if (_isLoading || !_hasMorePayments || _lastPaymentDocument == null || _selectedStudent == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final morePaymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('studentId', isEqualTo: _selectedStudent!['id'])
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastPaymentDocument!)
          .limit(_paymentLimit)
          .get();
      
      List<Map<String, dynamic>> morePayments = [];
      
      for (var doc in morePaymentsSnapshot.docs) {
        final data = doc.data();
        morePayments.add({
          'id': doc.id,
          'amount': (data['amount'] as num).toDouble(),
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'paymentMethod': data['paymentMethod'] ?? 'Cash',
          'paymentType': data['paymentType'] ?? 'Tuition Fee',
          'receiptNumber': data['receiptNumber'] ?? '',
          'receiptGenerated': data['receiptGenerated'] ?? false,
          'remarks': data['remarks'] ?? '',
          'processedBy': data['processedBy'] ?? '',
        });
      }
      
      setState(() {
        _paymentHistory.addAll(morePayments);
        _filteredPaymentHistory = List.from(_paymentHistory);
        
        _lastPaymentDocument = morePaymentsSnapshot.docs.isNotEmpty 
            ? morePaymentsSnapshot.docs.last 
            : _lastPaymentDocument;
        _hasMorePayments = morePaymentsSnapshot.docs.length >= _paymentLimit;
        _isLoading = false;
      });
      
      _addDebugLog('Loaded ${morePaymentsSnapshot.docs.length} more payments');
    } catch (e) {
      _addDebugLog('Error loading more payments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    // Use a simpler design for better performance
    return Card(
      elevation: 1, // Reduced elevation
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: _darkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => _showPaymentDetails(payment),
        title: Row(
          children: [
            Expanded(
              child: Text(
                payment['paymentType'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                ),
              ),
            ),
            Text(
              currencyFormat.format(payment['amount']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                'Method: ${payment['paymentMethod']} • ${DateFormat('MMM d, yyyy').format(payment['timestamp'])}',
                style: TextStyle(
                  color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                ),
              ),
            ),
            if (payment['receiptNumber'].isNotEmpty)
              Text(
                '#${payment['receiptNumber']}',
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.primaryColor,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.receipt),
          onPressed: () {
            // Generate or view receipt
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptGenerationScreen(),
              ),
            ).then((_) {
              // Refresh data when returning from receipt screen
              if (_selectedStudent != null) {
                _loadPaymentHistory(_selectedStudent!['id']);
              }
            });
          },
          tooltip: 'View/Generate Receipt',
        ),
      ),
    );
  }
  
  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Details',
          style: TextStyle(
            color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Payment Type', payment['paymentType']),
              _buildDetailItem('Amount', currencyFormat.format(payment['amount']), isBold: true),
              _buildDetailItem('Payment Method', payment['paymentMethod']),
              _buildDetailItem('Date', DateFormat('MMMM d, yyyy').format(payment['timestamp'])),
              _buildDetailItem('Receipt Number', payment['receiptNumber'].isNotEmpty ? payment['receiptNumber'] : 'Not Generated'),
              _buildDetailItem('Transaction ID', payment['id']),
              if (payment['remarks'].isNotEmpty)
                _buildDetailItem('Remarks', payment['remarks']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to receipt generation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptGenerationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.receipt),
            label: Text(payment['receiptGenerated'] ? 'View Receipt' : 'Generate Receipt'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _darkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: _darkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}