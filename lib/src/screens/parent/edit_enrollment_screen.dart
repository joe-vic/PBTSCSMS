import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/enrollment.dart';
import '../../models/student.dart'; // Add this import for the Student model
import '../../services/firestore_service.dart';

class EditEnrollmentScreen extends StatefulWidget {
  final Enrollment enrollment;

  const EditEnrollmentScreen({required this.enrollment, Key? key}) : super(key: key);

  @override
  _EditEnrollmentScreenState createState() => _EditEnrollmentScreenState();
}

class _EditEnrollmentScreenState extends State<EditEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  // Student name fields
  final _studentLastNameController = TextEditingController();
  final _studentFirstNameController = TextEditingController();
  final _studentMiddleNameController = TextEditingController();

  // Primary contact (Guardian) fields
  final _primaryLastNameController = TextEditingController();
  final _primaryFirstNameController = TextEditingController();
  final _primaryMiddleNameController = TextEditingController();
  final _primaryContactController = TextEditingController();
  final _primaryFacebookController = TextEditingController();

  // Additional contacts
  List<Map<String, dynamic>> _additionalContacts = [];
  final List<String> _relationships = [
    'Father',
    'Mother',
    'Sibling',
    'Grandparent',
    'Other'
  ];

  String? _selectedGradeLevel;
  String? _selectedBranch;
  String? _selectedStrand;
  String? _selectedCourse;
  bool _isLoading = false;

  List<String> _gradeLevels = [];
  List<Map<String, String>> _branches = [];
  List<Map<String, String>> _filteredBranches = [];
  List<String> _strands = [];
  List<String> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      QuerySnapshot gradeLevelsSnapshot =
          await FirebaseFirestore.instance.collection('gradeLevels').get();
      QuerySnapshot branchesSnapshot =
          await FirebaseFirestore.instance.collection('branches').get();
      QuerySnapshot strandsSnapshot =
          await FirebaseFirestore.instance.collection('strands').get();
      QuerySnapshot coursesSnapshot =
          await FirebaseFirestore.instance.collection('courses').get();

      setState(() {
        _gradeLevels = gradeLevelsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
        _branches = branchesSnapshot.docs
            .map((doc) => {
                  'name': doc['name'] as String,
                  'code': doc['code'] as String,
                })
            .toList();
        _filteredBranches = _branches;
        _strands = strandsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
        _courses = coursesSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();

        // Initialize fields after data is fetched
        _initializeFields();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void _initializeFields() {
    _studentLastNameController.text = widget.enrollment.studentInfo['lastName'] ?? '';
    _studentFirstNameController.text = widget.enrollment.studentInfo['firstName'] ?? '';
    _studentMiddleNameController.text = widget.enrollment.studentInfo['middleName'] ?? '';
    _primaryLastNameController.text = widget.enrollment.parentInfo['lastName'] ?? '';
    _primaryFirstNameController.text = widget.enrollment.parentInfo['firstName'] ?? '';
    _primaryMiddleNameController.text = widget.enrollment.parentInfo['middleName'] ?? '';
    _primaryContactController.text = widget.enrollment.parentInfo['contact'] ?? '';
    _primaryFacebookController.text = widget.enrollment.parentInfo['facebook'] ?? '';
    _selectedGradeLevel = widget.enrollment.studentInfo['gradeLevel'];
    _selectedStrand = widget.enrollment.studentInfo['strand'];
    _selectedCourse = widget.enrollment.studentInfo['course'];

    if (_branches.isNotEmpty) {
      _selectedBranch = widget.enrollment.studentInfo['branch'] ?? _filteredBranches[0]['name'];
      _updateFilteredBranches();
    }

    // Initialize additional contacts
    _additionalContacts = (widget.enrollment.additionalContacts ?? []).map((contact) {
      return {
        'relationship': contact['relationship'] ?? _relationships[0],
        'lastName': TextEditingController(text: contact['lastName'] ?? ''),
        'firstName': TextEditingController(text: contact['firstName'] ?? ''),
        'middleName': TextEditingController(text: contact['middleName'] ?? ''),
        'contact': TextEditingController(text: contact['contact'] ?? ''),
        'facebook': TextEditingController(text: contact['facebook'] ?? ''),
      };
    }).toList();
  }

  String _toProperCase(String input) {
    if (input.isEmpty) return input;
    return input
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  bool _isValidPhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^(?:\+63|0)\d{10}$');
    return phoneRegex.hasMatch(phone);
  }

  void _updateFilteredBranches() {
    if (_selectedGradeLevel == 'Grade 11' ||
        _selectedGradeLevel == 'Grade 12' ||
        _selectedGradeLevel == 'College') {
      setState(() {
        _filteredBranches = _branches
            .where((branch) => branch['name'] == 'Macamot')
            .toList();
        _selectedBranch = _filteredBranches.isNotEmpty
            ? _filteredBranches[0]['name']
            : null;
      });
    } else {
      setState(() {
        _filteredBranches = _branches;
        if (!_filteredBranches.any((branch) => branch['name'] == _selectedBranch)) {
          _selectedBranch = _filteredBranches.isNotEmpty
              ? _filteredBranches[0]['name']
              : null;
        }
      });
    }
  }

  void _addAdditionalContact() {
    setState(() {
      _additionalContacts.add({
        'relationship': _relationships[0],
        'lastName': TextEditingController(),
        'firstName': TextEditingController(),
        'middleName': TextEditingController(),
        'contact': TextEditingController(),
        'facebook': TextEditingController(),
      });
    });
  }

  void _removeAdditionalContact(int index) {
    setState(() {
      _additionalContacts.removeAt(index);
    });
  }

  Future<void> _updateEnrollment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the existing student data from Firestore
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.enrollment.studentId)
          .get();

      if (!studentDoc.exists) {
        throw Exception('Student not found');
      }

      final existingStudent = Student.fromJson(studentDoc.data()!); // Changed fromMap to fromJson

      // Update studentInfo
      final studentInfo = {
        'lastName': _toProperCase(_studentLastNameController.text),
        'firstName': _toProperCase(_studentFirstNameController.text),
        'middleName': _toProperCase(_studentMiddleNameController.text),
        'gradeLevel': _selectedGradeLevel!,
        'branch': _selectedBranch!,
      };
      if (_selectedGradeLevel == 'Grade 11' || _selectedGradeLevel == 'Grade 12') {
        studentInfo['strand'] = _selectedStrand ?? '';
        studentInfo['course'] = '';
      } else if (_selectedGradeLevel == 'College') {
        studentInfo['strand'] = '';
        studentInfo['course'] = _selectedCourse ?? '';
      } else {
        studentInfo['strand'] = '';
        studentInfo['course'] = '';
      }

      // Update parentInfo
      final parentInfo = {
        'lastName': _toProperCase(_primaryLastNameController.text),
        'firstName': _toProperCase(_primaryFirstNameController.text),
        'middleName': _toProperCase(_primaryMiddleNameController.text),
        'contact': _primaryContactController.text.trim(),
        'facebook': _primaryFacebookController.text.trim(),
      };

      // Update additional contacts
      final additionalContacts = _additionalContacts.map((contact) {
        return {
          'relationship': contact['relationship'],
          'lastName': _toProperCase(contact['lastName'].text),
          'firstName': _toProperCase(contact['firstName'].text),
          'middleName': _toProperCase(contact['middleName'].text),
          'contact': contact['contact'].text.trim(),
          'facebook': contact['facebook'].text.trim(),
        };
      }).toList();

      // Update the Student record
      final student = Student(
        id: widget.enrollment.studentId!,
        lastName: studentInfo['lastName'] as String,
        firstName: studentInfo['firstName'] as String,
        middleName: studentInfo['middleName'] as String,
        gradeLevel: studentInfo['gradeLevel'] as String,
        strand: studentInfo['strand'] as String?,
        course: studentInfo['course'] as String?,
        parentId: widget.enrollment.parentId,
        age: existingStudent.age,
        gender: existingStudent.gender,
        address: existingStudent.address,
        contactNumber: existingStudent.contactNumber,
        dateOfBirth: existingStudent.dateOfBirth,
        placeOfBirth: existingStudent.placeOfBirth,
        religion: existingStudent.religion,
        height: existingStudent.height,
        weight: existingStudent.weight,
        guardianInfo: existingStudent.guardianInfo,
        fatherInfo: existingStudent.fatherInfo,
        motherInfo: existingStudent.motherInfo,
        lastSchoolName: existingStudent.lastSchoolName,
        lastSchoolAddress: existingStudent.lastSchoolAddress,
      );

      await Provider.of<FirestoreService>(context, listen: false).updateStudent(student);

      // Update the Enrollment record
      final updatedEnrollment = Enrollment(
        enrollmentId: widget.enrollment.enrollmentId,
        studentId: widget.enrollment.studentId,
        studentInfo: studentInfo,
        parentInfo: parentInfo,
        additionalContacts: additionalContacts,
        parentId: widget.enrollment.parentId,
        status: widget.enrollment.status,
        paymentStatus: widget.enrollment.paymentStatus,
        createdAt: widget.enrollment.createdAt,
        updatedAt: DateTime.now(),
        academicYear: widget.enrollment.academicYear,
        preEnrollmentDate: widget.enrollment.preEnrollmentDate,
        officialEnrollmentDate: widget.enrollment.officialEnrollmentDate,
      );

      await Provider.of<FirestoreService>(context, listen: false)
          .updateEnrollment(updatedEnrollment);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _studentLastNameController.dispose();
    _studentFirstNameController.dispose();
    _studentMiddleNameController.dispose();
    _primaryLastNameController.dispose();
    _primaryFirstNameController.dispose();
    _primaryMiddleNameController.dispose();
    _primaryContactController.dispose();
    _primaryFacebookController.dispose();
    for (var contact in _additionalContacts) {
      contact['lastName'].dispose();
      contact['firstName'].dispose();
      contact['middleName'].dispose();
      contact['contact'].dispose();
      contact['facebook'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Enrollment'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Enrollment Details',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update the details below.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Enrollment ID',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.confirmation_number, color: Colors.blueAccent),
                    ),
                    child: Text(
                      widget.enrollment.enrollmentId,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Student Information
                            const Text(
                              'Student Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _studentLastNameController,
                              decoration: InputDecoration(
                                labelText: 'Student Last Name *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the student\'s last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _studentFirstNameController,
                              decoration: InputDecoration(
                                labelText: 'Student First Name *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the student\'s first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _studentMiddleNameController,
                              decoration: InputDecoration(
                                labelText: 'Student Middle Name',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedGradeLevel,
                              decoration: InputDecoration(
                                labelText: 'Grade Level *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.school, color: Colors.blueAccent),
                              ),
                              items: _gradeLevels.map((gradeLevel) {
                                return DropdownMenuItem<String>(
                                  value: gradeLevel,
                                  child: Text(gradeLevel),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGradeLevel = value;
                                  _selectedStrand = null;
                                  _selectedCourse = null;
                                  _updateFilteredBranches();
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a grade level';
                                }
                                return null;
                              },
                            ),
                            if (_selectedGradeLevel == 'Grade 11' ||
                                _selectedGradeLevel == 'Grade 12') ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedStrand,
                                decoration: InputDecoration(
                                  labelText: 'Strand *',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.blueAccent),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.category, color: Colors.blueAccent),
                                ),
                                items: _strands.map((strand) {
                                  return DropdownMenuItem<String>(
                                    value: strand,
                                    child: Text(strand),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStrand = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a strand for SHS';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (_selectedGradeLevel == 'College') ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedCourse,
                                decoration: InputDecoration(
                                  labelText: 'Course *',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.blueAccent),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.book, color: Colors.blueAccent),
                                ),
                                items: _courses.map((course) {
                                  return DropdownMenuItem<String>(
                                    value: course,
                                    child: Text(course),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCourse = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a course for College';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            _filteredBranches.isEmpty
                                ? const Text(
                                    'No branches available',
                                    style: TextStyle(color: Colors.red),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: _selectedBranch,
                                    decoration: InputDecoration(
                                      labelText: 'Branch *',
                                      labelStyle: const TextStyle(color: Colors.grey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.blueAccent),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                                    ),
                                    items: _filteredBranches.map((branch) {
                                      return DropdownMenuItem<String>(
                                        value: branch['name'],
                                        child: Text(branch['name']!),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedBranch = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a branch';
                                      }
                                      return null;
                                    },
                                  ),
                            const SizedBox(height: 24),
                            // Primary Contact/Guardian Information
                            const Text(
                              'Primary Contact/Guardian Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please provide the details of the person responsible for the student (e.g., a parent or legal guardian).',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _primaryLastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _primaryFirstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _primaryMiddleNameController,
                              decoration: InputDecoration(
                                labelText: 'Middle Name',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _primaryContactController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Contact (e.g., +639123456789) *',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the contact number';
                                }
                                if (!_isValidPhoneNumber(value)) {
                                  return 'Please enter a valid phone number (e.g., +639123456789)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _primaryFacebookController,
                              decoration: InputDecoration(
                                labelText: 'Facebook Address (Optional)',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.facebook, color: Colors.blueAccent),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Additional Contacts
                            const Text(
                              'Additional Contacts (Optional)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add other contacts related to the student, such as parents or siblings, if applicable.',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ..._additionalContacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Contact ${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                            onPressed: () => _removeAdditionalContact(index),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: contact['relationship'],
                                        decoration: InputDecoration(
                                          labelText: 'Relationship *',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(Icons.family_restroom, color: Colors.blueAccent),
                                        ),
                                        items: _relationships.map((relationship) {
                                          return DropdownMenuItem<String>(
                                            value: relationship,
                                            child: Text(relationship),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            contact['relationship'] = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Please select a relationship';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: contact['lastName'],
                                        decoration: InputDecoration(
                                          labelText: 'Last Name *',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the last name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: contact['firstName'],
                                        decoration: InputDecoration(
                                          labelText: 'First Name *',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the first name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: contact['middleName'],
                                        decoration: InputDecoration(
                                          labelText: 'Middle Name',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: contact['contact'],
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(12),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: 'Contact (e.g., +639123456789) *',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the contact number';
                                          }
                                          if (!_isValidPhoneNumber(value)) {
                                            return 'Please enter a valid phone number (e.g., +639123456789)';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: contact['facebook'],
                                        decoration: InputDecoration(
                                          labelText: 'Facebook Address (Optional)',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Colors.blueAccent),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: const Icon(Icons.facebook, color: Colors.blueAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addAdditionalContact,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Another Contact'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Status',
                                labelStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.info, color: Colors.blueAccent),
                              ),
                              child: Text(
                                _toProperCase(widget.enrollment.status),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _updateEnrollment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Update Enrollment',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}