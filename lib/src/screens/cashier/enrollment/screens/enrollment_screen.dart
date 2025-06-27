import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../models/enrollment_form_state.dart';
import '../services/enrollment_service.dart';
import '../widgets/student_info_form.dart';
import '../widgets/parent_info_form.dart';
import '../widgets/academic_info_form.dart';
import '../widgets/payment_info_form.dart';

class CashierEnrollmentScreenImpl extends StatefulWidget {
  const CashierEnrollmentScreenImpl({Key? key}) : super(key: key);

  @override
  _CashierEnrollmentScreenImplState createState() =>
      _CashierEnrollmentScreenImplState();
}

class _CashierEnrollmentScreenImplState
    extends State<CashierEnrollmentScreenImpl> {
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late EnrollmentFormState _formState;
  late EnrollmentService _enrollmentService;
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isValidating = false;
  bool _isInitializing = true;
  bool _isFontLoaded = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<StudentInfoFormState> _studentInfoFormKey =
      GlobalKey<StudentInfoFormState>();
  final GlobalKey<ParentInfoFormState> _parentInfoFormKey =
      GlobalKey<ParentInfoFormState>();
  final GlobalKey<FormState> _academicInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _paymentInfoFormKey = GlobalKey<FormState>();

  // Cache the text styles
  late TextStyle _titleStyle;
  late TextStyle _stepTitleStyle;
  late TextStyle _buttonTextStyle;

  @override
  void initState() {
    super.initState();
    _formState = EnrollmentFormState();
    _enrollmentService = EnrollmentService();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      // Initialize text styles with a fallback
      _titleStyle = TextStyle(fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );
      _buttonTextStyle = TextStyle(fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );
      _stepTitleStyle = TextStyle(fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

      // Initialize enrollment service
      await _enrollmentService.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isFontLoaded = true;
        });
      }
    } catch (e) {
      print('Error initializing enrollment screen: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          // Even if font loading fails, we'll use system fonts
          _isFontLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Step> get _enrollmentSteps => [
        Step(
          title: Text('Student Info', style: _getStepTitleStyle()),
          content: StudentInfoForm(
            key: _studentInfoFormKey,
            formState: _formState,
            onChanged: () => setState(() {}),
            enabled: !_isProcessing,
            scrollController: _scrollController,
          ),
          isActive: _currentStep >= 0,
          state: _getStepState(0),
        ),
        Step(
          title: Text('Parent Info', style: _getStepTitleStyle()),
          content: ParentInfoForm(
            key: _parentInfoFormKey,
            formState: _formState,
            onChanged: () => setState(() {}),
            enabled: !_isProcessing,
            scrollController: _scrollController,
          ),
          isActive: _currentStep >= 1,
          state: _getStepState(1),
        ),
        Step(
          title: Text('Academic', style: _getStepTitleStyle()),
          content: AcademicInfoForm(
            key: _academicInfoFormKey,
            formState: _formState,
            onChanged: () => setState(() {}),
          ),
          isActive: _currentStep >= 2,
          state: _getStepState(2),
        ),
        Step(
          title: Text('Payment', style: _getStepTitleStyle()),
          content: PaymentInfoForm(
            key: _paymentInfoFormKey,
            formState: _formState,
            onChanged: () => setState(() {}),
          ),
          isActive: _currentStep >= 3,
          state: _getStepState(3),
        ),
      ];

  TextStyle _getStepTitleStyle() {
    if (!_isFontLoaded) {
      // Fallback to system font if Google Fonts failed to load
      return TextStyle(
        fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
        fontWeight: FontWeight.w500,
      );
    }
    return _stepTitleStyle;
  }

  StepState _getStepState(int step) {
    if (_currentStep > step) {
      return StepState.complete;
    } else if (_currentStep == step) {
      // Only show error state if validation was explicitly attempted
      if (!_isValidating) {
        return StepState.indexed;
      }

      switch (step) {
        case 0:
          final studentFormState = _studentInfoFormKey.currentState;
          if (studentFormState == null) return StepState.indexed;
          // Don't call validateAndScroll here, just check the validation state
          final isValid = studentFormState.validateAndScroll(context);
          return isValid ? StepState.indexed : StepState.error;
        case 1:
          final parentFormState = _parentInfoFormKey.currentState;
          if (parentFormState == null) return StepState.indexed;
          // Don't call validateAndScroll here, just check the validation state
          final isValid = parentFormState.validateAndScroll(context);
          return isValid ? StepState.indexed : StepState.error;
        default:
          final formState = _formKeys[step].currentState;
          if (formState == null) return StepState.indexed;
          return formState.validate() ? StepState.indexed : StepState.error;
      }
    }
    return StepState.indexed;
  }

  bool _validateCurrentStep() {
    setState(() => _isValidating = true);

    bool isValid = false;
    try {
      switch (_currentStep) {
        case 0: // Student Info
          final studentFormState = _studentInfoFormKey.currentState;
          if (studentFormState == null) return false;

          // Validate student form and check all required fields
          isValid = studentFormState.validateAndScroll(context);

          // Check if street address is filled
          if (isValid && (_formState.streetAddress?.isEmpty ?? true)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please fill in the Street Address field',
                  style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            isValid = false;
          }
          break;

        case 1: // Parent Info
          final parentFormState = _parentInfoFormKey.currentState;
          if (parentFormState == null) return false;
          isValid = parentFormState.validateAndScroll(context);
          break;

        case 2: // Academic Info
          final academicFormState = _academicInfoFormKey.currentState;
          if (academicFormState == null) return false;
          isValid = academicFormState.validate();
          break;

        case 3: // Payment Info
          final paymentFormState = _paymentInfoFormKey.currentState;
          if (paymentFormState == null) return false;
          isValid = paymentFormState.validate();
          break;

        default:
          isValid = false;
          break;
      }
    } finally {
      // Reset validation state after a delay only if validation failed
      if (!isValid) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _isValidating = false);
          }
        });
      }
    }

    return isValid;
  }

  void _handleNext() {
    if (_validateCurrentStep()) {
      setState(() {
        if (_currentStep < 3) {
          _currentStep++;
          // Reset validation state when moving to next step
          _isValidating = false;
        } else {
          _handleSubmit();
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isProcessing) return;

    final isValid = await _validateCurrentStep();
    if (!isValid) return;

    setState(() => _isProcessing = true);

    try {
      final enrollmentId =
          await _enrollmentService.submitEnrollment(_formState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enrollment submitted successfully!',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context, enrollmentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit enrollment: $e',
              style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Enrollment',
          style: _titleStyle,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 900;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 900 : double.infinity,
                ),
                child: Stepper(
                  type: isSmallScreen ? StepperType.vertical : StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepContinue: (_isProcessing || _isValidating) ? null : _handleNext,
                  onStepCancel: (_isProcessing || _isValidating)
                      ? null
                      : () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          }
                        },
                  onStepTapped: (_isProcessing || _isValidating)
                      ? null
                      : (step) async {
                          // Only allow tapping on previous steps if they're valid
                          if (step < _currentStep) {
                            setState(() => _currentStep = step);
                          } else if (step > _currentStep) {
                            // Validate all steps up to the target step
                            for (var i = _currentStep; i < step; i++) {
                              final isValid =
                                  _formKeys[i].currentState?.validate() ?? false;
                              if (!isValid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please complete step ${i + 1} first',
                                      style: _buttonTextStyle,
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                            setState(() => _currentStep = step);
                          }
                        },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: (_isProcessing || _isValidating)
                                    ? null
                                    : details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: _buttonTextStyle,
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isProcessing || _isValidating)
                                  ? null
                                  : details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isProcessing || _isValidating
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _currentStep == _enrollmentSteps.length - 1
                                          ? 'Submit'
                                          : 'Continue',
                                      style: _buttonTextStyle,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: _enrollmentSteps,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
