import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import '../../providers/auth_provider.dart' as app_auth;
import '../../config/theme.dart';
import '../student/StudentDashboard.dart';

// ==================== ERROR HANDLING SYSTEM ====================

enum RegistrationErrorType {
  network,
  weakPassword,
  emailInUse,
  invalidEmail,
  operationNotAllowed,
  tooManyRequests,
  userDisabled,
  emailNotSent,
  firestoreError,
  googleSignInCancelled,
  googleSignInFailed,
  userNotFound,
  unknown
}

class RegistrationException implements Exception {
  final RegistrationErrorType type;
  final String message;
  final String userMessage;
  final bool allowRetry;
  final dynamic originalError;

  RegistrationException({
    required this.type,
    required this.message,
    required this.userMessage,
    this.allowRetry = false,
    this.originalError,
  });
}

// ==================== ERROR HANDLER SERVICE ====================

class StudentRegistrationErrorHandler {
  static RegistrationException handleFirebaseAuthError(FirebaseAuthException e) {
    developer.log('Firebase Auth Error: ${e.code} - ${e.message}', name: 'StudentRegistration');
    
    switch (e.code) {
      case 'weak-password':
        return RegistrationException(
          type: RegistrationErrorType.weakPassword,
          message: 'Weak password provided',
          userMessage: 'Please choose a stronger password with at least 6 characters.',
        );
      
      case 'email-already-in-use':
        return RegistrationException(
          type: RegistrationErrorType.emailInUse,
          message: 'Email already in use',
          userMessage: 'An account with this email already exists. Please try signing in instead.',
        );
      
      case 'invalid-email':
        return RegistrationException(
          type: RegistrationErrorType.invalidEmail,
          message: 'Invalid email format',
          userMessage: 'Please enter a valid email address.',
        );
      
      case 'operation-not-allowed':
        return RegistrationException(
          type: RegistrationErrorType.operationNotAllowed,
          message: 'Email/password accounts are not enabled',
          userMessage: 'Email registration is currently disabled. Please contact support.',
        );
      
      case 'too-many-requests':
        return RegistrationException(
          type: RegistrationErrorType.tooManyRequests,
          message: 'Too many requests',
          userMessage: 'Too many attempts. Please wait a few minutes before trying again.',
          allowRetry: true,
        );
      
      case 'user-disabled':
        return RegistrationException(
          type: RegistrationErrorType.userDisabled,
          message: 'User account has been disabled',
          userMessage: 'This account has been disabled. Please contact support.',
        );
      
      default:
        return RegistrationException(
          type: RegistrationErrorType.unknown,
          message: 'Unknown Firebase Auth error: ${e.code}',
          userMessage: 'An unexpected error occurred. Please try again.',
          allowRetry: true,
          originalError: e,
        );
    }
  }

  static RegistrationException handleNetworkError() {
    return RegistrationException(
      type: RegistrationErrorType.network,
      message: 'No internet connection',
      userMessage: 'Please check your internet connection and try again.',
      allowRetry: true,
    );
  }

  static RegistrationException handleFirestoreError(dynamic e) {
    developer.log('Firestore Error: $e', name: 'StudentRegistration');
    
    return RegistrationException(
      type: RegistrationErrorType.firestoreError,
      message: 'Failed to save student data to Firestore',
      userMessage: 'Your account was created but we couldn\'t save your profile. Please contact support.',
      originalError: e,
    );
  }

  static RegistrationException handleGoogleSignInError(dynamic e) {
    developer.log('Google Sign-In Error: $e', name: 'StudentRegistration');
    
    return RegistrationException(
      type: RegistrationErrorType.googleSignInFailed,
      message: 'Google sign-in failed',
      userMessage: 'Google sign-in failed. Please try again or use email registration.',
      allowRetry: true,
      originalError: e,
    );
  }
}

// ==================== VALIDATION SERVICE ====================

class StudentInputValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

// ==================== NETWORK SERVICE ====================

class NetworkService {
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket');
  }
}

