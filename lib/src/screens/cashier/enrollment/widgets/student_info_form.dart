import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/forms/address_form.dart';
import '../models/enrollment_form_state.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/date_picker_field.dart';
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

class StudentInfoFormState extends State<StudentInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  bool _hasAttemptedSubmit = false;
  bool _isValidating = false;
  bool _isFontLoaded = false;
  Timer? _validationTimer;

  // Define text styles using local Poppins font
  TextStyle get _labelStyle => TextStyle(
        fontFamily: 'Poppins',
        color: Colors.grey.shade700,
        fontSize: 13, // Reduced from 14
      );

  TextStyle get _inputStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
      );

  TextStyle get _headerStyle => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16, // Reduced from 18
        fontWeight: FontWeight.w600,
        color: SMSTheme.primaryColor,
      );

  TextStyle get _errorStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
      );

  final Map<String, FocusNode> _focusNodes = {
    'lastName': FocusNode(),
    'firstName': FocusNode(),
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

  // Map field keys to user-friendly labels
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
    _heightController.text = widget.formState.height?.toString() ?? '';
    _weightController.text = widget.formState.weight?.toString() ?? '';

    _updateValidationStates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleInitialScroll();
      _handleInitialFocus();

      if (mounted) {
        final lastNameContext = _focusNodes['lastName']?.context;
        if (lastNameContext != null && widget.scrollController != null) {
          Scrollable.ensureVisible(
            lastNameContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.0,
          );
        }
      }
    });
  }

  void _handleInitialScroll() {
    if (!mounted) return;

    if (widget.scrollController?.hasClients ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.scrollController?.jumpTo(0);
      });
    }
  }

  void _handleInitialFocus() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    if (!isSmallScreen || isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusNodes['lastName']?.canRequestFocus ?? false) {
          _focusNodes['lastName']!.requestFocus();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleInitialFocus();
  }

  bool validateAndScroll(BuildContext context) {
    if (_isValidating) return false;
    _isValidating = true;

    _validationTimer?.cancel();

    setState(() {
      _hasAttemptedSubmit = true;
    });

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

        if (firstInvalidField == null) {
          firstInvalidField = fieldKey;
        }
      }
    }

    final isValid = invalidFields.isEmpty;

    if (!isValid && _hasAttemptedSubmit) {
      _validationTimer = Timer(Duration(milliseconds: 100), () {
        if (!mounted) return;

        if (firstInvalidField != null &&
            _focusNodes[firstInvalidField] != null) {
          _scrollToField(firstInvalidField);
          _focusNodes[firstInvalidField]?.requestFocus();
        }

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please fill in ${invalidFields.first}',
                style: _errorStyle,
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: Duration(seconds: 3),
            ),
          );

          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return WillPopScope(
                onWillPop: () async {
                  return true;
                },
                child: AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Required Fields',
                        style: _headerStyle,
                      ),
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please fill in the following required fields:',
                          style: _inputStyle,
                        ),
                        SizedBox(height: 12),
                        ...invalidFields
                            .map((field) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_right,
                                          color: Colors.red, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        field,
                                        style: _errorStyle,
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'OK',
                        style: _headerStyle,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          );
        }

        setState(() {
          _isValidating = false;
        });
      });
    } else {
      setState(() {
        _isValidating = false;
      });
    }

    return isValid;
  }

  void _updateValidationStates() {
    widget.formState.validationStates.forEach((key, value) {
      switch (key) {
        case 'lastName':
          widget.formState.validationStates[key] =
              (widget.formState.lastName?.isNotEmpty ?? false) &&
                  RegExp(r'^[a-zA-Z\s\-]+$')
                      .hasMatch(widget.formState.lastName ?? '');
          break;
        case 'firstName':
          widget.formState.validationStates[key] =
              (widget.formState.firstName?.isNotEmpty ?? false) &&
                  RegExp(r'^[a-zA-Z\s\-]+$')
                      .hasMatch(widget.formState.firstName ?? '');
          break;
      }
    });
  }

  bool _validateAddressForm() {
    return (widget.formState.region?.isNotEmpty ?? false) &&
        (widget.formState.province?.isNotEmpty ?? false) &&
        (widget.formState.municipality?.isNotEmpty ?? false) &&
        (widget.formState.barangay?.isNotEmpty ?? false) &&
        (widget.formState.streetAddress?.isNotEmpty ?? false);
  }

  void _showValidationError(BuildContext context) {
    final invalidFields = <String>[];
    widget.formState.validationStates.forEach((key, isValid) {
      if (_fieldLabels.containsKey(key) && isValid == false) {
        invalidFields.add(_fieldLabels[key]!);
      }
    });

    final message = invalidFields.isNotEmpty
        ? 'Please fill in the following fields correctly: ${invalidFields.join(", ")}'
        : 'Please fill in all required fields correctly';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: _errorStyle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _focusFirstInvalidField() {
    final fieldsOrder = [
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

    for (final field in fieldsOrder) {
      if (widget.formState.validationStates[field] == false) {
        _focusNodes[field]?.requestFocus();
        _scrollToField(field);
        break;
      }
    }
  }

  void _scrollToField(String fieldKey) {
    _validationTimer?.cancel();

    final context = _focusNodes[fieldKey]?.context;
    if (context != null && widget.scrollController != null) {
      _validationTimer = Timer(Duration(milliseconds: 100), () {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
      });
    }
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced from 24
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6, // Reduced from 8
            offset: const Offset(0, 1), // Reduced from 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 12), // Reduced from 16
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(title),
                  color: SMSTheme.primaryColor,
                  size: 20, // Reduced from 24
                ),
                const SizedBox(width: 8), // Reduced from 12
                Flexible(
                  child: Text(
                    title,
                    style: _headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          ...children,
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Student Name':
        return Icons.person;
      case 'Personal Information':
        return Icons.info;
      case 'Previous School Information':
        return Icons.school;
      default:
        return Icons.article;
    }
  }

  Widget _buildResponsiveRow({
    required List<Widget> children,
    double spacing = 12, // Reduced from 16
    bool forceRow = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900 || forceRow;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Expanded(
                  child: children[i],
                ),
                if (i < children.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String? value,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
    IconData? prefixIcon,
    FocusNode? focusNode,
    bool isRequired = false,
    String fieldKey = '',
    bool autofocus = false,
  }) {
    return CustomTextField(
      label: label,
      value: value,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      prefixIcon: prefixIcon,
      focusNode: focusNode,
      isRequired: isRequired,
      hasError: _fieldErrors[fieldKey] == true && _hasAttemptedSubmit,
      showValidation: _hasAttemptedSubmit,
      autofocus: autofocus,
    );
  }

  InputDecoration _getConsistentDecoration({
    required String label,
    required IconData prefixIcon,
    String? suffixText,
    bool isRequired = false,
    bool hasError = false,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: _labelStyle.copyWith(
        color: hasError ? Colors.red : Colors.grey.shade700,
      ),
      prefixIcon: Icon(prefixIcon, color: SMSTheme.primaryColor, size: 18), // Reduced from 20
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: SMSTheme.primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: widget.enabled ? Colors.white : Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
      isDense: true, // Makes the field more compact
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final bottomPadding = isSmallScreen ? mediaQuery.viewInsets.bottom : 0.0;

    return Form(
      key: _formKey,
      autovalidateMode: _hasAttemptedSubmit
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12 : 20, // Reduced horizontal padding
              12, // Reduced top padding
              isSmallScreen ? 12 : 20,
              bottomPadding + 24 // Reduced from 100 to 24
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Name Section
              Container(
                key: ValueKey('student_name_section'),
                child: _buildSectionContainer(
                  title: 'Student Name',
                  children: [
                    _buildResponsiveRow(
                      children: [
                        _buildCustomTextField(
                          label: 'Last Name',
                          value: widget.formState.lastName,
                          onChanged: (value) {
                            setState(() {
                              widget.formState.lastName = value;
                              widget.formState.validationStates['lastName'] =
                                  value.isNotEmpty &&
                                      RegExp(r'^[a-zA-Z\s\-]+$')
                                          .hasMatch(value);
                              _fieldErrors['lastName'] = false;
                            });
                            widget.onChanged();
                          },
                          validator: (value) {
                            if (!_hasAttemptedSubmit &&
                                !_focusNodes['lastName']!.hasFocus)
                              return null;
                            if (value?.isEmpty ?? true) {
                              return 'Last name is required';
                            }
                            if (!RegExp(r'^[a-zA-Z\s\-]+$')
                                .hasMatch(value!)) {
                              return 'Please enter a valid last name';
                            }
                            return null;
                          },
                          enabled: widget.enabled,
                          prefixIcon: Icons.person,
                          focusNode: _focusNodes['lastName'],
                          isRequired: true,
                          fieldKey: 'lastName',
                          autofocus: !isSmallScreen,
                        ),
                        _buildCustomTextField(
                          label: 'First Name',
                          value: widget.formState.firstName,
                          onChanged: (value) {
                            setState(() {
                              widget.formState.firstName = value;
                              widget.formState.validationStates['firstName'] =
                                  value.isNotEmpty &&
                                      RegExp(r'^[a-zA-Z\s\-]+$')
                                          .hasMatch(value);
                            });
                            widget.onChanged();
                          },
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'First name is required';
                            }
                            if (!RegExp(r'^[a-zA-Z\s\-]+$')
                                .hasMatch(value!)) {
                              return 'Please enter a valid first name';
                            }
                            return null;
                          },
                          enabled: widget.enabled,
                          prefixIcon: Icons.person_outline,
                          focusNode: _focusNodes['firstName'],
                          isRequired: true,
                          fieldKey: 'firstName',
                        ),
                        _buildCustomTextField(
                          label: 'Middle Name',
                          value: widget.formState.middleName,
                          onChanged: (value) {
                            widget.formState.middleName = value;
                            widget.onChanged();
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[a-zA-Z\s\-]+$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid middle name';
                              }
                            }
                            return null;
                          },
                          enabled: widget.enabled,
                          prefixIcon: Icons.person_outline,
                          fieldKey: 'middleName',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Address Section
              _buildSectionContainer(
                title: 'Address Information',
                children: [
                  AddressForm(
                    region: widget.formState.region,
                    province: widget.formState.province,
                    municipality: widget.formState.municipality,
                    barangay: widget.formState.barangay,
                    streetAddress: widget.formState.streetAddress ?? '',
                    onRegionChanged: (value) {
                      setState(() {
                        widget.formState.region = value ?? 'REGION IV-A';
                        widget.formState.validationStates['region'] =
                            value != null;
                      });
                      widget.onChanged();
                    },
                    onProvinceChanged: (value) {
                      setState(() {
                        widget.formState.province = value ?? 'RIZAL';
                        widget.formState.validationStates['province'] =
                            value != null;
                      });
                      widget.onChanged();
                    },
                    onMunicipalityChanged: (value) {
                      setState(() {
                        widget.formState.municipality = value ?? 'BINANGONAN';
                        widget.formState.validationStates['municipality'] =
                            value != null;
                      });
                      widget.onChanged();
                    },
                    onBarangayChanged: (value) {
                      setState(() {
                        widget.formState.barangay = value ?? '';
                        widget.formState.validationStates['barangay'] =
                            value?.isNotEmpty ?? false;
                      });
                      widget.onChanged();
                    },
                    onStreetAddressChanged: (value) {
                      setState(() {
                        widget.formState.streetAddress = value;
                        widget.formState.validationStates['streetAddress'] =
                            value.isNotEmpty;
                      });
                      widget.onChanged();
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
                  ),
                ],
              ),

              // Personal Information Section
              _buildSectionContainer(
                title: 'Personal Information',
                children: [
                  _buildResponsiveRow(
                    children: [
                      DropdownField(
                        label: 'Gender',
                        value: widget.formState.gender,
                        items: const ['Male', 'Female'],
                        onChanged: widget.enabled
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    widget.formState.gender = value;
                                    widget.formState
                                        .validationStates['gender'] = true;
                                  });
                                  widget.onChanged();
                                }
                              }
                            : null,
                        validator: (value) {
                          return (value?.isEmpty ?? true)
                              ? 'Please select a gender'
                              : null;
                        },
                        icon: Icons.wc,
                        focusNode: _focusNodes['gender'],
                        isRequired: true,
                      ),
                      DatePickerField(
                        label: 'Date of Birth',
                        value: widget.formState.dateOfBirth,
                        onChanged: (value) {
                          setState(() {
                            widget.formState.dateOfBirth = value;
                            widget.formState.validationStates['dateOfBirth'] =
                                value != null;
                          });
                          widget.onChanged();
                        },
                        validator: (value) {
                          return (value?.isEmpty ?? true)
                              ? 'Date of birth is required'
                              : null;
                        },
                        readOnly: !widget.enabled,
                        focusNode: _focusNodes['dateOfBirth'],
                        isRequired: true,
                        showValidation: _hasAttemptedSubmit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  CustomTextField(
                    label: 'Place of Birth',
                    value: widget.formState.placeOfBirth,
                    onChanged: (value) {
                      widget.formState.placeOfBirth = value;
                      widget.onChanged();
                    },
                    enabled: widget.enabled,
                    prefixIcon: Icons.location_city,
                  ),
                  const SizedBox(height: 12),
                  _buildResponsiveRow(
                    children: [
                      CustomTextField(
                        label: 'Religion',
                        value: widget.formState.religion ?? '',
                        onChanged: (value) {
                          widget.formState.religion = value;
                          widget.onChanged();
                        },
                        enabled: widget.enabled,
                        prefixIcon: Icons.church,
                      ),
                      TextFormField(
                        controller: _heightController,
                        enabled: widget.enabled,
                        focusNode: _focusNodes['height'],
                        decoration: _getConsistentDecoration(
                          label: 'Height',
                          prefixIcon: Icons.height,
                          suffixText: 'cm',
                        ),
                        style: _inputStyle,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final height = double.tryParse(value);
                            if (height == null || height <= 0 || height > 300) {
                              return 'Please enter a valid height (1-300 cm)';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          widget.formState.height = double.tryParse(value);
                          widget.onChanged();
                        },
                      ),
                      TextFormField(
                        controller: _weightController,
                        enabled: widget.enabled,
                        focusNode: _focusNodes['weight'],
                        decoration: _getConsistentDecoration(
                          label: 'Weight',
                          prefixIcon: Icons.monitor_weight,
                          suffixText: 'kg',
                        ),
                        style: _inputStyle,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final weight = double.tryParse(value);
                            if (weight == null ||
                                weight <= 0 ||
                                weight > 1000) {
                              return 'Please enter a valid weight (1-1000 kg)';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          widget.formState.weight = double.tryParse(value);
                          widget.onChanged();
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Previous School Information
              _buildSectionContainer(
                title: 'Previous School Information',
                children: [
                  _buildResponsiveRow(
                    children: [
                      CustomTextField(
                        label: 'Last School Name',
                        value: widget.formState.lastSchoolName ?? '',
                        onChanged: (value) {
                          widget.formState.lastSchoolName = value;
                          widget.onChanged();
                        },
                        enabled: widget.enabled,
                        prefixIcon: Icons.school,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildResponsiveRow(
                    children: [
                      CustomTextField(
                        label: 'Last School Address',
                        value: widget.formState.lastSchoolAddress ?? '',
                        onChanged: (value) {
                          widget.formState.lastSchoolAddress = value;
                          widget.onChanged();
                        },
                        enabled: widget.enabled,
                        prefixIcon: Icons.location_on,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _heightController.dispose();
    _weightController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}