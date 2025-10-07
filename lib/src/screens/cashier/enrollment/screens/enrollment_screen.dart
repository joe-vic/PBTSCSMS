import 'package:flutter/material.dart';
import '../models/enrollment_form_state.dart';
import '../services/enrollment_service.dart';
import '../services/billing_service.dart';
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
  late BillingService _billingService;
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isValidating = false;
  bool _isInitializing = true;
  bool _isFontLoaded = false;
  
  final GlobalKey<StudentInfoFormState> _studentInfoFormKey =
      GlobalKey<StudentInfoFormState>();
  final GlobalKey<ParentInfoFormState> _parentInfoFormKey =
      GlobalKey<ParentInfoFormState>();

  // Step configuration
  final List<StepConfig> _stepConfigs = [
    StepConfig(
      title: 'Student Info',
      shortTitle: 'Student',
      icon: Icons.person,
      description: 'Personal information',
    ),
    StepConfig(
      title: 'Parent Info',
      shortTitle: 'Parent',
      icon: Icons.family_restroom,
      description: 'Guardian details',
    ),
    StepConfig(
      title: 'Academic',
      shortTitle: 'Academic',
      icon: Icons.school,
      description: 'Grade and course',
    ),
    StepConfig(
      title: 'Payment',
      shortTitle: 'Payment',
      icon: Icons.payment,
      description: 'Fee structure',
    ),
  ];

  // Cache the text styles
  late TextStyle _titleStyle;
  late TextStyle _stepTitleStyle;
  late TextStyle _buttonTextStyle;

  @override
  void initState() {
    super.initState();
    _formState = EnrollmentFormState();
    _enrollmentService = EnrollmentService();
    _billingService = BillingService();
    
    // Initialize without causing setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    try {
      // Initialize text styles
      _titleStyle = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );
      _buttonTextStyle = TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 14,
      );
      _stepTitleStyle = TextStyle(
        fontFamily: 'Poppins',
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
          _isFontLoaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: Text('New Enrollment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing enrollment system...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isWideScreen = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Enrollment',
          style: _titleStyle,
        ),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 900 : double.infinity,
                ),
                child: Column(
                  children: [
                    // Custom Step Indicator
                    _buildCustomStepIndicator(isSmallScreen),
                    
                    // Form Content
                    Expanded(
                      child: _buildCurrentForm(),
                    ),
                    
                    // Navigation Controls
                    _buildNavigationControls(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomStepIndicator(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isSmallScreen 
          ? _buildVerticalStepIndicator()
          : _buildHorizontalStepIndicator(),
    );
  }

  Widget _buildHorizontalStepIndicator() {
    return Row(
      children: List.generate(_stepConfigs.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        final isClickable = index <= _currentStep;
        
        return Expanded(
          child: GestureDetector(
            onTap: isClickable && !_isProcessing ? () => _jumpToStep(index) : null,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isActive 
                    ? Theme.of(context).primaryColor 
                    : isCompleted 
                        ? Colors.green 
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive 
                      ? Theme.of(context).primaryColor 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _stepConfigs[index].icon,
                    color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${index + 1}. ${_stepConfigs[index].shortTitle}',
                    style: TextStyle(
                      color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isActive && !isCompleted) ...[
                    SizedBox(height: 2),
                    Text(
                      _stepConfigs[index].description,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerticalStepIndicator() {
    return Row(
      children: List.generate(_stepConfigs.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isActive 
                  ? Theme.of(context).primaryColor 
                  : isCompleted 
                      ? Colors.green 
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _stepConfigs[index].icon,
                  color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                  size: 16,
                ),
                SizedBox(height: 2),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentForm() {
    switch (_currentStep) {
      case 0:
        return StudentInfoForm(
          key: _studentInfoFormKey,
          formState: _formState,
          onChanged: _safeOnChanged,
          enabled: !_isProcessing,
        );
      case 1:
        return ParentInfoForm(
          key: _parentInfoFormKey,
          formState: _formState,
          onChanged: _safeOnChanged,
          enabled: !_isProcessing,
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: AcademicInfoForm(
            formState: _formState,
            onChanged: _safeOnChanged,
          ),
        );
      case 3:
        return Form(
          key: _formKeys[3],
          child: PaymentInfoForm(
            formState: _formState,
            onChanged: _safeOnChanged,
          ),
        );
      default:
        return Container(
          child: Center(
            child: Text('Invalid step'),
          ),
        );
    }
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_isProcessing || _isValidating) ? null : _handleBack,
                icon: Icon(Icons.arrow_back, size: 18),
                label: Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_isProcessing || _isValidating) ? null : _handleNext,
              icon: _isProcessing || _isValidating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      _currentStep == _stepConfigs.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      size: 18,
                    ),
              label: Text(
                _currentStep == _stepConfigs.length - 1
                    ? 'Submit Enrollment'
                    : 'Continue',
                style: _buttonTextStyle,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: _currentStep == _stepConfigs.length - 1
                    ? Colors.green
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _safeOnChanged() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _jumpToStep(int step) {
    if (step == _currentStep) return;
    
    setState(() {
      _currentStep = step;
      _isValidating = false;
    });
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isValidating = false;
      });
    }
  }

  void _handleNext() {
    if (_validateCurrentStep()) {
      if (_currentStep < _stepConfigs.length - 1) {
        setState(() {
          _currentStep++;
          _isValidating = false;
        });
      } else {
        _handleSubmit();
      }
    }
  }

  bool _validateCurrentStep() {
    bool isValid = false;
    
    try {
      switch (_currentStep) {
        case 0: // Student Info
          final studentFormState = _studentInfoFormKey.currentState;
          if (studentFormState == null) return false;
          
          isValid = studentFormState.validateAndScroll(context);
          
          if (isValid && (_formState.streetAddress?.isEmpty ?? true)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showErrorMessage('Please fill in the Street Address field');
              }
            });
            isValid = false;
          }
          break;

        case 1: // Parent Info
          final parentFormState = _parentInfoFormKey.currentState;
          if (parentFormState == null) return false;
          isValid = parentFormState.validateAndScroll(context);
          break;

        case 2: // Academic Info
          final academicFormState = _formKeys[2].currentState;
          if (academicFormState == null) return false;
          
          isValid = academicFormState.validate();
          
          if (isValid) {
            if (_formState.gradeLevel == null || _formState.gradeLevel!.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showErrorMessage('Please select a grade level');
                }
              });
              isValid = false;
            } else if (_formState.branch == null || _formState.branch!.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showErrorMessage('Please select a branch');
                }
              });
              isValid = false;
            } else if (_formState.academicYear == null || _formState.academicYear!.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showErrorMessage('Please select an academic year');
                }
              });
              isValid = false;
            }
          }
          break;

        case 3: // Payment Info
          final paymentFormState = _formKeys[3].currentState;
          if (paymentFormState == null) return false;
          isValid = paymentFormState.validate();
          
          if (isValid) {
            if (_formState.calculatedTotalAmountDue <= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showErrorMessage('Please configure the fee amounts');
                }
              });
              isValid = false;
            } else if (_formState.initialPaymentAmount < 
                      _formState.getMinimumPayment(_formState.calculatedTotalAmountDue)) {
              final minAmount = _formState.getMinimumPayment(_formState.calculatedTotalAmountDue);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showErrorMessage(
                    'Minimum payment of ₱${minAmount.toStringAsFixed(0)} required for ${_formState.paymentScheme}'
                  );
                }
              });
              isValid = false;
            }
          }
          break;
      }
    } catch (e) {
      print('Validation error: $e');
      isValid = false;
    }

    if (!isValid && !_isValidating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isValidating = true);
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => _isValidating = false);
            }
          });
        }
      });
    }

    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (_isProcessing) return;

    final isValid = _validateCurrentStep();
    if (!isValid) return;

    setState(() => _isProcessing = true);

    try {
      _showProgressDialog();

      final studentId = await _enrollmentService.submitEnrollment(_formState);

      if (mounted) {
        Navigator.of(context).pop();
      }

      String successMessage = 'Enrollment submitted successfully!\n\n';
      successMessage += '🎓 Student ID: $studentId\n';
      successMessage += '💰 Total Amount: ₱${_formState.calculatedTotalAmountDue.toStringAsFixed(2)}\n';
      
      if (_formState.initialPaymentAmount > 0) {
        successMessage += '💳 Initial Payment: ₱${_formState.initialPaymentAmount.toStringAsFixed(2)}\n';
        successMessage += '🧾 Official Receipt: OR-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}\n';
        
        final balance = _formState.balance;
        if (balance > 0) {
          successMessage += '⚖️ Remaining Balance: ₱${balance.toStringAsFixed(2)}';
        } else {
          successMessage += '✅ Payment Complete - No remaining balance';
        }
      } else {
        successMessage += '📋 Payment pending - Please proceed to cashier';
      }

      if (mounted) {
        _showSuccessDialog(studentId, successMessage);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Enrollment submission error: $e');
      
      if (mounted) {
        String errorMessage = 'Failed to submit enrollment.';
        
        if (e.toString().contains('billing')) {
          errorMessage = 'Enrollment created but billing setup failed. Please contact administration.';
        } else if (e.toString().contains('payment')) {
          errorMessage = 'Enrollment created but initial payment recording failed. Please contact administration.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Access denied. Please check your permissions.';
        }

        _showErrorDialog(errorMessage, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing Enrollment...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Creating student record and billing information',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String studentId, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enrollment Successful!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'What\'s next?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Student record has been created\n'
                    '• Billing information is set up\n'
                    '• Student can now access school services\n'
                    '• Payment schedule is available in student portal',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(studentId);
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message, String details) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enrollment Error',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ),
                if (details.isNotEmpty) ...[
                  SizedBox(height: 12),
                  ExpansionTile(
                    title: Text(
                      'Technical Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          details,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Step configuration class
class StepConfig {
  final String title;
  final String shortTitle;
  final IconData icon;
  final String description;

  StepConfig({
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.description,
  });
}