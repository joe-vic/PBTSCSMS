import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enrollment_form_state.dart';

class EnrollmentService {
  final FirebaseFirestore _firestore;
  
  // Cached data - existing
  List<Map<String, String>>? _cachedBranches;
  
  // Cached data - new additions
  List<Map<String, dynamic>>? _cachedGradeLevels;
  List<Map<String, dynamic>>? _cachedStrands;
  List<Map<String, dynamic>>? _cachedCourses;

  EnrollmentService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    try {
      // Pre-fetch all data to cache them
      await Future.wait([
        _initializeBranches(),
        _initializeGradeLevels(),
        _initializeStrands(),
        _initializeCourses(),
      ]);
    } catch (e) {
      print('Error initializing enrollment service: $e');
      // Initialize empty lists to prevent null errors
      _cachedBranches ??= <Map<String, String>>[];
      _cachedGradeLevels ??= <Map<String, dynamic>>[];
      _cachedStrands ??= <Map<String, dynamic>>[];
      _cachedCourses ??= <Map<String, dynamic>>[];
    }
  }

  // Initialize individual cached data
  Future<void> _initializeBranches() async {
    try {
      _cachedBranches = await getBranches();
    } catch (e) {
      print('Error initializing branches: $e');
      _cachedBranches = <Map<String, String>>[];
    }
  }

  Future<void> _initializeGradeLevels() async {
    try {
      _cachedGradeLevels = await getGradeLevels();
    } catch (e) {
      print('Error initializing grade levels: $e');
      _cachedGradeLevels = <Map<String, dynamic>>[];
    }
  }

  Future<void> _initializeStrands() async {
    try {
      _cachedStrands = await getStrands();
    } catch (e) {
      print('Error initializing strands: $e');
      _cachedStrands = <Map<String, dynamic>>[];
    }
  }

  Future<void> _initializeCourses() async {
    try {
      _cachedCourses = await getCourses();
    } catch (e) {
      print('Error initializing courses: $e');
      _cachedCourses = <Map<String, dynamic>>[];
    }
  }

  // EXISTING METHOD - Updated with null safety
  Future<List<Map<String, String>>> getBranches() async {
    // Return cached branches if available
    if (_cachedBranches != null) {
      return _cachedBranches!;
    }

    try {
      final snapshot = await _firestore.collection('branches').get();
      _cachedBranches = snapshot.docs.map<Map<String, String>>((doc) {
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return <String, String>{
          'name': (data != null && data['name'] != null) ? data['name'].toString() : '',
          'code': (data != null && data['code'] != null) ? data['code'].toString() : '',
        };
      }).toList();
      return _cachedBranches!;
    } catch (e) {
      print('Error fetching branches: $e');
      return <Map<String, String>>[]; // Return empty list on error
    }
  }

  // UPDATED METHOD - Safer getGradeLevels with proper sorting and better debugging
  Future<List<Map<String, dynamic>>> getGradeLevels() async {
    print('🔍 Debug: getGradeLevels called');
    
    // Return cached grade levels if available
    if (_cachedGradeLevels != null) {
      print('✅ Debug: Returning cached grade levels: ${_cachedGradeLevels!.length} items');
      return _cachedGradeLevels!;
    }

    try {
      print('🔍 Debug: Fetching from Firestore...');
      
      QuerySnapshot snapshot;
      bool usedCompositeQuery = false;
      
      try {
        // Try with composite query first (requires index)
        snapshot = await _firestore
            .collection('gradeLevels')
            .where('isActive', isEqualTo: true)
            .orderBy('Sort')
            .get();
        usedCompositeQuery = true;
        print('✅ Debug: Using composite query with Firestore index');
      } catch (indexError) {
        print('⚠️ Debug: Composite index not available, using simple query: $indexError');
        
        // Fallback: Get all active documents without orderBy
        snapshot = await _firestore
            .collection('gradeLevels')
            .where('isActive', isEqualTo: true)
            .get();
        usedCompositeQuery = false;
      }

      print('🔍 Debug: Snapshot received, doc count: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('❌ Debug: No documents found in gradeLevels collection');
        _cachedGradeLevels = <Map<String, dynamic>>[];
        return _cachedGradeLevels!;
      }

      // Use explicit type mapping to avoid type errors
      List<Map<String, dynamic>> gradeLevelsList = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        print('🔍 Debug: Processing doc ${doc.id}: $data');
        
        // Create explicitly typed map
        final Map<String, dynamic> gradeLevel = <String, dynamic>{};
        
        gradeLevel['id'] = doc.id;
        gradeLevel['name'] = (data != null && data['name'] != null) ? data['name'].toString() : '';
        gradeLevel['category'] = (data != null && data['category'] != null) ? data['category'].toString() : '';
        
        // Handle boolean fields safely with null checks
        gradeLevel['hasStrands'] = (data != null && data['hasStrands'] is bool) ? data['hasStrands'] as bool : false;
        gradeLevel['hasCourses'] = (data != null && data['hasCourses'] is bool) ? data['hasCourses'] as bool : false;
        gradeLevel['isActive'] = (data != null && data['isActive'] is bool) ? data['isActive'] as bool : true;
        
        // Handle numeric field safely with null checks
        gradeLevel['sort'] = (data != null && data['Sort'] is int) ? data['Sort'] as int : 
                           (data != null && data['sort'] is int) ? data['sort'] as int : 0;
        
        return gradeLevel;
      }).toList();
      
      // ALWAYS sort in memory to ensure proper ordering
      gradeLevelsList.sort((a, b) {
        final sortA = a['sort'] as int;
        final sortB = b['sort'] as int;
        return sortA.compareTo(sortB);
      });
      
      _cachedGradeLevels = gradeLevelsList;
      
      print('✅ Debug: Processed and sorted ${_cachedGradeLevels!.length} grade levels${usedCompositeQuery ? ' (using Firestore index)' : ' (using memory sort)'}');
      for (final grade in _cachedGradeLevels!) {
        print('  - Sort ${grade['sort']}: ${grade['name']} (hasStrands: ${grade['hasStrands']}, hasCourses: ${grade['hasCourses']})');
      }
      
      return _cachedGradeLevels!;
    } catch (e, stackTrace) {
      print('❌ Debug: Error fetching grade levels: $e');
      print('❌ Debug: Stack trace: $stackTrace');
      print('❌ Debug: Error type: ${e.runtimeType}');
      
      // Return empty list and cache it to avoid repeated failures
      _cachedGradeLevels = <Map<String, dynamic>>[];
      return _cachedGradeLevels!;
    }
  }

  // UPDATED METHOD - Safer getStrands with better type handling
  Future<List<Map<String, dynamic>>> getStrands() async {
    // Return cached strands if available
    if (_cachedStrands != null) {
      return _cachedStrands!;
    }

    try {
      final snapshot = await _firestore
          .collection('strands')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      _cachedStrands = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final Map<String, Object?>? data = doc.data();
        
        // Create explicitly typed map
        final Map<String, dynamic> strand = <String, dynamic>{};
        
        strand['id'] = doc.id;
        strand['name'] = (data != null && data['name'] != null) ? data['name'].toString() : '';
        strand['fullName'] = (data != null && data['fullName'] != null) ? data['fullName'].toString() : '';
        strand['description'] = (data != null && data['description'] != null) ? data['description'].toString() : '';
        strand['order'] = (data != null && data['order'] is int) ? data['order'] as int : 0;
        strand['isActive'] = (data != null && data['isActive'] is bool) ? data['isActive'] as bool : true;
        
        return strand;
      }).toList();
      
      return _cachedStrands!;
    } catch (e) {
      print('Error fetching strands: $e');
      _cachedStrands = <Map<String, dynamic>>[];
      return _cachedStrands!;
    }
  }

  // UPDATED METHOD - Safer getCourses with better type handling
  Future<List<Map<String, dynamic>>> getCourses() async {
    // Return cached courses if available
    if (_cachedCourses != null) {
      return _cachedCourses!;
    }

    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      _cachedCourses = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final Map<String, Object?>? data = doc.data();
        
        // Create explicitly typed map
        final Map<String, dynamic> course = <String, dynamic>{};
        
        course['id'] = doc.id;
        course['name'] = (data != null && data['name'] != null) ? data['name'].toString() : '';
        course['fullName'] = (data != null && data['fullName'] != null) ? data['fullName'].toString() : '';
        course['description'] = (data != null && data['description'] != null) ? data['description'].toString() : '';
        course['order'] = (data != null && data['order'] is int) ? data['order'] as int : 0;
        course['isActive'] = (data != null && data['isActive'] is bool) ? data['isActive'] as bool : true;
        
        return course;
      }).toList();
      
      return _cachedCourses!;
    } catch (e) {
      print('Error fetching courses: $e');
      _cachedCourses = <Map<String, dynamic>>[];
      return _cachedCourses!;
    }
  }

  // NEW METHOD - Clear all caches (useful for admin updates)
  void clearCache() {
    _cachedBranches = null;
    _cachedGradeLevels = null;
    _cachedStrands = null;
    _cachedCourses = null;
    print('🔄 Debug: All caches cleared');
  }

  // NEW METHOD - Force refresh all data (for testing)
  Future<void> forceRefreshAll() async {
    print('🔄 Debug: Force refreshing all data...');
    clearCache();
    await initialize();
  }

  // NEW METHOD - Refresh specific cache
  Future<void> refreshCache({
    bool branches = false,
    bool gradeLevels = false,
    bool strands = false,
    bool courses = false,
  }) async {
    try {
      if (branches) {
        _cachedBranches = null;
        await getBranches();
      }
      if (gradeLevels) {
        _cachedGradeLevels = null;
        await getGradeLevels();
      }
      if (strands) {
        _cachedStrands = null;
        await getStrands();
      }
      if (courses) {
        _cachedCourses = null;
        await getCourses();
      }
    } catch (e) {
      print('Error refreshing cache: $e');
    }
  }

  // EXISTING METHOD - Keep exactly as is
  Future<String> _getBranchCode(String? branchName) async {
    if (branchName == null) return 'MAC'; // Default to Macamot if null

    try {
      final snapshot = await _firestore
          .collection('branches')
          .where('name', isEqualTo: branchName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('code') as String;
      }
      
      return 'MAC'; // Default to Macamot if branch not found
    } catch (e) {
      print('Error getting branch code: $e');
      return 'MAC'; // Default to Macamot on error
    }
  }

  // EXISTING METHOD - Keep exactly as is
  String _getGradeCategoryCode(String? gradeLevel) {
    if (gradeLevel == null) return '01'; // Default to preschool if null

    final grade = gradeLevel.toLowerCase();
    
    // Pre-school (01)
    if (grade.contains('nursery') || 
        grade.contains('kinder') || 
        grade.contains('kindergarten')) {
      return '01';
    }
    
    // Elementary (02)
    if (grade.contains('grade') && 
        RegExp(r'grade [1-6]|grade1|grade2|grade3|grade4|grade5|grade6').hasMatch(grade)) {
      return '02';
    }
    
    // Junior High School (03)
    if (grade.contains('grade') && 
        RegExp(r'grade [7-9]|grade10|grade7|grade8|grade9').hasMatch(grade)) {
      return '03';
    }
    
    // Senior High School (04)
    if (grade.contains('grade') && 
        RegExp(r'grade 1[1-2]|grade11|grade12').hasMatch(grade)) {
      return '04';
    }
    
    // College (05)
    if (grade.contains('college') || 
        grade.contains('year') || 
        grade.contains('freshman') || 
        grade.contains('sophomore') || 
        grade.contains('junior') || 
        grade.contains('senior')) {
      return '05';
    }

    return '01'; // Default to preschool if no match
  }

  // EXISTING METHOD - Keep exactly as is
  Future<String> _generateStudentId(EnrollmentFormState formState) async {
    final now = DateTime.now();
    final year = now.year.toString();
    final branchCode = await _getBranchCode(formState.branch);
    final gradeCategory = _getGradeCategoryCode(formState.gradeLevel);
    
    // Get the last student ID for the current year and grade category
    final snapshot = await _firestore
        .collection('students')
        .where('studentId', isGreaterThanOrEqualTo: 'PBTSCI-$branchCode-$year-$gradeCategory')
        .where('studentId', isLessThan: 'PBTSCI-$branchCode-$year-$gradeCategory-9999')
        .orderBy('studentId', descending: true)
        .limit(1)
        .get();

    int sequence = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.get('studentId') as String;
      final lastSequence = lastId.split('-').last;
      sequence = int.parse(lastSequence) + 1;
    }

    return 'PBTSCI-$branchCode-$year-$gradeCategory-${sequence.toString().padLeft(4, '0')}';
  }

  // EXISTING METHOD - Keep exactly as is
  Future<String> submitEnrollment(EnrollmentFormState formState) async {
    try {
      final studentId = await _generateStudentId(formState);
      final academicYear = formState.academicYear;
      final now = DateTime.now();
      final branchCode = await _getBranchCode(formState.branch);

      // Create student document
      final studentData = {
        'studentId': studentId,
        'personalInfo': await _createPersonalInfo(formState),
        'enrollmentInfo': {
          'status': 'enrolled',
          'school': 'Pines Best Tech School',
          'dateEnrolled': now,
          'branch': formState.branch,
          'branchCode': branchCode,
          'gradeCategory': _getGradeCategoryCode(formState.gradeLevel),
        },
        'billing': {
          academicYear: await _createBillingInfo(formState),
        },
        'payments': {
          'payment${now.millisecondsSinceEpoch}': await _createInitialPayment(formState, academicYear),
        },
        'parentInfo': await _createParentInfo(formState),
        'createdAt': now,
        'updatedAt': now,
      };

      // Save to Firestore
      await _firestore.collection('students').doc(studentId).set(studentData);
      
      return studentId;
    } catch (e) {
      throw Exception('Failed to submit enrollment: $e');
    }
  }

  // EXISTING METHODS - Keep exactly as is
  Future<Map<String, dynamic>> _createPersonalInfo(EnrollmentFormState state) async {
    return {
      'firstName': state.firstName,
      'lastName': state.lastName,
      'middleName': state.middleName,
      'dateOfBirth': state.dateOfBirth,
      'gender': state.gender,
      'placeOfBirth': state.placeOfBirth,
      'religion': state.religion,
      'address': {
        'street': state.streetAddress,
        'province': state.province,
        'municipality': state.municipality,
        'barangay': state.barangay,
      },
      'height': state.height,
      'weight': state.weight,
      'lastSchool': {
        'name': state.lastSchoolName,
        'address': state.lastSchoolAddress,
      },
    };
  }

  Future<Map<String, dynamic>> _createParentInfo(EnrollmentFormState state) async {
    return {
      'mother': {
        'lastName': state.motherLastName,
        'firstName': state.motherFirstName,
        'middleName': state.motherMiddleName,
        'occupation': state.motherOccupation,
        'contact': state.motherContact,
        'facebook': state.motherFacebook,
      },
      'father': {
        'lastName': state.fatherLastName,
        'firstName': state.fatherFirstName,
        'middleName': state.fatherMiddleName,
        'occupation': state.fatherOccupation,
        'contact': state.fatherContact,
        'facebook': state.fatherFacebook,
      },
      'primary': {
        'lastName': state.primaryLastName,
        'firstName': state.primaryFirstName,
        'middleName': state.primaryMiddleName,
        'occupation': state.primaryOccupation,
        'contact': state.primaryContact,
        'facebook': state.primaryFacebook,
        'relationship': state.primaryRelationship,
      },
    };
  }

  Future<Map<String, dynamic>> _createBillingInfo(EnrollmentFormState state) async {
    final now = DateTime.now();
    Map<String, dynamic> billingData;

    final isCollege = state.gradeLevel != null && 
                     (state.gradeLevel!.toLowerCase().contains('college') ||
                      state.gradeLevel!.toLowerCase().contains('year'));

    if (!isCollege) {
      // For basic education (K-12)
      billingData = {
        'grade': state.gradeLevel,
        'yearLevel': state.gradeLevel,
        'tuitionFee': state.totalAmountDue,
        'idFee': state.idFee,
        'systemFee': state.systemFee,
        'totalPaid': state.totalAmountPaid,
        'balance': state.balanceRemaining,
        'timestamp': now,
      };
    } else {
      // For college
      billingData = {
        'semesters': {
          state.semesterType: {
            'grade': state.collegeYearLevel,
            'yearLevel': _getCollegeYearLevel(state.collegeYearLevel),
            'tuitionFee': state.totalAmountDue,
            'idFee': state.idFee,
            'systemFee': state.systemFee,
            'totalPaid': state.totalAmountPaid,
            'balance': state.balanceRemaining,
            'timestamp': now,
          }
        }
      };
    }

    return billingData;
  }

  String _getCollegeYearLevel(String? yearLevel) {
    switch (yearLevel?.toLowerCase()) {
      case '1st year':
        return 'Freshman';
      case '2nd year':
        return 'Sophomore';
      case '3rd year':
        return 'Junior';
      case '4th year':
        return 'Senior';
      default:
        return yearLevel ?? 'Freshman';
    }
  }

  Future<Map<String, dynamic>> _createInitialPayment(EnrollmentFormState state, String academicYear) async {
    final now = DateTime.now();
    final isCollege = state.gradeLevel != null && 
                     (state.gradeLevel!.toLowerCase().contains('college') ||
                      state.gradeLevel!.toLowerCase().contains('year'));

    return {
      'schoolYear': academicYear,
      'semester': isCollege ? state.semesterType : null,
      'amount': state.initialPaymentAmount,
      'type': state.paymentMethod.toLowerCase(),
      'date': now,
      'officialReceipt': 'OR-${now.year}-${now.millisecondsSinceEpoch}',
    };
  }
}