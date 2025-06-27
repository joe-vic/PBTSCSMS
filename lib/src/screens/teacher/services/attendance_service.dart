import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update an attendance session
  Future<void> saveAttendanceSession(AttendanceSession session) async {
    try {
      final docRef = _firestore
          .collection('classes')
          .doc(session.classId)
          .collection('attendance')
          .doc(session.id);

      await docRef.set(session.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save attendance session: $e');
    }
  }

  // Get attendance session for a specific date
  Future<AttendanceSession?> getAttendanceSession(
      String classId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return AttendanceSession.fromMap(
          snapshot.docs.first.id, snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get attendance session: $e');
    }
  }

  // Get attendance history for a student
  Stream<List<AttendanceRecord>> getStudentAttendance(
      String studentId, String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
      List<AttendanceRecord> records = [];
      for (var doc in snapshot.docs) {
        final session = AttendanceSession.fromMap(doc.id, doc.data());
        if (session.records.containsKey(studentId)) {
          records.add(session.records[studentId]!);
        }
      }
      return records;
    });
  }

  // Get attendance summary for a student
  Future<Map<String, dynamic>> getStudentAttendanceSummary(String studentId,
      String classId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .get();

      int present = 0;
      int absent = 0;
      int late = 0;
      int excused = 0;
      int total = 0;

      for (var doc in snapshot.docs) {
        final session = AttendanceSession.fromMap(doc.id, doc.data());
        if (session.records.containsKey(studentId)) {
          total++;
          switch (session.records[studentId]!.status) {
            case AttendanceStatus.present:
              present++;
              break;
            case AttendanceStatus.absent:
              absent++;
              break;
            case AttendanceStatus.late:
              late++;
              break;
            case AttendanceStatus.excused:
              excused++;
              break;
          }
        }
      }

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'excused': excused,
        'total': total,
        'presentPercentage': total > 0 ? (present / total * 100) : 0,
      };
    } catch (e) {
      throw Exception('Failed to get attendance summary: $e');
    }
  }

  // Generate PDF report for a class
  Future<List<int>> generateClassAttendanceReport(
      String classId, DateTime startDate, DateTime endDate) async {
    try {
      final pdf = pw.Document();
      final snapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .get();

      // Create a map to store attendance data by student
      Map<String, Map<String, AttendanceStatus>> attendanceByStudent = {};

      // Process all attendance records
      for (var doc in snapshot.docs) {
        final session = AttendanceSession.fromMap(doc.id, doc.data());
        final dateStr = DateFormat('yyyy-MM-dd').format(session.date);

        session.records.forEach((studentId, record) {
          attendanceByStudent.putIfAbsent(studentId, () => {});
          attendanceByStudent[studentId]![dateStr] = record.status;
        });
      }

      // Generate PDF content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Class Attendance Report',
                      style: pw.TextStyle(fontSize: 24)),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}'),
                pw.SizedBox(height: 20),
                _buildAttendanceTable(attendanceByStudent),
              ],
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw Exception('Failed to generate attendance report: $e');
    }
  }

  pw.Widget _buildAttendanceTable(
      Map<String, Map<String, AttendanceStatus>> attendanceByStudent) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Student ID'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Present'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Absent'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Late'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Excused'),
            ),
          ],
        ),
        // Data rows
        ...attendanceByStudent.entries.map((entry) {
          final counts = _getStatusCounts(entry.value);
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(entry.key),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(counts['present'].toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(counts['absent'].toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(counts['late'].toString()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(counts['excused'].toString()),
              ),
            ],
          );
        }),
      ],
    );
  }

  Map<String, int> _getStatusCounts(Map<String, AttendanceStatus> records) {
    final counts = {
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
    };

    records.values.forEach((status) {
      switch (status) {
        case AttendanceStatus.present:
          counts['present'] = counts['present']! + 1;
          break;
        case AttendanceStatus.absent:
          counts['absent'] = counts['absent']! + 1;
          break;
        case AttendanceStatus.late:
          counts['late'] = counts['late']! + 1;
          break;
        case AttendanceStatus.excused:
          counts['excused'] = counts['excused']! + 1;
          break;
      }
    });

    return counts;
  }

  // Generate CSV report for a class
  Future<String> generateClassAttendanceCSV(
      String classId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .get();

      // Create CSV header
      final csv = StringBuffer();
      csv.writeln('Date,Student ID,Status,Remarks');

      // Add records to CSV
      for (var doc in snapshot.docs) {
        final session = AttendanceSession.fromMap(doc.id, doc.data());
        final dateStr = DateFormat('yyyy-MM-dd').format(session.date);

        session.records.forEach((studentId, record) {
          csv.writeln(
              '$dateStr,$studentId,${record.status.toString().split('.').last},${record.remarks ?? ''}');
        });
      }

      return csv.toString();
    } catch (e) {
      throw Exception('Failed to generate CSV report: $e');
    }
  }
}
