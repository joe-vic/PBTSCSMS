import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:developer' as developer;

import '../../providers/auth_provider.dart' as LocalAuthProvider;
import '../admin/admin_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../cashier/dashboard/CashierDashboard.dart';
import '../registrar/registrar_dashboard.dart';
import '../student/StudentDashboard.dart';
import '../teacher/screens/teacher_dashboard_screen.dart';
import '../../config/theme.dart';
import 'user_type_selection_screen.dart';

// ==================== ERROR HANDLING SYSTEM ====================

enum LoginErrorType {
  network,
  userNotFound,
  wrongPassword,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  emailNotVerified,
  accountNotFound,
  weakPassword,
  emailInUse,
  operationNotAllowed,
  unknown
}

class LoginException implements Exception {
  final LoginErrorType type;
  final String message;
  final String userMessage;
  final bool allowRetry;
  final bool allowResendVerification;
  final dynamic originalError;

  LoginException({
    required this.type,
    required this.message,
    required this.userMessage,
    this.allowRetry = false,
    this.allowResendVerification = false,
    this.originalError,
  });
}

// ==================== ERROR HANDLER SERVICE ====================

class LoginErrorHandler {
  static LoginException handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    developer.log('Auth Error: $error', name: 'Login');

    if (errorString.contains('user-not-found')) {
      return LoginException(
        type: LoginErrorType.userNotFound,
        message: 'User not found',
        userMessage:
            'No account found with this email address. Please check your email or register for a new account.',
      );
    } else if (errorString.contains('wrong-password')) {
      return LoginException(
        type: LoginErrorType.wrongPassword,
        message: 'Wrong password',
        userMessage:
            'Incorrect password. Please check your password and try again.',
        allowRetry: true,
      );
    } else if (errorString.contains('invalid-email')) {
      return LoginException(
        type: LoginErrorType.invalidEmail,
        message: 'Invalid email',
        userMessage: 'Please enter a valid email address.',
      );
    } else if (errorString.contains('user-disabled')) {
      return LoginException(
        type: LoginErrorType.userDisabled,
        message: 'User disabled',
        userMessage:
            'This account has been disabled. Please contact support for assistance.',
      );
    } else if (errorString.contains('too-many-requests')) {
      return LoginException(
        type: LoginErrorType.tooManyRequests,
        message: 'Too many requests',
        userMessage:
            'Too many login attempts. Please wait a few minutes before trying again.',
        allowRetry: true,
      );
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return LoginException(
        type: LoginErrorType.network,
        message: 'Network error',
        userMessage: 'Please check your internet connection and try again.',
        allowRetry: true,
      );
    } else if (errorString.contains('email-already-in-use')) {
      return LoginException(
        type: LoginErrorType.emailInUse,
        message: 'Email already in use',
        userMessage:
            'This email is already registered. Please sign in instead.',
      );
    } else if (errorString.contains('weak-password')) {
      return LoginException(
        type: LoginErrorType.weakPassword,
        message: 'Weak password',
        userMessage: 'Password is too weak. Please use a stronger password.',
      );
    } else if (errorString.contains('operation-not-allowed')) {
      return LoginException(
        type: LoginErrorType.operationNotAllowed,
        message: 'Operation not allowed',
        userMessage:
            'This sign-in method is currently disabled. Please contact support.',
      );
    } else {
      return LoginException(
        type: LoginErrorType.unknown,
        message: 'Unknown error',
        userMessage: 'An unexpected error occurred. Please try again.',
        allowRetry: true,
        originalError: error,
      );
    }
  }

  static LoginException handleEmailNotVerified() {
    return LoginException(
      type: LoginErrorType.emailNotVerified,
      message: 'Email not verified',
      userMessage:
          'Please verify your email address before signing in. Check your inbox for a verification email.',
      allowResendVerification: true,
    );
  }
}

// ==================== VALIDATION SERVICE ====================

class LoginValidator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final bool emailValid =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(value);
    if (!emailValid) {
      return 'Enter a valid email address';
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

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name is too short';
    }
    return null;
  }
}

