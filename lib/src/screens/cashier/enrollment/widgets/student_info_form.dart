import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/forms/address_form.dart';
import '../models/enrollment_form_state.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/dropdown_field.dart';
import 'dart:async';

class StudentInfoForm extends StatefulWidget {
  final EnrollmentFormState formState;
  final VoidCallback onChanged;
  final bool enabled;
  final ScrollController? scrollController;

  const StudentInfoForm({
    Key? key,
    required this.formState,
    required this.onChanged,
    this.enabled = true,
    this.scrollController,
  }) : super(key: key);

  @override
  StudentInfoFormState createState() => StudentInfoFormState();
}

class StudentInfoFormState extends State<StudentInfoForm> with TickerProviderStateMixin {
  // NOTE: This form handles dateOfBirth as DateTime in the form state 
  // but displays it as a formatted string (MM/dd/yyyy) to the user
  
  final _formKey = GlobalKey<FormState>();
  bool _hasAttemptedSubmit = false;
  bool _isValidating = false;
  Timer? _validationTimer;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Focus nodes
  final Map<String, FocusNode> _focusNodes = {
    'lastName': FocusNode(),
    'firstName': FocusNode(),
    'middleName': FocusNode(),
    'gender': FocusNode(),
    'dateOfBirth': FocusNode(),
    'region': FocusNode(),
    'province': FocusNode(),
    'municipality': FocusNode(),
    'barangay': FocusNode(),
    'streetAddress': FocusNode(),
    'height': FocusNode(),
    'weight': FocusNode(),
  };

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Field validation tracking
  static const Map<String, String> _fieldLabels = {
    'lastName': 'Last Name',
    'firstName': 'First Name',
    'gender': 'Gender',
    'dateOfBirth': 'Date of Birth',
    'region': 'Region',
    'province': 'Province',
    'municipality': 'Municipality/City',
    'barangay': 'Barangay',
    'streetAddress': 'Street Address',
  };

  final Map<String, bool> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Initialize controllers
    _heightController.text = widget.formState.height?.toString() ?? '';
    _weightController.text = widget.formState.weight?.toString() ?? '';
    
    // Handle dateOfBirth - convert DateTime to String for display
    String dateText = '';
    try {
      final dateValue = widget.formState.dateOfBirth;
      if (dateValue != null) {
        dateText = '${dateValue.month.toString().padLeft(2, '0')}/${dateValue.day.toString().padLeft(2, '0')}/${dateValue.year}';
      }
    } catch (e) {
      print('Error initializing date: $e');
      dateText = '';
    }
    _dateController.text = dateText;
    
    _updateValidationStates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(StudentInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controllers if the form state changed
    if (oldWidget.formState.dateOfBirth != widget.formState.dateOfBirth) {
      String dateText = '';
      try {
        final dateValue = widget.formState.dateOfBirth;
        if (dateValue != null) {
          dateText = '${dateValue.month.toString().padLeft(2, '0')}/${dateValue.day.toString().padLeft(2, '0')}/${dateValue.year}';
        }
      } catch (e) {
        print('Error updating date: $e');
        dateText = '';
      }
      _dateController.text = dateText;
    }
    
    if (oldWidget.formState.height != widget.formState.height) {
      _heightController.text = widget.formState.height?.toString() ?? '';
    }
    
    if (oldWidget.formState.weight != widget.formState.weight) {
      _weightController.text = widget.formState.weight?.toString() ?? '';
    }
  }

  bool validateAndScroll(BuildContext context) {
    if (_isValidating) return false;
    _isValidating = true;

    _validationTimer?.cancel();
    setState(() => _hasAttemptedSubmit = true);
    _updateValidationStates();
    _fieldErrors.clear();

    final validationOrder = [
      'lastName',
      'firstName',
      'gender',
      'dateOfBirth',
      'region',
      'province',
      'municipality',
      'barangay',
      'streetAddress',
    ];

    final invalidFields = <String>[];
    String? firstInvalidField;

    for (var fieldKey in validationOrder) {
      if (!widget.formState.validationStates[fieldKey]!) {
        invalidFields.add(_fieldLabels[fieldKey]!);
        _fieldErrors[fieldKey] = true;
        firstInvalidField ??= fieldKey;
      }
    }

    final isValid = invalidFields.isEmpty;

    if (!isValid) {
      _showValidationError(firstInvalidField, invalidFields);
    }

    setState(() => _isValidating = false);
    return isValid;
  }

