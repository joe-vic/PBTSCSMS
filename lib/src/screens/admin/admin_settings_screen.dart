import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  final String tab; // Determines which section to display
  const AdminSettingsScreen({required this.tab});

  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for various inputs
  final TextEditingController _gradeLevelController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _strandController = TextEditingController();
  final TextEditingController _strandDescController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _courseDescController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _roomCapacityController = TextEditingController();
  final TextEditingController _enrollmentFeeController =
      TextEditingController();

  String? _selectedGradeLevelForSubject;
  List<String> _gradeLevels = [];

  @override
  void initState() {
    super.initState();
    if (widget.tab == 'subjects') {
      _fetchGradeLevels();
    }
  }

  void _fetchGradeLevels() async {
    QuerySnapshot snapshot = await _firestore.collection('gradeLevels').get();
    setState(() {
      _gradeLevels = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  void _addGradeLevel() async {
    String newGradeLevel = _gradeLevelController.text.trim();
    if (newGradeLevel.isNotEmpty) {
      await _firestore.collection('gradeLevels').doc(newGradeLevel).set({
        'name': newGradeLevel,
      });
      _gradeLevelController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grade Level "$newGradeLevel" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateGradeLevel(String docId, String currentName) async {
    String updatedName = _gradeLevelController.text.trim();
    if (updatedName.isNotEmpty) {
      await _firestore.collection('gradeLevels').doc(docId).update({
        'name': updatedName,
      });
      _gradeLevelController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grade Level updated to "$updatedName"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _addSubject() async {
    String newSubject = _subjectController.text.trim();
    if (newSubject.isNotEmpty && _selectedGradeLevelForSubject != null) {
      await _firestore.collection('subjects').add({
        'name': newSubject,
        'gradeLevel': _selectedGradeLevelForSubject,
      });
      _subjectController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject "$newSubject" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateSubject(String docId, String currentName) async {
    String updatedName = _subjectController.text.trim();
    if (updatedName.isNotEmpty && _selectedGradeLevelForSubject != null) {
      await _firestore.collection('subjects').doc(docId).update({
        'name': updatedName,
        'gradeLevel': _selectedGradeLevelForSubject,
      });
      _subjectController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject updated to "$updatedName"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _addStrand() async {
    String newStrand = _strandController.text.trim();
    String description = _strandDescController.text.trim();
    if (newStrand.isNotEmpty) {
      await _firestore.collection('strands').doc(newStrand.toLowerCase()).set({
        'name': newStrand,
        'description': description,
      });
      _strandController.clear();
      _strandDescController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Strand "$newStrand" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateStrand(String docId, String currentName) async {
    String updatedName = _strandController.text.trim();
    String updatedDesc = _strandDescController.text.trim();
    if (updatedName.isNotEmpty) {
      await _firestore.collection('strands').doc(docId).update({
        'name': updatedName,
        'description': updatedDesc,
      });
      _strandController.clear();
      _strandDescController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Strand updated to "$updatedName"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _addCourse() async {
    String newCourse = _courseController.text.trim();
    String description = _courseDescController.text.trim();
    if (newCourse.isNotEmpty) {
      await _firestore.collection('courses').doc(newCourse.toLowerCase()).set({
        'name': newCourse,
        'description': description,
      });
      _courseController.clear();
      _courseDescController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course "$newCourse" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateCourse(String docId, String currentName) async {
    String updatedName = _courseController.text.trim();
    String updatedDesc = _courseDescController.text.trim();
    if (updatedName.isNotEmpty) {
      await _firestore.collection('courses').doc(docId).update({
        'name': updatedName,
        'description': updatedDesc,
      });
      _courseController.clear();
      _courseDescController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course updated to "$updatedName"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _addBranch() async {
    String newBranch = _branchController.text.trim();
    if (newBranch.isNotEmpty) {
      await _firestore.collection('branches').doc(newBranch.toLowerCase()).set({
        'name': newBranch,
      });
      _branchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Branch "$newBranch" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateBranch(String docId, String currentName) async {
    String updatedName = _branchController.text.trim();
    if (updatedName.isNotEmpty) {
      await _firestore.collection('branches').doc(docId).update({
        'name': updatedName,
      });
      _branchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Branch updated to "$updatedName"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _addTeacher() async {
    String name = _teacherNameController.text.trim();
    String email = _teacherEmailController.text.trim();
    if (name.isNotEmpty && email.isNotEmpty) {
      await _firestore.collection('teachers').add({
        'name': name,
        'email': email,
      });
      _teacherNameController.clear();
      _teacherEmailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teacher "$name" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateTeacher(String docId, String currentName) async {
    String updatedName = _teacherNameController.text.trim();
    String updatedEmail = _teacherEmailController.text.trim();
    if (updatedName.isNotEmpty && updatedEmail.isNotEmpty) {
      await _firestore.collection('teachers').doc(docId).update({
        'name': updatedName,
        'email': updatedEmail,
      });
      _teacherNameController.clear();
      _teacherEmailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teacher updated to "$updatedName"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _addRoom() async {
    String roomNumber = _roomNumberController.text.trim();
    String capacity = _roomCapacityController.text.trim();
    if (roomNumber.isNotEmpty && capacity.isNotEmpty) {
      await _firestore.collection('rooms').add({
        'number': roomNumber,
        'capacity': int.parse(capacity),
      });
      _roomNumberController.clear();
      _roomCapacityController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room "$roomNumber" added'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateRoom(String docId, String currentNumber) async {
    String updatedNumber = _roomNumberController.text.trim();
    String updatedCapacity = _roomCapacityController.text.trim();
    if (updatedNumber.isNotEmpty && updatedCapacity.isNotEmpty) {
      await _firestore.collection('rooms').doc(docId).update({
        'number': updatedNumber,
        'capacity': int.parse(updatedCapacity),
      });
      _roomNumberController.clear();
      _roomCapacityController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room updated to "$updatedNumber"'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  void _updateEnrollmentSettings() async {
    String fee = _enrollmentFeeController.text.trim();
    if (fee.isNotEmpty) {
      await _firestore.collection('enrollmentSettings').doc('settings').set({
        'fee': double.parse(fee),
        'periodStart': DateTime.now().toIso8601String(),
        'periodEnd': DateTime.now().add(Duration(days: 30)).toIso8601String(),
      });
      _enrollmentFeeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment settings updated'),
          backgroundColor: SMSTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.tab.capitalize()}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildTabContent(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (widget.tab) {
      case 'gradeLevels':
        return _buildGradeLevelTab();
      case 'subjects':
        return _buildSubjectsTab();
      case 'strands':
        return _buildStrandsTab();
      case 'courses':
        return _buildCoursesTab();
      case 'branches':
        return _buildBranchesTab();
      case 'teachers':
        return _buildTeachersTab();
      case 'rooms':
        return _buildRoomsTab();
      case 'enrollment':
        return _buildEnrollmentTab();
      default:
        return const Center(child: Text('Select a management option'));
    }
  }

  Widget _buildGradeLevelTab() {
    return Column(
      children: [
        TextField(
          controller: _gradeLevelController,
          decoration: const InputDecoration(labelText: 'New Grade Level'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addGradeLevel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Grade Level'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('gradeLevels').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(doc['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _gradeLevelController.text = doc['name'];
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Grade Level'),
                                  content: TextField(
                                    controller: _gradeLevelController,
                                    decoration: const InputDecoration(
                                        labelText: 'Grade Level Name'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateGradeLevel(doc.id, doc['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('gradeLevels')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Grade Level deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    return Column(
      children: [
        DropdownButton<String>(
          hint: const Text('Select Grade Level'),
          value: _selectedGradeLevelForSubject,
          onChanged: (value) {
            setState(() {
              _selectedGradeLevelForSubject = value;
            });
          },
          items: _gradeLevels
              .map((grade) => DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(labelText: 'New Subject'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addSubject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Subject'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('subjects').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(doc['name']),
                      subtitle: Text('Grade: ${doc['gradeLevel']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _subjectController.text = doc['name'];
                              _selectedGradeLevelForSubject = doc['gradeLevel'];
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Subject'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButton<String>(
                                        hint: const Text('Select Grade Level'),
                                        value: _selectedGradeLevelForSubject,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGradeLevelForSubject =
                                                value;
                                          });
                                        },
                                        items: _gradeLevels
                                            .map((grade) => DropdownMenuItem(
                                                  value: grade,
                                                  child: Text(grade),
                                                ))
                                            .toList(),
                                      ),
                                      TextField(
                                        controller: _subjectController,
                                        decoration: const InputDecoration(
                                            labelText: 'Subject Name'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateSubject(doc.id, doc['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('subjects')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Subject deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStrandsTab() {
    return Column(
      children: [
        TextField(
          controller: _strandController,
          decoration: const InputDecoration(labelText: 'New Strand'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _strandDescController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addStrand,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Strand'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('strands').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(doc['name']),
                      subtitle: Text(doc['description'] ?? 'No description'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _strandController.text = doc['name'];
                              _strandDescController.text =
                                  doc['description'] ?? '';
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Strand'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _strandController,
                                        decoration: const InputDecoration(
                                            labelText: 'Strand Name'),
                                      ),
                                      TextField(
                                        controller: _strandDescController,
                                        decoration: const InputDecoration(
                                            labelText: 'Description'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateStrand(doc.id, doc['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('strands')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Strand deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesTab() {
    return Column(
      children: [
        TextField(
          controller: _courseController,
          decoration: const InputDecoration(labelText: 'New Course'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _courseDescController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addCourse,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Course'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(doc['name']),
                      subtitle: Text(doc['description'] ?? 'No description'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _courseController.text = doc['name'];
                              _courseDescController.text =
                                  doc['description'] ?? '';
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Course'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _courseController,
                                        decoration: const InputDecoration(
                                            labelText: 'Course Name'),
                                      ),
                                      TextField(
                                        controller: _courseDescController,
                                        decoration: const InputDecoration(
                                            labelText: 'Description'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateCourse(doc.id, doc['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('courses')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Course deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBranchesTab() {
    return Column(
      children: [
        TextField(
          controller: _branchController,
          decoration: const InputDecoration(labelText: 'New Branch'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addBranch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Branch'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('branches').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(doc['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _branchController.text = doc['name'];
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Branch'),
                                  content: TextField(
                                    controller: _branchController,
                                    decoration: const InputDecoration(
                                        labelText: 'Branch Name'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateBranch(doc.id, doc['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('branches')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Branch deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeachersTab() {
    return Column(
      children: [
        TextField(
          controller: _teacherNameController,
          decoration: const InputDecoration(labelText: 'Teacher Name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _teacherEmailController,
          decoration: const InputDecoration(labelText: 'Teacher Email'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addTeacher,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Teacher'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('teachers').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(doc['name']),
                      subtitle: Text(doc['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _teacherNameController.text = doc['name'];
                              _teacherEmailController.text = doc['email'];
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Teacher'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _teacherNameController,
                                        decoration: const InputDecoration(
                                            labelText: 'Teacher Name'),
                                      ),
                                      TextField(
                                        controller: _teacherEmailController,
                                        decoration: const InputDecoration(
                                            labelText: 'Teacher Email'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateTeacher(doc.id, doc['name']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('teachers')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Teacher deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsTab() {
    return Column(
      children: [
        TextField(
          controller: _roomNumberController,
          decoration: const InputDecoration(labelText: 'Room Number'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _roomCapacityController,
          decoration: const InputDecoration(labelText: 'Room Capacity'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Add Room'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('rooms').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text('Room ${doc['number']}'),
                      subtitle: Text('Capacity: ${doc['capacity']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () {
                              _roomNumberController.text = doc['number'];
                              _roomCapacityController.text =
                                  doc['capacity'].toString();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Room'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _roomNumberController,
                                        decoration: const InputDecoration(
                                            labelText: 'Room Number'),
                                      ),
                                      TextField(
                                        controller: _roomCapacityController,
                                        decoration: const InputDecoration(
                                            labelText: 'Room Capacity'),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _updateRoom(doc.id, doc['number']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore
                                  .collection('rooms')
                                  .doc(doc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Room deleted'),
                                  backgroundColor: SMSTheme.errorColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentTab() {
    return Column(
      children: [
        TextField(
          controller: _enrollmentFeeController,
          decoration: const InputDecoration(labelText: 'Enrollment Fee (₱)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _updateEnrollmentSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Update Enrollment Settings'),
        ),
        const SizedBox(height: 20),
        StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('enrollmentSettings')
              .doc('settings')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            var data = snapshot.data?.data() as Map<String, dynamic>?;
            if (data == null) return const Text('No settings found');
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fee: ₱${data['fee']}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Start: ${data['periodStart']}',
                        style: const TextStyle(fontSize: 16)),
                    Text('End: ${data['periodEnd']}',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
