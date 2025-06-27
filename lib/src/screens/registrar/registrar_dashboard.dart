import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class RegistrarDashboard extends StatefulWidget {
  @override
  _RegistrarDashboardState createState() => _RegistrarDashboardState();
}

class _RegistrarDashboardState extends State<RegistrarDashboard> {
  int _selectedIndex = 0;
  final List<String> _tabs = ['Enrollments', 'Students', 'Reports', 'Users'];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _approveEnrollment(String enrollmentId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    // await firestoreService.updateEnrollmentStatus(enrollmentId, 'approved');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrollment approved')),
    );
  }

  Future<void> _rejectEnrollment(String enrollmentId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    // await firestoreService.updateEnrollmentStatus(enrollmentId, 'rejected');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrollment rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Dashboard'),
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
                // Enrollments Tab
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No pending enrollments'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(data['studentInfo']['firstName'] + ' ' + data['studentInfo']['lastName']),
                            subtitle: Text('Status: Pending'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _approveEnrollment(doc.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _rejectEnrollment(doc.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Students Tab
                Center(child: Text('Student Records (Under Development)')),
                // Reports Tab
                Center(child: Text('Report Generation (Under Development)')),
                // Users Tab
                Center(child: Text('User Management (Under Development)')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}