  void _showValidationError(String? firstInvalidField, List<String> invalidFields) {
    _validationTimer = Timer(Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Focus first invalid field
      if (firstInvalidField != null) {
        _focusNodes[firstInvalidField]?.requestFocus();
      }

      // Show snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please fill in ${invalidFields.first}',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  void _updateValidationStates() {
    final states = widget.formState.validationStates;
    
    states['lastName'] = (widget.formState.lastName?.isNotEmpty ?? false) &&
        RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(widget.formState.lastName ?? '');
    
    states['firstName'] = (widget.formState.firstName?.isNotEmpty ?? false) &&
        RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(widget.formState.firstName ?? '');
    
    // Handle dateOfBirth - check if DateTime is not null
    bool hasValidDate = widget.formState.dateOfBirth != null;
    states['dateOfBirth'] = hasValidDate;
    
    states['gender'] = widget.formState.gender?.isNotEmpty ?? false;
    states['region'] = widget.formState.region?.isNotEmpty ?? false;
    states['province'] = widget.formState.province?.isNotEmpty ?? false;
    states['municipality'] = widget.formState.municipality?.isNotEmpty ?? false;
    states['barangay'] = widget.formState.barangay?.isNotEmpty ?? false;
    states['streetAddress'] = widget.formState.streetAddress?.isNotEmpty ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        autovalidateMode: _hasAttemptedSubmit
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withOpacity(0.02),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeader(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Student Name Section
                  _buildAnimatedSection(
                    title: '👤 Student Information',
                    subtitle: 'Enter the student\'s personal details',
                    delay: 0,
                    child: _buildStudentNameForm(isSmallScreen),
                  ),
                  SizedBox(height: 24),

                  // Address Section
                  _buildAnimatedSection(
                    title: '📍 Address Information',
                    subtitle: 'Complete residential address details',
                    delay: 200,
                    child: _buildAddressForm(isSmallScreen),
                  ),
                  SizedBox(height: 24),

                  // Personal Information Section
                  _buildAnimatedSection(
                    title: '🎂 Personal Details',
                    subtitle: 'Birth date and physical information',
                    delay: 400,
                    child: _buildPersonalInfoForm(isSmallScreen),
                  ),
                  SizedBox(height: 24),

                  // Previous School Section
                  _buildAnimatedSection(
                    title: '🏫 Previous School',
                    subtitle: 'Last attended educational institution',
                    delay: 600,
                    child: _buildPreviousSchoolForm(isSmallScreen),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_add,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Information',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete the enrollment form with accurate information',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({
    required String title,
    required String subtitle,
    required Widget child,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Section Content
            Padding(
              padding: EdgeInsets.all(20),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIED: Student Name Form - Always Horizontal Layout
 Widget _buildStudentNameForm(bool isSmallScreen) {
  return Column(
    children: [
      if (isSmallScreen) ...[
        // Mobile: Stack vertically
        _buildModernTextField(
          label: 'Last Name',
          value: widget.formState.lastName,
          onChanged: (value) {
            setState(() {
              widget.formState.lastName = value;
              widget.formState.validationStates['lastName'] = (value.isNotEmpty) &&
                  RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value);  // ✅ Fixed
            });
            _safeOnChanged();
          },
          focusNode: _focusNodes['lastName'],
          prefixIcon: Icons.person,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Last name is required';
            }
            if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {  // ✅ Fixed
              return 'Please enter a valid last name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          label: 'First Name',
          value: widget.formState.firstName,
          onChanged: (value) {
            setState(() {
              widget.formState.firstName = value;
              widget.formState.validationStates['firstName'] = (value.isNotEmpty) &&
                  RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value);  // ✅ Fixed
            });
            _safeOnChanged();
          },
          focusNode: _focusNodes['firstName'],
          prefixIcon: Icons.person,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'First name is required';
            }
            if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {  // ✅ Fixed
              return 'Please enter a valid first name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          label: 'Middle Name',
          value: widget.formState.middleName,
          onChanged: (value) {
            setState(() {
              widget.formState.middleName = value;
              // Middle name is typically optional
            });
            _safeOnChanged();
          },
          focusNode: _focusNodes['middleName'],
          prefixIcon: Icons.person,
          isRequired: false,
        ),
      ] else ...[
        // Desktop: Keep horizontal
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                label: 'Last Name',
                value: widget.formState.lastName,
                onChanged: (value) {
                  setState(() {
                    widget.formState.lastName = value;
                    widget.formState.validationStates['lastName'] = (value.isNotEmpty) &&
                        RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value);  // ✅ Fixed
                  });
                  _safeOnChanged();
                },
                focusNode: _focusNodes['lastName'],
                prefixIcon: Icons.person,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {  // ✅ Fixed
                    return 'Please enter a valid last name';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernTextField(
                label: 'First Name',
                value: widget.formState.firstName,
                onChanged: (value) {
                  setState(() {
                    widget.formState.firstName = value;
                    widget.formState.validationStates['firstName'] = (value.isNotEmpty) &&
                        RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value);  // ✅ Fixed
                  });
                  _safeOnChanged();
                },
                focusNode: _focusNodes['firstName'],
                prefixIcon: Icons.person,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {  // ✅ Fixed
                    return 'Please enter a valid first name';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildModernTextField(
                label: 'Middle Name',
                value: widget.formState.middleName,
                onChanged: (value) {
                  setState(() {
                    widget.formState.middleName = value;
                    // Middle name is typically optional
                  });
                  _safeOnChanged();
                },
                focusNode: _focusNodes['middleName'],
                prefixIcon: Icons.person,
                isRequired: false,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
  Widget _buildAddressForm(bool isSmallScreen) {
    return AddressForm(
      region: widget.formState.region,
      province: widget.formState.province,
      municipality: widget.formState.municipality,
      barangay: widget.formState.barangay,
      streetAddress: widget.formState.streetAddress ?? '',
      onRegionChanged: (value) {
        setState(() {
          widget.formState.region = value ?? 'REGION IV-A';
          widget.formState.validationStates['region'] = value != null;
        });
        _safeOnChanged();
      },
      onProvinceChanged: (value) {
        setState(() {
          widget.formState.province = value ?? 'RIZAL';
          widget.formState.validationStates['province'] = value != null;
        });
        _safeOnChanged();
      },
      onMunicipalityChanged: (value) {
        setState(() {
          widget.formState.municipality = value ?? 'BINANGONAN';
          widget.formState.validationStates['municipality'] = value != null;
        });
        _safeOnChanged();
      },
      onBarangayChanged: (value) {
        setState(() {
          widget.formState.barangay = value ?? '';
          widget.formState.validationStates['barangay'] = value?.isNotEmpty ?? false;
        });
        _safeOnChanged();
      },
      onStreetAddressChanged: (value) {
        setState(() {
          widget.formState.streetAddress = value;
          widget.formState.validationStates['streetAddress'] = value.isNotEmpty;
        });
        _safeOnChanged();
      },
      enabled: widget.enabled,
      isRequired: true,
      focusNodes: {
        'region': _focusNodes['region']!,
        'province': _focusNodes['province']!,
        'municipality': _focusNodes['municipality']!,
        'barangay': _focusNodes['barangay']!,
        'streetAddress': _focusNodes['streetAddress']!,
      },
      showValidation: _hasAttemptedSubmit,
    );
  }

  Widget _buildPersonalInfoForm(bool isSmallScreen) {
    return Column(
      children: [
        _buildResponsiveRow([
          _buildModernDropdown(
            label: 'Gender',
            value: widget.formState.gender,
            items: ['Male', 'Female'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.formState.gender = value;
                  widget.formState.validationStates['gender'] = true;
                });
                _safeOnChanged();
              }
            },
            prefixIcon: Icons.wc,
            isRequired: true,
          ),
          _buildDatePickerField(),
        ], isSmallScreen),
        SizedBox(height: 16),
        _buildModernTextField(
          label: 'Place of Birth',
          value: widget.formState.placeOfBirth,
          onChanged: (value) {
            widget.formState.placeOfBirth = value;
            _safeOnChanged();
          },
          prefixIcon: Icons.location_city,
        ),
        SizedBox(height: 16),
        _buildResponsiveRow([
          _buildModernTextField(
            label: 'Religion',
            value: widget.formState.religion ?? '',
            onChanged: (value) {
              widget.formState.religion = value;
              _safeOnChanged();
            },
            prefixIcon: Icons.church,
          ),
          _buildModernTextField(
            label: 'Height (cm)',
            value: _heightController.text,
            controller: _heightController,
            onChanged: (value) {
              widget.formState.height = double.tryParse(value);
              _safeOnChanged();
            },
            prefixIcon: Icons.height,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final height = double.tryParse(value);
                if (height == null || height <= 0 || height > 300) {
                  return 'Invalid height';
                }
              }
              return null;
            },
          ),
          _buildModernTextField(
            label: 'Weight (kg)',
            value: _weightController.text,
            controller: _weightController,
            onChanged: (value) {
              widget.formState.weight = double.tryParse(value);
              _safeOnChanged();
            },
            prefixIcon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0 || weight > 1000) {
                  return 'Invalid weight';
                }
              }
              return null;
            },
          ),
        ], isSmallScreen),
      ],
    );
  }

  Widget _buildPreviousSchoolForm(bool isSmallScreen) {
    return Column(
      children: [
        _buildModernTextField(
          label: 'Last School Name',
          value: widget.formState.lastSchoolName ?? '',
          onChanged: (value) {
            widget.formState.lastSchoolName = value;
            _safeOnChanged();
          },
          prefixIcon: Icons.school,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          label: 'Last School Address',
          value: widget.formState.lastSchoolAddress ?? '',
          onChanged: (value) {
            widget.formState.lastSchoolAddress = value;
            _safeOnChanged();
          },
          prefixIcon: Icons.location_on,
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    String? value,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    bool isRequired = false,
    FocusNode? focusNode,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: controller == null ? value : null,
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        enabled: widget.enabled,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          prefixIcon: prefixIcon != null
              ? Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    String? value,
    required List<String> items,
    Function(String?)? onChanged,
    IconData? prefixIcon,
    bool isRequired = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: widget.enabled ? onChanged : null,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          prefixIcon: prefixIcon != null
              ? Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        validator: isRequired
            ? (value) => (value?.isEmpty ?? true) ? 'Please select $label' : null
            : null,
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        readOnly: true,
        controller: _dateController,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Date of Birth *',
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          hintText: 'Tap to select date',
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) => (value?.isEmpty ?? true) ? 'Date of birth is required' : null,
        onTap: widget.enabled ? _selectDate : null,
      ),
    );
  }

  Future<void> _selectDate() async {
    // Note: This handles DateTime in form state but displays as formatted string
    FocusScope.of(context).requestFocus(FocusNode());
    
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = now;
    
    DateTime initialDate = now.subtract(Duration(days: 365 * 18));
    
    // Try to parse existing date from form state
    final existingDate = widget.formState.dateOfBirth;
    if (existingDate != null) {
      try {
        // If it's already a DateTime, use it
        initialDate = existingDate;
      } catch (e) {
        print('Error using existing date: $e');
        // Use default date
      }
    }
    
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    try {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null && mounted) {
        final formattedDate = '${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}';
        
        // Update the controller with formatted string
        _dateController.text = formattedDate;
        
        setState(() {
          // Assign DateTime object to form state
          widget.formState.dateOfBirth = pickedDate;
          widget.formState.validationStates['dateOfBirth'] = true;
        });
        
        _safeOnChanged();
      }
    } catch (e) {
      print('Error showing date picker: $e');
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error opening date picker. Please try again.',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildResponsiveRow(List<Widget> children, bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: children.map((child) => 
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: child,
          )
        ).toList(),
      );
    }
    
    return Row(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < children.length - 1 ? 16 : 0,
            ),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  void _safeOnChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _validationTimer?.cancel();
    _heightController.dispose();
    _weightController.dispose();
    _dateController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}