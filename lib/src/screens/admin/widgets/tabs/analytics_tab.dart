import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/providers/dashboard_provider.dart';
import 'package:school_management_system/src/config/theme.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final metrics = provider.metrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),
          
          // Key Performance Indicators
          _buildKPICards(metrics),
          const SizedBox(height: 28),
          
          // Revenue Analytics
          _buildRevenueSection(metrics),
          const SizedBox(height: 28),
          
          // Two Column Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Distribution
              Expanded(
                child: _buildStudentDistribution(metrics),
              ),
              const SizedBox(width: 20),
              
              // Attendance Overview
              Expanded(
                child: _buildAttendanceOverview(),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Performance Trends
          _buildPerformanceTrends(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Comprehensive insights and metrics',
              style: TextStyle(
                fontSize: 14,
                color: SMSTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: SMSTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SMSTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: SMSTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Last 30 days',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICards(DashboardMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            label: 'Total Revenue',
            value: '₱${NumberFormat('#,##0').format(metrics.totalRevenue)}',
            change: '+12.5%',
            isPositive: true,
            icon: Icons.payments_rounded,
            gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            label: 'This Month',
            value: '₱${NumberFormat('#,##0').format(metrics.thisMonthRevenue)}',
            change: '+8.2%',
            isPositive: true,
            icon: Icons.trending_up_rounded,
            gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            label: 'Avg per Student',
            value: '₱${NumberFormat('#,##0').format(metrics.totalRevenue ~/ (metrics.totalStudents > 0 ? metrics.totalStudents : 1))}',
            change: '+5.3%',
            isPositive: true,
            icon: Icons.person_rounded,
            gradientColors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            label: 'Collection Rate',
            value: '94.2%',
            change: '+2.1%',
            isPositive: true,
            icon: Icons.check_circle_rounded,
            gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? SMSTheme.successLight : SMSTheme.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: isPositive ? SMSTheme.successDark : SMSTheme.errorDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? SMSTheme.successDark : SMSTheme.errorDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: SMSTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(DashboardMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Text(
                'Revenue Trends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildLegendItem('Revenue', Color(0xFF3B82F6)),
              const SizedBox(width: 20),
              _buildLegendItem('Target', SMSTheme.neutralGray300),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 280,
            child: _buildRevenueChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: SMSTheme.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 15,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => SMSTheme.neutralGray800.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₱${(rod.toY * 50000).toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    months[value.toInt()],
                    style: TextStyle(
                      color: SMSTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₱${(value * 50).toInt()}k',
                  style: TextStyle(
                    color: SMSTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: SMSTheme.neutralGray200,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: [
          _buildBarGroup(0, 8),
          _buildBarGroup(1, 10),
          _buildBarGroup(2, 7),
          _buildBarGroup(3, 12),
          _buildBarGroup(4, 9),
          _buildBarGroup(5, 11),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildStudentDistribution(DashboardMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Student Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (metrics.studentsByGradeLevel.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: SMSTheme.neutralGray400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No data available',
                      style: TextStyle(color: SMSTheme.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: metrics.studentsByGradeLevel.entries.map((entry) {
                final total = metrics.studentsByGradeLevel.values.reduce((a, b) => a + b);
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getGradeColor(entry.key),
                                  _getGradeColor(entry.key).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Grade ${entry.key}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${entry.value} students',
                                      style: TextStyle(
                                        color: SMSTheme.textSecondaryLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: SMSTheme.neutralGray200,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: entry.value / total,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _getGradeColor(entry.key),
                                              _getGradeColor(entry.key).withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGradeColor(entry.key).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$percentage%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getGradeColor(entry.key),
                              ),
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
    );
  }

  Widget _buildAttendanceOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: 85,
                    title: '85%',
                    color: Color(0xFF10B981),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 10,
                    title: '10%',
                    color: Color(0xFFF59E0B),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 5,
                    title: '5%',
                    color: Color(0xFFEF4444),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAttendanceItem('Present', '85%', Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildAttendanceItem('Late', '10%', Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildAttendanceItem('Absent', '5%', Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTrends() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Performance Indicators',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Completion Rate',
                  '92.5%',
                  Icons.check_circle_rounded,
                  Color(0xFF10B981),
                  '+3.2%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Growth Rate',
                  '15.8%',
                  Icons.trending_up_rounded,
                  Color(0xFF3B82F6),
                  '+2.5%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Active Users',
                  '1,234',
                  Icons.people_rounded,
                  SMSTheme.primaryColor,
                  '+8.1%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Avg Score',
                  '85.2%',
                  Icons.assessment_rounded,
                  Color(0xFF8B5CF6),
                  '+1.7%',
                  true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: SMSTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive ? SMSTheme.successLight : SMSTheme.errorLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPositive ? SMSTheme.successDark : SMSTheme.errorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    final colors = {
      '1': Color(0xFF3B82F6),
      '2': Color(0xFF10B981),
      '3': Color(0xFFF59E0B),
      '4': Color(0xFFEF4444),
      '5': Color(0xFF8B5CF6),
      '6': Color(0xFF06B6D4),
      '7': Color(0xFFEC4899),
      '8': Color(0xFF84CC16),
      '9': Color(0xFFF97316),
      '10': Color(0xFF6366F1),
    };
    return colors[grade] ?? SMSTheme.neutralGray500;
  }
}