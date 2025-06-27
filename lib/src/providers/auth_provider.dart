import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _userRole;
  bool _isLoadingRole = false;

  AuthProvider() {
    print('AuthProvider initialized');
    _auth.authStateChanges().listen((user) async {
      print('Auth state changed. User: ${user?.uid ?? "null"}');
      _user = user;
      if (user != null) {
        _isLoadingRole = true;
        notifyListeners(); // Notify that we're loading the role
        
        try {
          print('Fetching role for UID: ${user.uid}');
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          print('User document exists: ${userDoc.exists}');
          
          if (userDoc.exists) {
            _userRole = (userDoc['role'] as String?)?.toLowerCase() ?? 'none';
            print('Fetched role: $_userRole for UID: ${user.uid}');
          } else {
            _userRole = 'none';
            print('User document does not exist, setting role to none');
          }
        } catch (e) {
          print('Error fetching role in authStateChanges: $e');
          _userRole = 'none'; // Fallback in case of error
        } finally {
          _isLoadingRole = false;
          notifyListeners(); // Notify that role loading is complete
        }
      } else {
        _userRole = null;
        _isLoadingRole = false;
        print('User logged out, role set to null');
        notifyListeners();
      }
    });
  }

  bool get isAuthenticated => _user != null;
  String? get userRole => _userRole;
  User? get user => _user;
  bool get isLoadingRole => _isLoadingRole;

  Future<void> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      print('Signed in successfully. User UID: ${_user?.uid}');
      
      if (_user != null) {
        _isLoadingRole = true;
        notifyListeners(); // Notify that we're loading the role
        
        try {
          print('Fetching role for UID: ${_user!.uid} after sign-in');
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
          print('User document exists after sign-in: ${userDoc.exists}');
          
          if (userDoc.exists) {
            _userRole = (userDoc['role'] as String?)?.toLowerCase() ?? 'none';
            print('Fetched role after sign-in: $_userRole for UID: ${_user!.uid}');
          } else {
            _userRole = 'none';
            print('User document does not exist after sign-in, setting role to none');
          }
        } catch (e) {
          print('Error fetching role after sign-in: $e');
          _userRole = 'none'; // Fallback in case of error
        } finally {
          _isLoadingRole = false;
          notifyListeners(); // Notify that role loading is complete
        }
      }
    } catch (e) {
      print('Sign-in error: $e');
      _isLoadingRole = false;
      notifyListeners();
      throw Exception('Login failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In canceled by user');
        throw Exception('Google Sign-In canceled');
      }

      print('Google Sign-In successful for email: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      print('Google Sign-In authenticated with Firebase. UID: ${_user?.uid}');

      if (_user != null) {
        try {
          print('Fetching role for UID: ${_user!.uid} after Google sign-in');
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
          print('User document exists after Google sign-in: ${userDoc.exists}');
          if (!userDoc.exists) {
            print('New Google user detected for UID: ${_user!.uid}, setting default role to parent');
            await _firestore.collection('users').doc(_user!.uid).set(
              {
                'role': 'parent',
                'email': googleUser.email,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
            _userRole = 'parent';
          } else {
            // Normalize role to lowercase and provide a default if missing
            _userRole = userDoc.exists ? (userDoc['role'] as String?)?.toLowerCase() ?? 'none' : 'none';
          }
          print('Fetched role after Google sign-in: $_userRole for UID: ${_user!.uid}');
        } catch (e) {
          print('Error fetching role after Google sign-in: $e');
          _userRole = 'none'; // Fallback in case of error
        }
      }
      notifyListeners();
    } catch (e) {
      print('Google Sign-In error: $e');
      throw Exception('Google login failed: $e');
    }
  }

  Future<void> signOut() async {
    print('Attempting to sign out');
    await _auth.signOut();
    _user = null;
    _userRole = null;
    print('Signed out successfully');
    notifyListeners();
  }


  // Inside auth_provider.dart
Future<void> register(String email, String password) async {
  try {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _user = credential.user;
    notifyListeners();
  } catch (e) {
    rethrow; // Re-throw the error to handle it in the UI
  }
}
}