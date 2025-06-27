import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../teacher/models/attendance_model.dart';
import '../../teacher/models/class_model.dart';
import '../../teacher/services/attendance_service.dart';
import '../../teacher/services/class_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  _StudentDashboardScreenState createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ClassService _classService = ClassService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final studentId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: SMSTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: SMSTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 40, color: SMSTheme.primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.user?.displayName ?? 'Student',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    authProvider.user?.email ?? '',
                    style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text('Dashboard', style: TextStyle(fontFamily: 'Poppins',)),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Attendance', style: TextStyle(fontFamily: 'Poppins',)),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Logout', style: TextStyle(fontFamily: 'Poppins',)),
              onTap: () async {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: _buildBody(studentId),
    );
  }

  Widget _buildBody(String studentId) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(studentId);
      case 1:
        return _buildAttendanceContent(studentId);
      default:
        return _buildDashboardContent(studentId);
    }
  }

  Widget _buildDashboardContent(String studentId) {
    return StreamBuilder<List<ClassModel>>(
      stream: _classService.getStudentClasses(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTodayAttendance(studentId, classes),
                const SizedBox(height: 24),
                _buildClassList(classes),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAttendance(String studentId, List<ClassModel> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Classes",
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return StreamBuilder<List<AttendanceRecord>>(
              stream:
                  _attendanceService.getStudentAttendance(studentId, cls.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final records = snapshot.data!;
                final todayRecord = records.where((record) {
                  final today = DateTime.now();
                  return record.date.year == today.year &&
                      record.date.month == today.month &&
                      record.date.day == today.day;
                }).firstOrNull;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          cls.isHomeroom ? Colors.orange : Colors.purple,
                      child: Icon(
                        cls.isHomeroom ? Icons.home : Icons.book,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      cls.name,
                      style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      cls.subjects.join(', '),
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: _buildAttendanceStatus(todayRecord?.status),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceStatus(AttendanceStatus? status) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Not marked',
          style: TextStyle(fontFamily: 'Poppins',
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      );
    }

    IconData icon;
    Color color;
    String text;

    switch (status) {
      case AttendanceStatus.present:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Present';
        break;
      case AttendanceStatus.absent:
        icon = Icons.cancel;
        color = Colors.red;
        text = 'Absent';
        break;
      case AttendanceStatus.late:
        icon = Icons.access_time;
        color = Colors.orange;
        text = 'Late';
        break;
      case AttendanceStatus.excused:
        icon = Icons.medical_services;
        color = Colors.blue;
        text = 'Excused';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontFamily: 'Poppins',
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(List<ClassModel> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Classes',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor:
                      cls.isHomeroom ? Colors.orange : Colors.purple,
                  child: Icon(
                    cls.isHomeroom ? Icons.home : Icons.book,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  cls.name,
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade ${cls.gradeLevel} - Section ${cls.section}',
                      style: TextStyle(fontFamily: 'Poppins',),
                    ),
                    Text(
                      cls.subjects.join(', '),
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceContent(String studentId) {
    return StreamBuilder<List<ClassModel>>(
      stream: _classService.getStudentClasses(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data!;

        return DefaultTabController(
          length: classes.length,
          child: Column(
            children: [
              Container(
                color: Colors.grey[100],
                child: TabBar(
                  isScrollable: true,
                  labelColor: SMSTheme.primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: SMSTheme.primaryColor,
                  tabs: classes
                      .map(
                        (cls) => Tab(
                          child: Text(
                            cls.name,
                            style: TextStyle(fontFamily: 'Poppins',),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: classes
                      .map(
                          (cls) => _buildClassAttendanceHistory(studentId, cls))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassAttendanceHistory(String studentId, ClassModel classModel) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendanceService.getStudentAttendance(studentId, classModel.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!;
        records.sort((a, b) => b.date.compareTo(a.date));

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No attendance records yet',
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: _buildAttendanceIcon(record.status),
                title: Text(
                  record.status.toString().split('.').last,
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${_formatDate(record.date)}',
                      style: TextStyle(fontFamily: 'Poppins',),
                    ),
                    if (record.remarks?.isNotEmpty ?? false)
                      Text(
                        'Remarks: ${record.remarks}',
                        style: TextStyle(fontFamily: 'Poppins',
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceIcon(AttendanceStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case AttendanceStatus.present:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case AttendanceStatus.absent:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case AttendanceStatus.late:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case AttendanceStatus.excused:
        icon = Icons.medical_services;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
