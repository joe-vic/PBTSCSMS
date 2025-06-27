import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  final List<String> _tabs = ['Students', 'Attendance', 'Grades', 'Schedule', 'Announcements'];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueAccent,
            child: TabBar(
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              onTap: _onTabTapped,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Students Tab
                FutureBuilder<List<Student>>(
                  future: Provider.of<FirestoreService>(context, listen: false).getAllStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final students = snapshot.data ?? [];
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return ListTile(
                          title: Text('${student.firstName} ${student.lastName}'),
                          subtitle: Text('Grade: ${student.gradeLevel}'),
                        );
                      },
                    );
                  },
                ),
                // Attendance Tab
                Center(child: Text('Attendance Tracking (Under Development)')),
                // Grades Tab
                Center(child: Text('Grade Management (Under Development)')),
                // Schedule Tab
                Center(child: Text('Class Schedule (Under Development)')),
                // Announcements Tab
                Center(child: Text('Announcements (Under Development)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}