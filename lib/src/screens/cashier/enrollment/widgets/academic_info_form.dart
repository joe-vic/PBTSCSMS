import 'package:flutter/material.dart';
import '../models/enrollment_form_state.dart';
import '../services/enrollment_service.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/dropdown_field.dart';

class AcademicInfoForm extends StatefulWidget {
  final EnrollmentFormState formState;
  final VoidCallback onChanged;

  const AcademicInfoForm({
    Key? key,
    required this.formState,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<AcademicInfoForm> createState() => _AcademicInfoFormState();
}

class _AcademicInfoFormState extends State<AcademicInfoForm> {
  final EnrollmentService _enrollmentService = EnrollmentService();

  // Dynamic data lists
  List<Map<String, String>> _branches = [];
  List<Map<String, dynamic>> _gradeLevels = [];
  List<Map<String, dynamic>> _strands = [];
  List<Map<String, dynamic>> _courses = [];

  // Loading states
  bool _isBranchesLoading = true;
  bool _isGradeLevelsLoading = true;
  bool _isStrandsLoading = true;
  bool _isCoursesLoading = true;
  bool _isInitialized =
      false; // Track initialization to prevent setState during build

  @override
  void initState() {
    super.initState();

    // FIXED: Use post-frame callback to prevent setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeForm();
      }
    });
  }

  Future<void> _initializeForm() async {
    try {
      // Set initialized flag first
      setState(() {
        _isInitialized = true;
      });

      // Load all data and set academic year
      await Future.wait([
        _loadInitialData(),
        _setAcademicYearSafely(),
      ]);

      // ← ADD THIS: Load fees if grade level is already set
      if (widget.formState.gradeLevel != null &&
          widget.formState.gradeLevel!.isNotEmpty) {
        try {
          print(
              '🔄 Initializing fees for existing grade level: ${widget.formState.gradeLevel}');
          await _enrollmentService.updateAllFees(widget.formState);
          print('✅ Initial fees loaded');
          _safeOnChanged(); // Notify parent that fees are loaded
        } catch (e) {
          print('❌ Error loading initial fees: $e');
        }
      }
    } catch (e) {
      print('Error initializing academic form: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      // Load all data concurrently
      await Future.wait([
        _loadBranches(),
        _loadGradeLevels(),
        _loadStrands(),
        _loadCourses(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> _loadBranches() async {
    if (!mounted) return;

    try {
      final branches = await _enrollmentService.getBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _isBranchesLoading = false;
        });
      }
    } catch (e) {
      print('Error loading branches: $e');
      if (mounted) {
        setState(() {
          _isBranchesLoading = false;
        });
      }
    }
  }

  Future<void> _loadGradeLevels() async {
    if (!mounted) return;

    try {
      final gradeLevels = await _enrollmentService.getGradeLevels();
      if (mounted) {
        setState(() {
          _gradeLevels = gradeLevels;
          _isGradeLevelsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading grade levels: $e');
      if (mounted) {
        setState(() {
          _isGradeLevelsLoading = false;
        });
      }
    }
  }

  Future<void> _loadStrands() async {
    if (!mounted) return;

    try {
      final strands = await _enrollmentService.getStrands();
      if (mounted) {
        setState(() {
          _strands = strands;
          _isStrandsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading strands: $e');
      if (mounted) {
        setState(() {
          _isStrandsLoading = false;
        });
      }
    }
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;

    try {
      final courses = await _enrollmentService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isCoursesLoading = false;
        });
      }
    } catch (e) {
      print('Error loading courses: $e');
      if (mounted) {
        setState(() {
          _isCoursesLoading = false;
        });
      }
    }
  }

  // FIXED: Safe academic year calculation
  Future<void> _setAcademicYearSafely() async {
    if (!mounted || !_isInitialized) return;

    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      String academicYear;

      // Philippine school year logic:
      // May (5) - December (12): Current year to next year (NEW school year)
      // January (1) - April (4): Previous year to current year (CURRENT school year)
      if (currentMonth >= 5) {
        // May to December: 2025-2026 (NEW school year)
        academicYear = '$currentYear-${currentYear + 1}';
      } else {
        // January to April: 2024-2025 (CURRENT school year)
        academicYear = '${currentYear - 1}-$currentYear';
      }

      // FIXED: Only update if value actually changed and widget is mounted
      if (mounted && widget.formState.academicYear != academicYear) {
        widget.formState.academicYear = academicYear;

        // FIXED: Safe onChange call
        _safeOnChanged();
      }

      print(
          '📅 Auto-calculated Academic Year (PH): $academicYear (Current date: ${now.toString().split(' ')[0]})');
    } catch (e) {
      print('Error setting academic year: $e');
    }
  }

  // FIXED: Safe onChange wrapper
  void _safeOnChanged() {
    if (!mounted || !_isInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onChanged();
      }
    });
  }

  // Helper method to check if current grade level has strands
  bool _currentGradeLevelHasStrands() {
    try {
      if (widget.formState.gradeLevel == null || _gradeLevels.isEmpty) {
        return false;
      }

      final selectedGradeLevel = _gradeLevels.firstWhere(
        (grade) => grade['name'] == widget.formState.gradeLevel,
        orElse: () => <String, dynamic>{},
      );

      return selectedGradeLevel['hasStrands'] ?? false;
    } catch (e) {
      print('Error checking hasStrands: $e');
      return false;
    }
  }

  // Helper method to check if current grade level has courses
  bool _currentGradeLevelHasCourses() {
    try {
      if (widget.formState.gradeLevel == null || _gradeLevels.isEmpty) {
        return false;
      }

      final selectedGradeLevel = _gradeLevels.firstWhere(
        (grade) => grade['name'] == widget.formState.gradeLevel,
        orElse: () => <String, dynamic>{},
      );

      return selectedGradeLevel['hasCourses'] ?? false;
    } catch (e) {
      print('Error checking hasCourses: $e');
      return false;
    }
  }

  // Helper to get sorted grade level names while preserving order
  List<String> _getSortedGradeLevelNames() {
    try {
      // _gradeLevels is already sorted by the service, just extract names in order
      return _gradeLevels.map((grade) => grade['name'] as String).toList();
    } catch (e) {
      print('Error getting grade level names: $e');
      return [];
    }
  }

  // Helper to get sorted course names while preserving order
  List<String> _getSortedCourseNames() {
    try {
      // _courses is already sorted by the service, just extract names in order
      return _courses.map((course) => course['name'] as String).toList();
    } catch (e) {
      print('Error getting course names: $e');
      return [];
    }
  }

  // Helper to get strand names
  List<String> _getStrandNames() {
    try {
      return _strands.map((strand) => strand['name'] as String).toList();
    } catch (e) {
      print('Error getting strand names: $e');
      return [];
    }
  }

  // Helper to get branch names
  List<String> _getBranchNames() {
    try {
      return _branches.map((branch) => branch['name']!).toList();
    } catch (e) {
      print('Error getting branch names: $e');
      return [];
    }
  }

  bool get _isLoading =>
      _isBranchesLoading ||
      _isGradeLevelsLoading ||
      _isStrandsLoading ||
      _isCoursesLoading;

  @override
  Widget build(BuildContext context) {
    // Show loading state if not initialized yet
    if (!_isInitialized) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading academic information...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          SizedBox(height: 24),

          // Main Form Content
          _buildFormContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school,
              color: Colors.blue[700],
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Academic Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Select the student\'s grade level, branch, and academic details',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grade Level and Branch Selection
            Row(
              children: [
                Expanded(
                  child: _isGradeLevelsLoading
                      ? Container(
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownField(
                          label: 'Grade Level',
                          value: widget.formState.gradeLevel,
                          items: _getSortedGradeLevelNames(),
                          onChanged: (value) async {
                            // ← Add async here
                            if (value != null && mounted && _isInitialized) {
                              setState(() {
                                widget.formState.gradeLevel = value;
                                // Clear dependent fields when grade level changes
                                widget.formState.strand = null;
                                widget.formState.course = null;
                                widget.formState.collegeYearLevel = null;
                                widget.formState.semesterType = null;
                              });

                              // ← ADD THIS: Fetch all fees when grade level changes
                              try {
                                print(
                                    '🔄 Grade level changed to: $value, fetching fees...');
                                await _enrollmentService
                                    .debugFirebaseStructure(); // ← ADD THIS
                                await _enrollmentService
                                    .updateAllFees(widget.formState);
                                print('✅ Fees updated successfully');
                              } catch (e) {
                                print('❌ Error updating fees: $e');
                              }

                              _safeOnChanged();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Grade level is required';
                            }
                            return null;
                          },
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isBranchesLoading
                      ? Container(
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownField(
                          label: 'Branch',
                          value: widget.formState.branch,
                          items: _getBranchNames(),
                          onChanged: (value) {
                            if (value != null && mounted && _isInitialized) {
                              widget.formState.branch = value;
                              _safeOnChanged();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Branch is required';
                            }
                            return null;
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Strand Selection (for Senior High)
            if (_currentGradeLevelHasStrands())
              Column(
                children: [
                  _isStrandsLoading
                      ? Container(
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownField(
                          label: 'Strand',
                          value: widget.formState.strand,
                          items: _getStrandNames(),
                          onChanged: (value) {
                            if (value != null && mounted && _isInitialized) {
                              widget.formState.strand = value;
                              _safeOnChanged();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Strand is required for Senior High School';
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),
                ],
              ),

            // Course Selection (for College)
            if (_currentGradeLevelHasCourses()) ...[
              _isCoursesLoading
                  ? Container(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownField(
                      label: 'Course',
                      value: widget.formState.course,
                      items: _getSortedCourseNames(),
                      onChanged: (value) {
                        if (value != null && mounted && _isInitialized) {
                          widget.formState.course = value;
                          if (widget.formState.gradeLevel == 'College') {
                            try {
                              _enrollmentService
                                  .updateAllFees(widget.formState)
                                  .then((_) {
                                if (mounted) setState(() {});
                              });
                            } catch (e) {
                              print(
                                  '❌ Error updating fees for course change: $e');
                            }
                          }

                          _safeOnChanged();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Course is required for College';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),
              DropdownField(
                label: 'Year Level',
                value: widget.formState.collegeYearLevel,
                items: const [
                  '1st Year',
                  '2nd Year',
                  '3rd Year',
                  '4th Year',
                ],
                onChanged: (value) {
                  if (value != null && mounted && _isInitialized) {
                    widget.formState.collegeYearLevel = value;
                    _safeOnChanged();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Year level is required for College';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownField(
                label: 'Semester',
                value: widget.formState.semesterType,
                items: const [
                  '1st Semester',
                  '2nd Semester',
                  'Summer',
                ],
                onChanged: (value) {
                  if (value != null && mounted && _isInitialized) {
                    widget.formState.semesterType = value;
                    _safeOnChanged();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Semester is required for College';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),
            // Academic Year - Auto-calculated with option to edit
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Academic Year',
                    value: widget.formState.academicYear,
                    onChanged: (value) {
                      if (mounted && _isInitialized) {
                        widget.formState.academicYear = value;
                        _safeOnChanged();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Academic year is required';
                      }
                      if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(value)) {
                        return 'Academic year should be in format YYYY-YYYY';
                      }
                      return null;
                    },
                    hintText: 'e.g., 2024-2025',
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _setAcademicYearSafely(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Auto-calculate Academic Year',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.orange,
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              child: Text(
                '📅 Academic year auto-calculated for Philippine school calendar (June-March)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
