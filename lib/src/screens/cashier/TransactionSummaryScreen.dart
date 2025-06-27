import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import 'ReceiptGenerationScreen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class TransactionSummaryScreen extends StatefulWidget {
  const TransactionSummaryScreen({super.key});

  @override
  _TransactionSummaryScreenState createState() =>
      _TransactionSummaryScreenState();
}

class _TransactionSummaryScreenState extends State<TransactionSummaryScreen>
    with SingleTickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterType = 'All';
  bool _isFilterExpanded = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _darkMode = false;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Data
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  List<String> _selectedTransactionIds = [];
  double _totalAmount = 0;
  Map<String, double> _paymentTypeBreakdown = {};
  Map<String, double> _paymentMethodBreakdown = {};

  // For chart visualization
  late TabController _tabController;
  List<FlSpot> _dailyTransactionSpots = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPreferences();

    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkMode = prefs.getBool('darkMode') ?? false;
      });
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _darkMode);
    } catch (e) {
      print('Error saving user preferences: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('payments');

      // Apply date filters if set
      if (_startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      }
      if (_endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
      }

      // Apply payment type filter if not "All"
      if (_filterType != 'All') {
        query = query.where('paymentType', isEqualTo: _filterType);
      }

      // Order by timestamp (descending)
      query = query.orderBy('timestamp', descending: true);

      final snapshot = await query.get();
      final transactions = snapshot.docs;

      List<Map<String, dynamic>> transactionList = [];
      double totalAmount = 0;
      Map<String, double> typeBreakdown = {};
      Map<String, double> methodBreakdown = {};
      Map<DateTime, double> dailyAmounts = {};

      for (var doc in transactions) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract student info
        Map<String, dynamic> studentInfo = {};
        if (data.containsKey('studentInfo') && data['studentInfo'] is Map) {
          studentInfo = Map<String, dynamic>.from(data['studentInfo']);
        }

        // Get payment details
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final paymentType = data['paymentType'] as String? ?? 'Other';
        final paymentMethod = data['paymentMethod'] as String? ?? 'Cash';
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        // Update total amount
        totalAmount += amount;

        // Update type breakdown
        typeBreakdown[paymentType] = (typeBreakdown[paymentType] ?? 0) + amount;

        // Update method breakdown
        methodBreakdown[paymentMethod] =
            (methodBreakdown[paymentMethod] ?? 0) + amount;

        // Update daily amounts for chart
        final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
        dailyAmounts[day] = (dailyAmounts[day] ?? 0) + amount;

        // Add to transaction list
        transactionList.add({
          'id': doc.id,
          'studentId': data['studentId'],
          'studentName': _formatStudentName(studentInfo),
          'amount': amount,
          'paymentType': paymentType,
          'paymentMethod': paymentMethod,
          'timestamp': timestamp,
          'receiptGenerated': data['receiptGenerated'] ?? false,
          'remarks': data['remarks'] ?? '',
          'cashierName': data['cashierName'] ?? '',
          'status': data['status'] ?? 'active', // 'active', 'voided'
          'voidedBy': data['voidedBy'],
          'voidedAt': data['voidedAt'],
          'voidReason': data['voidReason'],
        });
      }

      // Convert daily amounts to FlSpots for chart
      List<FlSpot> dailySpots = [];
      if (dailyAmounts.isNotEmpty) {
        // Sort days
        List<DateTime> sortedDays = dailyAmounts.keys.toList()..sort();

        // Fill in missing days with zero values
        DateTime currentDay = sortedDays.first;
        DateTime lastDay = sortedDays.last;

        while (currentDay.isBefore(lastDay) ||
            currentDay.isAtSameMomentAs(lastDay)) {
          final value = dailyAmounts[currentDay] ?? 0.0;

          // X position is number of days since first day
          final xPos =
              currentDay.difference(sortedDays.first).inDays.toDouble();
          dailySpots.add(FlSpot(xPos, value));

          // Move to next day
          currentDay = currentDay.add(const Duration(days: 1));
        }
      }

      setState(() {
        _transactions = transactionList;
        _filteredTransactions = List.from(transactionList);
        _totalAmount = totalAmount;
        _paymentTypeBreakdown = typeBreakdown;
        _paymentMethodBreakdown = methodBreakdown;
        _dailyTransactionSpots = dailySpots;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load transactions. Please try again later.';
      });
    }
  }

  String _formatStudentName(Map<String, dynamic> studentInfo) {
    final firstName = studentInfo['firstName'] as String? ?? '';
    final lastName = studentInfo['lastName'] as String? ?? '';
    final middleName = studentInfo['middleName'] as String? ?? '';

    return lastName.isNotEmpty
        ? '$lastName, $firstName${middleName.isNotEmpty ? ' $middleName' : ''}'
        : 'Unknown Student';
  }

  void _filterTransactions(String query) {
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _filteredTransactions = List.from(_transactions);
      } else {
        _filteredTransactions = _transactions.where((transaction) {
          final studentId = transaction['studentId'].toString().toLowerCase();
          final studentName =
              transaction['studentName'].toString().toLowerCase();
          final paymentType =
              transaction['paymentType'].toString().toLowerCase();
          final paymentMethod =
              transaction['paymentMethod'].toString().toLowerCase();

          return studentId.contains(query.toLowerCase()) ||
              studentName.contains(query.toLowerCase()) ||
              paymentType.contains(query.toLowerCase()) ||
              paymentMethod.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _batchPrintReceipts() {
    // This would connect to actual printing functionality
    // For now, just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Print Receipts'),
        content: Text(
            'Printing ${_selectedTransactionIds.length} receipts...\n\nThis feature would connect to your printer service.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedTransactionIds.clear(); // Clear selection after action
              });
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _batchEmailReceipts() {
    // This would connect to email sending functionality
    // For now, just show a dialog
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Receipts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send ${_selectedTransactionIds.length} receipts to:'),
            SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'recipient@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter an email address')),
                );
                return;
              }

              Navigator.pop(context);
              // Here you would send the emails
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Receipts have been sent to $email')),
              );

              setState(() {
                _selectedTransactionIds.clear(); // Clear selection after action
              });
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final selectedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SMSTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange != null) {
      setState(() {
        _startDate = selectedRange.start;
        _endDate = DateTime(selectedRange.end.year, selectedRange.end.month,
            selectedRange.end.day, 23, 59, 59);
      });
      await _fetchTransactions();
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Create CSV data
      List<List<dynamic>> rows = [];

      // Add header row
      rows.add([
        'Transaction ID',
        'Student ID',
        'Student Name',
        'Payment Type',
        'Payment Method',
        'Amount',
        'Date',
        'Status'
      ]);

      // Add data rows
      for (var transaction in _filteredTransactions) {
        rows.add([
          transaction['id'],
          transaction['studentId'],
          transaction['studentName'],
          transaction['paymentType'],
          transaction['paymentMethod'],
          transaction['amount'],
          DateFormat('yyyy-MM-dd HH:mm').format(transaction['timestamp']),
          transaction['status'],
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Get document directory
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName =
          'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('$path/$fileName');

      // Write to file
      await file.writeAsString(csv);

      // Share the file (updated method)
      await Share.shareXFiles([XFile(file.path)], text: 'Transactions Export');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }

  Future<void> _exportToPDF() async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Transaction Summary',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Period: ${_startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : ''} - ${_endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : ''}'),
                pw.SizedBox(height: 10),
                pw.Text('Total Transactions: ${_filteredTransactions.length}'),
                pw.Text('Total Amount: ${currencyFormat.format(_totalAmount)}'),
                pw.SizedBox(height: 20),

                // Create table
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  border: pw.TableBorder.all(),
                  cellAlignment: pw.Alignment.center,
                  cellAlignments: {0: pw.Alignment.centerLeft},
                  headers: [
                    'ID',
                    'Student',
                    'Type',
                    'Method',
                    'Amount',
                    'Date',
                    'Status'
                  ],
                  data: _filteredTransactions
                      .map((transaction) => [
                            transaction['studentId'],
                            transaction['studentName'],
                            transaction['paymentType'],
                            transaction['paymentMethod'],
                            currencyFormat.format(transaction['amount']),
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(transaction['timestamp']),
                            transaction['status'],
                          ])
                      .toList(),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName =
          'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('$path/$fileName');

      await file.writeAsBytes(await pdf.save());

      // Share the file
      await Share.shareXFiles([XFile(file.path)],
          text: 'Transactions PDF Export');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  void _sort<T>(Function(Map<String, dynamic>) getField, int columnIndex,
      bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _filteredTransactions.sort((a, b) {
        if (!ascending) {
          final temp = a;
          a = b;
          b = temp;
        }

        final aValue = getField(a);
        final bValue = getField(b);

        return Comparable.compare(aValue, bValue);
      });
    });
  }

  void _showEditDialog(Map<String, dynamic> transaction) {
    // Create controllers pre-filled with current values
    final amountController =
        TextEditingController(text: transaction['amount'].toString());
    final remarksController =
        TextEditingController(text: transaction['remarks'] ?? '');
    String selectedPaymentType = transaction['paymentType'];
    String selectedPaymentMethod = transaction['paymentMethod'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${transaction['studentName']}'),
              Text('ID: ${transaction['studentId']}'),
              SizedBox(height: 16),

              // Edit payment type
              DropdownButtonFormField<String>(
                value: selectedPaymentType,
                decoration: InputDecoration(labelText: 'Payment Type'),
                items: [
                  'Tuition Fee',
                  'Registration',
                  'Downpayment',
                  'Books',
                  'Uniform',
                  'Miscellaneous',
                  'Scholarship'
                ]
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => selectedPaymentType = value!,
              ),

              // Edit payment method
              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                decoration: InputDecoration(labelText: 'Payment Method'),
                items: [
                  'Cash',
                  'Credit Card',
                  'Debit Card',
                  'Online Transfer',
                  'Check',
                  'Scholarship',
                  'Installment'
                ]
                    .map((method) =>
                        DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => selectedPaymentMethod = value!,
              ),

              // Edit amount
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),

              // Edit remarks
              TextField(
                controller: remarksController,
                decoration: InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Show confirmation dialog for this sensitive operation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Edit'),
                  content: Text(
                      'Are you sure you want to edit this transaction? This will be logged in the system audit trail.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Update transaction in Firestore with audit trail
                        FirebaseFirestore.instance
                            .collection('payments')
                            .doc(transaction['id'])
                            .update({
                          'paymentType': selectedPaymentType,
                          'paymentMethod': selectedPaymentMethod,
                          'amount': double.parse(amountController.text),
                          'remarks': remarksController.text,
                          'lastModifiedBy':
                              FirebaseAuth.instance.currentUser?.displayName,
                          'lastModifiedAt': Timestamp.now(),
                          'editHistory': FieldValue.arrayUnion([
                            {
                              'timestamp': Timestamp.now(),
                              'modifiedBy': FirebaseAuth
                                  .instance.currentUser?.displayName,
                              'previousValues': {
                                'paymentType': transaction['paymentType'],
                                'paymentMethod': transaction['paymentMethod'],
                                'amount': transaction['amount'],
                                'remarks': transaction['remarks'] ?? '',
                              }
                            }
                          ])
                        }).then((_) {
                          // Close both dialogs and refresh transactions
                          Navigator.pop(context);
                          Navigator.pop(context);
                          _fetchTransactions();
                        });
                      },
                      child: Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              );
            },
            child: Text('Save Changes'),
            style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  void _showVoidDialog(Map<String, dynamic> transaction) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Void Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to void this transaction?'),
            SizedBox(height: 8),
            Text(
                'Transaction: ${transaction['paymentType']} - ${currencyFormat.format(transaction['amount'])}'),
            Text('Student: ${transaction['studentName']}'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Voiding *',
                hintText: 'Please provide a detailed reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('A reason is required to void a transaction')));
                return;
              }

              // Update the transaction status but don't delete it
              FirebaseFirestore.instance
                  .collection('payments')
                  .doc(transaction['id'])
                  .update({
                'status': 'voided',
                'voidedBy': FirebaseAuth.instance.currentUser?.displayName,
                'voidedAt': Timestamp.now(),
                'voidReason': reasonController.text.trim(),
              }).then((_) {
                // Close dialog and refresh data
                Navigator.pop(context);
                _fetchTransactions();

                // Create an audit log entry
                FirebaseFirestore.instance.collection('audit_logs').add({
                  'action': 'transaction_voided',
                  'transactionId': transaction['id'],
                  'performedBy': FirebaseAuth.instance.currentUser?.displayName,
                  'timestamp': Timestamp.now(),
                  'details': {
                    'studentId': transaction['studentId'],
                    'amount': transaction['amount'],
                    'paymentType': transaction['paymentType'],
                    'reason': reasonController.text.trim(),
                  }
                });
              });
            },
            child: Text('Void Transaction'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Export Transactions'),
        children: [
          ListTile(
            leading: Icon(Icons.table_chart),
            title: Text('Export to CSV'),
            onTap: () {
              Navigator.pop(context);
              _exportToCSV();
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Export to PDF'),
            onTap: () {
              Navigator.pop(context);
              _exportToPDF();
            },
          ),
        ],
      ),
    );
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
          title: const Text('Transaction Summarysssss'),
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _darkMode = !_darkMode;
                  _saveUserPreferences();
                });
              },
              tooltip:
                  _darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: _selectDateRange,
              tooltip: 'Select Date Range',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchTransactions,
              tooltip: 'Refresh Data',
            ),
            IconButton(
              icon: Icon(Icons.download),
              tooltip: 'Export Transactions',
              onPressed: () => _showExportOptions(),
            ),
          ],
        ),
        body: _hasError
            ? _buildErrorView()
            : _isLoading
                ? _buildLoadingIndicator()
                : _buildTransactionSummary(),
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
          Text(
            _errorMessage,
            style: TextStyle(
              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
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
            'Loading transactions...',
            style: TextStyle(
              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Container(
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
          // Summary header
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            child: _buildSummaryHeader(),
          ),

          // Filters section
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 100),
            child: _buildFiltersSection(),
          ),

          // Tab bar
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey.shade900 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Analytics'),
                ],
                labelColor: SMSTheme.primaryColor,
                unselectedLabelColor:
                    _darkMode ? Colors.white70 : Colors.grey.shade600,
                indicatorColor: SMSTheme.primaryColor,
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Transactions list tab
                _buildTransactionsTab(),

                // Analytics tab
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSummaryHeader() {
  final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _darkMode ? Colors.grey.shade900 : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
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
                    'Transactions Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  if (_startDate != null && _endDate != null)
                    Text(
                      'Period: ${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}',
                      style: TextStyle(
                        color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 16),
              label: const Text('Change Period'),
              onPressed: _selectDateRange,
              style: OutlinedButton.styleFrom(
                foregroundColor: SMSTheme.primaryColor,
                side: BorderSide(color: SMSTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary cards - Updated to prevent overflow
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = isLargeScreen ? 4 : 2;
            final cardWidth = (constraints.maxWidth - (16 * (crossAxisCount - 1))) / crossAxisCount;
            
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(
                    'Total Transactions',
                    _filteredTransactions.length.toString(),
                    Icons.receipt_long,
                    SMSTheme.primaryColor,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(
                    'Total Amount',
                    currencyFormat.format(_totalAmount),
                    Icons.monetization_on,
                    Colors.green.shade700,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(
                    'Average Transaction',
                    _filteredTransactions.isEmpty
                        ? currencyFormat.format(0)
                        : currencyFormat.format(_totalAmount / _filteredTransactions.length),
                    Icons.trending_up,
                    Colors.orange.shade700,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(
                    'Payment Types',
                    _paymentTypeBreakdown.length.toString(),
                    Icons.category,
                    Colors.purple.shade700,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _darkMode ? Colors.grey.shade800 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important: Let the card size itself
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12, // Reduced from 14
                  color: _darkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                maxLines: 2, // Allow wrapping
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, // Reduced from 16
            fontWeight: FontWeight.bold,
            color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _buildFiltersSection() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _darkMode ? Colors.grey.shade900 : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // Important: let the column size itself
      children: [
        // Search bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  filled: true,
                  fillColor: _darkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterTransactions('');
                          },
                        )
                      : null,
                ),
                onChanged: _filterTransactions,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isFilterExpanded ? Icons.expand_less : Icons.filter_list),
              onPressed: () {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              },
              tooltip: 'Filters',
            ),
          ],
        ),

        // Expanded filters section with proper animation
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isFilterExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(), // When collapsed
          secondChild: Padding( // When expanded
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Type'),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: _filterType,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: 'All', child: Text('All Types')),
                              ...List.generate(
                                _paymentTypeBreakdown.keys.length,
                                (index) {
                                  final type = _paymentTypeBreakdown.keys.elementAt(index);
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                },
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filterType = value!;
                              });
                              _fetchTransactions();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Date'),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: 'Custom',
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                              DropdownMenuItem(value: 'Today', child: Text('Today')),
                              DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                              DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                              DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                final now = DateTime.now();
                                switch (value) {
                                  case 'Today':
                                    _startDate = DateTime(now.year, now.month, now.day);
                                    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                                    break;
                                  case 'This Week':
                                    _startDate = now.subtract(Duration(days: now.weekday - 1));
                                    _endDate = _startDate!.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
                                    break;
                                  case 'This Month':
                                    _startDate = DateTime(now.year, now.month, 1);
                                    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                                    break;
                                  case 'Last Month':
                                    _startDate = DateTime(now.year, now.month - 1, 1);
                                    _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
                                    break;
                                  default:
                                    break;
                                }
                              });
                              _fetchTransactions();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterType = 'All';
                          _searchController.clear();
                          _searchQuery = '';
                          final now = DateTime.now();
                          _startDate = DateTime(now.year, now.month, 1);
                          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                        });
                        _fetchTransactions();
                      },
                      child: const Text('Reset Filters'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isFilterExpanded = false;
                        });
                        _fetchTransactions();
                      },
                      child: const Text('Apply Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SMSTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
 
Widget _buildTransactionsTab() {
    if (_filteredTransactions.isEmpty) {
      return Center(
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
              _searchQuery.isEmpty && _filterType == 'All'
                  ? 'No transactions found for this period'
                  : 'No transactions match your search criteria',
              style: TextStyle(
                fontSize: 16,
                color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // If _selectedTransactionIds is not empty, show the batch actions bar
        if (_selectedTransactionIds.isNotEmpty)
          Container(
            padding: EdgeInsets.all(8),
            color: _darkMode
                ? Colors.grey.shade800.withOpacity(0.9)
                : Colors.grey.shade200,
            child: Row(
              children: [
                Text('${_selectedTransactionIds.length} selected',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                ElevatedButton.icon(
                  icon: Icon(Icons.print),
                  label: Text('Print Receipts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _batchPrintReceipts(),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.email),
                  label: Text('Email Receipts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _batchEmailReceipts(),
                ),
              ],
            ),
          ),
        // Show the data table
        Expanded(child: _buildDataTable()),
      ],
    );
  }

Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: true, // Enable selection
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingRowColor: MaterialStateProperty.all(_darkMode
              ? Colors.grey.shade800
              : SMSTheme.primaryColor.withOpacity(0.1)),
          border: TableBorder.all(
            color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 0.5,
          ),
          onSelectAll: (isSelected) {
            setState(() {
              _selectedTransactionIds = isSelected == true
                  ? _filteredTransactions.map((t) => t['id'] as String).toList()
                  : [];
            });
          },
          columns: [
            DataColumn(
              label: Text('ID'),
              onSort: (columnIndex, ascending) {
                _sort((transaction) => transaction['studentId'], columnIndex,
                    ascending);
              },
            ),
            DataColumn(
              label: Text('Student'),
              onSort: (columnIndex, ascending) {
                _sort((transaction) => transaction['studentName'], columnIndex,
                    ascending);
              },
            ),
            DataColumn(
                label: Text('Type/Status'),
                onSort: (columnIndex, ascending) {
                  _sort((transaction) => transaction['paymentType'],
                      columnIndex, ascending);
                }),
            DataColumn(label: Text('Method')),
            DataColumn(
              label: Text('Amount'),
              numeric: true,
              onSort: (columnIndex, ascending) {
                _sort((transaction) => transaction['amount'], columnIndex,
                    ascending);
              },
            ),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _filteredTransactions.map((transaction) {
            final isSelected =
                _selectedTransactionIds.contains(transaction['id']);

            return DataRow(
              selected: isSelected,
              onSelectChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    _selectedTransactionIds.add(transaction['id'] as String);
                  } else {
                    _selectedTransactionIds.remove(transaction['id'] as String);
                  }
                });
              },
              cells: [
                DataCell(Text(transaction['studentId'] ?? 'N/A')),
                DataCell(Text(transaction['studentName'])),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color:
                              _getPaymentTypeColor(transaction['paymentType'])
                                  .withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getPaymentTypeIcon(transaction['paymentType']),
                          size: 8,
                          color:
                              _getPaymentTypeColor(transaction['paymentType']),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(transaction['paymentType']),
                      if (transaction['status'] == 'voided')
                        Container(
                          margin: EdgeInsets.only(left: 4),
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'VOID',
                            style: TextStyle(
                                color: Colors.red.shade800, fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(Text(transaction['paymentMethod'])),
                DataCell(
                  Text(
                    currencyFormat.format(transaction['amount']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                DataCell(
                  Text(DateFormat('yyyy-MM-dd HH:mm')
                      .format(transaction['timestamp'])),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        onPressed: transaction['status'] != 'voided'
                            ? () => _showEditDialog(transaction)
                            : null,
                        tooltip: 'Edit',
                        constraints:
                            BoxConstraints(maxWidth: 28, maxHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: Icon(Icons.money_off, size: 18),
                        onPressed: transaction['status'] == 'active'
                            ? () => _showVoidDialog(transaction)
                            : null,
                        tooltip: 'Void',
                        constraints:
                            BoxConstraints(maxWidth: 28, maxHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: Icon(Icons.receipt, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceiptGenerationScreen(
                                  paymentId: transaction['id']),
                            ),
                          ).then((_) => _fetchTransactions());
                        },
                        tooltip: 'Receipt',
                        constraints:
                            BoxConstraints(maxWidth: 28, maxHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

// Helper method to create table header cells
Widget _buildTableHeaderCell(String text, {bool isNumeric = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: _darkMode ? Colors.white : SMSTheme.primaryColor,
        ),
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      ),
    );
  }

// Helper method to create table body cells
Widget _buildTableCell(
      {required Widget content,
      Alignment alignment = Alignment.centerLeft,
      required Function() onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        height: 48,
        alignment: alignment,
        child: content,
      ),
    );
  }

Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      color: _darkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getPaymentTypeColor(transaction['paymentType']),
          child: Icon(
            _getPaymentTypeIcon(transaction['paymentType']),
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction['studentName'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              currencyFormat.format(transaction['amount']),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${transaction['studentId']} • ${transaction['paymentType']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _darkMode
                          ? Colors.white70
                          : SMSTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'via ${transaction['paymentMethod']} • ${transaction['cashierName'].isNotEmpty ? 'by ${transaction['cashierName']}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _darkMode
                          ? Colors.white70
                          : SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('MMM d, yyyy').format(transaction['timestamp']),
              style: TextStyle(
                fontSize: 12,
                color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.receipt),
          onPressed: () {
            // Navigate to receipt generation
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReceiptGenerationScreen(paymentId: transaction['id']),
              ),
            ).then((_) {
              // Refresh after returning
              _fetchTransactions();
            });
          },
          tooltip: 'Generate Receipt',
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Transaction Details',
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
              _buildDetailRow('Student', transaction['studentName']),
              _buildDetailRow('Student ID', transaction['studentId']),
              _buildDetailRow(
                  'Amount', currencyFormat.format(transaction['amount']),
                  isBold: true),
              _buildDetailRow('Payment Type', transaction['paymentType']),
              _buildDetailRow('Payment Method', transaction['paymentMethod']),
              _buildDetailRow('Date',
                  DateFormat('MMMM d, yyyy').format(transaction['timestamp'])),
              _buildDetailRow('Time',
                  DateFormat('h:mm a').format(transaction['timestamp'])),
              _buildDetailRow('Processed By', transaction['cashierName']),
              _buildDetailRow('Receipt Generated',
                  transaction['receiptGenerated'] ? 'Yes' : 'No'),
              _buildDetailRow('Transaction ID', transaction['id']),
              if (transaction['remarks'].isNotEmpty)
                _buildDetailRow('Remarks', transaction['remarks']),
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
                  builder: (context) =>
                      ReceiptGenerationScreen(paymentId: transaction['id']),
                ),
              ).then((_) {
                // Refresh after returning
                _fetchTransactions();
              });
            },
            icon: const Icon(Icons.receipt),
            label: const Text('Generate Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
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

Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Trend Chart
          Card(
            elevation: 1,
            color: _darkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _startDate != null && _endDate != null
                        ? 'From ${DateFormat('MMM d').format(_startDate!)} to ${DateFormat('MMM d').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}'
                        : 'Period trend',
                    style: TextStyle(
                      fontSize: 14,
                      color: _darkMode
                          ? Colors.white70
                          : SMSTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _dailyTransactionSpots.isEmpty
                        ? Center(
                            child: Text(
                              'No data available for chart',
                              style: TextStyle(
                                color: _darkMode
                                    ? Colors.white70
                                    : SMSTheme.textSecondaryColor,
                              ),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1000,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: _darkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      if (_startDate == null ||
                                          value % 2 != 0) {
                                        return const SizedBox.shrink();
                                      }

                                      final date = _startDate!
                                          .add(Duration(days: value.toInt()));

                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          DateFormat('MMM d').format(date),
                                          style: TextStyle(
                                            color: _darkMode
                                                ? Colors.white70
                                                : SMSTheme.textSecondaryColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          currencyFormat
                                              .format(value)
                                              .replaceAll('.00', ''),
                                          style: TextStyle(
                                            color: _darkMode
                                                ? Colors.white70
                                                : SMSTheme.textSecondaryColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _dailyTransactionSpots,
                                  isCurved: true,
                                  color: SMSTheme.primaryColor,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color:
                                        SMSTheme.primaryColor.withOpacity(0.2),
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

          const SizedBox(height: 16),

          // Payment Type Breakdown
          Card(
            elevation: 1,
            color: _darkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Type Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _paymentTypeBreakdown.isEmpty
                      ? Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(
                              color: _darkMode
                                  ? Colors.white70
                                  : SMSTheme.textSecondaryColor,
                            ),
                          ),
                        )
                      : Column(
                          children: _paymentTypeBreakdown.entries.map((entry) {
                            final type = entry.key;
                            final amount = entry.value;
                            final percentage = _totalAmount > 0
                                ? (amount / _totalAmount) * 100
                                : 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: _getPaymentTypeColor(type),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: _darkMode
                                                  ? Colors.white
                                                  : SMSTheme.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        currencyFormat.format(amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _darkMode
                                              ? Colors.white
                                              : SMSTheme.textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            backgroundColor: _darkMode
                                                ? Colors.grey.shade700
                                                : Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    _getPaymentTypeColor(type)),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _darkMode
                                              ? Colors.white70
                                              : SMSTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Method Breakdown
          Card(
            elevation: 1,
            color: _darkMode ? Colors.grey.shade800 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _paymentMethodBreakdown.isEmpty
                      ? Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(
                              color: _darkMode
                                  ? Colors.white70
                                  : SMSTheme.textSecondaryColor,
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _paymentMethodBreakdown.length,
                          itemBuilder: (context, index) {
                            final method =
                                _paymentMethodBreakdown.keys.elementAt(index);
                            final amount = _paymentMethodBreakdown[method]!;
                            final percentage = _totalAmount > 0
                                ? (amount / _totalAmount) * 100
                                : 0;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _darkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getPaymentMethodIcon(method),
                                        size: 16,
                                        color: _getPaymentMethodColor(method),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          method,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: _darkMode
                                                ? Colors.white
                                                : SMSTheme.textPrimaryColor,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currencyFormat.format(amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _darkMode
                                              ? Colors.white
                                              : SMSTheme.textPrimaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getPaymentMethodColor(method)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _getPaymentMethodColor(method),
                                          ),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }

  Color _getPaymentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'tuition fee':
        return Colors.blue.shade600;
      case 'downpayment':
        return Colors.green.shade600;
      case 'full payment':
        return Colors.purple.shade600;
      case 'registration':
        return SMSTheme.primaryColor;
      case 'uniform':
        return Colors.indigo.shade600;
      case 'books':
        return Colors.amber.shade700;
      case 'miscellaneous':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPaymentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'tuition fee':
        return Icons.school;
      case 'downpayment':
        return Icons.payments;
      case 'full payment':
        return Icons.paid;
      case 'registration':
        return Icons.how_to_reg;
      case 'uniform':
        return Icons.checkroom;
      case 'books':
        return Icons.book;
      case 'miscellaneous':
        return Icons.miscellaneous_services;
      default:
        return Icons.receipt;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green.shade600;
      case 'online transfer':
        return Colors.blue.shade600;
      case 'credit card':
        return Colors.purple.shade600;
      case 'debit card':
        return Colors.indigo.shade600;
      case 'check':
        return Colors.amber.shade700;
      case 'scholarship':
        return Colors.teal.shade600;
      case 'installment':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments;
      case 'online transfer':
        return Icons.shopping_bag;
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.credit_card;
      case 'check':
        return Icons.money;
      case 'scholarship':
        return Icons.school;
      case 'installment':
        return Icons.calendar_today;
      default:
        return Icons.payment;
    }
  }
}
