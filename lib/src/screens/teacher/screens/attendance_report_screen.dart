import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../models/class_model.dart';
import '../services/attendance_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceReportScreen extends StatefulWidget {
  final ClassModel classModel;

  const AttendanceReportScreen({
    Key? key,
    required this.classModel,
  }) : super(key: key);

  @override
  _AttendanceReportScreenState createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  Map<String, Map<String, dynamic>> _studentSummaries = {};

  @override
  void initState() {
    super.initState();
    _loadAttendanceSummaries();
  }

  Future<void> _loadAttendanceSummaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summaries = <String, Map<String, dynamic>>{};
      for (final studentId in widget.classModel.studentIds) {
        final summary = await _attendanceService.getStudentAttendanceSummary(
          studentId,
          widget.classModel.id,
          _startDate,
          _endDate,
        );
        summaries[studentId] = summary;
      }

      setState(() {
        _studentSummaries = summaries;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load attendance summaries: $e',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportPDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdfData = await _attendanceService.generateClassAttendanceReport(
        widget.classModel.id,
        _startDate,
        _endDate,
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/attendance_report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.pdf',
      );
      await file.writeAsBytes(pdfData);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Attendance Report for ${widget.classModel.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export PDF: $e',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportCSV() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final csvData = await _attendanceService.generateClassAttendanceCSV(
        widget.classModel.id,
        _startDate,
        _endDate,
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/attendance_report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.csv',
      );
      await file.writeAsString(csvData);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Attendance Report for ${widget.classModel.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export CSV: $e',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendanceSummaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Report',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pdf':
                  _exportPDF();
                  break;
                case 'csv':
                  _exportCSV();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Export as PDF', style: TextStyle(fontFamily: 'Poppins',)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Export as CSV', style: TextStyle(fontFamily: 'Poppins',)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.classModel.name,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Period: ${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                        style: TextStyle(fontFamily: 'Poppins',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _studentSummaries.length,
                    itemBuilder: (context, index) {
                      final studentId = _studentSummaries.keys.elementAt(index);
                      final summary = _studentSummaries[studentId]!;
                      final presentPercentage =
                          summary['presentPercentage'] as double;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student ID: $studentId',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: presentPercentage / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getAttendanceColor(presentPercentage),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Attendance Rate: ${presentPercentage.toStringAsFixed(1)}%',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: _getAttendanceColor(
                                          presentPercentage),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${summary['present']}/${summary['total']} days',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatusCount(
                                    'Present',
                                    summary['present'] as int,
                                    Colors.green,
                                  ),
                                  _buildStatusCount(
                                    'Absent',
                                    summary['absent'] as int,
                                    Colors.red,
                                  ),
                                  _buildStatusCount(
                                    'Late',
                                    summary['late'] as int,
                                    Colors.orange,
                                  ),
                                  _buildStatusCount(
                                    'Excused',
                                    summary['excused'] as int,
                                    Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(fontFamily: 'Poppins',
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