// ==================== MAIN STUDENT REGISTRATION SCREEN ====================

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State Variables
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Services
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ==================== LIFECYCLE METHODS ====================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==================== ERROR HANDLING UI ====================

  Future<bool> _showErrorDialog(RegistrationException error) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Registration Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage),
            if (error.allowRetry) ...[
              const SizedBox(height: 16),
              const Text(
                'Would you like to try again?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        actions: [
          if (error.allowRetry)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(error.allowRetry ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
    
    return shouldRetry ?? false;
  }

  Future<void> _showEmailVerificationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.mark_email_unread,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Verify Your Email'),
          ],
        ),
        content: Text(
          'A verification email has been sent to ${_emailController.text}. '
          'Please check your inbox (and spam folder) and click the verification link to activate your student account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _setErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  void _clearErrorMessage() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  // ==================== REGISTRATION LOGIC ====================

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ✅ Step: Check if user is already logged in via Google
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser != null && currentUser.providerData.any((p) => p.providerId == 'google.com')) {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
  if (!userDoc.exists) {
    await _saveStudentToFirestore(currentUser, 'google');
  }

  Navigator.of(context).pushReplacementNamed('/login');
  return;
}

    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      
      // Step 1: Register user with Firebase Auth
      await authProvider.register(_emailController.text.trim(), _passwordController.text);
      
      final user = authProvider.user;
      if (user == null) {
        throw RegistrationException(
          type: RegistrationErrorType.unknown,
          message: 'User is null after registration',
          userMessage: 'Registration failed unexpectedly. Please try again.',
          allowRetry: true,
        );
      }

      // Step 2: Send verification email
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
          await _showEmailVerificationDialog();
        } catch (e) {
          developer.log('Failed to send verification email: $e', name: 'StudentRegistration');
          throw RegistrationException(
            type: RegistrationErrorType.emailNotSent,
            message: 'Failed to send verification email',
            userMessage: 'Your student account was created, but we couldn\'t send the verification email. You can request a new one from the login screen.',
            originalError: e,
          );
        }
      }

      // Step 3: Save student data to Firestore
      await _saveStudentToFirestore(user, 'email');

      // Step 4: Navigate to login screen (or student dashboard)
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }

    } on FirebaseAuthException catch (e) {
      final error = StudentRegistrationErrorHandler.handleFirebaseAuthError(e);
      final shouldRetry = await _showErrorDialog(error);
      
      if (shouldRetry) {
        await _registerStudent();
      } else {
        _setErrorMessage(error.userMessage);
      }
      
    } on RegistrationException catch (e) {
      await _showErrorDialog(e);
      _setErrorMessage(e.userMessage);
      
    } catch (e) {
      developer.log('Unexpected student registration error: $e', name: 'StudentRegistration');
      
      // Check if it's a network error
      final isNetworkError = NetworkService.isNetworkError(e);
      
      final error = RegistrationException(
        type: isNetworkError ? RegistrationErrorType.network : RegistrationErrorType.unknown,
        message: isNetworkError ? 'Network error during registration' : 'Unexpected error during registration',
        userMessage: isNetworkError 
            ? 'Please check your internet connection and try again.'
            : 'An unexpected error occurred. Please try again.',
        allowRetry: true,
        originalError: e,
      );
      
      final shouldRetry = await _showErrorDialog(error);
      if (shouldRetry) {
        await _registerStudent();
      } else {
        _setErrorMessage(error.userMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== GOOGLE SIGN-IN LOGIC ====================

Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
          // Let the user confirm and submit form (optional)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please review your details and tap "Create Account" to finish.'),
            ),
          );
          return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      developer.log('Google sign-in error: $e', name: 'StudentGoogleSignIn');
      final isNetworkError = NetworkService.isNetworkError(e);
      final error = RegistrationException(
        type: isNetworkError ? RegistrationErrorType.network : RegistrationErrorType.googleSignInFailed,
        message: isNetworkError ? 'Network error during Google sign-in' : 'Google sign-in failed',
        userMessage: isNetworkError
            ? 'Please check your internet connection and try again.'
            : 'Google sign-in failed. Please try again or use email registration.',
        allowRetry: true,
        originalError: e,
      );
      final shouldRetry = await _showErrorDialog(error);
      if (shouldRetry) {
        await _signInWithGoogle();
      } else {
        _setErrorMessage(error.userMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }
  // ==================== FIRESTORE OPERATIONS ====================

  Future<void> _saveStudentToFirestore(User user, String authProvider) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'student',
        'email': user.email?.toLowerCase().trim(),
        'name': authProvider == 'google' 
            ? (user.displayName ?? 'Google User') 
            : _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL,
        'authProvider': authProvider,
        'emailVerified': user.emailVerified,
        'studentInfo': {
          'enrollmentDate': FieldValue.serverTimestamp(),
          'status': 'active',
          'courses': [],
        },
      });
    } catch (e) {
      throw StudentRegistrationErrorHandler.handleFirestoreError(e);
    }
  }

  // ==================== UI BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Register as Student"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),
              _buildErrorMessage(),
              _buildGoogleSignInButton(),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildRegistrationForm(),
              const SizedBox(height: 24),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join as Student',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your learning journey with us today',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shadowColor: Colors.black26,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isGoogleLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Signing in...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    child: CustomPaint(
                      painter: SimpleGoogleLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: "Full Name",
            icon: Icons.person_outline,
            validator: StudentInputValidator.validateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: StudentInputValidator.validateEmail,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: StudentInputValidator.validatePassword,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Creating Account...",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : const Text(
                "Create Student Account",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text(
            "Sign In",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ==================== SIMPLE GOOGLE LOGO PAINTER ====================

class SimpleGoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Google's official colors
    final colors = [
      Color(0xFF4285F4), // Blue
      Color(0xFFEA4335), // Red  
      Color(0xFFFBBC05), // Yellow
      Color(0xFF34A853), // Green
    ];

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 6;

    // Draw simple colored circles representing Google
    // Blue circle (top-left)
    paint.color = colors[0];
    canvas.drawCircle(
      Offset(center.dx - radius/2, center.dy - radius/2),
      radius/2,
      paint,
    );

    // Red circle (top-right)  
    paint.color = colors[1];
    canvas.drawCircle(
      Offset(center.dx + radius/2, center.dy - radius/2),
      radius/2,
      paint,
    );

    // Yellow circle (bottom-left)
    paint.color = colors[2];
    canvas.drawCircle(
      Offset(center.dx - radius/2, center.dy + radius/2),
      radius/2,
      paint,
    );

    // Green circle (bottom-right)
    paint.color = colors[3];
    canvas.drawCircle(
      Offset(center.dx + radius/2, center.dy + radius/2),
      radius/2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}