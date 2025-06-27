import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/enrollment.dart';
import '../../models/student.dart';
import '../../services/firestore_service.dart';
import '../../models/location_data.dart';

// Core enrollment type enum
enum EnrollmentType {
  student,    // Student self-enrollment
  parent,     // Parent enrolling student
}

// Form state management class
class EnrollmentFormState {
  // Student Information
  String lastName = '';
  String firstName = '';
  String middleName = '';
  String streetAddress = '';
  String? province = 'RIZAL';
  String? municipality = 'BINANGONAN';
  String? barangay = '';
  String gender = 'Male';
  DateTime? dateOfBirth;
  String placeOfBirth = '';
  String? religion;
  String? lastSchoolName;
  String? lastSchoolAddress;
  String? gradeLevel;
  String? strand;

  // Parent/Guardian Information
  String? guardianLastName;
  String? guardianFirstName;
  String? guardianMiddleName;
  String? guardianOccupation;
  String? guardianContact;
  String relationship = 'Parent';

  // Enrollment Details
  String academicYear = '';
  String enrollmentStatus = 'pending';
}

class StudentEnrollmentScreen extends StatefulWidget {
  final Enrollment? enrollment;

  const StudentEnrollmentScreen({
    Key? key,
    this.enrollment,
  }) : super(key: key);

  @override
  _StudentEnrollmentScreenState createState() => _StudentEnrollmentScreenState();
}

