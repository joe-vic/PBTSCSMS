import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/student.dart';

class StudentSelectionScreen extends StatefulWidget {
  final String gradeLevel;
  final List<String> alreadySelectedStudents;

  const StudentSelectionScreen({
    Key? key,
    required this.gradeLevel,
    required this.alreadySelectedStudents,
  }) : super(key: key);

  @override
  _StudentSelectionScreenState createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends State<StudentSelectionScreen> {
  final Set<String> _selectedStudents = {};
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStudents.addAll(widget.alreadySelectedStudents);
  }

  Stream<QuerySnapshot> _getStudentsStream() {
    Query query = FirebaseFirestore.instance
        .collection('students')
        .where('gradeLevel', isEqualTo: widget.gradeLevel);

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('lastName', isGreaterThanOrEqualTo: _searchQuery)
          .where('lastName', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Students - Grade ${widget.gradeLevel}',
          style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
        ),
        backgroundColor: SMSTheme.primaryColor,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedStudents.toList());
            },
            child: Text(
              'Done (${_selectedStudents.length})',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by last name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStudentsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data?.docs ?? [];

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final student =
                        students[index].data() as Map<String, dynamic>;
                    final studentId = students[index].id;
                    final isSelected = _selectedStudents.contains(studentId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? SMSTheme.primaryColor
                              : Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        title: Text(
                          '${student['lastName']}, ${student['firstName']} ${student['mi'] ?? ''}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Student ID: ${student['studentId'] ?? 'N/A'}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: SMSTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedStudents.add(studentId);
                              } else {
                                _selectedStudents.remove(studentId);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedStudents.remove(studentId);
                            } else {
                              _selectedStudents.add(studentId);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _selectedStudents.toList());
        },
        backgroundColor: SMSTheme.primaryColor,
        icon: const Icon(Icons.check),
        label: Text(
          'Confirm Selection',
          style: TextStyle(fontFamily: 'Poppins',),
        ),
      ),
    );
  }
}
