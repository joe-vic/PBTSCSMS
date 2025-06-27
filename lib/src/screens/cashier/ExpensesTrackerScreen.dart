import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesTrackerScreen extends StatefulWidget {
  const ExpensesTrackerScreen({Key? key}) : super(key: key);

  @override
  _ExpensesTrackerScreenState createState() => _ExpensesTrackerScreenState();
}

class _ExpensesTrackerScreenState extends State<ExpensesTrackerScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _darkMode = false;
  
  // Expenses data
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  
  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  String _searchQuery = '';
  
  // Summary data
  double _totalExpenses = 0;
  double _monthlyExpenses = 0;
  double _weeklyExpenses = 0;
  Map<String, double> _expensesByCategory = {};
  
  // Form controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // Chart data
  late TabController _tabController;
  List<FlSpot> _weeklyExpenseSpots = [];
  List<FlSpot> _monthlyExpenseSpots = [];
  
  // Selection
  String _selectedExpenseId = '';
  
  // Category options
  List<String> _categories = [
    'Utilities',
    'Maintenance',
    'Office Supplies',
    'Salaries',
    'Taxes',
    'Insurance',
    'Software',
    'Transportation',
    'Events',
    'Marketing',
    'Other'
  ];
  
  // Payment method options
  List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'Debit Card',
    'Check',
    'Mobile Payment'
  ];
  
  // String _selectedCategory = 'Utilities';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final dateFormat = DateFormat('MMMM d, yyyy');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPreferences();
    _loadExpenses();
    _loadExpenseCategories();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _searchController.dispose();
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
  
  Future<void> _loadExpenseCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('expenseCategories')
          .get();
      
      if (categoriesSnapshot.exists && categoriesSnapshot.data() != null) {
        final data = categoriesSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('categories') && data['categories'] is List) {
          setState(() {
            _categories = List<String>.from(data['categories']);
            // Default to first category if current selection is not in the list
            if (!_categories.contains(_selectedCategory) && _categories.isNotEmpty) {
              _selectedCategory = _categories[0];
            }
          });
        }
      }
      
      final paymentMethodsSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('paymentMethods')
          .get();
      
      if (paymentMethodsSnapshot.exists && paymentMethodsSnapshot.data() != null) {
        final data = paymentMethodsSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('methods') && data['methods'] is List) {
          setState(() {
            _paymentMethods = List<String>.from(data['methods']);
            // Default to first method if current selection is not in the list
            if (!_paymentMethods.contains(_selectedPaymentMethod) && _paymentMethods.isNotEmpty) {
              _selectedPaymentMethod = _paymentMethods[0];
            }
          });
        }
      }
    } catch (e) {
      print('Error loading expense categories: $e');
    }
  }
  
  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final DateTime startOfMonth = DateTime(now.year, now.month, 1);
      
      // Load expenses
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();
      
      final List<Map<String, dynamic>> expenses = [];
      double totalAmount = 0;
      double monthlyAmount = 0;
      double weeklyAmount = 0;
      Map<String, double> categoryTotals = {};
      
      // Process weekly chart data
      Map<int, double> dailyTotals = {};
      for (int i = 0; i < 7; i++) {
        dailyTotals[i] = 0;
      }
      
      // Process monthly chart data
      Map<int, double> monthlyTotals = {};
      for (int i = 1; i <= 31; i++) {
        monthlyTotals[i] = 0;
      }
      
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final DateTime expenseDate = (data['date'] as Timestamp).toDate();
        final double amount = (data['amount'] as num).toDouble();
        final String category = data['category'] as String;
        
        // Calculate totals
        totalAmount += amount;
        
        if (expenseDate.isAfter(startOfMonth)) {
          monthlyAmount += amount;
          
          // Update monthly chart data
          final int day = expenseDate.day;
          monthlyTotals[day] = (monthlyTotals[day] ?? 0) + amount;
        }
        
        if (expenseDate.isAfter(startOfWeek)) {
          weeklyAmount += amount;
          
          // Update weekly chart data
          final int dayDiff = expenseDate.difference(startOfWeek).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            dailyTotals[dayDiff] = (dailyTotals[dayDiff] ?? 0) + amount;
          }
        }
        
        // Update category totals
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
        
        // Create expense object
        expenses.add({
          'id': doc.id,
          'description': data['description'] ?? 'No Description',
          'amount': amount,
          'date': expenseDate,
          'category': category,
          'paymentMethod': data['paymentMethod'] ?? 'Cash',
          'reference': data['reference'] ?? '',
          'notes': data['notes'] ?? '',
          'createdBy': data['createdBy'] ?? '',
          'approved': data['approved'] ?? false,
          'approvedBy': data['approvedBy'],
          'approvalDate': data['approvalDate'],
          'receiptUrl': data['receiptUrl'],
        });
      }
      
      // Convert daily totals to chart spots
      final weeklySpots = dailyTotals.entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();
      
      // Convert monthly totals to chart spots
      final monthlySpots = monthlyTotals.entries
          .where((entry) => entry.key <= DateTime(now.year, now.month + 1, 0).day) // Only days in current month
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();
      
      setState(() {
        _expenses = expenses;
        _filteredExpenses = expenses;
        _totalExpenses = totalAmount;
        _monthlyExpenses = monthlyAmount;
        _weeklyExpenses = weeklyAmount;
        _expensesByCategory = categoryTotals;
        _weeklyExpenseSpots = weeklySpots;
        _monthlyExpenseSpots = monthlySpots;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading expenses: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load expenses. Please try again.';
      });
    }
  }
  
  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        // Filter by search query
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final String description = expense['description'].toString().toLowerCase();
          final String category = expense['category'].toString().toLowerCase();
          final String reference = expense['reference'].toString().toLowerCase();
          final String notes = expense['notes'].toString().toLowerCase();
          
          matchesSearch = description.contains(_searchQuery.toLowerCase()) ||
                         category.contains(_searchQuery.toLowerCase()) ||
                         reference.contains(_searchQuery.toLowerCase()) ||
                         notes.contains(_searchQuery.toLowerCase());
        }
        
        // Filter by date range
        bool matchesDateRange = true;
        if (_startDate != null) {
          matchesDateRange = matchesDateRange && expense['date'].isAfter(_startDate!);
        }
        if (_endDate != null) {
          // Add one day to include the end date fully
          final endDatePlusOne = _endDate!.add(const Duration(days: 1));
          matchesDateRange = matchesDateRange && expense['date'].isBefore(endDatePlusOne);
        }
        
        // Filter by category
        bool matchesCategory = true;
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          matchesCategory = expense['category'] == _selectedCategory;
        }
        
        return matchesSearch && matchesDateRange && matchesCategory;
      }).toList();
    });
  }
  
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
      _filteredExpenses = _expenses;
    });
  }
  
  Future<void> _showDateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
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
    
    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
      _filterExpenses();
    }
  }
  
  Future<void> _selectExpenseDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
  
  void _clearExpenseForm() {
    setState(() {
      _descriptionController.clear();
      _amountController.clear();
      _referenceController.clear();
      _notesController.clear();
      _selectedCategory = _categories.isNotEmpty ? _categories[0] : 'Other';
      _selectedPaymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods[0] : 'Cash';
      _selectedDate = DateTime.now();
      _selectedExpenseId = '';
    });
  }
  
  Future<void> _saveExpense() async {
    // Validate form
    if (_descriptionController.text.isEmpty) {
      _showErrorSnackBar('Please enter a description');
      return;
    }
    
    if (_amountController.text.isEmpty) {
      _showErrorSnackBar('Please enter an amount');
      return;
    }
    
    double? amount;
    try {
      amount = double.parse(_amountController.text.replaceAll(',', ''));
    } catch (e) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }
    
    if (amount <= 0) {
      _showErrorSnackBar('Amount must be greater than zero');
      return;
    }
    
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final expenseData = {
        'description': _descriptionController.text.trim(),
        'amount': amount,
        'date': Timestamp.fromDate(_selectedDate),
        'category': _selectedCategory,
        'paymentMethod': _selectedPaymentMethod,
        'reference': _referenceController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdBy': user?.displayName ?? user?.email ?? 'Unknown User',
        'createdAt': Timestamp.now(),
        'approved': false,
        'approvedBy': null,
        'approvalDate': null,
        'receiptUrl': null,
      };
      
      if (_selectedExpenseId.isEmpty) {
        // Create new expense
        await FirebaseFirestore.instance
            .collection('expenses')
            .add(expenseData);
        
        _showSuccessSnackBar('Expense added successfully');
      } else {
        // Update existing expense
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(_selectedExpenseId)
            .update(expenseData);
        
        _showSuccessSnackBar('Expense updated successfully');
      }
      
      // Refresh data
      await _loadExpenses();
      
      // Clear form
      _clearExpenseForm();
      
      // Close bottom sheet if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving expense: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to save expense: $e');
    }
  }
  
  Future<void> _deleteExpense(String expenseId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expenseId)
          .delete();
      
      // Refresh data
      await _loadExpenses();
      
      _showSuccessSnackBar('Expense deleted successfully');
    } catch (e) {
      print('Error deleting expense: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to delete expense: $e');
    }
  }
  
  void _showExpenseForm({Map<String, dynamic>? expense}) {
    // Clear form first
    _clearExpenseForm();
    
    // Fill form with expense data if editing
    if (expense != null) {
      setState(() {
        _selectedExpenseId = expense['id'];
        _descriptionController.text = expense['description'];
        _amountController.text = expense['amount'].toString();
        _selectedCategory = expense['category'];
        _selectedPaymentMethod = expense['paymentMethod'];
        _selectedDate = expense['date'];
        _referenceController.text = expense['reference'] ?? '';
        _notesController.text = expense['notes'] ?? '';
      });
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: _darkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense != null ? 'Edit Expense' : 'Add New Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description field
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Amount field
                      TextField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount (₱) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: _selectedCategory,
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment method dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: _selectedPaymentMethod,
                        items: _paymentMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date picker
                      InkWell(
                        onTap: _selectExpenseDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMMM d, yyyy').format(_selectedDate)),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Reference field
                      TextField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: 'Reference Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Notes field
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Upload receipt button (placeholder for future implementation)
                      OutlinedButton.icon(
                        onPressed: () {
                          // Implement receipt upload functionality
                          _showNotImplementedSnackBar('Receipt upload will be implemented in a future update');
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Receipt'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearExpenseForm();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveExpense,
                      child: Text(expense != null ? 'Update' : 'Save'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
  }
  
  void _showExpenseDetails(Map<String, dynamic> expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense['category']).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(expense['category']),
                    color: _getCategoryColor(expense['category']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense['description'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        currencyFormat.format(expense['amount']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildExpenseDetailRow('Date', dateFormat.format(expense['date'])),
            _buildExpenseDetailRow('Category', expense['category']),
            _buildExpenseDetailRow('Payment Method', expense['paymentMethod']),
            if (expense['reference'].isNotEmpty)
              _buildExpenseDetailRow('Reference', expense['reference']),
            if (expense['notes'].isNotEmpty)
              _buildExpenseDetailRow('Notes', expense['notes']),
            _buildExpenseDetailRow('Created By', expense['createdBy']),
            _buildExpenseDetailRow(
              'Status',
              expense['approved'] ? 'Approved' : 'Pending Approval',
              valueColor: expense['approved'] ? Colors.green : Colors.orange,
            ),
            if (expense['approved'] && expense['approvedBy'] != null)
              _buildExpenseDetailRow('Approved By', expense['approvedBy']),
            if (expense['approved'] && expense['approvalDate'] != null)
              _buildExpenseDetailRow(
                'Approval Date',
                dateFormat.format((expense['approvalDate'] as Timestamp).toDate()),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Edit button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExpenseForm(expense: expense);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SMSTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(expense);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
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
  
  void _showDeleteConfirmation(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense?\n\n${expense['description']} (${currencyFormat.format(expense['amount'])})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(expense['id']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                color: valueColor ?? (_darkMode ? Colors.white : SMSTheme.textPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  void _showNotImplementedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          title: const Text('Expenses Tracker'),
          backgroundColor: SMSTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _darkMode = !_darkMode;
                  _saveUserPreferences();
                });
              },
              tooltip: _darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadExpenses,
              tooltip: 'Refresh Data',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFiltersBottomSheet,
              tooltip: 'Filter Expenses',
            ),
          ],
        ),
        body: _hasError
            ? _buildErrorView()
            : _isLoading
                ? _buildLoadingIndicator()
                : _buildContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showExpenseForm(),
          backgroundColor: SMSTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
          tooltip: 'Add New Expense',
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
          Text(
            _errorMessage,
            style: TextStyle(
              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadExpenses,
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
            'Loading expenses data...',
            style: TextStyle(
              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
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
          // Summary Cards
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            child: _buildSummarySection(),
          ),
          
          // Tabs for different views
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 100),
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
                  Tab(text: 'All Expenses'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Categories'),
                ],
                labelColor: SMSTheme.primaryColor,
                unselectedLabelColor: _darkMode ? Colors.white70 : Colors.grey.shade600,
                indicatorColor: SMSTheme.primaryColor,
              ),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Expenses tab
                _buildExpensesListTab(),
                
                // Analytics tab
                _buildAnalyticsTab(),
                
                // Categories tab
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Weekly Expenses',
                  currencyFormat.format(_weeklyExpenses),
                  Icons.date_range,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Monthly Expenses',
                  currencyFormat.format(_monthlyExpenses),
                  Icons.calendar_month,
                  Colors.blue,
                ),
              ),
            ],
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpensesListTab() {
    return Column(
      children: [
        // Search bar
        FadeInDown(
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterExpenses();
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterExpenses();
              },
            ),
          ),
        ),
        
        // Active filters display
        if (_startDate != null || _endDate != null || _selectedCategory != null) 
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Active filters:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _darkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_startDate != null && _endDate != null)
                    _buildFilterChip(
                      '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}',
                      Icons.date_range,
                      () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _filterExpenses();
                      },
                    ),
                  if (_selectedCategory != null)
                    _buildFilterChip(
                      _selectedCategory!,
                      _getCategoryIcon(_selectedCategory!),
                      () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _filterExpenses();
                      },
                    ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Clear All'),
                    onPressed: () {
                      _resetFilters();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: SMSTheme.primaryColor,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Expenses list
        Expanded(
          child: _filteredExpenses.isEmpty
              ? FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Center(
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
                          _searchQuery.isNotEmpty || _startDate != null || _endDate != null || _selectedCategory != null
                              ? 'No expenses match your filters'
                              : 'No expenses recorded yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _startDate != null || _endDate != null || _selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton.icon(
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Clear Filters'),
                              onPressed: _resetFilters,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.builder(
                    itemCount: _filteredExpenses.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final expense = _filteredExpenses[index];
                      return _buildExpenseListItem(expense);
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SMSTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: SMSTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: SMSTheme.primaryColor,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.clear,
              size: 14,
              color: SMSTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseListItem(Map<String, dynamic> expense) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: _darkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(expense['category']).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(expense['category']),
                      color: _getCategoryColor(expense['category']),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense['description'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          expense['category'],
                          style: TextStyle(
                            fontSize: 12,
                            color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(expense['amount']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(expense['date']),
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (expense['notes'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: Text(
                    expense['notes'],
                    style: TextStyle(
                      fontSize: 12,
                      color: _darkMode ? Colors.white70 : Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: _darkMode ? Colors.white60 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expense['paymentMethod'],
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkMode ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: expense['approved']
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      expense['approved'] ? 'Approved' : 'Pending Approval',
                      style: TextStyle(
                        fontSize: 12,
                        color: expense['approved'] ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
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
  }
  
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Expenses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _weeklyExpenseSpots.isEmpty
                      ? Center(
                          child: Text(
                            'No expense data available for this week',
                            style: TextStyle(
                              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                              fontSize: 14,
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
                                  color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
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
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    final int index = value.toInt();
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        index >= 0 && index < days.length ? days[index] : '',
                                        style: TextStyle(
                                          color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
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
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    String text = '';
                                    if (value == 0) {
                                      text = '₱0';
                                    } else if (value == 1000) {
                                      text = '₱1k';
                                    } else if (value == 2000) {
                                      text = '₱2k';
                                    } else if (value == 3000) {
                                      text = '₱3k';
                                    }
                                    
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                                          fontSize: 12,
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
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _weeklyExpenseSpots,
                                isCurved: true,
                                color: Colors.red.shade700,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.red.shade700.withOpacity(0.1),
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
          
          const SizedBox(height: 20),
          
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Expenses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _monthlyExpenseSpots.isEmpty
                      ? Center(
                          child: Text(
                            'No expense data available for this month',
                            style: TextStyle(
                              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                              fontSize: 14,
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
                                  color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
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
                                  interval: 5, // Show every 5th day
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final int day = value.toInt();
                                    // Only show labels for days 1, 5, 10, 15, 20, 25, 30
                                    if (day % 5 == 0 || day == 1) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          '$day',
                                          style: TextStyle(
                                            color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    String text = '';
                                    if (value == 0) {
                                      text = '₱0';
                                    } else if (value == 1000) {
                                      text = '₱1k';
                                    } else if (value == 2000) {
                                      text = '₱2k';
                                    } else if (value == 3000) {
                                      text = '₱3k';
                                    }
                                    
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                                          fontSize: 12,
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
                            minX: 1,
                            maxX: DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day.toDouble(),
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _monthlyExpenseSpots,
                                isCurved: true,
                                color: Colors.red.shade700,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.red.shade700.withOpacity(0.1),
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
          
          const SizedBox(height: 20),
          
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Expenses',
                          currencyFormat.format(_totalExpenses),
                          Icons.account_balance_wallet,
                          Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Expenses this Month',
                          currencyFormat.format(_monthlyExpenses),
                          Icons.calendar_month,
                          Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Expenses this Week',
                          currencyFormat.format(_weeklyExpenses),
                          Icons.date_range,
                          Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Avg. Daily Expense',
                          currencyFormat.format(_expenses.isEmpty ? 0 : _monthlyExpenses / 30),
                          Icons.trending_up,
                          Colors.green.shade700,
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
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesTab() {
    // Sort categories by amount (descending)
    final sortedCategories = _expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sortedCategories.map((entry) {
                    final category = entry.key;
                    final amount = entry.value;
                    final percentage = _totalExpenses > 0 ? (amount / _totalExpenses) * 100 : 0;
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _darkMode ? Colors.white70 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                  
                  if (sortedCategories.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category,
                            size: 64,
                            color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expense data available',
                            style: TextStyle(
                              color: _darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Implement category management functionality
                      _showNotImplementedSnackBar('Category management will be implemented in a future update');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Manage Categories'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Generate expense report
                      _showReportOptionsDialog();
                    },
                    icon: const Icon(Icons.summarize),
                    label: const Text('Generate Expense Report'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date Range
            Text(
              'Date Range',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                          : 'Select date range',
                      style: TextStyle(
                        color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
                      ),
                    ),
                    const Icon(Icons.calendar_month),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Filter
            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedCategory,
              hint: const Text('All Categories'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterExpenses();
                    },
                    child: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
  
  void _showReportOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Expense Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.date_range, color: Colors.blue.shade700),
              ),
              title: const Text('Current Month'),
              subtitle: const Text('Expenses for the current month'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('month');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.calendar_today, color: Colors.green.shade700),
              ),
              title: const Text('Custom Date Range'),
              subtitle: const Text('Select your own date range'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker().then((_) {
                  if (_startDate != null && _endDate != null) {
                    _generateReport('custom');
                  }
                });
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.category, color: Colors.purple.shade700),
              ),
              title: const Text('By Category'),
              subtitle: const Text('Breakdown by expense categories'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('category');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _generateReport(String type) {
    // This would typically generate a PDF report or export to Excel
    // For now, we'll show a snackbar indicating this feature
    String message;
    switch (type) {
      case 'month':
        message = 'Generating expense report for ${DateFormat('MMMM yyyy').format(DateTime.now())}...';
        break;
      case 'custom':
        message = 'Generating expense report from ${DateFormat('MMM d').format(_startDate!)} to ${DateFormat('MMM d').format(_endDate!)}...';
        break;
      case 'category':
        message = 'Generating expense report by categories...';
        break;
      default:
        message = 'Generating expense report...';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SMSTheme.primaryColor,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Icons.electrical_services;
      case 'maintenance':
        return Icons.build;
      case 'office supplies':
        return Icons.inventory_2;
      case 'salaries':
        return Icons.people;
      case 'taxes':
        return Icons.account_balance;
      case 'insurance':
        return Icons.health_and_safety;
      case 'software':
        return Icons.laptop;
      case 'transportation':
        return Icons.directions_car;
      case 'events':
        return Icons.event;
      case 'marketing':
        return Icons.campaign;
      default:
        return Icons.category;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Colors.amber.shade700;
      case 'maintenance':
        return Colors.brown.shade500;
      case 'office supplies':
        return Colors.blue.shade700;
      case 'salaries':
        return Colors.green.shade700;
      case 'taxes':
        return Colors.red.shade700;
      case 'insurance':
        return Colors.purple.shade700;
      case 'software':
        return Colors.indigo.shade700;
      case 'transportation':
        return Colors.orange.shade700;
      case 'events':
        return Colors.pink.shade700;
      case 'marketing':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}