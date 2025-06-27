// ============================================================================
// FILE: lib/utils/login_error_handler.dart
// INSTRUCTIONS: Replace your current login_error_handler.dart with this enhanced version
// ============================================================================

import 'dart:developer' as developer;

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
  googleSignInCanceled,    // NEW: For when user cancels Google Sign-In
  googleSignInFailed,      // NEW: For actual Google Sign-In failures
  googleSignInNetworkError, // NEW: For network issues during Google Sign-In
  unknown
}

class LoginException implements Exception {
  final LoginErrorType type;
  final String message;
  final String userMessage;
  final bool allowRetry;
  final bool allowResendVerification;
  final bool showAsError;  // NEW: Whether to show this as an error or just info
  final dynamic originalError;

  LoginException({
    required this.type,
    required this.message,
    required this.userMessage,
    this.allowRetry = false,
    this.allowResendVerification = false,
    this.showAsError = true,  // NEW: Default to showing as error
    this.originalError,
  });
}

class LoginErrorHandler {
  static LoginException handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    developer.log('Auth Error: $error', name: 'LoginErrorHandler');

    // Handle Google Sign-In specific errors first
    if (errorString.contains('google')) {
      return _handleGoogleSignInError(errorString, error);
    }

    // Handle Firebase Auth errors
    if (errorString.contains('user-not-found')) {
      return LoginException(
        type: LoginErrorType.userNotFound,
        message: 'User not found',
        userMessage: 'No account found with this email address. Please check your email or register for a new account.',
      );
    } else if (errorString.contains('wrong-password')) {
      return LoginException(
        type: LoginErrorType.wrongPassword,
        message: 'Wrong password',
        userMessage: 'Incorrect password. Please check your password and try again.',
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
        userMessage: 'This account has been disabled. Please contact support for assistance.',
      );
    } else if (errorString.contains('too-many-requests')) {
      return LoginException(
        type: LoginErrorType.tooManyRequests,
        message: 'Too many requests',
        userMessage: 'Too many login attempts. Please wait a few minutes before trying again.',
        allowRetry: true,
      );
    } else if (errorString.contains('network') || errorString.contains('connection')) {
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
        userMessage: 'This email is already registered. Please sign in instead.',
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
        userMessage: 'This sign-in method is currently disabled. Please contact support.',
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

  // NEW: Specific Google Sign-In error handling
  static LoginException _handleGoogleSignInError(String errorString, dynamic originalError) {
    developer.log('Handling Google Sign-In Error: $errorString', name: 'GoogleSignIn');

    if (errorString.contains('canceled') || errorString.contains('cancelled')) {
      return LoginException(
        type: LoginErrorType.googleSignInCanceled,
        message: 'Google Sign-In canceled',
        userMessage: 'Sign-in was canceled. You can try again anytime.',
        allowRetry: true,
        showAsError: false, // Don't show as error since user chose to cancel
        originalError: originalError,
      );
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return LoginException(
        type: LoginErrorType.googleSignInNetworkError,
        message: 'Google Sign-In network error',
        userMessage: 'Please check your internet connection and try Google Sign-In again.',
        allowRetry: true,
        originalError: originalError,
      );
    } else if (errorString.contains('sign_in_failed') || errorString.contains('failed')) {
      return LoginException(
        type: LoginErrorType.googleSignInFailed,
        message: 'Google Sign-In failed',
        userMessage: 'Google Sign-In encountered an issue. Please try again or use email login.',
        allowRetry: true,
        originalError: originalError,
      );
    } else {
      return LoginException(
        type: LoginErrorType.googleSignInFailed,
        message: 'Google Sign-In error',
        userMessage: 'Unable to sign in with Google. Please try again or use email login.',
        allowRetry: true,
        originalError: originalError,
      );
    }
  }

  static LoginException handleEmailNotVerified() {
    return LoginException(
      type: LoginErrorType.emailNotVerified,
      message: 'Email not verified',
      userMessage: 'Please verify your email address before signing in. Check your inbox for a verification email.',
      allowResendVerification: true,
    );
  }

  // NEW: Get user-friendly message for error types
  static String getUserFriendlyMessage(LoginErrorType type) {
    switch (type) {
      case LoginErrorType.googleSignInCanceled:
        return "No worries! You can try signing in again whenever you're ready.";
      case LoginErrorType.googleSignInFailed:
        return "Google Sign-In isn't working right now. Try using your email instead.";
      case LoginErrorType.googleSignInNetworkError:
        return "Check your internet connection and try Google Sign-In again.";
      case LoginErrorType.network:
        return "Connection issue. Please check your internet and try again.";
      case LoginErrorType.userNotFound:
        return "This email isn't registered yet. Would you like to create an account?";
      case LoginErrorType.wrongPassword:
        return "Wrong password. Double-check and try again.";
      default:
        return "Something went wrong. Please try again.";
    }
  }
}