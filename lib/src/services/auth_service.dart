// ============================================================================
// FILE: lib/services/auth_service.dart
// INSTRUCTIONS: Replace your current auth_service.dart with this enhanced version
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart' as LocalAuthProvider;
import '../utils/login_error_handler.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<AuthResult> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      developer.log('🔑 Attempting login with email: $email',
          name: 'AuthService');

      // Clean the inputs
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // Validate inputs
      if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
        return AuthResult.failure('Please enter both email and password.');
      }

      // Attempt Firebase Auth login
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (credential.user == null) {
        return AuthResult.failure('Login failed. Please try again.');
      }

      final user = credential.user!;

      // Check email verification
      if (!user.emailVerified) {
        developer.log('❌ Email not verified for: ${user.email}',
            name: 'AuthService');
        return AuthResult.emailNotVerified(user);
      }

      // Get user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return AuthResult.failure(
            'User profile not found. Please contact support.');
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String?;

      if (userRole == null) {
        return AuthResult.failure(
            'User role not assigned. Please contact support.');
      }

      developer.log('✅ Login successful. Role: $userRole', name: 'AuthService');
      return AuthResult.success(userRole);
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Firebase Auth error: ${e.code} - ${e.message}',
          name: 'AuthService');

      // Convert Firebase errors to user-friendly messages
      switch (e.code) {
        case 'user-not-found':
          return AuthResult.failure(
              'No account found with this email address.');

        case 'wrong-password':
          return AuthResult.failure('Incorrect password. Please try again.');

        case 'invalid-email':
          return AuthResult.failure('Please enter a valid email address.');

        case 'user-disabled':
          return AuthResult.failure(
              'This account has been disabled. Please contact support.');

        case 'too-many-requests':
          return AuthResult.failure(
              'Too many failed attempts. Please try again later.');

        case 'invalid-credential':
          return AuthResult.failure(
              'Invalid email or password. Please check your credentials.');

        case 'network-request-failed':
          return AuthResult.failure(
              'Network error. Please check your internet connection.');

        case 'operation-not-allowed':
          return AuthResult.failure(
              'Email/password sign-in is not enabled. Please contact support.');

        default:
          return AuthResult.failure(
              'Login failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('❌ Unexpected login error: $e', name: 'AuthService');
      return AuthResult.failure('Unable to sign in. Please try again.');
    }
  }

  // ALSO UPDATE YOUR REGISTER METHOD to handle errors properly
  static Future<AuthResult> registerWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      developer.log('📝 Attempting registration with email: $email',
          name: 'AuthService');

      // Clean inputs
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();

      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure(
            'Failed to create account. Please try again.');
      }

      final user = credential.user!;

      // Send verification email
      await user.sendEmailVerification();

      // Create user document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'parent', // Default role
        'email': cleanEmail,
        'name': cleanName,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      // Sign out the user (they need to verify email first)
      await _auth.signOut();

      developer.log('✅ Registration successful for: $cleanEmail',
          name: 'AuthService');
      return AuthResult.registrationSuccess(cleanEmail);
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Firebase registration error: ${e.code} - ${e.message}',
          name: 'AuthService');

      switch (e.code) {
        case 'email-already-in-use':
          return AuthResult.failure(
              'An account with this email already exists.');

        case 'invalid-email':
          return AuthResult.failure('Please enter a valid email address.');

        case 'weak-password':
          return AuthResult.failure(
              'Password is too weak. Please use at least 6 characters.');

        case 'network-request-failed':
          return AuthResult.failure(
              'Network error. Please check your internet connection.');

        default:
          return AuthResult.failure(
              'Registration failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('❌ Unexpected registration error: $e', name: 'AuthService');
      return AuthResult.failure('Unable to create account. Please try again.');
    }
  }

  // ENHANCED: Better Google Sign-In with new user detection
  static Future<AuthResult> loginWithGoogle({
    required BuildContext context,
  }) async {
    developer.log('🚀 Starting Google Sign-In', name: 'AuthService');

    try {
      final authProvider =
          Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);

      // Get the current user before sign-in attempt
      final userBeforeSignIn = authProvider.user;
      developer.log(
          '👤 User before sign-in: ${userBeforeSignIn?.email ?? 'null'}',
          name: 'AuthService');

      // Attempt Google Sign-In
      await authProvider.signInWithGoogle();

      // Get user after sign-in attempt
      final userAfterSignIn = authProvider.user;
      developer.log(
          '👤 User after sign-in: ${userAfterSignIn?.email ?? 'null'}',
          name: 'AuthService');

      // Check if sign-in was successful
      if (userAfterSignIn == null) {
        developer.log('❌ Google Sign-In returned null user - likely canceled',
            name: 'AuthService');
        return AuthResult.googleSignInCanceled();
      }

      // Check if user actually changed (successful sign-in)
      if (userBeforeSignIn?.uid == userAfterSignIn.uid &&
          userBeforeSignIn != null) {
        developer.log('⚠️ Same user before and after - possible cancellation',
            name: 'AuthService');
        return AuthResult.googleSignInCanceled();
      }

      final userId = userAfterSignIn.uid;
      final userEmail = userAfterSignIn.email ?? '';
      final userName = userAfterSignIn.displayName ?? 'User';

      developer.log('🔍 Checking if user is new or existing: $userEmail', name: 'AuthService');

      // ENHANCED: Check if this is a new user and handle accordingly
      final userResult = await _handleGoogleUser(userId, userEmail, userName);
      
      return userResult;

    } catch (e) {
      final errorString = e.toString().toLowerCase();
      developer.log('❌ Google Sign-In exception: $e', name: 'AuthService');

      // Check for specific cancellation patterns
      if (errorString.contains('sign_in_canceled') ||
          errorString.contains('canceled') ||
          errorString.contains('cancelled') ||
          errorString.contains('aborted_by_user') ||
          errorString.contains('user_canceled')) {
        developer.log('🚫 Google Sign-In canceled by user',
            name: 'AuthService');
        return AuthResult.googleSignInCanceled();
      }

      // Handle other Google Sign-In errors
      if (errorString.contains('network')) {
        return AuthResult.failure('Network error during Google sign-in. Please check your connection.');
      }

      // For any other errors, try to create a helpful login exception
      try {
        final loginException = LoginErrorHandler.handleAuthError(e);
        return AuthResult.loginException(loginException);
      } catch (handlerError) {
        // If the error handler fails, return a generic message
        return AuthResult.failure('Google sign-in failed. Please try again or use email login.');
      }
    }
  }

  // NEW: Enhanced method to handle Google users (new vs existing)
  static Future<AuthResult> _handleGoogleUser(String userId, String email, String name) async {
    try {
      developer.log('🔍 Checking user document for UID: $userId', name: 'AuthService');

      // Check if user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        developer.log('🆕 New Google user detected, creating profile', name: 'AuthService');
        return await _createNewGoogleUser(userId, email, name);
      } else {
        developer.log('👤 Existing Google user found, loading profile', name: 'AuthService');
        return await _handleExistingGoogleUser(userDoc, email);
      }

    } catch (e) {
      developer.log('❌ Error handling Google user: $e', name: 'AuthService');
      return AuthResult.failure('Failed to process your Google account. Please try again.');
    }
  }

  // NEW: Create profile for new Google users
  static Future<AuthResult> _createNewGoogleUser(String userId, String email, String name) async {
    try {
      developer.log('📝 Creating new Google user profile for: $email', name: 'AuthService');

      // Create user document with comprehensive data
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': 'parent', // Default role for new Google users
        'email': email.trim(),
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': true, // Google accounts are pre-verified
        'provider': 'google',
        'lastSignIn': FieldValue.serverTimestamp(),
        'isNewGoogleUser': true, // Flag for welcome message
      });

      developer.log('✅ New Google user profile created successfully', name: 'AuthService');
      
      // Return special result for new Google users (triggers welcome dialog)
      return AuthResult.newGoogleUser(email, name);

    } catch (e) {
      developer.log('❌ Failed to create new Google user profile: $e', name: 'AuthService');
      
      // Sign out the user since we couldn't create their profile
      try {
        await _auth.signOut();
      } catch (signOutError) {
        developer.log('❌ Also failed to sign out user: $signOutError', name: 'AuthService');
      }
      
      return AuthResult.failure(
        'Failed to create your account profile. Please try again or contact support.'
      );
    }
  }

  // NEW: Handle existing Google users
  static Future<AuthResult> _handleExistingGoogleUser(DocumentSnapshot userDoc, String email) async {
    try {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String?;

      if (userRole == null || userRole.isEmpty) {
        developer.log('❌ Existing user has no role assigned', name: 'AuthService');
        return AuthResult.failure('Your account role is not set. Please contact support.');
      }

      // Update last sign-in time and ensure profile is up to date
      await userDoc.reference.update({
        'lastSignIn': FieldValue.serverTimestamp(),
        'emailVerified': true, // Ensure Google users are marked as verified
      });

      developer.log('✅ Existing Google user sign-in successful. Role: $userRole', name: 'AuthService');
      return AuthResult.success(userRole);

    } catch (e) {
      developer.log('❌ Error handling existing Google user: $e', name: 'AuthService');
      return AuthResult.failure('Failed to load your account information. Please try again.');
    }
  }

  static Future<AuthResult> resetPassword({
    required String email,
  }) async {
    try {
      developer.log('🔐 Starting password reset for email: $email',
          name: 'AuthService');

      // Clean the email
      final cleanEmail = email.trim().toLowerCase();
      developer.log('📧 Cleaned email: $cleanEmail', name: 'AuthService');

      // REMOVED: Don't check if user exists - let Firebase handle this
      // The fetchSignInMethodsForEmail method was causing false negatives

      // Send password reset email directly
      await _auth.sendPasswordResetEmail(email: cleanEmail);

      developer.log('✅ Password reset email sent successfully to: $cleanEmail',
          name: 'AuthService');
      return AuthResult.passwordResetSent(cleanEmail);
    } catch (e) {
      developer.log('❌ Password reset error: $e', name: 'AuthService');
      final errorString = e.toString().toLowerCase();

      // Handle specific Firebase errors
      if (errorString.contains('user-not-found')) {
        return AuthResult.failure('No account found with this email address.');
      } else if (errorString.contains('invalid-email')) {
        return AuthResult.failure('Please enter a valid email address.');
      } else if (errorString.contains('too-many-requests')) {
        return AuthResult.failure(
            'Too many password reset attempts. Please wait a few minutes.');
      } else {
        return AuthResult.failure(
            'Unable to send reset email. Please try again.');
      }
    }
  }

  static Future<void> resendVerificationEmail(dynamic user) async {
    try {
      await user.sendEmailVerification();
      developer.log('Verification email resent to: ${user.email}',
          name: 'AuthService');
    } catch (e) {
      developer.log('Failed to resend verification email: $e',
          name: 'AuthService');
      throw e;
    }
  }

  // LEGACY: Keep this method for backward compatibility but it's now replaced by _handleGoogleUser
  static Future<void> _ensureUserDocument(
      String userId, String email, String? userRole) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        developer.log('Creating new user document for UID: $userId',
            name: 'AuthService');
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'role': 'parent',
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (userRole == null) {
        developer.log('Updating user role for UID: $userId',
            name: 'AuthService');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'role': 'parent',
          'email': email.trim(),
        });
      }
    } catch (e) {
      developer.log('Error ensuring user document: $e', name: 'AuthService');
    }
  }

  // NEW: Testing method for Google Sign-In configuration
  static Future<void> testGoogleSignInSetup() async {
    try {
      developer.log('🧪 Testing Google Sign-In setup...', name: 'AuthService');
      
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signInSilently();
      
      if (account != null) {
        developer.log('✅ Google Sign-In: User already signed in: ${account.email}', name: 'AuthService');
      } else {
        developer.log('ℹ️ Google Sign-In: No user currently signed in', name: 'AuthService');
      }
      
      developer.log('✅ Google Sign-In configuration appears to be working', name: 'AuthService');
    } catch (e) {
      developer.log('❌ Google Sign-In configuration issue: $e', name: 'AuthService');
    }
  }
}

