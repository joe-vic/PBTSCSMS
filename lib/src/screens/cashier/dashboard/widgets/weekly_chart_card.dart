// lib/screens/cashier/dashboard/widgets/weekly_chart_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';

/// 🎯 This shows a line chart of weekly collections
/// Think of it like a graph showing how much money was collected each day
class WeeklyChartCard extends StatelessWidget {
  final List<FlSpot> weeklyData;
  final bool darkMode;

  const WeeklyChartCard({
    super.key,
    required this.weeklyData,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Divider line
          Divider(
            color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            thickness: 0.5,
          ),
          
          const SizedBox(height: 16),
          
          // Chart section
          SizedBox(
            height: 200,
            child: weeklyData.isEmpty
                ? _buildNoDataView()
                : _buildChart(days),
          ),
        ],
      ),
    );
  }

  /// 🎯 Chart header with title and badge
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Collections',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white : SMSTheme.textPrimaryColor,
              ),
            ),
            Text(
              'Current week overview',
              style: TextStyle(
                fontSize: 12,
                color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SMSTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'This Week',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SMSTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  /// 🎯 Show message when no data is available
  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No collections data available for this week',
            style: TextStyle(
              color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🎯 Build the actual line chart
  Widget _buildChart(List<String> days) {
    return LineChart(
      LineChartData(
        // Grid lines
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        
        // Axis labels
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return _buildBottomTitle(value, days, meta);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return _buildLeftTitle(value, meta);
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
        
        // Chart borders
        borderData: FlBorderData(show: false),
        
        // Chart range
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: _getMaxY(),
        
        // Line data
        lineBarsData: [
          LineChartBarData(
            spots: weeklyData,
            isCurved: true,
            color: SMSTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: SMSTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: SMSTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Build day labels (Mon, Tue, Wed, etc.)
  Widget _buildBottomTitle(double value, List<String> days, TitleMeta meta) {
    final int index = value.toInt();
    if (index >= 0 && index < days.length) {
      return SideTitleWidget(
        meta: meta,
        child: Text(
          days[index],
          style: TextStyle(
            color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 🎯 Build amount labels (₱0, ₱1k, ₱2k, etc.)
  Widget _buildLeftTitle(double value, TitleMeta meta) {
    String text = '';
    if (value == 0) {
      text = '₱0';
    } else if (value >= 1000) {
      final int thousands = (value / 1000).round();
      text = '₱${thousands}k';
    } else {
      text = '₱${value.toInt()}';
    }
    
    return SideTitleWidget(
      meta: meta,
      child: Text(
        text,
        style: TextStyle(
          color: darkMode ? Colors.white70 : SMSTheme.textSecondaryColor,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 🎯 Calculate appropriate interval for horizontal grid lines
  double _getHorizontalInterval() {
    if (weeklyData.isEmpty) return 1000;
    
    final maxValue = weeklyData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    if (maxValue <= 1000) return 250;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    return 5000;
  }

  /// 🎯 Calculate the maximum Y value for the chart
  double _getMaxY() {
    if (weeklyData.isEmpty) return 5000;
    
    final maxValue = weeklyData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    // Add 20% padding above the highest point
    final paddedMax = maxValue * 1.2;
    
    // Round to nice numbers
    if (paddedMax <= 1000) return 1000;
    if (paddedMax <= 5000) return 5000;
    if (paddedMax <= 10000) return 10000;
    if (paddedMax <= 25000) return 25000;
    if (paddedMax <= 50000) return 50000;
    
    // For larger numbers, round to nearest 10k
    return ((paddedMax / 10000).ceil() * 10000).toDouble();
  }
}