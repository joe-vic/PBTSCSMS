import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../../config/theme.dart';

class DailyCollectionsScreen extends StatefulWidget {
  const DailyCollectionsScreen({super.key});

  @override
  _DailyCollectionsScreenState createState() => _DailyCollectionsScreenState();
}

class _DailyCollectionsScreenState extends State<DailyCollectionsScreen> with SingleTickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchType = 'Specific Date';
  String _studentSearchField = 'Last Name';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFilterExpanded = false;
  bool _isLoading = false;
  
  // For visualization
  List<Map<String, dynamic>> _paymentsByType = [];
  Map<String, double> _paymentMethodTotals = {};
  double _totalCollected = 0;
  double _previousPeriodTotal = 0;
  double _percentChange = 0;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize with today's date
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Load data
    _fetchCollectionStats();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchCollectionStats() async {
    if (_startDate == null || _endDate == null) {
      // Set default dates if not set
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch current period stats
      final currentPeriodSnapshot = await _buildQuery().get();
      final payments = currentPeriodSnapshot.docs;
      
      // Calculate totals for current period
      double total = 0;
      Map<String, double> typeBreakdown = {};
      Map<String, double> methodTotals = {};
      
      for (var doc in payments) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        total += amount;
        
        final paymentType = data['paymentType']?.toString() ?? 'Other';
        typeBreakdown[paymentType] = (typeBreakdown[paymentType] ?? 0) + amount;
        
        final paymentMethod = data['paymentMethod']?.toString() ?? 'Cash';
        methodTotals[paymentMethod] = (methodTotals[paymentMethod] ?? 0) + amount;
      }
      
      // Format payment type data for the chart
      List<Map<String, dynamic>> paymentsByType = [];
      typeBreakdown.forEach((type, amount) {
        paymentsByType.add({
          'type': type,
          'amount': amount,
          'percentage': total > 0 ? (amount / total) * 100 : 0,
        });
      });
      
      // Sort by amount in descending order
      paymentsByType.sort((a, b) => b['amount'].compareTo(a['amount']));
      
      // Fetch previous period stats for comparison
      final currentPeriodLength = _endDate!.difference(_startDate!).inDays + 1;
      final previousPeriodStart = _startDate!.subtract(Duration(days: currentPeriodLength));
      final previousPeriodEnd = _startDate!.subtract(const Duration(days: 1));
      
      final previousPeriodSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(previousPeriodStart))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(previousPeriodEnd))
          .get();
      
      double previousTotal = 0;
      for (var doc in previousPeriodSnapshot.docs) {
        previousTotal += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      
      // Calculate percent change
      double percentChange = 0;
      if (previousTotal > 0) {
        percentChange = ((total - previousTotal) / previousTotal) * 100;
      }
      
      setState(() {
        _totalCollected = total;
        _paymentsByType = paymentsByType;
        _paymentMethodTotals = methodTotals;
        _previousPeriodTotal = previousTotal;
        _percentChange = percentChange;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching collection stats: $e');
      setState(() {
        _isLoading = false;
        // Initialize with empty data to prevent null errors
        _paymentsByType = [];
        _paymentMethodTotals = {};
        _totalCollected = 0;
        _previousPeriodTotal = 0;
        _percentChange = 0;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))
          : null,
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
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _fetchCollectionStats();
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('payments');

    // Apply date filter based on search type
    if (_searchType == 'Specific Date') {
      if (_startDate != null && _endDate != null) {
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
      }
    } else if (_searchType == 'Weekly') {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek));
    } else if (_searchType == 'Monthly') {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
    }

    // Apply student search filter
    if (_searchQuery.isNotEmpty) {
      try {
        if (_studentSearchField == 'Last Name') {
          query = query.where('studentInfo.lastName', isGreaterThanOrEqualTo: _searchQuery)
                       .where('studentInfo.lastName', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        } else if (_studentSearchField == 'First Name') {
          query = query.where('studentInfo.firstName', isGreaterThanOrEqualTo: _searchQuery)
                       .where('studentInfo.firstName', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        } else if (_studentSearchField == 'Student ID') {
          query = query.where('studentId', isEqualTo: _searchQuery);
        } else if (_studentSearchField == 'Grade Level') {
          query = query.where('studentInfo.gradeLevel', isEqualTo: _searchQuery);
        } else if (_studentSearchField == 'Course') {
          query = query.where('studentInfo.course', isEqualTo: _searchQuery);
        }
      } catch (e) {
        print('Error building query: $e');
      }
    }

    return query;
  }
  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    final bool isMediumScreen = MediaQuery.of(context).size.width > 600 && MediaQuery.of(context).size.width <= 800;
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Collections Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCollectionStats,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Select date range',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _generateReport(context),
            tooltip: 'Generate report',
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
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date summary and analytics section
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: _buildHeaderSection(currencyFormat),
              ),
              
              const SizedBox(height: 16),
              
              // Search and Filter Card
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: _buildSearchFilterCard(),
              ),
              
              const SizedBox(height: 16),
              
              // Tab bar for tables/visualizations
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: SMSTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: SMSTheme.primaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.table_chart),
                        text: 'Payment Records',
                      ),
                      Tab(
                        icon: Icon(Icons.pie_chart),
                        text: 'Analytics',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Active Filters Display
              if (_startDate != null || _searchQuery.isNotEmpty)
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_startDate != null && _endDate != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(
                                  'Date: ${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    final now = DateTime.now();
                                    _startDate = DateTime(now.year, now.month, now.day);
                                    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                                    _searchType = 'Specific Date';
                                  });
                                  _fetchCollectionStats();
                                },
                                backgroundColor: Colors.grey[100],
                              ),
                            ),
                          if (_searchQuery.isNotEmpty)
                            Chip(
                              label: Text(
                                '$_studentSearchField: $_searchQuery',
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _fetchCollectionStats();
                              },
                              backgroundColor: Colors.grey[100],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Tabbed Content - Payment Records / Analytics
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Payment Records DataTable
                        _buildPaymentRecordsTab(currencyFormat),
                        
                        // Tab 2: Analytics with Charts
                        _buildAnalyticsTab(currencyFormat),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _generateReport(context);
        },
        icon: const Icon(Icons.summarize),
        label: const Text('Export Report'),
        backgroundColor: SMSTheme.primaryColor,
      ),
    );
  }

  Widget _buildHeaderSection(NumberFormat currencyFormat) {
    final periodText = _startDate != null && _endDate != null
        ? _startDate!.day == _endDate!.day && _startDate!.month == _endDate!.month && _startDate!.year == _endDate!.year
            ? 'Today\'s Collections'
            : 'Collections for ${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}'
        : 'Today\'s Collections';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Last updated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Change Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SMSTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Summary Cards - Responsive Grid
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount;
                if (constraints.maxWidth > 1000) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 650) {
                  crossAxisCount = 2;
                } else {
                  crossAxisCount = 1;
                }
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _buildSummaryCard(
                      title: 'Total Collections',
                      value: currencyFormat.format(_totalCollected),
                      icon: Icons.payment,
                      iconColor: Colors.green,
                      percentChange: _percentChange,
                      context: context,
                    ),
                    _buildSummaryCard(
                      title: 'Cash Payments',
                      value: currencyFormat.format(_paymentMethodTotals['Cash'] ?? 0),
                      icon: Icons.payments,
                      iconColor: Colors.blue,
                      context: context,
                    ),
                    _buildSummaryCard(
                      title: 'Online Payments',
                      value: currencyFormat.format((_paymentMethodTotals['Online'] ?? 0) + (_paymentMethodTotals['Credit Card'] ?? 0)),
                      icon: Icons.credit_card,
                      iconColor: Colors.purple,
                      context: context,
                    ),
                    _buildSummaryCard(
                      title: 'Other Payments',
                      value: currencyFormat.format(_paymentMethodTotals.entries
                        .where((e) => !['Cash', 'Online', 'Credit Card'].contains(e.key))
                        .fold(0.0, (sum, item) => sum + item.value)),
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.orange,
                      context: context,
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required BuildContext context,
    double? percentChange,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              if (percentChange != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentChange >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        percentChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: percentChange >= 0 ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${percentChange.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: percentChange >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildSearchFilterCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by $_studentSearchField',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _fetchCollectionStats();
                        },
                        tooltip: 'Clear search',
                      ),
                    IconButton(
                      icon: Icon(
                        _isFilterExpanded ? Icons.expand_less : Icons.filter_list,
                        color: SMSTheme.accentColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                        });
                      },
                      tooltip: 'Filters',
                    ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
                _fetchCollectionStats();
              },
            ),
            
            // Expandable Filter Section
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isFilterExpanded ? 180 : 0,
              child: SingleChildScrollView(
                physics: _isFilterExpanded 
                    ? const AlwaysScrollableScrollPhysics() 
                    : const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(top: _isFilterExpanded ? 16 : 0),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // Date Filter Row
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 18),
                          const SizedBox(width: 8),
                          Text('Date Filter:', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _searchType,
                              underline: const SizedBox(),
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              onChanged: (value) {
                                setState(() {
                                  _searchType = value!;
                                  final now = DateTime.now();
                                  if (value == 'Weekly') {
                                    _startDate = now.subtract(Duration(days: now.weekday - 1));
                                    _endDate = _startDate!.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
                                  } else if (value == 'Monthly') {
                                    _startDate = DateTime(now.year, now.month, 1);
                                    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                                  } else if (_startDate == null) {
                                    // For specific date, default to today if not set
                                    _startDate = DateTime(now.year, now.month, now.day);
                                    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                                  }
                                });
                                _fetchCollectionStats();
                              },
                              items: ['Specific Date', 'Weekly', 'Monthly']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date Range Selector
                      if (_searchType == 'Specific Date') 
                        GestureDetector(
                          onTap: () => _selectDateRange(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startDate != null && _endDate != null
                                        ? '${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}'
                                        : 'Select Date Range',
                                    style: TextStyle(
                                      color: _startDate != null ? Colors.black : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Search Field Selector
                      Row(
                        children: [
                          const Icon(Icons.person_search, size: 18),
                          const SizedBox(width: 8),
                          Text('Search by:', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _studentSearchField,
                              underline: const SizedBox(),
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              onChanged: (value) {
                                setState(() {
                                  _studentSearchField = value!;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              items: ['Last Name', 'First Name', 'Student ID', 'Grade Level', 'Course']
                                  .map((field) => DropdownMenuItem(
                                        value: field,
                                        child: Text(field),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                final now = DateTime.now();
                                _startDate = DateTime(now.year, now.month, now.day);
                                _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                                _searchType = 'Specific Date';
                                _studentSearchField = 'Last Name';
                                _searchController.clear();
                                _searchQuery = '';
                              });
                              _fetchCollectionStats();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Reset Filters'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = _searchController.text.trim();
                                _isFilterExpanded = false;
                              });
                              _fetchCollectionStats();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SMSTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRecordsTab(NumberFormat currencyFormat) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No collections found for the selected criteria',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search query',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final payments = snapshot.data!.docs;
        double total = 0;
        List<Map<String, dynamic>> paymentList = [];
        
        for (var doc in payments) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['amount'] as num?)?.toDouble() ?? 0;
          final studentInfo = data['studentInfo'] as Map<String, dynamic>? ?? {};
          
          paymentList.add({
            'id': doc.id,
            'studentInfo': studentInfo,
            'studentId': data['studentId']?.toString() ?? 'Unknown',
            'amount': data['amount']?.toDouble() ?? 0,
            'paymentType': data['paymentType']?.toString() ?? 'Unknown',
            'paymentMethod': data['paymentMethod']?.toString() ?? 'Cash',
            'parentName': data['parentName']?.toString() ?? 'Unknown',
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Collection Records (${paymentList.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export CSV'),
                          onPressed: () => _exportCSV(paymentList),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SMSTheme.primaryColor,
                            side: BorderSide(color: SMSTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Collected: ${currencyFormat.format(total)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data Table
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: _buildPaymentsDataTable(paymentList, currencyFormat),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentsDataTable(List<Map<String, dynamic>> paymentList, NumberFormat currencyFormat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  columnSpacing: 16,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  horizontalMargin: 16,
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Last Name')),
                    DataColumn(label: Text('First Name')),
                    DataColumn(label: Text('MI')),
                    DataColumn(label: Text('Student ID')),
                    DataColumn(label: Text('Grade/Course')),
                    DataColumn(label: Text('Amount'), numeric: true),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Method')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: paymentList.map((payment) {
                    final studentInfo = payment['studentInfo'] as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          studentInfo['lastName']?.toString() ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        )),
                        DataCell(Text(
                          studentInfo['firstName']?.toString() ?? 'N/A',
                        )),
                        DataCell(Text(
                          studentInfo['mi']?.toString() ?? '',
                        )),
                        DataCell(Text(payment['studentId'])),
                        DataCell(Text(
                          studentInfo['gradeLevel']?.toString() ?? 
                          studentInfo['course']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        )),
                        DataCell(
                          Text(
                            currencyFormat.format(payment['amount']),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPaymentTypeColor(payment['paymentType']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment['paymentType'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(payment['paymentMethod'])),
                        DataCell(Text(
                          DateFormat('MM/dd/yyyy').format(payment['timestamp']),
                        )),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.receipt, size: 18),
                                tooltip: 'View Receipt',
                                onPressed: () => _showPaymentDetails(context, payment),
                                color: SMSTheme.primaryColor,
                              ),
                              IconButton(
                                icon: const Icon(Icons.print, size: 18),
                                tooltip: 'Print Receipt',
                                onPressed: () => _printReceipt(payment),
                                color: SMSTheme.accentColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          _showPaymentDetails(context, payment);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildAnalyticsTab(NumberFormat currencyFormat) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Type Breakdown Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Type Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For period: ${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Chart and Legend container
                  SizedBox(
                    height: 300,
                    child: _paymentsByType.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pie_chart, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No payment data available',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            // Pie Chart
                            Expanded(
                              flex: 2,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: PieChart(
                                  PieChartData(
                                    sections: _paymentsByType.map((payment) {
                                      final index = _paymentsByType.indexOf(payment);
                                      final colors = [
                                        Colors.blue.shade400,
                                        Colors.green.shade400,
                                        Colors.orange.shade400,
                                        Colors.purple.shade400,
                                        Colors.teal.shade400,
                                      ];
                                      return PieChartSectionData(
                                        color: colors[index % colors.length],
                                        value: payment['amount'].toDouble(),
                                        title: '${payment['percentage'].toStringAsFixed(0)}%',
                                        radius: 100,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    startDegreeOffset: 180,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Legend
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(_paymentsByType.length, (index) {
                                  final payment = _paymentsByType[index];
                                  final colors = [
                                    Colors.blue.shade400,
                                    Colors.green.shade400,
                                    Colors.orange.shade400,
                                    Colors.purple.shade400,
                                    Colors.teal.shade400,
                                  ];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: colors[index % colors.length],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            payment['type'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          currencyFormat.format(payment['amount']),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${payment['percentage'].toStringAsFixed(1)}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment Method Distribution Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _paymentMethodTotals.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No payment method data available',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;
                          if (constraints.maxWidth > 800) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth > 500) {
                            crossAxisCount = 2;
                          } else {
                            crossAxisCount = 1;
                          }
                          
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _paymentMethodTotals.length,
                            itemBuilder: (context, index) {
                              final entry = _paymentMethodTotals.entries.elementAt(index);
                              final methodName = entry.key;
                              final amount = entry.value;
                              final percentage = _totalCollected > 0 ? (amount / _totalCollected) * 100 : 0;
                              
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getPaymentMethodIcon(methodName),
                                          color: _getPaymentMethodColor(methodName),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            methodName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          currencyFormat.format(amount),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Suggestions/Insights Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: SMSTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Insights & Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInsightItem(
                    Icons.trending_up,
                    _percentChange >= 0 
                      ? 'Collections have increased by ${_percentChange.abs().toStringAsFixed(1)}% compared to previous period.'
                      : 'Collections have decreased by ${_percentChange.abs().toStringAsFixed(1)}% compared to previous period.',
                    _percentChange >= 0 ? Colors.green : Colors.orange,
                  ),
                  
                  _buildInsightItem(
                    Icons.payments,
                    _getMostPopularPaymentMethod(),
                    Colors.blue,
                  ),
                  
                  _buildInsightItem(
                    Icons.calendar_today,
                    'Consider running a detailed monthly report to identify longer-term collection trends.',
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMostPopularPaymentMethod() {
    if (_paymentMethodTotals.isEmpty) {
      return 'No payment method data available for insights.';
    }
    
    // Find the payment method with the highest total
    var entries = _paymentMethodTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    final topMethod = entries.first.key;
    final percentage = _totalCollected > 0 
        ? (entries.first.value / _totalCollected) * 100 
        : 0;
    
    return '$topMethod is the most popular payment method, accounting for ${percentage.toStringAsFixed(1)}% of collections.';
  }

 void _showPaymentDetails(BuildContext context, Map<String, dynamic> payment) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final studentInfo = payment['studentInfo'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt, color: SMSTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Payment Receipt Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Student Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Name', '${studentInfo['firstName'] ?? ''} ${studentInfo['mi'] ?? ''} ${studentInfo['lastName'] ?? ''}'),
                    _buildDetailRow('Student ID', payment['studentId']),
                    _buildDetailRow('Grade/Course', studentInfo['gradeLevel'] ?? studentInfo['course'] ?? 'N/A'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Payment Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Amount', currencyFormat.format(payment['amount']), valueStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                    _buildDetailRow('Payment Type', payment['paymentType']),
                    _buildDetailRow('Payment Method', payment['paymentMethod']),
                    _buildDetailRow('Date & Time', DateFormat('MM/dd/yyyy hh:mm a').format(payment['timestamp'])),
                    _buildDetailRow('Receipt #', payment['id']),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Receipt'),
            onPressed: () {
              Navigator.of(context).pop();
              _printReceipt(payment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(Map<String, dynamic> payment) async {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final studentInfo = payment['studentInfo'] as Map<String, dynamic>;
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Philippine Best Training Systems Colleges Inc.',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Payment Receipt',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${DateFormat('MM/dd/yyyy').format(payment['timestamp'])}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Receipt #: ${payment['id']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Student Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Student Information',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildPdfRow('Name', '${studentInfo['lastName'] ?? ''}, ${studentInfo['firstName'] ?? ''} ${studentInfo['mi'] ?? ''}'),
                    _buildPdfRow('Student ID', payment['studentId']),
                    _buildPdfRow('Grade/Course', studentInfo['gradeLevel'] ?? studentInfo['course'] ?? 'N/A'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Payment Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Information',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildPdfRow('Amount', currencyFormat.format(payment['amount'])),
                    _buildPdfRow('Payment Type', payment['paymentType']),
                    _buildPdfRow('Payment Method', payment['paymentMethod']),
                    _buildPdfRow('Date & Time', DateFormat('MM/dd/yyyy hh:mm a').format(payment['timestamp'])),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Payment Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount Paid:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      currencyFormat.format(payment['amount']),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('__________________________'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Cashier Signature',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('__________________________'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Received By',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Center(
                child: pw.Text(
                  'Thank you for your payment!',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              
              pw.SizedBox(height: 4),
              
              pw.Center(
                child: pw.Text(
                  'This is an official receipt of Philippine Best Training Systems Colleges Inc.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PBTS_Receipt_${payment['id']}',
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV(List<Map<String, dynamic>> payments) async {
    try {
      // Build CSV content
      String csv = 'Receipt ID,Student ID,Student Name,Grade/Course,Amount,Payment Type,Payment Method,Date,Time\n';
      
      for (var payment in payments) {
        final studentInfo = payment['studentInfo'] as Map<String, dynamic>;
        final studentName = '${studentInfo['lastName'] ?? ''},${studentInfo['firstName'] ?? ''} ${studentInfo['mi'] ?? ''}'.trim();
        final gradeLevel = studentInfo['gradeLevel'] ?? studentInfo['course'] ?? 'N/A';
        final amount = payment['amount'].toString();
        final paymentType = payment['paymentType'];
        final paymentMethod = payment['paymentMethod'];
        final date = DateFormat('MM/dd/yyyy').format(payment['timestamp']);
        final time = DateFormat('HH:mm:ss').format(payment['timestamp']);
        
        csv += '${payment['id']},'
             '${payment['studentId']},'
             '"$studentName",'
             '"$gradeLevel",'
             '$amount,'
             '"$paymentType",'
             '"$paymentMethod",'
             '$date,'
             '$time\n';
      }
      
      // Show download dialog/preview
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CSV export ready for download'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      
      // In a real app, use file_picker or path_provider to save the file
      // For this implementation, we're just showing the export is ready
      await Printing.sharePdf(bytes: Uint8List.fromList(csv.codeUnits), filename: 'PBTS_Collections_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _generateReport(BuildContext context) async {
    try {
      final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
      final pdf = pw.Document();
      
      // Get the data
      final collectionSnapshot = await _buildQuery().get();
      final payments = collectionSnapshot.docs;
      double total = 0;
      List<Map<String, dynamic>> paymentList = [];
      
      for (var doc in payments) {
        final data = doc.data();
        total += (data['amount'] as num?)?.toDouble() ?? 0;
        final studentInfo = data['studentInfo'] as Map<String, dynamic>? ?? {};
        
        paymentList.add({
          'id': doc.id,
          'studentInfo': studentInfo,
          'studentId': data['studentId']?.toString() ?? 'Unknown',
          'amount': data['amount']?.toDouble() ?? 0,
          'paymentType': data['paymentType']?.toString() ?? 'Unknown',
          'paymentMethod': data['paymentMethod']?.toString() ?? 'Cash',
          'parentName': data['parentName']?.toString() ?? 'Unknown',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }
      
      // Sort payments by timestamp (newest first)
      paymentList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      
      // Create the PDF document
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Philippine Best Training Systems Colleges Inc.',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Financial Collections Report',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Period: ${DateFormat('MMMM d, yyyy').format(_startDate!)} - ${DateFormat('MMMM d, yyyy').format(_endDate!.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)))}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${DateFormat('MMMM d, yyyy h:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'PBTS Collections Report - Confidential',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Collection Summary',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Collections:'),
                        pw.Text(
                          currencyFormat.format(total),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Number of Transactions:'),
                        pw.Text(
                          paymentList.length.toString(),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Payment Type Breakdown
              pw.Text(
                'Collections by Payment Type',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              
              _buildPaymentTypeTablePdf(_paymentsByType, currencyFormat),
              
              pw.SizedBox(height: 20),
              
              // Payment Method Breakdown
              pw.Text(
                'Collections by Payment Method',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              
              _buildPaymentMethodTablePdf(_paymentMethodTotals, _totalCollected, currencyFormat),
              
              pw.SizedBox(height: 20),
              
              // Transactions Table
              pw.Text(
                'Collection Records',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              
              _buildTransactionsTablePdf(paymentList, currencyFormat),
            ];
          },
        ),
      );
      
      // Show print preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'PBTS_Collections_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  pw.Widget _buildPaymentTypeTablePdf(List<Map<String, dynamic>> paymentsByType, NumberFormat currencyFormat) {
    final headers = ['Payment Type', 'Amount', 'Percentage'];
    final rows = paymentsByType.map((payment) {
      return [
        payment['type'],
        currencyFormat.format(payment['amount']),
        '${payment['percentage'].toStringAsFixed(1)}%',
      ];
    }).toList();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                header,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) {
          return pw.TableRow(
            children: row.map((cell) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(cell),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildPaymentMethodTablePdf(Map<String, double> methodTotals, double total, NumberFormat currencyFormat) {
    final headers = ['Payment Method', 'Amount', 'Percentage'];
    final methodEntries = methodTotals.entries.toList();
    final rows = methodEntries.map((entry) {
      final percentage = total > 0 ? (entry.value / total) * 100 : 0;
      return [
        entry.key,
        currencyFormat.format(entry.value),
        '${percentage.toStringAsFixed(1)}%',
      ];
    }).toList();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                header,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) {
          return pw.TableRow(
            children: row.map((cell) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(cell),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildTransactionsTablePdf(List<Map<String, dynamic>> payments, NumberFormat currencyFormat) {
    final headers = ['Date', 'Student ID', 'Student Name', 'Amount', 'Payment Type', 'Method'];
    final rows = payments.map((payment) {
      final studentInfo = payment['studentInfo'] as Map<String, dynamic>;
      final studentName = '${studentInfo['lastName'] ?? ''}, ${studentInfo['firstName'] ?? ''} ${studentInfo['mi'] ?? ''}'.trim();
      
      return [
        DateFormat('MM/dd/yyyy').format(payment['timestamp']),
        payment['studentId'],
        studentName,
        currencyFormat.format(payment['amount']),
        payment['paymentType'],
        payment['paymentMethod'],
      ];
    }).toList();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                header,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) {
          return pw.TableRow(
            children: row.asMap().entries.map((entry) {
              final index = entry.key;
              final cell = entry.value;
              final textAlign = index == 3 // Amount column
                  ? pw.TextAlign.right
                  : (index == 0 || index == 1) // Date and Student ID
                      ? pw.TextAlign.center
                      : pw.TextAlign.left;
                      
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  cell,
                  textAlign: textAlign,
                  style: index == 3 // Amount column
                      ? pw.TextStyle(
                          color: PdfColors.green900,
                          fontWeight: pw.FontWeight.bold,
                        )
                      : null,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }
  
  Color _getPaymentTypeColor(String paymentType) {
    final type = paymentType.toLowerCase();
    if (type.contains('tuition')) {
      return Colors.blue.shade100;
    } else if (type.contains('downpayment')) {
      return Colors.green.shade100;
    } else if (type.contains('full')) {
      return Colors.purple.shade100;
    } else if (type.contains('partial')) {
      return Colors.orange.shade100;
    } else if (type.contains('scholarship')) {
      return Colors.teal.shade100;
    } else {
      return Colors.grey.shade100;
    }
  }
  
  Color _getPaymentMethodColor(String paymentMethod) {
    final method = paymentMethod.toLowerCase();
    if (method.contains('cash')) {
      return Colors.green;
    } else if (method.contains('online')) {
      return Colors.blue;
    } else if (method.contains('credit')) {
      return Colors.purple;
    } else if (method.contains('scholarship')) {
      return Colors.teal;
    } else if (method.contains('installment')) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
  
  IconData _getPaymentMethodIcon(String paymentMethod) {
    final method = paymentMethod.toLowerCase();
    if (method.contains('cash')) {
      return Icons.payments;
    } else if (method.contains('online')) {
      return Icons.language;
    } else if (method.contains('credit')) {
      return Icons.credit_card;
    } else if (method.contains('scholarship')) {
      return Icons.school;
    } else if (method.contains('installment')) {
      return Icons.calendar_month;
    } else {
      return Icons.payment;
    }
  }
}