// ENHANCED: Result classes with better error handling
abstract class AuthResult {
  const AuthResult();

  factory AuthResult.success(String? userRole) = AuthSuccess;
  factory AuthResult.failure(String message) = AuthFailure;
  factory AuthResult.emailNotVerified(dynamic user) = AuthEmailNotVerified;
  factory AuthResult.registrationSuccess(String email) = AuthRegistrationSuccess;
  factory AuthResult.passwordResetSent(String email) = AuthPasswordResetSent;
  factory AuthResult.loginException(LoginException exception) = AuthLoginException;
  factory AuthResult.googleSignInCanceled() = AuthGoogleSignInCanceled;
  factory AuthResult.newGoogleUser(String email, String name) = AuthNewGoogleUser; // NEW
}

class AuthSuccess extends AuthResult {
  final String? userRole;
  const AuthSuccess(this.userRole);
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

class AuthEmailNotVerified extends AuthResult {
  final dynamic user;
  const AuthEmailNotVerified(this.user);
}

class AuthRegistrationSuccess extends AuthResult {
  final String email;
  const AuthRegistrationSuccess(this.email);
}

class AuthPasswordResetSent extends AuthResult {
  final String email;
  const AuthPasswordResetSent(this.email);
}

// For detailed login exceptions
class AuthLoginException extends AuthResult {
  final LoginException exception;
  const AuthLoginException(this.exception);
}

// Specific for Google Sign-In cancellation
class AuthGoogleSignInCanceled extends AuthResult {
  const AuthGoogleSignInCanceled();
}

// NEW: For new Google users (triggers welcome dialog)
class AuthNewGoogleUser extends AuthResult {
  final String email;
  final String name;
  const AuthNewGoogleUser(this.email, this.name);
}