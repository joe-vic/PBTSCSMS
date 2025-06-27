import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/enrollment/payment_notification_widget.dart';

/// A dashboard screen for monitoring payments and enrollments
class PaymentDashboardScreen extends StatefulWidget {
  const PaymentDashboardScreen({Key? key}) : super(key: key);

  @override
  _PaymentDashboardScreenState createState() => _PaymentDashboardScreenState();
}

class _PaymentDashboardScreenState extends State<PaymentDashboardScreen> {
  String _currentAcademicYear = '';
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;
  
  // Dashboard metrics
  int _totalEnrollments = 0;
  int _pendingEnrollments = 0;
  int _unpaidEnrollments = 0;
  int _partialEnrollments = 0;
  int _paidEnrollments = 0;
  int _overduePayments = 0;
  double _totalCollected = 0.0;
  double _totalOutstanding = 0.0;
  
  // Chart data
  List<Map<String, dynamic>> _paymentsByDay = [];
  List<Map<String, dynamic>> _enrollmentsByStatus = [];
  List<Map<String, dynamic>> _paymentsByMethod = [];
  
  // Filter options
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'All Time',
  ];
  
  @override
  void initState() {
    super.initState();
    _initAcademicYear();
    _loadDashboardData();
  }
  
  /// Initialize the academic year based on current date
  void _initAcademicYear() {
    final now = DateTime.now();
    final year = now.month >= 6 ? now.year : now.year - 1; // Academic year starts in June
    _currentAcademicYear = '$year-${year + 1}';
  }
  
  /// Load dashboard data
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadEnrollmentMetrics(),
        _loadPaymentMetrics(),
        _loadChartData(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Load enrollment metrics
  Future<void> _loadEnrollmentMetrics() async {
    // Get enrollment counts by status
    final enrollmentsQuery = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('academicYear', isEqualTo: _currentAcademicYear)
        .get();
    
    final enrollments = enrollmentsQuery.docs;
    
    int totalEnrollments = enrollments.length;
    int pendingEnrollments = 0;
    int unpaidEnrollments = 0;
    int partialEnrollments = 0;
    int paidEnrollments = 0;
    
    for (final doc in enrollments) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'pending';
      final paymentStatus = data['paymentStatus'] as String? ?? 'unpaid';
      
      if (status == 'pending') {
        pendingEnrollments++;
      }
      
      if (paymentStatus == 'unpaid') {
        unpaidEnrollments++;
      } else if (paymentStatus == 'partial') {
        partialEnrollments++;
      } else if (paymentStatus == 'paid') {
        paidEnrollments++;
      }
    }
    
    // Get overdue payments count
    final overdueQuery = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('academicYear', isEqualTo: _currentAcademicYear)
        .where('isOverdue', isEqualTo: true)
        .get();
    
    final overduePayments = overdueQuery.docs.length;
    
    setState(() {
      _totalEnrollments = totalEnrollments;
      _pendingEnrollments = pendingEnrollments;
      _unpaidEnrollments = unpaidEnrollments;
      _partialEnrollments = partialEnrollments;
      _paidEnrollments = paidEnrollments;
      _overduePayments = overduePayments;
    });
  }
  
  /// Load payment metrics
  Future<void> _loadPaymentMetrics() async {
    // Calculate date range based on selected period
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Quarter':
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'All Time':
      default:
        // Use a distant past date
        startDate = DateTime(2000, 1, 1);
        break;
    }
    
    // Convert to Timestamp for Firestore query
    final startTimestamp = Timestamp.fromDate(startDate);
    
    // Get payment totals
    final paymentsQuery = await FirebaseFirestore.instance
        .collection('payments')
        .where('academicYear', isEqualTo: _currentAcademicYear)
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .get();
    
    double totalCollected = 0.0;
    
    for (final doc in paymentsQuery.docs) {
      final data = doc.data();
      final amount = data['amount'] as double? ?? 0.0;
      totalCollected += amount;
    }
    
    // Get total outstanding balance
    final enrollmentsQuery = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('academicYear', isEqualTo: _currentAcademicYear)
        .where('paymentStatus', whereIn: ['unpaid', 'partial'])
        .get();
    
    double totalOutstanding = 0.0;
    
    for (final doc in enrollmentsQuery.docs) {
      final data = doc.data();
      final balance = data['balanceRemaining'] as double? ?? 0.0;
      totalOutstanding += balance;
    }
    
    setState(() {
      _totalCollected = totalCollected;
      _totalOutstanding = totalOutstanding;
    });
  }
  
  /// Load chart data
  Future<void> _loadChartData() async {
    await Future.wait([
      _loadPaymentsByDayChart(),
      _loadEnrollmentsByStatusChart(),
      _loadPaymentsByMethodChart(),
    ]);
  }
  
  /// Load payments by day chart
  Future<void> _loadPaymentsByDayChart() async {
    // Calculate date range based on selected period
    final now = DateTime.now();
    DateTime startDate;
    int days;
    
    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        days = 1;
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        days = 7;
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        // Calculate days in month
        final nextMonth = now.month < 12 
            ? DateTime(now.year, now.month + 1, 1)
            : DateTime(now.year + 1, 1, 1);
        days = nextMonth.difference(startDate).inDays;
        break;
      case 'This Quarter':
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        days = 90; // Approximate days in a quarter
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        days = 365; // Approximate days in a year
        break;
      case 'All Time':
      default:
        // Use academic year start
        final academicYearStart = int.parse(_currentAcademicYear.split('-')[0]);
        startDate = DateTime(academicYearStart, 6, 1); // June 1st of academic year
        days = DateTime.now().difference(startDate).inDays + 1;
        break;
    }
    
    // Convert to Timestamp for Firestore query
    final startTimestamp = Timestamp.fromDate(startDate);
    
    // Initialize data for each day
    final List<Map<String, dynamic>> paymentsByDay = [];
    
    // For 'Today', we'll show hourly data
    if (_selectedPeriod == 'Today') {
      for (int hour = 0; hour < 24; hour++) {
        paymentsByDay.add({
          'label': '$hour:00',
          'amount': 0.0,
          'count': 0,
        });
      }
      
      // Get payments for today
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('academicYear', isEqualTo: _currentAcademicYear)
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .get();
      
      for (final doc in paymentsQuery.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        
        if (timestamp != null) {
          final date = timestamp.toDate();
          final hour = date.hour;
          
          if (hour >= 0 && hour < 24) {
            paymentsByDay[hour]['amount'] += data['amount'] as double? ?? 0.0;
            paymentsByDay[hour]['count'] += 1;
          }
        }
      }
    } else {
      // For other periods, we'll show daily data
      for (int i = 0; i < days; i++) {
        final day = startDate.add(Duration(days: i));
        paymentsByDay.add({
          'date': day,
          'label': DateFormat('MMM d').format(day),
          'amount': 0.0,
          'count': 0,
        });
      }
      
      // Get payments for the period
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('academicYear', isEqualTo: _currentAcademicYear)
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .get();
      
      for (final doc in paymentsQuery.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dayDifference = date.difference(startDate).inDays;
          
          if (dayDifference >= 0 && dayDifference < days) {
            paymentsByDay[dayDifference]['amount'] += data['amount'] as double? ?? 0.0;
            paymentsByDay[dayDifference]['count'] += 1;
          }
        }
      }
    }
    
    setState(() {
      _paymentsByDay = paymentsByDay;
    });
  }
  
  /// Load enrollments by status chart
  Future<void> _loadEnrollmentsByStatusChart() async {
    // Get enrollment counts by status
    final enrollmentsQuery = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('academicYear', isEqualTo: _currentAcademicYear)
        .get();
    
    final enrollments = enrollmentsQuery.docs;
    
    int pendingCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;
    
    for (final doc in enrollments) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'pending';
      
      if (status == 'pending') {
        pendingCount++;
      } else if (status == 'approved') {
        approvedCount++;
      } else if (status == 'rejected') {
        rejectedCount++;
      }
    }
    
    setState(() {
      _enrollmentsByStatus = [
        {'status': 'Pending', 'count': pendingCount, 'color': Colors.orange},
        {'status': 'Approved', 'count': approvedCount, 'color': Colors.green},
        {'status': 'Rejected', 'count': rejectedCount, 'color': Colors.red},
      ];
    });
  }
  
  /// Load payments by method chart
  Future<void> _loadPaymentsByMethodChart() async {
    // Calculate date range based on selected period
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Quarter':
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'All Time':
      default:
        // Use a distant past date
        startDate = DateTime(2000, 1, 1);
        break;
    }
    
    // Convert to Timestamp for Firestore query
    final startTimestamp = Timestamp.fromDate(startDate);
    
    // Get payments by method
    final paymentsQuery = await FirebaseFirestore.instance
        .collection('payments')
        .where('academicYear', isEqualTo: _currentAcademicYear)
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .get();
    
    final Map<String, double> methodTotals = {};
    
    for (final doc in paymentsQuery.docs) {
      final data = doc.data();
      final method = data['paymentMethod'] as String? ?? 'Cash';
      final amount = data['amount'] as double? ?? 0.0;
      
      methodTotals[method] = (methodTotals[method] ?? 0.0) + amount;
    }
    
    // Convert to list for chart
    final List<Map<String, dynamic>> paymentsByMethod = [];
    
    // Assign colors
    final List<Color> methodColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    
    int colorIndex = 0;
    methodTotals.forEach((method, amount) {
      paymentsByMethod.add({
        'method': method,
        'amount': amount,
        'color': methodColors[colorIndex % methodColors.length],
      });
      colorIndex++;
    });
    
    // Sort by amount (descending)
    paymentsByMethod.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    
    setState(() {
      _paymentsByMethod = paymentsByMethod;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Dashboard', style: TextStyle(fontFamily: 'Poppins',)),
        actions: [
          // Period selector
          DropdownButton<String>(
            value: _selectedPeriod,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            dropdownColor: Colors.indigo.shade800,
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _selectedPeriod) {
                setState(() {
                  _selectedPeriod = newValue;
                });
                _loadDashboardData();
              }
            },
            items: _periods.map((period) => DropdownMenuItem(
              value: period,
              child: Text(period),
            )).toList(),
          ),
          const SizedBox(width: 16),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
    );
  }
  
  /// Build the dashboard content
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notifications
          const PaymentNotificationWidget(),
          const SizedBox(height: 24),
          
          // Dashboard header
          Text(
            'Payment Dashboard',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          Text(
            'Academic Year: $_currentAcademicYear | Period: $_selectedPeriod',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Key metrics
          _buildMetricsSection(),
          const SizedBox(height: 24),
          
          // Charts
          _buildChartsSection(),
          const SizedBox(height: 24),
          
          // Recent payments and overdue
          _buildRecentActivitySection(),
        ],
      ),
    );
  }
  
  /// Build the metrics section
  Widget _buildMetricsSection() {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Metrics grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Revenue metric
            _buildMetricCard(
              title: 'Total Revenue',
              value: currencyFormat.format(_totalCollected),
              icon: Icons.monetization_on,
              color: Colors.green,
            ),
            
            // Outstanding balance metric
            _buildMetricCard(
              title: 'Outstanding Balance',
              value: currencyFormat.format(_totalOutstanding),
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
            ),
            
            // Total enrollments metric
            _buildMetricCard(
              title: 'Total Enrollments',
              value: _totalEnrollments.toString(),
              icon: Icons.school,
              color: Colors.blue,
            ),
            
            // Overdue payments metric
            _buildMetricCard(
              title: 'Overdue Payments',
              value: _overduePayments.toString(),
              icon: Icons.warning,
              color: Colors.red,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Payment status breakdown
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Status Breakdown',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status progress bars
                _buildProgressBar(
                  label: 'Paid',
                  count: _paidEnrollments,
                  total: _totalEnrollments,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildProgressBar(
                  label: 'Partial',
                  count: _partialEnrollments,
                  total: _totalEnrollments,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildProgressBar(
                  label: 'Unpaid',
                  count: _unpaidEnrollments,
                  total: _totalEnrollments,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a metric card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a progress bar
  Widget _buildProgressBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            Text(
              '$count / $total (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  /// Build the charts section
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charts & Analytics',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Payments by day chart
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payments by ${_selectedPeriod == 'Today' ? 'Hour' : 'Day'}',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 200,
                  child: _buildPaymentsByDayChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Enrollments by status & Payments by method charts
        Row(
          children: [
            // Enrollments by status pie chart
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enrollments by Status',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 200,
                        child: _buildEnrollmentsByStatusChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Payments by method pie chart
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments by Method',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 200,
                        child: _buildPaymentsByMethodChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build the payments by day chart
  Widget _buildPaymentsByDayChart() {
    if (_paymentsByDay.isEmpty) {
      return Center(
        child: Text(
          'No payment data available for this period',
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxPaymentAmount() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // Remove the problematic background color parameter completely
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = _paymentsByDay[groupIndex];
              final amount = data['amount'] as double;
              final count = data['count'] as int;
              return BarTooltipItem(
                '${data['label']}\n₱${amount.toStringAsFixed(2)}\n$count payment${count == 1 ? '' : 's'}',
                TextStyle(fontFamily: 'Poppins',color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show fewer labels if there are many days
                if (_paymentsByDay.length > 10) {
                  if (value.toInt() % (_paymentsByDay.length ~/ 10 + 1) != 0) {
                    return const SizedBox.shrink();
                  }
                }
                
                final index = value.toInt();
                if (index >= 0 && index < _paymentsByDay.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _paymentsByDay[index]['label'] as String,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₱${value.toInt()}',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _getMaxPaymentAmount() / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: _getPaymentBarGroups(),
      ),
    );
  }
  
  /// Get the maximum payment amount for the chart
  double _getMaxPaymentAmount() {
    if (_paymentsByDay.isEmpty) return 1000.0;
    
    double maxAmount = 0.0;
    for (final data in _paymentsByDay) {
      final amount = data['amount'] as double;
      if (amount > maxAmount) {
        maxAmount = amount;
      }
    }
    
    return maxAmount > 0 ? maxAmount : 1000.0;
  }
  
  /// Get the bar groups for the payment chart
  List<BarChartGroupData> _getPaymentBarGroups() {
    return List.generate(_paymentsByDay.length, (index) {
      final data = _paymentsByDay[index];
      final amount = data['amount'] as double;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: SMSTheme.primaryColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
  
  /// Build the enrollments by status chart
  Widget _buildEnrollmentsByStatusChart() {
    if (_enrollmentsByStatus.isEmpty || _enrollmentsByStatus.every((item) => item['count'] == 0)) {
      return Center(
        child: Text(
          'No enrollment data available',
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sections: _enrollmentsByStatus.map((item) {
          final status = item['status'] as String;
          final count = item['count'] as int;
          final color = item['color'] as Color;
          
          return PieChartSectionData(
            value: count.toDouble(),
            title: count > 0 ? status : '',
            color: color,
            radius: 80,
            titleStyle: TextStyle(fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
  
  /// Build the payments by method chart
  Widget _buildPaymentsByMethodChart() {
    if (_paymentsByMethod.isEmpty) {
      return Center(
        child: Text(
          'No payment data available for this period',
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    
    final total = _paymentsByMethod.fold<double>(
        0.0, (sum, item) => sum + (item['amount'] as double));
    
    return Stack(
      children: [
        PieChart(
          PieChartData(
            sections: _paymentsByMethod.map((item) {
              final method = item['method'] as String;
              final amount = item['amount'] as double;
              final color = item['color'] as Color;
              final percentage = total > 0 ? (amount / total * 100) : 0.0;
              
              return PieChartSectionData(
                value: amount,
                title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                color: color,
                radius: 80,
                titleStyle: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build the recent activity section
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Recent payments and overdue tabs
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Recent Payments'),
                  Tab(text: 'Overdue Payments'),
                ],
                labelColor: SMSTheme.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: SMSTheme.primaryColor,
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    // Recent payments tab
                    _buildRecentPaymentsTab(),
                    
                    // Overdue payments tab
                    _buildOverduePaymentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build the recent payments tab
  Widget _buildRecentPaymentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('academicYear', isEqualTo: _currentAcademicYear)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading payments: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No recent payments found',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade600),
            ),
          );
        }
        
        final payments = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index].data() as Map<String, dynamic>;
            final studentInfo = payment['studentInfo'] as Map<String, dynamic>? ?? {};
            final studentName = '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}';
            final amount = payment['amount'] as double? ?? 0.0;
            final timestamp = payment['timestamp'] as Timestamp?;
            final date = timestamp?.toDate() ?? DateTime.now();
            final paymentMethod = payment['paymentMethod'] as String? ?? 'Cash';
            
            return ListTile(
              title: Text(
                studentName,
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${DateFormat('MMM d, yyyy h:mm a').format(date)} • $paymentMethod',
                style: TextStyle(fontFamily: 'Poppins',fontSize: 12),
              ),
              trailing: Text(
                '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.payments, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
  
  /// Build the overdue payments tab
  Widget _buildOverduePaymentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('academicYear', isEqualTo: _currentAcademicYear)
          .where('isOverdue', isEqualTo: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading overdue payments: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No overdue payments found',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade600),
            ),
          );
        }
        
        final enrollments = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index].data() as Map<String, dynamic>;
            final studentInfo = enrollment['studentInfo'] as Map<String, dynamic>? ?? {};
            final studentName = '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}';
            final balanceRemaining = enrollment['balanceRemaining'] as double? ?? 0.0;
            final overdueAt = enrollment['overdueAt'] as Timestamp?;
            final overdueDate = overdueAt?.toDate() ?? DateTime.now();
            final daysOverdue = DateTime.now().difference(overdueDate).inDays;
            
            return ListTile(
              title: Text(
                studentName,
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Overdue for $daysOverdue day${daysOverdue == 1 ? '' : 's'}',
                style: TextStyle(fontFamily: 'Poppins',fontSize: 12),
              ),
              trailing: Text(
                '₱${balanceRemaining.toStringAsFixed(2)}',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Icon(Icons.warning, color: Colors.red),
              ),
            );
          },
        );
      },
    );
  }
}