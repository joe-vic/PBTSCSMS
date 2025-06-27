import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import '../../../../config/theme.dart';
import '../models/enrollment_form_state.dart';
import '../../../../widgets/forms/custom_text_field.dart';

class ParentInfoForm extends StatefulWidget {
  final EnrollmentFormState formState;
  final VoidCallback onChanged;
  final bool enabled;
  final ScrollController? scrollController;

  const ParentInfoForm({
    Key? key,
    required this.formState,
    required this.onChanged,
    this.enabled = true,
    this.scrollController,
  }) : super(key: key);

  @override
  ParentInfoFormState createState() => ParentInfoFormState();
}

class ParentInfoFormState extends State<ParentInfoForm> {
  final _formKey = GlobalKey<FormState>();
  bool _hasAttemptedSubmit = false;
  bool _isValidating = false;
  Timer? _validationTimer;
  final _scrollController = ScrollController();

  final Map<String, FocusNode> _focusNodes = {
    'motherLastName': FocusNode(),
    'motherFirstName': FocusNode(),
    'motherContact': FocusNode(),
    'fatherLastName': FocusNode(),
    'fatherFirstName': FocusNode(),
    'fatherContact': FocusNode(),
    'primaryLastName': FocusNode(),
    'primaryFirstName': FocusNode(),
    'primaryContact': FocusNode(),
  };

  // Map field keys to user-friendly labels
  static const Map<String, String> _fieldLabels = {
    'motherLastName': 'Mother\'s Last Name',
    'motherFirstName': 'Mother\'s First Name',
    'motherContact': 'Mother\'s Contact Number',
    'fatherLastName': 'Father\'s Last Name',
    'fatherFirstName': 'Father\'s First Name',
    'fatherContact': 'Father\'s Contact Number',
    'primaryLastName': 'Primary Contact\'s Last Name',
    'primaryFirstName': 'Primary Contact\'s First Name',
    'primaryContact': 'Primary Contact\'s Contact Number',
  };

  final Map<String, bool> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _updateValidationStates();

    // Platform-agnostic initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Handle initial scroll
      _handleInitialScroll();

      // Handle initial focus based on platform
      _handleInitialFocus();

