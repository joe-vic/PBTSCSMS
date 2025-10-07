import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enrollment_form_state.dart';
import 'billing_service.dart'; // NEW: Import billing service

class EnrollmentService {
  final FirebaseFirestore _firestore;

  // Cached data - existing
  List<Map<String, String>>? _cachedBranches;

  // Cached data - new additions
  List<Map<String, dynamic>>? _cachedGradeLevels;
  List<Map<String, dynamic>>? _cachedStrands;
  List<Map<String, dynamic>>? _cachedCourses;

  // NEW: Add billing service
  final BillingService _billingService;

  double? _tuitionFee; // NEW: Tuition fee cache

  EnrollmentService({
    FirebaseFirestore? firestore,
    BillingService? billingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _billingService =
            billingService ?? BillingService(firestore: firestore);

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
          'name': (data != null && data['name'] != null)
              ? data['name'].toString()
              : '',
          'code': (data != null && data['code'] != null)
              ? data['code'].toString()
              : '',
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
      print(
          '✅ Debug: Returning cached grade levels: ${_cachedGradeLevels!.length} items');
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
        print(
            '⚠️ Debug: Composite index not available, using simple query: $indexError');

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
      List<Map<String, dynamic>> gradeLevelsList =
          snapshot.docs.map<Map<String, dynamic>>((doc) {
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        print('🔍 Debug: Processing doc ${doc.id}: $data');

        // Create explicitly typed map
        final Map<String, dynamic> gradeLevel = <String, dynamic>{};

        gradeLevel['id'] = doc.id;
        gradeLevel['name'] = (data != null && data['name'] != null)
            ? data['name'].toString()
            : '';
        gradeLevel['category'] = (data != null && data['category'] != null)
            ? data['category'].toString()
            : '';

        // Handle boolean fields safely with null checks
        gradeLevel['hasStrands'] = (data != null && data['hasStrands'] is bool)
            ? data['hasStrands'] as bool
            : false;
        gradeLevel['hasCourses'] = (data != null && data['hasCourses'] is bool)
            ? data['hasCourses'] as bool
            : false;
        gradeLevel['isActive'] = (data != null && data['isActive'] is bool)
            ? data['isActive'] as bool
            : true;

        // Handle numeric field safely with null checks
        gradeLevel['sort'] = (data != null && data['Sort'] is int)
            ? data['Sort'] as int
            : (data != null && data['sort'] is int)
                ? data['sort'] as int
                : 0;

        return gradeLevel;
      }).toList();

      // ALWAYS sort in memory to ensure proper ordering
      gradeLevelsList.sort((a, b) {
        final sortA = a['sort'] as int;
        final sortB = b['sort'] as int;
        return sortA.compareTo(sortB);
      });

      _cachedGradeLevels = gradeLevelsList;

      print(
          '✅ Debug: Processed and sorted ${_cachedGradeLevels!.length} grade levels${usedCompositeQuery ? ' (using Firestore index)' : ' (using memory sort)'}');
      for (final grade in _cachedGradeLevels!) {
        print(
            '  - Sort ${grade['sort']}: ${grade['name']} (hasStrands: ${grade['hasStrands']}, hasCourses: ${grade['hasCourses']})');
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
        strand['name'] = (data != null && data['name'] != null)
            ? data['name'].toString()
            : '';
        strand['fullName'] = (data != null && data['fullName'] != null)
            ? data['fullName'].toString()
            : '';
        strand['description'] = (data != null && data['description'] != null)
            ? data['description'].toString()
            : '';
        strand['order'] =
            (data != null && data['order'] is int) ? data['order'] as int : 0;
        strand['isActive'] = (data != null && data['isActive'] is bool)
            ? data['isActive'] as bool
            : true;

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
        course['name'] = (data != null && data['name'] != null)
            ? data['name'].toString()
            : '';
        course['fullName'] = (data != null && data['fullName'] != null)
            ? data['fullName'].toString()
            : '';
        course['description'] = (data != null && data['description'] != null)
            ? data['description'].toString()
            : '';
        course['order'] =
            (data != null && data['order'] is int) ? data['order'] as int : 0;
        course['isActive'] = (data != null && data['isActive'] is bool)
            ? data['isActive'] as bool
            : true;

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
        RegExp(r'grade [1-6]|grade1|grade2|grade3|grade4|grade5|grade6')
            .hasMatch(grade)) {
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

  Future<String> _generateStudentId(EnrollmentFormState formState) async {
    final now = DateTime.now();
    final year =
        now.year.toString().substring(2); // Get last 2 digits: "2025" → "25"

    // Get branch code (563, 564, 565, 991)
    final branchCode = await _getBranchCode(formState.branch);

    // Get department code (001, 002, 003, 004, 005)
    final deptCode = _getDepartmentCode(formState.gradeLevel);

    print('🔍 STUDENT ID DEBUG:');
    print('   branch: ${formState.branch}');
    print('   branchCode: $branchCode');
    print('   year: $year');
    print('   deptCode: $deptCode');

    // Create ID prefix: 56425-001
    final idPrefix = '$branchCode$year-$deptCode';

    // Get the last student ID for this prefix
    final snapshot = await _firestore
        .collection('students')
        .where('studentId', isGreaterThanOrEqualTo: '${idPrefix}0000')
        .where('studentId', isLessThan: '${idPrefix}9999')
        .orderBy('studentId', descending: true)
        .limit(1)
        .get();

    int sequence = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.get('studentId') as String;
      // Extract last 4 digits: "56425-010005" → "0005"
      final lastSequence = lastId.substring(lastId.length - 4);
      sequence = int.parse(lastSequence) + 1;

      print('   lastId found: $lastId');
      print('   lastSequence: $lastSequence');
      print('   nextSequence: $sequence');
    }

    // Create final ID: 56425-010001
    final newId = '$idPrefix${sequence.toString().padLeft(4, '0')}';
    print('   Generated ID: $newId');

    return newId;
  }

  /// Get department code based on grade level
  String _getDepartmentCode(String? gradeLevel) {
    if (gradeLevel == null) return '001';

    final grade = gradeLevel.toLowerCase();

    // 001 - Nursery, Kinder, Prep
    if (grade.contains('nursery') ||
        grade.contains('kinder') ||
        grade.contains('prep')) {
      return '001';
    }

    // 002 - Elementary (Grades 1-6)
    if (grade.contains('grade') && RegExp(r'grade [1-6]').hasMatch(grade)) {
      return '002';
    }

    // 003 - Junior High (Grades 7-10)
    if (grade.contains('grade') &&
        RegExp(r'grade [7-9]|grade 10').hasMatch(grade)) {
      return '003';
    }

    // 004 - Senior High (Grades 11-12)
    if (grade.contains('grade') && RegExp(r'grade 1[1-2]').hasMatch(grade)) {
      return '004';
    }

    // 005 - College
    if (grade.contains('college')) {
      return '005';
    }

    return '001'; // Default to NKP
  }

  // UPDATED METHOD - Now uses the new billing service
  Future<String> submitEnrollment(EnrollmentFormState formState) async {
    try {
      final studentId = await _generateStudentId(formState);
      final academicYear = formState.academicYear;
      final now = DateTime.now();
      final branchCode = await _getBranchCode(formState.branch);

      print('🎓 Starting enrollment submission for student: $studentId');

      // Set the total amount due in the form state
      formState.totalAmountDue = formState.calculatedTotalAmountDue;

      // Create student document
      final studentData = {
        'studentId': studentId,
        'personalInfo': await _createPersonalInfo(formState),
        'enrollmentInfo': {
          'status': 'enrolled',
          'school': 'Pines Best Tech School',
          'dateEnrolled': now.toIso8601String(),
          'branch': formState.branch,
          'branchCode': branchCode,
          'gradeCategory': _getGradeCategoryCode(formState.gradeLevel),
          'academicYear': academicYear,
        },
        'parentInfo': await _createParentInfo(formState),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      print('💾 Saving student document...');
      // Save student to Firestore
      await _firestore.collection('students').doc(studentId).set(studentData);

      print('💰 Creating billing record...');
      // Create billing record using the new billing service
      await _billingService.createBillingRecord(
        studentId: studentId,
        formState: formState,
      );

      // Record initial payment if any
      if (formState.initialPaymentAmount > 0) {
        print(
            '💳 Recording initial payment of ₱${formState.initialPaymentAmount}...');

        String? semester;

        // Determine if it's college level for semester tracking
        if (formState.collegeYearLevel != null ||
            (formState.gradeLevel?.toLowerCase().contains('college') ??
                false)) {
          semester = formState.semesterType ?? 'Semester1';
        }

        final receiptNumber = await _billingService.recordPayment(
          studentId: studentId,
          academicYear: academicYear,
          amount: formState.initialPaymentAmount,
          paymentType: formState.paymentType,
          semester: semester,
          notes: 'Initial enrollment payment',
        );

        print('📄 Payment recorded with receipt: $receiptNumber');
      }

      print('✅ Enrollment completed successfully for student: $studentId');
      return studentId;
    } catch (e, stackTrace) {
      print('❌ Error submitting enrollment: $e');
      print('❌ Stack trace: $stackTrace');
      throw Exception('Failed to submit enrollment: $e');
    }
  }

  // EXISTING METHODS - Keep exactly as is
  Future<Map<String, dynamic>> _createPersonalInfo(
      EnrollmentFormState state) async {
    return {
      'firstName': state.firstName,
      'lastName': state.lastName,
      'middleName': state.middleName,
      'dateOfBirth': state.dateOfBirth?.toIso8601String(),
      'gender': state.gender,
      'placeOfBirth': state.placeOfBirth,
      'religion': state.religion,
      'address': {
        'street': state.streetAddress,
        'province': state.province,
        'municipality': state.municipality,
        'barangay': state.barangay,
        'region': state.region,
      },
      'height': state.height,
      'weight': state.weight,
      'lastSchool': {
        'name': state.lastSchoolName,
        'address': state.lastSchoolAddress,
      },
    };
  }

  Future<Map<String, dynamic>> _createParentInfo(
      EnrollmentFormState state) async {
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

  /// COMPREHENSIVE METHOD - Fetch all fees for a grade level
  Future<Map<String, double>> getAllFees(
      String? gradeLevel, String paymentScheme) async {
    Map<String, double> fees = {
      'tuitionFee': 0.0,
      'bookFee': 0.0,
      'idFee': 0.0,
      'systemFee': 0.0,
    };

    if (gradeLevel == null || gradeLevel.isEmpty) {
      print('⚠️ No grade level provided, returning zero fees');
      return fees;
    }

    try {
      print(
          '🔍 Fetching all fees for grade: $gradeLevel, payment: $paymentScheme');

      // Get tuition fee from tuitionConfiguration
      fees['tuitionFee'] =
          await _getTuitionFeeFromConfig(gradeLevel, paymentScheme);

      // Get other fees from feeConfiguration
      final otherFees = await _getOtherFeesFromConfig(gradeLevel);
      fees['bookFee'] = otherFees['bookFee'] ?? 0.0;
      fees['idFee'] = otherFees['idFee'] ?? 0.0;
      fees['systemFee'] = otherFees['systemFee'] ?? 0.0;

      print('✅ All fees loaded for $gradeLevel:');
      print('   Tuition: ₱${fees['tuitionFee']}');
      print('   Book: ₱${fees['bookFee']}');
      print('   ID: ₱${fees['idFee']}');
      print('   System: ₱${fees['systemFee']}');

      return fees;
    } catch (e) {
      print('❌ Error fetching fees: $e');
      return fees;
    }
  }

  /// FIXED: Get tuition fee from document field, not subcollection
  Future<double> _getTuitionFeeFromConfig(
      String gradeLevel, String paymentScheme) async {
    try {
      String normalizedGrade = gradeLevel.replaceAll(' ', '');
      print('🔍 Looking for tuition config: $normalizedGrade');

      // FIXED: Read the gradeLevels field from the tuitionConfiguration document
      final tuitionDoc = await _firestore
          .collection('adminSettings')
          .doc('tuitionConfiguration')
          .get();

      if (!tuitionDoc.exists) {
        print('❌ tuitionConfiguration document not found');
        return 0.0;
      }

      final tuitionData = tuitionDoc.data() as Map<String, dynamic>;
      final gradeLevelsMap =
          tuitionData['gradeLevels'] as Map<String, dynamic>?;

      if (gradeLevelsMap == null) {
        print('❌ gradeLevels field not found in tuitionConfiguration');
        return 0.0;
      }

      // FIXED: Access grade data from the gradeLevels map
      final gradeConfig =
          gradeLevelsMap[normalizedGrade] as Map<String, dynamic>?;

      if (gradeConfig == null) {
        print('❌ No tuition configuration found for: $normalizedGrade');
        print('❌ Available grades: ${gradeLevelsMap.keys.toList()}');
        return 0.0;
      }

      print('✅ Found tuition config for $normalizedGrade: $gradeConfig');

      // Check if enabled
      bool isEnabled = gradeConfig['enabled'] ?? false;
      if (!isEnabled) {
        print('⚠️ Tuition for $normalizedGrade is disabled');
        return 0.0;
      }

      // Get appropriate fee based on payment scheme
      double tuitionFee = 0.0;
      if (paymentScheme == 'Standard Full Payment') {
        tuitionFee =
            (gradeConfig['tuitionFee_cash'] as num?)?.toDouble() ?? 0.0;
        print('💰 Using cash rate: ₱$tuitionFee');
      } else {
        tuitionFee =
            (gradeConfig['tuitionFee_installment'] as num?)?.toDouble() ??
                (gradeConfig['tuitionFee_cash'] as num?)?.toDouble() ??
                0.0;
        print('💰 Using installment rate: ₱$tuitionFee');
      }

      return tuitionFee;
    } catch (e) {
      print('❌ Error fetching tuition fee: $e');
      return 0.0;
    }
  }

  /// Get other fees from feeConfiguration
  Future<Map<String, double>> _getOtherFeesFromConfig(String gradeLevel) async {
    Map<String, double> fees = {
      'bookFee': 0.0,
      'idFee': 0.0,
      'systemFee': 0.0,
    };

    try {
      // FIXED: Normalize grade level to match Firebase (remove space)
      // "Grade 5" → "Grade5" to match your Firebase structure
      String normalizedGrade = gradeLevel.replaceAll(' ', '');
      print('🔍 Looking for fee config: $normalizedGrade');

      // Correct path: adminSettings/feeConfiguration/gradeLevels/Grade5/miscFees
      final miscFeesSnapshot = await _firestore
          .collection('adminSettings')
          .doc('feeConfiguration')
          .collection('gradeLevels')
          .doc(normalizedGrade) // "Grade5" (no space)
          .collection('miscFees')
          .get();

      if (miscFeesSnapshot.docs.isEmpty) {
        print('❌ No misc fees found for: $normalizedGrade');

        // Debug: List available grade documents
        try {
          final gradeSnapshot = await _firestore
              .collection('adminSettings')
              .doc('feeConfiguration')
              .collection('gradeLevels')
              .get();
          final availableGrades =
              gradeSnapshot.docs.map((doc) => doc.id).toList();
          print(
              '❌ Available grade levels in feeConfiguration: $availableGrades');
        } catch (e) {
          print('❌ Error listing grades: $e');
        }

        // Return defaults
        fees['idFee'] = 200.0;
        fees['systemFee'] = 120.0;
        return fees;
      }

      print('✅ Found ${miscFeesSnapshot.docs.length} misc fee documents');

      // Process each misc fee document using the 'name' field
      for (var doc in miscFeesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final enabled = data['enabled'] ?? true;
        final name = data['name']?.toString().toLowerCase() ?? '';

        print(
            '🔍 Processing fee doc ${doc.id}: name="$name", amount=$amount, enabled=$enabled');

        if (!enabled || amount <= 0) {
          print('⚠️ Skipping disabled or zero fee: ${doc.id}');
          continue;
        }

        // FIXED: Use the 'name' field to identify fee types
        if (name.contains('book')) {
          fees['bookFee'] = amount;
          print('✅ Found book fee: ₱$amount');
        } else if (name.contains('id')) {
          fees['idFee'] = amount;
          print('✅ Found ID fee: ₱$amount');
        } else if (name.contains('system')) {
          fees['systemFee'] = amount;
          print('✅ Found system fee: ₱$amount');
        } else {
          print('⚠️ Unknown fee type: $name (amount: ₱$amount)');
        }
      }

      // Set defaults for missing fees
      if (fees['idFee'] == 0.0) {
        fees['idFee'] = 200.0;
        print('⚠️ Using default ID fee: ₱200');
      }
      if (fees['systemFee'] == 0.0) {
        fees['systemFee'] = 120.0;
        print('⚠️ Using default system fee: ₱120');
      }

      return fees;
    } catch (e) {
      print('❌ Error fetching other fees: $e');
      // Return defaults on error
      fees['idFee'] = 200.0;
      fees['systemFee'] = 120.0;
      return fees;
    }
  }

  /// Updated method to load all fees into form state
  Future<void> updateAllFees(EnrollmentFormState formState) async {
    if (formState.gradeLevel == null || formState.gradeLevel!.isEmpty) {
      formState.tuitionFee = 0.0;
      formState.bookFee = 0.0;
      formState.idFee = 200.0; // Keep default
      formState.systemFee = 120.0; // Keep default
      print('🎓 No grade level, using default fees');
      return;
    }

    // ← ADD THIS: Use course name for college students
    String gradeForTuition = formState.gradeLevel!;

    // If it's college and a course is selected, use the course name for tuition lookup
    if (formState.gradeLevel == 'College' &&
        formState.course != null &&
        formState.course!.isNotEmpty) {
      gradeForTuition = formState.course!;
      print('🎓 Using course name for tuition: $gradeForTuition');
    }

    final fees = await getAllFees(gradeForTuition, formState.paymentScheme);

    formState.tuitionFee = fees['tuitionFee']!;
    formState.bookFee = fees['bookFee']!;
    formState.idFee = fees['idFee']!;
    formState.systemFee = fees['systemFee']!;

    print('🎓 Updated all fees for ${formState.gradeLevel}');
    print('✅ Total fees loaded: ₱${formState.calculatedTotalAmountDue}');
  }

  /// DEBUG: Check the actual Firebase structure
  Future<void> debugFirebaseStructure() async {
    try {
      print('🔍 DEBUG: Checking Firebase structure...');

      // Step 1: Check if adminSettings collection exists
      print('Step 1: Checking adminSettings collection...');
      final adminSnapshot = await _firestore.collection('adminSettings').get();
      print(
          '📋 adminSettings documents: ${adminSnapshot.docs.map((doc) => doc.id).toList()}');

      // Step 2: Check tuitionConfiguration document
      print('Step 2: Checking tuitionConfiguration document...');
      final tuitionDoc = await _firestore
          .collection('adminSettings')
          .doc('tuitionConfiguration')
          .get();
      print('📄 tuitionConfiguration exists: ${tuitionDoc.exists}');

      if (tuitionDoc.exists) {
        final data = tuitionDoc.data();
        print('📄 tuitionConfiguration data keys: ${data?.keys.toList()}');

        // Check if gradeLevels is a field in the document
        if (data != null && data.containsKey('gradeLevels')) {
          print('📄 gradeLevels found as field in document');
          print('📄 gradeLevels content: ${data['gradeLevels']}');
        }
      }

      // Step 3: Try to access gradeLevels as subcollection
      print('Step 3: Checking gradeLevels as subcollection...');
      final gradeLevelsSnapshot = await _firestore
          .collection('adminSettings')
          .doc('tuitionConfiguration')
          .collection('gradeLevels')
          .get();
      print(
          '📋 gradeLevels subcollection count: ${gradeLevelsSnapshot.docs.length}');
      print(
          '📋 gradeLevels documents: ${gradeLevelsSnapshot.docs.map((doc) => doc.id).toList()}');

      // Step 4: Try alternative path
      print('Step 4: Trying alternative paths...');
      try {
        final altSnapshot = await _firestore
            .collection('adminSettings')
            .doc('tuitionConfiguration')
            .collection('gradeLevels')
            .doc('Grade5')
            .get();
        print('📄 Direct Grade5 access: exists=${altSnapshot.exists}');
        if (altSnapshot.exists) {
          print('📄 Grade5 data: ${altSnapshot.data()}');
        }
      } catch (e) {
        print('❌ Alternative path error: $e');
      }
    } catch (e) {
      print('❌ DEBUG Structure Error: $e');
    }
  }
}
