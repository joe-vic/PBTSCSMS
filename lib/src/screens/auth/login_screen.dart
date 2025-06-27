// ============================================================================
// FILE: lib/screens/auth/login_screen.dart
// INSTRUCTIONS: Replace your current login_screen.dart with this cleaned up version
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:developer' as developer;
import 'dart:async';

import '../../providers/auth_provider.dart' as LocalAuthProvider;
import '../admin/admin_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../cashier/dashboard/CashierDashboard.dart';
import '../registrar/registrar_dashboard.dart';
import '../student/StudentDashboard.dart';
import '../teacher/screens/teacher_dashboard_screen.dart';
import '../../config/theme.dart';
import 'user_type_selection_screen.dart';

// NEW IMPORTS - Add these to use the organized code
import '../../utils/login_validators.dart';
import '../../utils/login_error_handler.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// Debug message for logging
String? _debugMessage;

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
  String? _debugMessage;
  bool _isRegistering = false;

  // Animation
  late AnimationController _controller;
  late Animation<double> _animation;

  // Form
  final _formKey = GlobalKey<FormState>();

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

  Widget _buildMessageDisplay() {
    // Prioritize error messages over debug messages
    final message = _errorMessage ?? _debugMessage;
    final isError = _errorMessage != null;

    if (message == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isError ? Colors.red.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: isError ? Colors.red.shade400 : Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontFamily: 'Poppins',
                    color: isError ? Colors.red.shade700 : Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// UPDATED: Better state management for messages
  void _setErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _debugMessage = null; // Clear debug when setting error
      });
    }
  }

  void _setDebugMessage(String message) {
    if (mounted) {
      setState(() {
        _debugMessage = message;
        _errorMessage = null; // Clear error when setting debug
      });
    }
  }

  void _clearAllMessages() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _debugMessage = null;
      });
    }
  }