      // Ensure the Mother's Information section is visible
      if (mounted) {
        final motherInfoContext = _focusNodes['motherLastName']?.context;
        if (motherInfoContext != null && widget.scrollController != null) {
          Scrollable.ensureVisible(
            motherInfoContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.0, // Align to top
          );
        }
      }
    });
  }

  void _handleInitialScroll() {
    if (!mounted) return;

    // Ensure we're at the top
    if (widget.scrollController?.hasClients ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.scrollController?.jumpTo(0);
      });
    }
  }

  void _handleInitialFocus() {
    if (!mounted) return;

    // Check if we should auto-focus based on platform and screen size
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    // Only auto-focus on larger screens or when keyboard is already visible
    if (!isSmallScreen || isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusNodes['motherLastName']?.canRequestFocus ?? false) {
          _focusNodes['motherLastName']!.requestFocus();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-initialize focus when dependencies change (like screen size)
    _handleInitialFocus();
  }

  void _updateValidationStates() {
    // Strictly validate Primary Contact fields
    bool isPrimaryLastNameValid =
        (widget.formState.primaryLastName?.isNotEmpty ?? false) &&
            RegExp(r'^[a-zA-Z\s\-]+$')
                .hasMatch(widget.formState.primaryLastName ?? '');

    bool isPrimaryFirstNameValid =
        (widget.formState.primaryFirstName?.isNotEmpty ?? false) &&
            RegExp(r'^[a-zA-Z\s\-]+$')
                .hasMatch(widget.formState.primaryFirstName ?? '');

    bool isPrimaryContactValid = (widget.formState.primaryContact?.isNotEmpty ??
            false) &&
        RegExp(r'^\+?09\d{9}$').hasMatch(
            widget.formState.primaryContact?.replaceAll(RegExp(r'[\s-]'), '') ??
                '');

    // Update validation states
    widget.formState.validationStates['primaryLastName'] =
        isPrimaryLastNameValid;
    widget.formState.validationStates['primaryFirstName'] =
        isPrimaryFirstNameValid;
    widget.formState.validationStates['primaryContact'] = isPrimaryContactValid;

    // Mother and Father info are optional, so always mark as valid
    widget.formState.validationStates['motherLastName'] = true;
    widget.formState.validationStates['motherFirstName'] = true;
    widget.formState.validationStates['motherContact'] = true;
    widget.formState.validationStates['fatherLastName'] = true;
    widget.formState.validationStates['fatherFirstName'] = true;
    widget.formState.validationStates['fatherContact'] = true;
  }

  // Improved phone number validation and formatting
  bool _isValidPhoneNumber(String? number) {
    if (number == null || number.isEmpty) return false;

    // Remove any formatting characters
    String cleaned = number.replaceAll(RegExp(r'[\s\-]'), '');

    // Must start with 09 and be exactly 11 digits
    return RegExp(r'^09\d{9}$').hasMatch(cleaned);
  }

  // Enhanced phone number formatting
  String _formatPhoneNumber(String value) {
    // Remove all non-digit characters first
    String digits = value.replaceAll(RegExp(r'\D'), '');

    // If doesn't start with 0 and starts with 9, add 0
    if (!digits.startsWith('0') && digits.startsWith('9')) {
      digits = '0$digits';
    }

    // Limit to 11 digits
    digits = digits.substring(0, min(digits.length, 11));

    // Format as 0999-999-9999
    if (digits.length >= 4) {
      digits = digits.substring(0, 4) + '-' + digits.substring(4);
    }
    if (digits.length >= 8) {
      digits = digits.substring(0, 8) + '-' + digits.substring(8);
    }

    return digits;
  }

  // Enhanced copy functionality
  void _copyFromParent(String source) {
    setState(() {
      switch (source) {
        case 'mother':
          if (widget.formState.motherLastName?.isNotEmpty ?? false) {
            widget.formState.primaryLastName = widget.formState.motherLastName;
            widget.formState.primaryFirstName =
                widget.formState.motherFirstName;
            widget.formState.primaryMiddleName =
                widget.formState.motherMiddleName;
            widget.formState.primaryOccupation =
                widget.formState.motherOccupation;
            widget.formState.primaryContact = widget.formState.motherContact;
            widget.formState.primaryFacebook = widget.formState.motherFacebook;

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully copied mother\'s information to primary contact',
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Show error message if mother's info is empty
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Mother\'s information is empty',
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;

        case 'father':
          if (widget.formState.fatherLastName?.isNotEmpty ?? false) {
            widget.formState.primaryLastName = widget.formState.fatherLastName;
            widget.formState.primaryFirstName =
                widget.formState.fatherFirstName;
            widget.formState.primaryMiddleName =
                widget.formState.fatherMiddleName;
            widget.formState.primaryOccupation =
                widget.formState.fatherOccupation;
            widget.formState.primaryContact = widget.formState.fatherContact;
            widget.formState.primaryFacebook = widget.formState.fatherFacebook;

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully copied father\'s information to primary contact',
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Show error message if father's info is empty
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Father\'s information is empty',
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
      }

      // Update validation states after copying
      _updateValidationStates();
    });

    widget.onChanged();
  }

  void _scrollToField(String fieldKey) {
    // Cancel any pending validation
    _validationTimer?.cancel();

    final context = _focusNodes[fieldKey]?.context;
    if (context != null && widget.scrollController != null) {
      // Debounce the scroll
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

  bool validateAndScroll(BuildContext context) {
    // Prevent multiple simultaneous validations
    if (_isValidating) return false;
    _isValidating = true;

    // Cancel any pending validation
    _validationTimer?.cancel();

    setState(() {
      _hasAttemptedSubmit = true;
    });

    // Strictly validate Primary Contact fields
    bool isPrimaryLastNameValid =
        (widget.formState.primaryLastName?.isNotEmpty ?? false) &&
            RegExp(r'^[a-zA-Z\s\-]+$')
                .hasMatch(widget.formState.primaryLastName ?? '');

    bool isPrimaryFirstNameValid =
        (widget.formState.primaryFirstName?.isNotEmpty ?? false) &&
            RegExp(r'^[a-zA-Z\s\-]+$')
                .hasMatch(widget.formState.primaryFirstName ?? '');

    bool isPrimaryContactValid = (widget.formState.primaryContact?.isNotEmpty ??
            false) &&
        RegExp(r'^\+?09\d{9}$').hasMatch(
            widget.formState.primaryContact?.replaceAll(RegExp(r'[\s-]'), '') ??
                '');

    // Update validation states
    widget.formState.validationStates['primaryLastName'] =
        isPrimaryLastNameValid;
    widget.formState.validationStates['primaryFirstName'] =
        isPrimaryFirstNameValid;
    widget.formState.validationStates['primaryContact'] = isPrimaryContactValid;

    // All primary contact fields must be valid
    bool isPrimaryComplete = isPrimaryLastNameValid &&
        isPrimaryFirstNameValid &&
        isPrimaryContactValid;

    if (!isPrimaryComplete) {
      // Use post frame callback to show validation feedback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Find first invalid required field
        String? firstInvalidField;
        if (!isPrimaryLastNameValid) {
          firstInvalidField = 'primaryLastName';
        } else if (!isPrimaryFirstNameValid) {
          firstInvalidField = 'primaryFirstName';
        } else if (!isPrimaryContactValid) {
          firstInvalidField = 'primaryContact';
        }

        // Scroll to and focus the first invalid field
        if (firstInvalidField != null) {
          _scrollToField(firstInvalidField);
          _focusNodes[firstInvalidField]?.requestFocus();
        }

        // Show validation feedback
        if (mounted && context.mounted) {
          // Clear any existing snackbars
          ScaffoldMessenger.of(context).clearSnackBars();

          // Show snackbar with specific error message
          String errorMessage = 'Please complete Primary Contact Information: ';
          if (!isPrimaryLastNameValid) {
            errorMessage += 'Last Name';
          } else if (!isPrimaryFirstNameValid) {
            errorMessage += 'First Name';
          } else if (!isPrimaryContactValid) {
            errorMessage += 'Contact Number (09XX-XXX-XXXX)';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
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
        }
      });

      setState(() {
        _isValidating = false;
      });
      return false;
    }

    setState(() {
      _isValidating = false;
    });
    return true;
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSectionIcon(title),
                color: SMSTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Mother\'s Information':
        return Icons.person_2;
      case 'Father\'s Information':
        return Icons.person;
      case 'Primary Contact Information':
        return Icons.contact_phone;
      default:
        return Icons.person;
    }
  }

  Widget _buildResponsiveRow({
    required List<Widget> children,
    double spacing = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        if (isSmallScreen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: child,
                    ))
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(children.length, (index) {
            final child = children[index];
            final isLast = index == children.length - 1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : spacing),
                child: child,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCopyButtons({
    required String copyFromTitle,
    VoidCallback? onCopyFromMother,
    VoidCallback? onCopyFromFather,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return isSmallScreen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copyFromTitle,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onCopyFromMother != null)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: onCopyFromMother,
                            icon: Icon(Icons.person_2),
                            label: Text('Copy from Mother'),
                            style: TextButton.styleFrom(
                              foregroundColor: SMSTheme.primaryColor,
                            ),
                          ),
                        ),
                      if (onCopyFromMother != null && onCopyFromFather != null)
                        const SizedBox(width: 8),
                      if (onCopyFromFather != null)
                        Flexible(
                          child: TextButton.icon(
                            onPressed: onCopyFromFather,
                            icon: Icon(Icons.person),
                            label: Text('Copy from Father'),
                            style: TextButton.styleFrom(
                              foregroundColor: SMSTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Text(
                    copyFromTitle,
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (onCopyFromMother != null)
                    TextButton.icon(
                      onPressed: onCopyFromMother,
                      icon: Icon(Icons.person_2),
                      label: Text('Copy from Mother'),
                      style: TextButton.styleFrom(
                        foregroundColor: SMSTheme.primaryColor,
                      ),
                    ),
                  if (onCopyFromMother != null && onCopyFromFather != null)
                    const SizedBox(width: 8),
                  if (onCopyFromFather != null)
                    TextButton.icon(
                      onPressed: onCopyFromFather,
                      icon: Icon(Icons.person),
                      label: Text('Copy from Father'),
                      style: TextButton.styleFrom(
                        foregroundColor: SMSTheme.primaryColor,
                      ),
                    ),
                ],
              );
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool hasError = _fieldErrors[fieldKey] == true && _hasAttemptedSubmit;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        onChanged: (value) {
          onChanged(value);
          setState(() {
            _fieldErrors[fieldKey] = false;
          });
        },
        validator: validator,
        enabled: enabled,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(fontFamily: 'Poppins',
            color: hasError ? Colors.red : Colors.grey.shade700,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon ?? Icons.text_fields,
            color: SMSTheme.primaryColor,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SMSTheme.primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: widget.enabled ? Colors.white : Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildParentSection({
    required String title,
    required String lastNameValue,
    required String firstNameValue,
    required String middleNameValue,
    required String occupationValue,
    required String contactValue,
    required String facebookValue,
    required Function(String) onLastNameChanged,
    required Function(String) onFirstNameChanged,
    required Function(String) onMiddleNameChanged,
    required Function(String) onOccupationChanged,
    required Function(String) onContactChanged,
    required Function(String) onFacebookChanged,
    required String lastNameKey,
    required String firstNameKey,
    required String contactKey,
    required FocusNode lastNameFocusNode,
    required FocusNode firstNameFocusNode,
    required FocusNode contactFocusNode,
    String? copyFromTitle,
    VoidCallback? onCopyFromMother,
    VoidCallback? onCopyFromFather,
    bool isRequired = false,
    bool autofocus = false,
  }) {
    return _buildSectionContainer(
      title: title,
      children: [
        if (copyFromTitle != null) ...[
          _buildCopyButtons(
            copyFromTitle: copyFromTitle,
            onCopyFromMother: onCopyFromMother,
            onCopyFromFather: onCopyFromFather,
          ),
          const SizedBox(height: 16),
        ],
        _buildResponsiveRow(
          children: [
            _buildCustomTextField(
              label: 'Last Name',
              value: lastNameValue,
              onChanged: onLastNameChanged,
              validator: isRequired
                  ? (value) {
                      if (!widget.formState.validationStates[lastNameKey]!) {
                        return 'Last name is required';
                      }
                      if (value?.isNotEmpty ??
                          false &&
                              !RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value!)) {
                        return 'Please enter a valid last name';
                      }
                      return null;
                    }
                  : null,
              prefixIcon: Icons.person,
              focusNode: lastNameFocusNode,
              isRequired: isRequired,
              fieldKey: lastNameKey,
            ),
            _buildCustomTextField(
              label: 'First Name',
              value: firstNameValue,
              onChanged: onFirstNameChanged,
              validator: isRequired
                  ? (value) {
                      if (!widget.formState.validationStates[firstNameKey]!) {
                        return 'First name is required';
                      }
                      if (value?.isNotEmpty ??
                          false &&
                              !RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value!)) {
                        return 'Please enter a valid first name';
                      }
                      return null;
                    }
                  : null,
              prefixIcon: Icons.person_outline,
              focusNode: firstNameFocusNode,
              isRequired: isRequired,
              fieldKey: firstNameKey,
            ),
            _buildCustomTextField(
              label: 'Middle Name',
              value: middleNameValue,
              onChanged: onMiddleNameChanged,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
                    return 'Please enter a valid middle name';
                  }
                }
                return null;
              },
              prefixIcon: Icons.person_outline,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          children: [
            _buildCustomTextField(
              label: 'Occupation',
              value: occupationValue,
              onChanged: onOccupationChanged,
              prefixIcon: Icons.work,
            ),
            _buildCustomTextField(
              label: 'Contact Number',
              value: contactValue,
              onChanged: (value) {
                String formattedNumber = _formatPhoneNumber(value);
                onContactChanged(formattedNumber);
              },
              validator: isRequired
                  ? (value) {
                      if (!widget.formState.validationStates[contactKey]!) {
                        return 'Contact number is required';
                      }
                      if (value?.isNotEmpty ?? false) {
                        String cleanNumber =
                            value!.replaceAll(RegExp(r'[\s-]'), '');
                        if (!RegExp(r'^\+?09\d{9}$').hasMatch(cleanNumber)) {
                          return 'Please enter a valid 11-digit mobile number (09XX-XXX-XXXX)';
                        }
                      }
                      return null;
                    }
                  : null,
              prefixIcon: Icons.phone,
              focusNode: contactFocusNode,
              isRequired: isRequired,
              fieldKey: contactKey,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            _buildCustomTextField(
              label: 'Facebook Account',
              value: facebookValue,
              onChanged: onFacebookChanged,
              prefixIcon: Icons.facebook,
            ),
          ],
        ),
      ],
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
              isSmallScreen ? 12 : 24, // Horizontal padding
              12, // Top padding
              isSmallScreen ? 12 : 24, // Horizontal padding
              bottomPadding + 100 // Bottom padding + extra space for keyboard
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mother's Information Section
              Container(
                key: ValueKey('mother_info_section'),
                child: _buildParentSection(
                  title: 'Mother\'s Information (Optional)',
                  lastNameValue: widget.formState.motherLastName ?? '',
                  firstNameValue: widget.formState.motherFirstName ?? '',
                  middleNameValue: widget.formState.motherMiddleName ?? '',
                  occupationValue: widget.formState.motherOccupation ?? '',
                  contactValue: widget.formState.motherContact ?? '',
                  facebookValue: widget.formState.motherFacebook ?? '',
                  onLastNameChanged: (value) {
                    widget.formState.motherLastName = value;
                    widget.onChanged();
                  },
                  onFirstNameChanged: (value) {
                    widget.formState.motherFirstName = value;
                    widget.onChanged();
                  },
                  onMiddleNameChanged: (value) {
                    widget.formState.motherMiddleName = value;
                    widget.onChanged();
                  },
                  onOccupationChanged: (value) {
                    widget.formState.motherOccupation = value;
                    widget.onChanged();
                  },
                  onContactChanged: (value) {
                    String formattedNumber = _formatPhoneNumber(value);
                    widget.formState.motherContact = formattedNumber;
                    widget.onChanged();
                  },
                  onFacebookChanged: (value) {
                    widget.formState.motherFacebook = value;
                    widget.onChanged();
                  },
                  lastNameKey: 'motherLastName',
                  firstNameKey: 'motherFirstName',
                  contactKey: 'motherContact',
                  lastNameFocusNode: _focusNodes['motherLastName']!,
                  firstNameFocusNode: _focusNodes['motherFirstName']!,
                  contactFocusNode: _focusNodes['motherContact']!,
                  isRequired: false,
                  autofocus: !isSmallScreen,
                ),
              ),

              // Father's Information Section
              _buildParentSection(
                title: 'Father\'s Information (Optional)',
                lastNameValue: widget.formState.fatherLastName ?? '',
                firstNameValue: widget.formState.fatherFirstName ?? '',
                middleNameValue: widget.formState.fatherMiddleName ?? '',
                occupationValue: widget.formState.fatherOccupation ?? '',
                contactValue: widget.formState.fatherContact ?? '',
                facebookValue: widget.formState.fatherFacebook ?? '',
                onLastNameChanged: (value) {
                  widget.formState.fatherLastName = value;
                  widget.onChanged();
                },
                onFirstNameChanged: (value) {
                  widget.formState.fatherFirstName = value;
                  widget.onChanged();
                },
                onMiddleNameChanged: (value) {
                  widget.formState.fatherMiddleName = value;
                  widget.onChanged();
                },
                onOccupationChanged: (value) {
                  widget.formState.fatherOccupation = value;
                  widget.onChanged();
                },
                onContactChanged: (value) {
                  widget.formState.fatherContact = value;
                  widget.onChanged();
                },
                onFacebookChanged: (value) {
                  widget.formState.fatherFacebook = value;
                  widget.onChanged();
                },
                lastNameKey: 'fatherLastName',
                firstNameKey: 'fatherFirstName',
                contactKey: 'fatherContact',
                lastNameFocusNode: _focusNodes['fatherLastName']!,
                firstNameFocusNode: _focusNodes['fatherFirstName']!,
                contactFocusNode: _focusNodes['fatherContact']!,
                isRequired: false,
                autofocus: false,
              ),

              // Primary Contact Information Section
              _buildParentSection(
                title: 'Primary Contact Information (Required)',
                lastNameValue: widget.formState.primaryLastName ?? '',
                firstNameValue: widget.formState.primaryFirstName ?? '',
                middleNameValue: widget.formState.primaryMiddleName ?? '',
                occupationValue: widget.formState.primaryOccupation ?? '',
                contactValue: widget.formState.primaryContact ?? '',
                facebookValue: widget.formState.primaryFacebook ?? '',
                onLastNameChanged: (value) {
                  widget.formState.primaryLastName = value;
                  widget.onChanged();
                  _updateValidationStates();
                },
                onFirstNameChanged: (value) {
                  widget.formState.primaryFirstName = value;
                  widget.onChanged();
                  _updateValidationStates();
                },
                onMiddleNameChanged: (value) {
                  widget.formState.primaryMiddleName = value;
                  widget.onChanged();
                },
                onOccupationChanged: (value) {
                  widget.formState.primaryOccupation = value;
                  widget.onChanged();
                },
                onContactChanged: (value) {
                  String formattedNumber = _formatPhoneNumber(value);
                  widget.formState.primaryContact = formattedNumber;
                  widget.onChanged();
                  _updateValidationStates();
                },
                onFacebookChanged: (value) {
                  widget.formState.primaryFacebook = value;
                  widget.onChanged();
                },
                lastNameKey: 'primaryLastName',
                firstNameKey: 'primaryFirstName',
                contactKey: 'primaryContact',
                lastNameFocusNode: _focusNodes['primaryLastName']!,
                firstNameFocusNode: _focusNodes['primaryFirstName']!,
                contactFocusNode: _focusNodes['primaryContact']!,
                copyFromTitle: 'Quick Fill:',
                onCopyFromMother: () => _copyFromParent('mother'),
                onCopyFromFather: () => _copyFromParent('father'),
                isRequired: true,
                autofocus: false,
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
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}
