import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../models/attendance_model.dart';
import '../models/class_model.dart';
import '../services/attendance_service.dart';
import 'attendance_report_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final ClassModel classModel;

  const AttendanceScreen({
    Key? key,
    required this.classModel,
  }) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _selectedDate = DateTime.now();
  AttendanceSession? _currentSession;
  bool _isLoading = true;
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  @override
  void dispose() {
    _remarksControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final session = await _attendanceService.getAttendanceSession(
        widget.classModel.id,
        _selectedDate,
      );

      if (session != null) {
        setState(() {
          _currentSession = session;
        });
      } else {
        // Create a new session with default values
        final records = Map.fromEntries(
          widget.classModel.studentIds.map(
            (studentId) => MapEntry(
              studentId,
              AttendanceRecord(
                id: studentId,
                studentId: studentId,
                classId: widget.classModel.id,
                date: _selectedDate,
                status: AttendanceStatus.present,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        );

        setState(() {
          _currentSession = AttendanceSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            classId: widget.classModel.id,
            date: _selectedDate,
            records: records,
            isComplete: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }

      // Initialize remarks controllers
      _currentSession?.records.forEach((studentId, record) {
        _remarksControllers[studentId] =
            TextEditingController(text: record.remarks);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load attendance: $e',
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

  Future<void> _saveAttendance() async {
    if (_currentSession == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update remarks from controllers
      final updatedRecords =
          Map<String, AttendanceRecord>.from(_currentSession!.records);
      updatedRecords.forEach((studentId, record) {
        updatedRecords[studentId] = record.copyWith(
          remarks: _remarksControllers[studentId]?.text,
          updatedAt: DateTime.now(),
        );
      });

      final updatedSession = _currentSession!.copyWith(
        records: updatedRecords,
        isComplete: true,
        updatedAt: DateTime.now(),
      );

      await _attendanceService.saveAttendanceSession(updatedSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance saved successfully',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save attendance: $e',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendance();
    }
  }

  void _updateAttendanceStatus(String studentId, AttendanceStatus status) {
    if (_currentSession == null) return;

    setState(() {
      final updatedRecords =
          Map<String, AttendanceRecord>.from(_currentSession!.records);
      final currentRecord = updatedRecords[studentId]!;
      updatedRecords[studentId] = currentRecord.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      _currentSession = _currentSession!.copyWith(
        records: updatedRecords,
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceReportScreen(
                    classModel: widget.classModel,
                  ),
                ),
              );
            },
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.classModel.name,
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                            style: TextStyle(fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.classModel.studentIds.length} students',
                        style: TextStyle(fontFamily: 'Poppins',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _currentSession == null
                      ? const Center(child: Text('No attendance data'))
                      : ListView.builder(
                          itemCount: _currentSession!.records.length,
                          itemBuilder: (context, index) {
                            final studentId =
                                _currentSession!.records.keys.elementAt(index);
                            final record = _currentSession!.records[studentId]!;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  'Student ID: $studentId',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Status: ${record.status.toString().split('.').last}',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    color: _getStatusColor(record.status),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            _buildStatusButton(
                                              studentId,
                                              AttendanceStatus.present,
                                              record.status,
                                              Icons.check_circle,
                                              Colors.green,
                                            ),
                                            _buildStatusButton(
                                              studentId,
                                              AttendanceStatus.absent,
                                              record.status,
                                              Icons.cancel,
                                              Colors.red,
                                            ),
                                            _buildStatusButton(
                                              studentId,
                                              AttendanceStatus.late,
                                              record.status,
                                              Icons.access_time,
                                              Colors.orange,
                                            ),
                                            _buildStatusButton(
                                              studentId,
                                              AttendanceStatus.excused,
                                              record.status,
                                              Icons.medical_services,
                                              Colors.blue,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller:
                                              _remarksControllers[studentId],
                                          decoration: InputDecoration(
                                            labelText: 'Remarks',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          style: TextStyle(fontFamily: 'Poppins',),
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAttendance,
        backgroundColor: SMSTheme.primaryColor,
        icon: const Icon(Icons.save),
        label: Text(
          'Save Attendance',
          style: TextStyle(fontFamily: 'Poppins',),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String studentId,
    AttendanceStatus status,
    AttendanceStatus currentStatus,
    IconData icon,
    Color color,
  ) {
    final isSelected = status == currentStatus;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: () => _updateAttendanceStatus(studentId, status),
          icon: Icon(
            icon,
            color: isSelected ? Colors.white : color,
          ),
          label: Text(
            status.toString().split('.').last,
            style: TextStyle(fontFamily: 'Poppins',
              color: isSelected ? Colors.white : color,
              fontSize: 12,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.white,
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }
}
