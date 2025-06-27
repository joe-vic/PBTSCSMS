import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/enrollment_payment_model.dart';
import '../../widgets/enrollment/enrollment_type_selector.dart';
import '../../widgets/enrollment/payment_plan_selector.dart';
import '../../widgets/enrollment/fee_calculator_widget.dart';
import '../../widgets/enrollment/payment_guidance_widget.dart';
import '../../widgets/enrollment/payment_form_widget.dart';
import '../../widgets/enrollment/fee_adjustment_widget.dart';
import '../../config/theme.dart';

/// A wizard-style screen for the enrollment payment process
class PaymentWizardScreen extends StatefulWidget {
  final String studentId;
  final String? enrollmentId;
  final Map<String, dynamic> studentInfo;
  final Map<String, dynamic> parentInfo;
  final List<Map<String, dynamic>>? additionalContacts;
  final String gradeLevel;
  final bool isEditing;

  const PaymentWizardScreen({
    Key? key,
    required this.studentId,
    this.enrollmentId,
    required this.studentInfo,
    required this.parentInfo,
    this.additionalContacts,
    required this.gradeLevel,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _PaymentWizardScreenState createState() => _PaymentWizardScreenState();
}

class _PaymentWizardScreenState extends State<PaymentWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  final EnrollmentPaymentService _enrollmentService = EnrollmentPaymentService();
  
  // Steps in the wizard
  final List<String> _steps = [
    'Enrollment Type',
    'Payment Plan',
    'Fee Adjustments',
    'Payment Details',
    'Review & Submit'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize provider with student grade level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EnrollmentPaymentProvider>(context, listen: false);
      provider.setGradeLevel(widget.gradeLevel);
      
      // If editing, load existing enrollment data
      if (widget.isEditing && widget.enrollmentId != null) {
        _loadExistingEnrollment();
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  /// Load data from an existing enrollment for editing
  Future<void> _loadExistingEnrollment() async {
    if (widget.enrollmentId == null) return;
    
    try {
      final enrollment = await _enrollmentService.getEnrollmentById(widget.enrollmentId!);
      if (enrollment != null) {
        final provider = Provider.of<EnrollmentPaymentProvider>(context, listen: false);
        
        // Load enrollment data into provider
        // You would need to add a method to your provider to handle this
        // For example:
        // provider.loadFromEnrollment(enrollment.toJson());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Go to next step in the wizard
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// Go to previous step in the wizard
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// Handle form submission
  Future<void> _submitEnrollment() async {
    final provider = Provider.of<EnrollmentPaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Validate payment amount
    if (!provider.isValidPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.paymentValidationMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final cashierId = authProvider.user?.uid ?? '';
      final cashierName = authProvider.user?.displayName ?? 'Cashier';
      
      // Prepare data for Firestore
      final enrollmentData = provider.toFirestoreData(
        studentId: widget.studentId,
        cashierId: cashierId,
        cashierName: cashierName,
      );
      
      // Add student info from previous steps
      enrollmentData['studentInfo'] = widget.studentInfo;
      enrollmentData['parentInfo'] = widget.parentInfo;
      enrollmentData['additionalContacts'] = widget.additionalContacts;
      
      if (widget.isEditing && widget.enrollmentId != null) {
        // Update existing enrollment
        final enrollment = EnrollmentPayment(
          id: widget.enrollmentId!,
          studentId: widget.studentId,
          enrollmentType: enrollmentData['enrollmentType'],
          paymentPlan: enrollmentData['paymentPlan'],
          status: enrollmentData['status'],
          paymentStatus: enrollmentData['paymentStatus'],
          paymentMethod: enrollmentData['paymentMethod'],
          hasScholarship: enrollmentData['hasScholarship'],
          scholarshipType: enrollmentData['scholarshipType'],
          scholarshipPercentage: enrollmentData['scholarshipPercentage'],
          discountType: enrollmentData['discountType'],
          discountAmount: enrollmentData['discountAmount'],
          baseFee: enrollmentData['baseFee'],
          idFee: enrollmentData['idFee'],
          systemFee: enrollmentData['systemFee'],
          bookFee: enrollmentData['bookFee'],
          otherFees: enrollmentData['otherFees'],
          totalFee: enrollmentData['totalFee'],
          initialPaymentAmount: enrollmentData['initialPaymentAmount'],
          balanceRemaining: enrollmentData['balanceRemaining'],
          minimumPayment: enrollmentData['minimumPayment'],
          academicYear: enrollmentData['academicYear'],
          gradeLevel: enrollmentData['gradeLevel'],
          isVoucherBeneficiary: enrollmentData['isVoucherBeneficiary'],
          semesterType: enrollmentData['semesterType'],
          paymentOverride: enrollmentData['paymentOverride'],
          overrideReason: enrollmentData['overrideReason'],
          overrideBy: enrollmentData['overrideBy'],
          createdAt: DateTime.parse(enrollmentData['createdAt'].toString()),
          updatedAt: DateTime.now(),
          cashierId: cashierId,
          cashierName: cashierName,
          studentInfo: enrollmentData['studentInfo'],
          parentInfo: enrollmentData['parentInfo'],
          additionalContacts: enrollmentData['additionalContacts'],
        );
        
        await _enrollmentService.updateEnrollment(enrollment);
        _showSuccessDialog('Enrollment updated successfully');
      } else {
        // Create new enrollment
        final enrollmentId = await _enrollmentService.addEnrollment(
          EnrollmentPayment(
            id: '', // Will be set by Firestore
            studentId: widget.studentId,
            enrollmentType: enrollmentData['enrollmentType'],
            paymentPlan: enrollmentData['paymentPlan'],
            status: enrollmentData['status'],
            paymentStatus: enrollmentData['paymentStatus'],
            paymentMethod: enrollmentData['paymentMethod'],
            hasScholarship: enrollmentData['hasScholarship'],
            scholarshipType: enrollmentData['scholarshipType'],
            scholarshipPercentage: enrollmentData['scholarshipPercentage'],
            discountType: enrollmentData['discountType'],
            discountAmount: enrollmentData['discountAmount'],
            baseFee: enrollmentData['baseFee'],
            idFee: enrollmentData['idFee'],
            systemFee: enrollmentData['systemFee'],
            bookFee: enrollmentData['bookFee'],
            otherFees: enrollmentData['otherFees'],
            totalFee: enrollmentData['totalFee'],
            initialPaymentAmount: enrollmentData['initialPaymentAmount'],
            balanceRemaining: enrollmentData['balanceRemaining'],
            minimumPayment: enrollmentData['minimumPayment'],
            academicYear: enrollmentData['academicYear'],
            gradeLevel: enrollmentData['gradeLevel'],
            isVoucherBeneficiary: enrollmentData['isVoucherBeneficiary'],
            semesterType: enrollmentData['semesterType'],
            paymentOverride: enrollmentData['paymentOverride'],
            overrideReason: enrollmentData['overrideReason'],
            overrideBy: enrollmentData['overrideBy'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            cashierId: cashierId,
            cashierName: cashierName,
            studentInfo: enrollmentData['studentInfo'],
            parentInfo: enrollmentData['parentInfo'],
            additionalContacts: enrollmentData['additionalContacts'],
          ),
        );
        
        // Record payment if amount > 0
        if (provider.initialPaymentAmount > 0) {
          // Here you would add code to record payment in a separate collection
          // This would typically involve another service class for payment records
        }
        
        _showSuccessDialog('Enrollment submitted successfully');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  /// Show success dialog and navigate back
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Success', style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontFamily: 'Poppins',),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: SMSTheme.primaryColor),
            child: Text('OK', style: TextStyle(fontFamily: 'Poppins',color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Enrollment Payment' : 'New Enrollment Payment',
          style: TextStyle(fontFamily: 'Poppins',),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Steps indicator
                Row(
                  children: List.generate(_steps.length, (index) {
                    final isActive = index <= _currentStep;
                    final isCompleted = index < _currentStep;
                    
                    return Expanded(
                      child: Row(
                        children: [
                          // Step circle
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isActive ? SMSTheme.primaryColor : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                ? Icon(Icons.check, color: Colors.white, size: 16)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                            ),
                          ),
                          
                          // Connector line (except for last step)
                          if (index < _steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isCompleted ? SMSTheme.primaryColor : Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                
                // Step labels
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    
                    return Expanded(
                      child: Text(
                        step,
                        textAlign: index == 0 
                            ? TextAlign.start 
                            : (index == _steps.length - 1 ? TextAlign.end : TextAlign.center),
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 12,
                          color: index <= _currentStep ? SMSTheme.primaryColor : Colors.grey.shade600,
                          fontWeight: index == _currentStep ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                // Step 1: Enrollment Type
                _buildStep(
                  title: 'Select Enrollment Type',
                  description: 'Choose the type of enrollment that best fits the student\'s situation',
                  content: const EnrollmentTypeSelector(),
                ),
                
                // Step 2: Payment Plan
                _buildStep(
                  title: 'Choose Payment Plan',
                  description: 'Select how the student will pay the tuition fees',
                  content: const PaymentPlanSelector(),
                ),
                
                // Step 3: Fee Adjustments
                _buildStep(
                  title: 'Fee Adjustments',
                  description: 'Apply scholarships or discounts if applicable',
                  content: const FeeAdjustmentWidget(),
                ),
                
                // Step 4: Payment Details
                _buildStep(
                  title: 'Payment Details',
                  description: 'Enter payment information and enrollment status',
                  content: const PaymentFormWidget(),
                ),
                
                // Step 5: Review & Submit
                _buildStep(
                  title: 'Review & Submit',
                  description: 'Verify all information before submitting',
                  content: _buildReviewStep(),
                ),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Previous', style: TextStyle(fontFamily: 'Poppins',)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_currentStep < _steps.length - 1 ? _nextStep : _submitEnrollment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SMSTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentStep < _steps.length - 1 ? 'Continue' : 'Submit Enrollment',
                            style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a step container with consistent styling
  Widget _buildStep({
    required String title,
    required String description,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          Text(
            description,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }
  
  /// Build the review step with summary of all selections
  Widget _buildReviewStep() {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    return Column(
      children: [
        // Payment summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Summary',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.primaryColor,
                ),
              ),
              const Divider(height: 24),
              
              // Student information
              _buildReviewItem(
                label: 'Student',
                value: '${widget.studentInfo['lastName']}, ${widget.studentInfo['firstName']}',
                icon: Icons.person,
              ),
              _buildReviewItem(
                label: 'Grade Level',
                value: widget.gradeLevel,
                icon: Icons.school,
              ),
              
              const Divider(height: 24),
              
              // Enrollment details
              _buildReviewItem(
                label: 'Enrollment Type',
                value: provider.enrollmentType.label,
                icon: Icons.how_to_reg,
              ),
              _buildReviewItem(
                label: 'Payment Plan',
                value: provider.paymentPlan.label,
                icon: Icons.payment,
              ),
              if (provider.hasScholarship)
                _buildReviewItem(
                  label: 'Scholarship',
                  value: '${provider.scholarshipType.label} (${provider.scholarshipPercentage}%)',
                  icon: Icons.school,
                ),
              if (provider.discountType != DiscountType.none)
                _buildReviewItem(
                  label: 'Discount',
                  value: '${provider.discountType.label} (${currencyFormat.format(provider.discountAmount)})',
                  icon: Icons.discount,
                ),
              
              const Divider(height: 24),
              
              // Fee details
              _buildReviewItem(
                label: 'Total Fee',
                value: currencyFormat.format(provider.totalFee),
                icon: Icons.summarize,
                valueColor: SMSTheme.primaryColor,
                isBold: true,
              ),
              _buildReviewItem(
                label: 'Initial Payment',
                value: currencyFormat.format(provider.initialPaymentAmount),
                icon: Icons.payments,
              ),
              _buildReviewItem(
                label: 'Balance',
                value: currencyFormat.format(provider.balanceRemaining),
                icon: Icons.account_balance_wallet,
                valueColor: provider.balanceRemaining > 0 ? Colors.orange.shade700 : Colors.green.shade700,
              ),
              
              const Divider(height: 24),
              
              // Status information
              _buildReviewItem(
                label: 'Enrollment Status',
                value: provider.enrollmentStatus.label,
                icon: Icons.check_circle,
                valueColor: _getStatusColor(provider.enrollmentStatus.label),
              ),
              _buildReviewItem(
                label: 'Payment Status',
                value: provider.paymentStatus.label,
                icon: Icons.receipt_long,
                valueColor: _getStatusColor(provider.paymentStatus.label),
              ),
              
              // Payment override info (if applicable)
              if (provider.paymentOverride) ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Override Applied',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${provider.overrideReason}',
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Fee calculator and payment guidance for reference
        const FeeCalculatorWidget(),
        const SizedBox(height: 16),
        const PaymentGuidanceWidget(),
      ],
    );
  }
  
  /// Build a review item with consistent styling
  Widget _buildReviewItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: SMSTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? SMSTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get appropriate color for status text
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'paid':
      case 'fully paid':
        return Colors.green.shade700;
      case 'pending':
      case 'partial':
      case 'partially paid':
        return Colors.orange.shade700;
      case 'rejected':
      case 'unpaid':
        return Colors.red.shade600;
      default:
        return SMSTheme.textPrimaryColor;
    }
  }
}