// ==================== MAIN LOGIN SCREEN ====================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  bool _isRegistering = false;

  // Animation
  late AnimationController _controller;
  late Animation<double> _animation;

  // Form
  final _formKey = GlobalKey<FormState>();

  // ==================== LIFECYCLE METHODS ====================

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ==================== UI HELPER METHODS ====================

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

  void _toggleAuthMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;

      if (_isRegistering) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        _confirmPasswordController.clear();
        _nameController.clear();
      }
    });
  }

  // ==================== ERROR HANDLING UI ====================

  Future<bool> _showErrorDialog(LoginException error) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error.type == LoginErrorType.emailNotVerified
                  ? Icons.mark_email_unread
                  : Icons.error_outline,
              color: error.type == LoginErrorType.emailNotVerified
                  ? SMSTheme.primaryColor
                  : Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.type == LoginErrorType.emailNotVerified
                    ? 'Email Verification Required'
                    : 'Login Error',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error.userMessage,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.4,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              if (error.allowRetry || error.allowResendVerification) ...[
                const SizedBox(height: 12),
                if (error.allowRetry)
                  Text(
                    'Would you like to try again?',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                if (error.allowResendVerification)
                  Text(
                    'Would you like to resend the verification email?',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              (error.allowRetry || error.allowResendVerification)
                  ? 'Cancel'
                  : 'OK',
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (error.allowResendVerification)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('resend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Resend Email',
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
              ),
            ),
          if (error.allowRetry)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );

    return result == 'retry';
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.4,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMAIL VERIFICATION ====================

  Future<bool> _checkEmailVerification(
      LocalAuthProvider.AuthProvider authProvider) async {
    final user = authProvider.user;
    if (user == null) return false;

    // Reload user to get latest email verification status
    await user.reload();
    final updatedUser = authProvider.user;

    if (updatedUser != null && !updatedUser.emailVerified) {
      // Show email verification dialog
      final dialogResult = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_unread,
                color: SMSTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Email Verification Required',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please verify your email address before signing in. Check your inbox for a verification email.',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.4,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Would you like to resend the verification email?',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: SMSTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins',
                  color: SMSTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('resend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Resend Email',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

      if (dialogResult == 'resend') {
        await _resendVerificationEmail(updatedUser);
      }

      return false; // Email not verified
    }

    return true; // Email is verified
  }

  Future<void> _resendVerificationEmail(user) async {
    try {
      setState(() => _isLoading = true);

      await user.sendEmailVerification();

      await _showSuccessDialog(
        'Verification Email Sent',
        'A new verification email has been sent to ${user.email}. Please check your inbox and spam folder.',
      );
    } catch (e) {
      developer.log('Failed to resend verification email: $e', name: 'Login');
      final error = LoginErrorHandler.handleAuthError(e);
      await _showErrorDialog(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== NAVIGATION ====================

  Widget _getNextScreen(String? userRole) {
    switch (userRole) {
      case 'admin':
        return AdminDashboard();
      case 'parent':
        return const ParentDashboard();
      case 'cashier':
        return const CashierDashboard();
      case 'registrar':
        return RegistrarDashboard();
      case 'student':
        return StudentDashboard();
      case 'teacher':
        return TeacherDashboardScreen();
      default:
        developer.log('Unknown role: $userRole, defaulting to ParentDashboard',
            name: 'Login');
        return const ParentDashboard();
    }
  }

  // ==================== AUTH METHODS ====================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('Starting login for email: ${_emailController.text}',
          name: 'Login');

      final authProvider =
          Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      await authProvider.signIn(
          _emailController.text.trim(), _passwordController.text);

      // Check email verification BEFORE proceeding
      final isEmailVerified = await _checkEmailVerification(authProvider);
      if (!isEmailVerified) {
        // Sign out the user since email is not verified
        await authProvider.signOut();
        return;
      }

      final userId = authProvider.user?.uid;
      final userRole = authProvider.userRole;

      if (userId != null) {
        developer.log(
            'Checking user document for UID: $userId, Role: $userRole',
            name: 'Login');

        // Wait a bit for Firebase to sync
        await Future.delayed(const Duration(milliseconds: 500));

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (!userDoc.exists) {
          developer.log(
              'New user detected for UID: $userId, setting default role to parent',
              name: 'Login');
          await FirebaseFirestore.instance.collection('users').doc(userId).set(
            {
              'role': 'parent',
              'email': _emailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else if (userRole == null) {
          developer.log(
              'Existing user with no role for UID: $userId, setting to parent',
              name: 'Login');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'role': 'parent',
            'email': _emailController.text.trim(),
          });
        }

        if (mounted) {
          final nextScreen = _getNextScreen(userRole);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'Login');
      final error = LoginErrorHandler.handleAuthError(e);
      final shouldRetry = await _showErrorDialog(error);

      if (shouldRetry) {
        await _login();
      } else {
        _setErrorMessage(error.userMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('Starting registration for email: ${_emailController.text}',
          name: 'Login');

      final authProvider =
          Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      await authProvider.register(
          _emailController.text.trim(), _passwordController.text);

      final userId = authProvider.user?.uid;

      if (userId != null && mounted) {
        // Send verification email
        final user = authProvider.user;
        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification();

            await _showSuccessDialog(
              'Registration Successful!',
              'Your account has been created. Please check your email (${_emailController.text}) for a verification link before signing in.',
            );
          } catch (e) {
            developer.log('Failed to send verification email: $e',
                name: 'Login');
          }
        }

        // Create user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'role': 'parent', // Default role for new registrations
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': user?.emailVerified ?? false,
        });

        // Sign out the user so they have to verify email first
        await authProvider.signOut();

        // Switch back to login mode
        setState(() {
          _isRegistering = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
          _nameController.clear();
        });
      }
    } catch (e) {
      developer.log('Registration error: $e', name: 'Login');
      final error = LoginErrorHandler.handleAuthError(e);
      await _showErrorDialog(error);
      _setErrorMessage(error.userMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider =
          Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      final userId = authProvider.user?.uid;
      final userRole = authProvider.userRole;

      if (userId != null && mounted) {
        // Google sign-in usually provides verified emails, so we can proceed
        final nextScreen = _getNextScreen(userRole);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } catch (e) {
      developer.log('Google login error: $e', name: 'Login');
      final error = LoginErrorHandler.handleAuthError(e);
      await _showErrorDialog(error);
      _setErrorMessage(error.userMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== UI BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SMSTheme.primaryColor, SMSTheme.backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _animation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).viewPadding.top -
                        MediaQuery.of(context).viewPadding.bottom -
                        32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        _buildLoginCard(),
                        const SizedBox(height: 24),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildHeader() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Container(
            width: isSmallScreen ? 100 : 120,
            height: isSmallScreen ? 100 : 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/PBTSLogo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.school,
                      size: isSmallScreen ? 60 : 80,
                      color: SMSTheme.primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        FadeInDown(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 600),
          child: Text(
            'Philippine Best Training',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        FadeInDown(
          delay: const Duration(milliseconds: 250),
          duration: const Duration(milliseconds: 600),
          child: Text(
            'Systems Colleges Inc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        FadeInDown(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 600),
          child: Text(
            'Student Management System',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 24 : 32),
      ],
    );
  }

  Widget _buildLoginCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 400, // Limit max width for better responsiveness
        ),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 360 ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardHeader(),
                  const SizedBox(height: 20),
                  _buildFormFields(),
                  _buildErrorMessage(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                  _buildToggleAuthMode(),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildGoogleSignInButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isRegistering ? 'Create Account' : 'Welcome Back',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: SMSTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isRegistering ? 'Register to get started' : 'Sign in to continue',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: isSmallScreen ? 12 : 14,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final fieldSpacing = isSmallScreen ? 12.0 : 16.0;

    return Column(
      children: [
        // Name field (only for registration)
        if (_isRegistering) ...[
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person,
            validator: LoginValidator.validateName,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: fieldSpacing),
        ],

        // Email field
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email,
          validator: LoginValidator.validateEmail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: fieldSpacing),

        // Password field
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          isVisible: _isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          validator: LoginValidator.validatePassword,
          textInputAction:
              _isRegistering ? TextInputAction.next : TextInputAction.done,
        ),

        // Confirm Password field (only for registration)
        if (_isRegistering) ...[
          SizedBox(height: fieldSpacing),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            isVisible: _isConfirmPasswordVisible,
            onToggleVisibility: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            validator: (value) => LoginValidator.validateConfirmPassword(
                value, _passwordController.text),
            textInputAction: TextInputAction.done,
            icon: Icons.lock_outline,
          ),
        ],

        // Forgot password link (only for login)
        if (!_isRegistering) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset functionality coming soon',
                      style: TextStyle(fontFamily: 'Poppins',),
                    ),
                    backgroundColor: SMSTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(fontFamily: 'Poppins',
                  color: SMSTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderSide: BorderSide(color: SMSTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: SMSTheme.primaryColor),
        labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
        hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      style: TextStyle(fontFamily: 'Poppins',),
      validator: validator,
      textInputAction: textInputAction,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    TextInputAction? textInputAction,
    IconData icon = Icons.lock,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderSide: BorderSide(color: SMSTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: SMSTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: SMSTheme.textSecondaryColor,
          ),
          onPressed: onToggleVisibility,
        ),
        labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
        hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      obscureText: !isVisible,
      style: TextStyle(fontFamily: 'Poppins',),
      validator: validator,
      textInputAction: textInputAction,
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(fontFamily: 'Poppins',
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isRegistering ? _register : _login),
        style: ElevatedButton.styleFrom(
          backgroundColor: SMSTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          disabledBackgroundColor: SMSTheme.primaryColor.withOpacity(0.6),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isRegistering ? 'Register' : 'Sign In',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12.0 : 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _isRegistering
                ? 'Already have an account?'
                : 'Don\'t have an account?',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          TextButton(
            onPressed: _isRegistering
                ? _toggleAuthMode
                : () {
                    Navigator.of(context).pushReplacementNamed('/select-role');
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              _isRegistering ? 'Sign In' : 'Register',
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _googleLogin,
        icon: Icon(
          Icons.g_mobiledata,
          color: Colors.red,
          size: isSmallScreen ? 20 : 24,
        ),
        label: Text(
          'Sign in with Google',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: isSmallScreen ? 14 : 16,
            color: SMSTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: 16,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeIn(
      delay: const Duration(milliseconds: 1000),
      child: Text(
        '© ${DateTime.now().year} PBTS Colleges Inc.',
        style: TextStyle(fontFamily: 'Poppins',
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
        ),
      ),
    );
  }
}
