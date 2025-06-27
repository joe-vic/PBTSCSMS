import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart' as LocalAuthProvider;
import '../parent/parent_dashboard.dart';
import '../student/StudentDashboard.dart';
import 'login_screen.dart';
import '../../config/theme.dart';
import 'package:animate_do/animate_do.dart';

class UserRegistrationScreen extends StatefulWidget {
  final String userRole; // 'parent' or 'student'
  
  const UserRegistrationScreen({
    super.key,
    required this.userRole,
  });

  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validation helpers
  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'First name is too short';
    }
    return null;
  }
  
  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Last name is too short';
    }
    return null;
  }
  
  String? _validateMiddleName(String? value) {
    // Middle name can be optional
    return null;
  }
  
  String? _validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final bool emailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value);
    if (!emailValid) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Clean error messages
  String _getCleanErrorMessage(String errorMessage) {
    if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email format.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'An error occurred. Please try again.';
  }

  // Register user with email/password
  Future<void> _registerUser() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with Firebase Authentication
      await Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false)
          .register(_emailController.text, _passwordController.text);

      final authProvider = Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId != null && mounted) {
        // Combine full name
        String fullName = '${_firstNameController.text} ${_middleNameController.text} ${_lastNameController.text}';
        
        // Store user data in Firestore with the selected role
        Map<String, dynamic> userData = {
          'role': widget.userRole, // 'parent' or 'student'
          'email': _emailController.text,
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'fullName': fullName.trim(),
          'contactNumber': _contactNumberController.text,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        // Additional fields based on user type
        if (widget.userRole == 'parent') {
          userData['students'] = []; // Empty list for future student registrations
        } else if (widget.userRole == 'student') {
          userData['gradeLevel'] = '';
          userData['enrolled'] = false;
          userData['parentId'] = '';
        }
        
        await FirebaseFirestore.instance.collection('users').doc(userId).set(userData);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful!',
              style: TextStyle(fontFamily: 'Poppins',),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Navigate to appropriate dashboard
        if (mounted) {
          if (widget.userRole == 'parent') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ParentDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) =>  StudentDashboard()),
            );
          }
        }
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getCleanErrorMessage(e.toString());
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
  
  // Register with Google
  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in with Google
      await Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false).signInWithGoogle();
      
      final authProvider = Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userId = user?.uid;
      
      if (userId != null && mounted) {
        // Check if this Google account already has a user document
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          // User already exists, navigate to their dashboard
          final userData = userDoc.data() as Map<String, dynamic>;
          final userRole = userData['role'] as String?;
          
          // Navigate based on existing role
          if (mounted) {
            if (userRole == 'parent') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ParentDashboard()),
              );
            } else if (userRole == 'student') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) =>  StudentDashboard()),
              );
            } else {
              // Fallback to parent dashboard if role is undefined
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ParentDashboard()),
              );
            }
          }
        } else {
          // New Google user, create a document with the selected role
          
          // Extract name parts from Google info
          String? displayName = user?.displayName ?? '';
          List<String> nameParts = displayName.split(' ');
          
          String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          String lastName = nameParts.length > 1 ? nameParts.last : '';
          String middleName = '';
          
          if (nameParts.length > 2) {
            // Extract middle name/s (everything between first and last)
            middleName = nameParts.sublist(1, nameParts.length - 1).join(' ');
          }
          
          // Create user document
          Map<String, dynamic> userData = {
            'role': widget.userRole,
            'email': user?.email ?? '',
            'firstName': firstName,
            'middleName': middleName,
            'lastName': lastName,
            'fullName': displayName,
            'contactNumber': '',  // Google doesn't provide phone number
            'photoURL': user?.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          // Additional fields based on user type
          if (widget.userRole == 'parent') {
            userData['students'] = [];
          } else if (widget.userRole == 'student') {
            userData['gradeLevel'] = '';
            userData['enrolled'] = false;
            userData['parentId'] = '';
          }
          
          await FirebaseFirestore.instance.collection('users').doc(userId).set(userData);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Google registration successful!',
                style: TextStyle(fontFamily: 'Poppins',),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          
          // Navigate to appropriate dashboard
          if (mounted) {
            if (widget.userRole == 'parent') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ParentDashboard()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) =>  StudentDashboard()),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Google registration error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getCleanErrorMessage(e.toString());
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: 100,
                      height: 100,
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
                                size: 60,
                                color: SMSTheme.primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // School name
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Philippine Best Training',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 24,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Student Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Registration form card
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create ${widget.userRole.capitalize()} Account',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: SMSTheme.primaryColor,
                                ),
                              ),
                              
                              Text(
                                'Enter your details to register',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: SMSTheme.textSecondaryColor,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // First Name field
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  hintText: 'Enter your first name',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.person, color: SMSTheme.primaryColor),
                                ),
                                validator: _validateFirstName,
                                textInputAction: TextInputAction.next,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Middle Name field
                              TextFormField(
                                controller: _middleNameController,
                                decoration: InputDecoration(
                                  labelText: 'Middle Name (Optional)',
                                  hintText: 'Enter your middle name',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.person_outline, color: SMSTheme.primaryColor),
                                ),
                                validator: _validateMiddleName,
                                textInputAction: TextInputAction.next,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Last Name field
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  hintText: 'Enter your last name',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.people, color: SMSTheme.primaryColor),
                                ),
                                validator: _validateLastName,
                                textInputAction: TextInputAction.next,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Contact Number field
                              TextFormField(
                                controller: _contactNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Contact Number',
                                  hintText: 'Enter your contact number',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.phone, color: SMSTheme.primaryColor),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: _validateContactNumber,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(15),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.email, color: SMSTheme.primaryColor),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                textInputAction: TextInputAction.next,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Create a password',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.lock, color: SMSTheme.primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: _validatePassword,
                                textInputAction: TextInputAction.next,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Confirm Password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: 'Confirm your password',
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: Icon(Icons.lock_outline, color: SMSTheme.primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_isConfirmPasswordVisible,
                                validator: _validateConfirmPassword,
                                textInputAction: TextInputAction.done,
                              ),
                              
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                
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
                              
                              const SizedBox(height: 24),
                              
                              // Register button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _registerUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SMSTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          'Register',
                                          style: TextStyle(fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Divider
                              Row(
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
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Google login button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _registerWithGoogle,
                                  icon: Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  label: Text(
                                    'Register with Google',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: SMSTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account?',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      color: SMSTheme.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(fontFamily: 'Poppins',
                                        color: SMSTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer text
                  FadeIn(
                    delay: const Duration(milliseconds: 1000),
                    child: Text(
                      '© ${DateTime.now().year} PBTS Colleges Inc.',
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}