// UPDATED: Toggle auth mode with message clearing
  void _toggleAuthMode() {
    setState(() {
      _isRegistering = !_isRegistering;

      if (_isRegistering) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        _confirmPasswordController.clear();
        _nameController.clear();
      }
    });

    _clearAllMessages(); // Clear messages when switching modes
  }

  // Navigation helper
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    _clearAllMessages(); // Clear all messages at start

    try {
      developer.log('🔑 Starting login process', name: 'Login');

      final result = await AuthService.loginWithEmail(
        context: context,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      developer.log('🔑 Login result: ${result.runtimeType}', name: 'Login');
      await _handleAuthResult(result);
    } catch (e) {
      developer.log('❌ Unexpected login error: $e', name: 'Login');
      _setErrorMessage(
          'Unable to connect to the server. Please check your internet connection and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// UPDATED: Register method using new message helpers
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    _clearAllMessages();

    try {
      developer.log('📝 Starting registration process', name: 'Register');

      final result = await AuthService.registerWithEmail(
        context: context,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      developer.log('📝 Registration result: ${result.runtimeType}',
          name: 'Register');
      await _handleAuthResult(result);
    } catch (e) {
      developer.log('❌ Unexpected registration error: $e', name: 'Register');
      _setErrorMessage(
          'Unable to create account. Please check your internet connection and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // NEW: Password recovery method
  Future<void> _handlePasswordReset() async {
    developer.log('🔐 Starting password reset process', name: 'PasswordReset');

    final email = await _showPasswordResetDialog();
    if (email == null || email.isEmpty) {
      developer.log('❌ Password reset canceled - no email provided',
          name: 'PasswordReset');
      return;
    }

    developer.log('📧 Attempting password reset for email: $email',
        name: 'PasswordReset');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.resetPassword(email: email);
      developer.log('✅ Password reset result: ${result.runtimeType}',
          name: 'PasswordReset');
      await _handleAuthResult(result);
    } catch (e) {
      developer.log('❌ Password reset error: $e', name: 'PasswordReset');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to send password reset email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// IMPROVED: Enhanced auth result handling with better cancellation UI
  Future<void> _handleAuthResult(AuthResult result) async {
    developer.log('🔄 Handling auth result: ${result.runtimeType}',
        name: 'LoginScreen');

    switch (result.runtimeType) {
      case AuthSuccess:
        final success = result as AuthSuccess;
        developer.log('✅ Auth success with role: ${success.userRole}',
            name: 'LoginScreen');
        if (mounted) {
          final nextScreen = _getNextScreen(success.userRole);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
        break;

      case AuthFailure:
        final failure = result as AuthFailure;
        developer.log('❌ Auth failure: ${failure.message}',
            name: 'LoginScreen');
        _setErrorMessage(failure.message);
        break;

      case AuthEmailNotVerified:
        final emailNotVerified = result as AuthEmailNotVerified;
        developer.log('📧 Email not verified', name: 'LoginScreen');
        final shouldResend =
            await _showEmailVerificationDialog(emailNotVerified.user);
        if (shouldResend) {
          await _resendVerificationEmail(emailNotVerified.user);
        }
        break;

      case AuthRegistrationSuccess:
        final registrationSuccess = result as AuthRegistrationSuccess;
        developer.log('🎉 Registration success: ${registrationSuccess.email}',
            name: 'LoginScreen');
        await _showSuccessDialog(
          'Registration Successful!',
          'Your account has been created. Please check your email (${registrationSuccess.email}) for a verification link before signing in.',
        );
        _toggleAuthMode();
        break;

      case AuthPasswordResetSent:
        final passwordReset = result as AuthPasswordResetSent;
        developer.log('📤 Password reset sent: ${passwordReset.email}',
            name: 'LoginScreen');
        await _showSuccessDialog(
          'Password Reset Email Sent',
          'A password reset link has been sent to ${passwordReset.email}. Please check your inbox and follow the instructions.',
        );
        break;

      case AuthGoogleSignInCanceled:
        developer.log('🚫 Google Sign-In canceled by user',
            name: 'LoginScreen');
        _setDebugMessage(
            'Google sign-in was canceled. You can try again or use email login.');
        break;

      // NEW: Handle new Google users with welcome message
      case AuthNewGoogleUser:
        final newGoogleUser = result as AuthNewGoogleUser;
        developer.log('🎉 New Google user created: ${newGoogleUser.email}',
            name: 'LoginScreen');
        await _showGoogleWelcomeDialog(newGoogleUser.name, newGoogleUser.email);
        // Navigate to dashboard after welcome
        if (mounted) {
          final nextScreen = _getNextScreen('parent'); // Default role
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
        break;

      case AuthLoginException:
        final loginException = result as AuthLoginException;
        developer.log('⚠️ Login exception: ${loginException.exception.type}',
            name: 'LoginScreen');
        await _handleLoginException(loginException.exception);
        break;

      default:
        developer.log('❓ Unknown auth result type: ${result.runtimeType}',
            name: 'LoginScreen');
        _setErrorMessage(
            'An unexpected response was received. Please try again.');
        break;
    }
  }

  Future<void> _showGoogleWelcomeDialog(String name, String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade100,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to PBTS!',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: SMSTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi $name! 👋',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your Google account has been successfully connected to our Student Management System.',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                height: 1.5,
                color: SMSTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Account Details',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email: $email',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            Text(
                              'Role: Parent (Default)',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can now access all parent features of the system. If you need a different role, please contact the administrator.',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                height: 1.4,
                color: SMSTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// NEW: Dedicated method for Google Sign-In cancellation message
  Future<void> _showGoogleSignInCanceledMessage() async {
    // Clear any existing error message
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Wait a brief moment to ensure loading is cleared
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Show a more visible and longer-lasting message
    ScaffoldMessenger.of(context)
        .clearSnackBars(); // Clear any existing snackbars

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign-in Canceled',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'You can try again anytime or use email login',
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: SMSTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4), // Longer duration
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

// ADD THIS METHOD to your _LoginScreenState class
  void _showGoogleSignInCanceledState() {
    developer.log('🎯 Setting Google Sign-In canceled state message',
        name: 'LoginScreen');

    if (mounted) {
      setState(() {
        _errorMessage = null;
        _debugMessage =
            'Sign-in was canceled. You can try again or use email login.';
      });

      // Auto-clear the message after a few seconds
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _debugMessage = null;
          });
        }
      });
    }
  }

// IMPROVED: Google login method with better error clearing
// UPDATED: Google login with better message handling
  Future<void> _googleLogin() async {
    developer.log('🎯 Starting Google login process', name: 'LoginScreen');

    setState(() {
      _isLoading = true;
    });

    _clearAllMessages(); // Clear all messages at start

    try {
      final result = await AuthService.loginWithGoogle(context: context);
      await _handleAuthResult(result);
    } catch (e) {
      developer.log('❌ Google login error in UI: $e', name: 'LoginScreen');
      _setErrorMessage(
          'Google sign-in encountered an issue. Please try again.');
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// NEW: Alternative - Show as a dialog instead of SnackBar (more visible)
  Future<void> _showGoogleSignInCanceledDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: SMSTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sign-in Canceled',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'No worries! You canceled the Google sign-in. You can try again anytime or use your email and password instead.',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.4,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _googleLogin(); // Try Google Sign-In again
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Try Again',
              style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

// NEW: Handle login exceptions with improved UI
  Future<void> _handleLoginException(LoginException exception) async {
    developer.log('Handling login exception: ${exception.type}',
        name: 'LoginScreen');

    // For Google Sign-In cancellation, show as debug message
    if (exception.type == LoginErrorType.googleSignInCanceled) {
      _setDebugMessage(
          'Google sign-in was canceled. You can try again or use email login.');
      return;
    }

    // For Google Sign-In specific errors, show helpful messages
    if (exception.type == LoginErrorType.googleSignInFailed) {
      _setErrorMessage(
          'Google sign-in failed. Please check your internet connection and try again.');
      return;
    }

    if (exception.type == LoginErrorType.googleSignInNetworkError) {
      _setErrorMessage(
          'Network error during Google sign-in. Please check your connection.');
      return;
    }

    // For other errors, show the user message
    _setErrorMessage(exception.userMessage);

    // Only show dialogs for errors that need user action
    if (exception.type == LoginErrorType.emailNotVerified &&
        exception.allowResendVerification) {
      final shouldResend = await _showEmailVerificationDialog(null);
      if (shouldResend) {
        // Resend verification logic here
      }
    }
  }

// NEW: Specific dialog for Google Sign-In errors
  Future<void> _showGoogleSignInErrorDialog(LoginException exception) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(
              Icons.g_mobiledata,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Sign-In Issue',
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
              exception.userMessage,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                height: 1.4,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can also sign in using your email and password below.',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Use Email Instead',
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (exception.allowRetry)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _googleLogin(); // Retry Google Sign-In
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

// ENHANCED: Better error dialog
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
                _getErrorDialogTitle(error.type),
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

  // NEW: Get appropriate dialog title for error type
  String _getErrorDialogTitle(LoginErrorType type) {
    switch (type) {
      case LoginErrorType.emailNotVerified:
        return 'Email Verification Required';
      case LoginErrorType.googleSignInFailed:
      case LoginErrorType.googleSignInNetworkError:
        return 'Google Sign-In Issue';
      case LoginErrorType.network:
        return 'Connection Issue';
      case LoginErrorType.userNotFound:
        return 'Account Not Found';
      case LoginErrorType.wrongPassword:
        return 'Incorrect Password';
      case LoginErrorType.tooManyRequests:
        return 'Too Many Attempts';
      default:
        return 'Sign-In Error';
    }
  }

  // Dialog methods
  Future<String?> _showPasswordResetDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: SMSTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reset Password',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SMSTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.4,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.email, color: SMSTheme.primaryColor),
                  labelStyle:
                      TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
                  hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: LoginValidators.validateEmail,
                autofocus: true,
                style: TextStyle(fontFamily: 'Poppins',),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(emailController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Send Reset Link',
              style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showEmailVerificationDialog(dynamic user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.mark_email_unread,
                color: SMSTheme.primaryColor, size: 24),
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
        content: Text(
          'Please verify your email address before signing in. Check your inbox for a verification email.\n\nWould you like to resend the verification email?',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.4,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Resend Email',
              style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
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

  Future<void> _resendVerificationEmail(dynamic user) async {
    try {
      setState(() => _isLoading = true);
      await AuthService.resendVerificationEmail(user);
      await _showSuccessDialog(
        'Verification Email Sent',
        'A new verification email has been sent to ${user.email}. Please check your inbox and spam folder.',
      );
    } catch (e) {
      developer.log('Failed to resend verification email: $e', name: 'Login');
      setState(() {
        _errorMessage =
            'Failed to resend verification email. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SMSTheme.primaryColor,
              SMSTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 400 : double.infinity,
                  minWidth: 0,
                ),
                child: FadeTransition(
                  opacity: _animation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Container(
            width: isSmallScreen ? 80 : 120,
            height: isSmallScreen ? 80 : 120,
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
                      size: isSmallScreen ? 40 : 80,
                      color: SMSTheme.primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 16),
        FadeInDown(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 600),
          child: Text(
            'Philippine Best Training',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: isSmallScreen ? 18 : 24,
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
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 8),
        FadeInDown(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 600),
          child: Text(
            'Student Management System',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
      ],
    );
  }

  Widget _buildLoginCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 360 ? 12 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardHeader(),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 12 : 20),
                  _buildFormFields(),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 12 : 20),
                  _buildSubmitButton(),
                  _buildToggleAuthMode(),
                  _buildDivider(),
                  SizedBox(height: MediaQuery.of(context).size.width < 360 ? 8 : 16),
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
            validator: LoginValidators.validateName,
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
          validator: LoginValidators.validateEmail,
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
          validator: LoginValidators.validatePassword,
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
            validator: (value) => LoginValidators.validateConfirmPassword(
                value, _passwordController.text),
            textInputAction: TextInputAction.done,
            icon: Icons.lock_outline,
          ),
        ],

        // SINGLE MESSAGE DISPLAY (replaces both debug and error)
        _buildMessageDisplay(),

        // Forgot password link (only for login)
        if (!_isRegistering) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handlePasswordReset,
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
            ? const SizedBox(
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
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SMSTheme.textSecondaryColor,
                ),
              )
            : Icon(
                Icons.g_mobiledata,
                color: Colors.red,
                size: isSmallScreen ? 20 : 24,
              ),
        label: Text(
          _isLoading ? 'Signing in...' : 'Sign in with Google',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: isSmallScreen ? 14 : 16,
            color: _isLoading
                ? SMSTheme.textSecondaryColor
                : SMSTheme.textPrimaryColor,
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
          side: BorderSide(
            color: _isLoading ? Colors.grey.shade400 : Colors.grey.shade300,
            width: 1.5,
          ),
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
