import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/config/theme.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  String _selectedCategory = 'All';
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),
          
          // Report Generation Cards
          _buildReportGeneration(),
          const SizedBox(height: 28),
          
          // Recent Reports Section
          _buildRecentReportsSection(),
          const SizedBox(height: 28),
          
          // Quick Export Actions
          _buildQuickExportSection(),
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
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Generate and manage system reports',
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
            gradient: LinearGradient(
              colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: SMSTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.auto_graph_rounded, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Generate Custom',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportGeneration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Generate Reports', Icons.note_add_rounded),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildReportCard(
              'Student Enrollment',
              'Complete enrollment statistics',
              Icons.school_rounded,
              [Color(0xFF3B82F6), Color(0xFF2563EB)],
              '1,234 records',
            ),
            _buildReportCard(
              'Financial Summary',
              'Revenue and payment analysis',
              Icons.payments_rounded,
              [Color(0xFF10B981), Color(0xFF059669)],
              '₱2.5M total',
            ),
            _buildReportCard(
              'Attendance Report',
              'Student & teacher attendance',
              Icons.calendar_today_rounded,
              [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              '92% average',
            ),
            _buildReportCard(
              'Performance Analytics',
              'Academic performance metrics',
              Icons.analytics_rounded,
              [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              '85% avg score',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SMSTheme.primaryColor.withOpacity(0.1),
                SMSTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: SMSTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    List<Color> gradientColors,
    String metaInfo,
  ) {
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradientColors[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  metaInfo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: gradientColors[0],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: SMSTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _generateReport(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradientColors[0],
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Generate',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('Recent Reports', Icons.history_rounded),
            const Spacer(),
            _buildCategoryFilter(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
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
            children: [
              _buildReportItem(
                'Monthly Enrollment Report',
                '2024-01-15',
                'PDF',
                Icons.school_rounded,
                Color(0xFF3B82F6),
                '2.4 MB',
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildReportItem(
                'Financial Q4 2023',
                '2024-01-10',
                'Excel',
                Icons.payments_rounded,
                Color(0xFF10B981),
                '1.8 MB',
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildReportItem(
                'Student Performance Analysis',
                '2024-01-05',
                'PDF',
                Icons.analytics_rounded,
                Color(0xFF8B5CF6),
                '3.2 MB',
              ),
              Divider(height: 1, color: SMSTheme.neutralGray200),
              _buildReportItem(
                'Teacher Attendance Summary',
                '2024-01-01',
                'Excel',
                Icons.calendar_today_rounded,
                SMSTheme.primaryColor,
                '1.1 MB',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SMSTheme.neutralGray100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('PDF'),
          _buildFilterChip('Excel'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? SMSTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : SMSTheme.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(
    String title,
    String date,
    String format,
    IconData icon,
    Color color,
    String fileSize,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: SMSTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Generated on $date',
                      style: TextStyle(
                        fontSize: 12,
                        color: SMSTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.storage_rounded,
                      size: 12,
                      color: SMSTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fileSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: SMSTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getFormatColor(format),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              format,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadReport(title),
            color: SMSTheme.primaryColor,
            style: IconButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor.withOpacity(0.1),
            ),
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.visibility_rounded),
            onPressed: () => _viewReport(title),
            color: SMSTheme.neutralGray600,
            tooltip: 'Preview',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Export', Icons.flash_on_rounded),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildQuickExportCard(
                'Students Data',
                Icons.school_rounded,
                [Color(0xFF3B82F6), Color(0xFF2563EB)],
                '1,234 records',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickExportCard(
                'Payment Records',
                Icons.receipt_long_rounded,
                [Color(0xFF10B981), Color(0xFF059669)],
                '856 transactions',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickExportCard(
                'Course Data',
                Icons.book_rounded,
                [SMSTheme.primaryColor, SMSTheme.secondaryColor],
                '48 courses',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickExportCard(
                'Complete Backup',
                Icons.cloud_download_rounded,
                [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                'Full database',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickExportCard(
    String title,
    IconData icon,
    List<Color> gradientColors,
    String info,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _quickExport(title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(0.1),
                gradientColors[1].withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradientColors[0].withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info,
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gradientColors[0],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.file_download_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return Color(0xFFEF4444);
      case 'excel':
        return Color(0xFF10B981);
      case 'csv':
        return Color(0xFF3B82F6);
      default:
        return SMSTheme.neutralGray500;
    }
  }

  void _generateReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Generating $reportType...'),
          ],
        ),
        backgroundColor: SMSTheme.successDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _downloadReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Downloading $reportName...'),
          ],
        ),
        backgroundColor: SMSTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _viewReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Opening $reportName...'),
          ],
        ),
        backgroundColor: SMSTheme.infoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _quickExport(String dataType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.file_download_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Exporting $dataType...'),
          ],
        ),
        backgroundColor: SMSTheme.neutralGray800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}