class _StudentEnrollmentScreenState extends State<StudentEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late EnrollmentFormState _formState;
  bool _isLoading = false;
  int _currentStep = 0;

  // Controllers
  late TextEditingController _studentFirstNameController;
  late TextEditingController _studentLastNameController;
  late TextEditingController _studentMiddleNameController;
  late TextEditingController _placeOfBirthController;
  late TextEditingController _religionController;
  late TextEditingController _guardianLastNameController;
  late TextEditingController _guardianFirstNameController;
  late TextEditingController _guardianMiddleNameController;
  late TextEditingController _guardianOccupationController;
  late TextEditingController _guardianContactController;
  final _dateOfBirthController = TextEditingController();

  // Location Data
  late LocationData _locationData;
  List<String> _provinces = ['RIZAL'];
  List<String> _municipalities = [];
  List<String> _barangays = [];
  List<String> _gradeLevels = [
    'Nursery',
    'Kinder 1',
    'Kinder 2',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];
  List<String> _strands = [
    'STEM',
    'ABM',
    'HUMSS',
    'GAS',
    'TVL',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _formState = EnrollmentFormState();
    _initializeControllers();
    _loadLocationData();
    _setCurrentAcademicYear();
  }

  void _initializeControllers() {
    _studentFirstNameController = TextEditingController();
    _studentLastNameController = TextEditingController();
    _studentMiddleNameController = TextEditingController();
    _placeOfBirthController = TextEditingController();
    _religionController = TextEditingController();
    _guardianLastNameController = TextEditingController();
    _guardianFirstNameController = TextEditingController();
    _guardianMiddleNameController = TextEditingController();
    _guardianOccupationController = TextEditingController();
    _guardianContactController = TextEditingController();
  }

  Future<void> _loadLocationData() async {
    // TODO: Implement location data loading
    setState(() {
      _municipalities = ['BINANGONAN'];
      _barangays = ['SAMPLE BARANGAY']; // Replace with actual data
    });
  }

  void _setCurrentAcademicYear() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    // Academic year is from June to May
    _formState.academicYear = month >= 6 
        ? '$year-${year + 1}'
        : '${year - 1}-$year';
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Student Information'),
        content: _buildStudentInfoForm(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Address Information'),
        content: _buildAddressForm(),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Guardian Information'),
        content: _buildGuardianForm(),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('Academic Information'),
        content: _buildAcademicForm(),
        isActive: _currentStep >= 3,
      ),
    ];
  }

  Widget _buildStudentInfoForm() {
    return Column(
      children: [
        TextFormField(
          controller: _studentLastNameController,
          decoration: const InputDecoration(labelText: 'Last Name *'),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: (value) => _formState.lastName = value,
        ),
        TextFormField(
          controller: _studentFirstNameController,
          decoration: const InputDecoration(labelText: 'First Name *'),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: (value) => _formState.firstName = value,
        ),
        TextFormField(
          controller: _studentMiddleNameController,
          decoration: const InputDecoration(labelText: 'Middle Name'),
          onChanged: (value) => _formState.middleName = value,
        ),
        DropdownButtonFormField<String>(
          value: _formState.gender,
          decoration: const InputDecoration(labelText: 'Gender *'),
          items: _genders.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _formState.gender = value ?? 'Male';
            });
          },
        ),
        TextFormField(
          controller: _dateOfBirthController,
          decoration: const InputDecoration(
            labelText: 'Date of Birth *',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _formState.dateOfBirth = date;
                _dateOfBirthController.text = DateFormat('MM/dd/yyyy').format(date);
              });
            }
          },
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
        DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: true,
          ),
          items: _provinces,
          selectedItem: _formState.province,
          onChanged: (value) {
            setState(() {
              _formState.province = value;
              // TODO: Update municipalities based on province
            });
          },
        ),
        DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: true,
          ),
          items: _municipalities,
          selectedItem: _formState.municipality,
          onChanged: (value) {
            setState(() {
              _formState.municipality = value;
              // TODO: Update barangays based on municipality
            });
          },
        ),
        DropdownSearch<String>(
          popupProps: PopupProps.menu(
            showSelectedItems: true,
            showSearchBox: true,
          ),
          items: _barangays,
          selectedItem: _formState.barangay,
          onChanged: (value) {
            setState(() {
              _formState.barangay = value;
            });
          },
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Street Address *'),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: (value) => _formState.streetAddress = value,
        ),
      ],
    );
  }

  Widget _buildGuardianForm() {
    return Column(
      children: [
        TextFormField(
          controller: _guardianLastNameController,
          decoration: const InputDecoration(labelText: 'Guardian Last Name *'),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: (value) => _formState.guardianLastName = value,
        ),
        TextFormField(
          controller: _guardianFirstNameController,
          decoration: const InputDecoration(labelText: 'Guardian First Name *'),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: (value) => _formState.guardianFirstName = value,
        ),
        TextFormField(
          controller: _guardianMiddleNameController,
          decoration: const InputDecoration(labelText: 'Guardian Middle Name'),
          onChanged: (value) => _formState.guardianMiddleName = value,
        ),
        TextFormField(
          controller: _guardianOccupationController,
          decoration: const InputDecoration(labelText: 'Guardian Occupation'),
          onChanged: (value) => _formState.guardianOccupation = value,
        ),
        TextFormField(
          controller: _guardianContactController,
          decoration: const InputDecoration(labelText: 'Guardian Contact Number *'),
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onChanged: (value) => _formState.guardianContact = value,
        ),
      ],
    );
  }

  Widget _buildAcademicForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _formState.gradeLevel,
          decoration: const InputDecoration(labelText: 'Grade Level *'),
          items: _gradeLevels.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _formState.gradeLevel = value;
            });
          },
          validator: (value) => value == null ? 'Required' : null,
        ),
        if (_formState.gradeLevel == 'Grade 11' || _formState.gradeLevel == 'Grade 12')
          DropdownButtonFormField<String>(
            value: _formState.strand,
            decoration: const InputDecoration(labelText: 'Strand *'),
            items: _strands.map((strand) {
              return DropdownMenuItem(
                value: strand,
                child: Text(strand),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formState.strand = value;
              });
            },
            validator: (value) => value == null ? 'Required' : null,
          ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Last School Attended'),
          onChanged: (value) => _formState.lastSchoolName = value,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Last School Address'),
          onChanged: (value) => _formState.lastSchoolAddress = value,
        ),
      ],
    );
  }

  Future<void> _submitEnrollment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final enrollment = {
        'studentInfo': {
          'lastName': _formState.lastName,
          'firstName': _formState.firstName,
          'middleName': _formState.middleName,
          'gender': _formState.gender,
          'dateOfBirth': _formState.dateOfBirth?.toIso8601String(),
          'placeOfBirth': _formState.placeOfBirth,
          'religion': _formState.religion,
        },
        'address': {
          'street': _formState.streetAddress,
          'barangay': _formState.barangay,
          'municipality': _formState.municipality,
          'province': _formState.province,
        },
        'guardianInfo': {
          'lastName': _formState.guardianLastName,
          'firstName': _formState.guardianFirstName,
          'middleName': _formState.guardianMiddleName,
          'occupation': _formState.guardianOccupation,
          'contactNumber': _formState.guardianContact,
          'relationship': _formState.relationship,
        },
        'academicInfo': {
          'gradeLevel': _formState.gradeLevel,
          'strand': _formState.strand,
          'lastSchool': _formState.lastSchoolName,
          'lastSchoolAddress': _formState.lastSchoolAddress,
        },
        'enrollmentDetails': {
          'academicYear': _formState.academicYear,
          'status': _formState.enrollmentStatus,
          'dateSubmitted': DateTime.now().toIso8601String(),
        },
      };

      // TODO: Save to Firestore
      await FirebaseFirestore.instance.collection('enrollments').add(enrollment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to a success screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting enrollment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Enrollment'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < _buildSteps().length - 1) {
              setState(() {
                _currentStep++;
              });
            } else {
              _submitEnrollment();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            }
          },
          steps: _buildSteps(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _studentFirstNameController.dispose();
    _studentLastNameController.dispose();
    _studentMiddleNameController.dispose();
    _placeOfBirthController.dispose();
    _religionController.dispose();
    _guardianLastNameController.dispose();
    _guardianFirstNameController.dispose();
    _guardianMiddleNameController.dispose();
    _guardianOccupationController.dispose();
    _guardianContactController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }
}