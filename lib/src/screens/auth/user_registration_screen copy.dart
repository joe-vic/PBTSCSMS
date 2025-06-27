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
  const UserRegistrationScreen({super.key});

  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactNumberController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  String _userType = 'parent'; // Default to parent registration
  
  // Validation helpers
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name is too short';
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

  String? _validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    
    // Basic Philippine phone number validation
    // Format: +63XXXXXXXXXX or 09XXXXXXXXX
    final bool isValidPhilippineNumber = RegExp(r'^(\+63|0)[0-9]{10}$').hasMatch(value);
    if (!isValidPhilippineNumber) {
      return 'Enter a valid Philippine phone number';
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

  // Register user
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
        // Create user document in Firestore with role
        Map<String, dynamic> userData = {
          'role': _userType, // 'parent' or 'student'
          'email': _emailController.text,
          'name': _nameController.text,
          'contactNumber': _contactNumberController.text,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        // Additional fields based on user type
        if (_userType == 'parent') {
          userData['students'] = []; // Empty list for future student registrations
        } else if (_userType == 'student') {
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
          if (_userType == 'parent') {
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNumberController.dispose();
    super.dispose();
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and header
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
                    
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Join Philippine Best Training Systems Colleges',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Registration card
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User type selection
                                Text(
                                  'I am registering as a:',
                                  style: TextStyle(fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: SMSTheme.textPrimaryColor,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // User type selection buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _userType = 'parent';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: _userType == 'parent' 
                                              ? SMSTheme.primaryColor.withOpacity(0.2) 
                                              : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _userType == 'parent'
                                                ? SMSTheme.primaryColor
                                                : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.family_restroom,
                                                color: _userType == 'parent'
                                                  ? SMSTheme.primaryColor
                                                  : Colors.grey.shade600,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Parent',
                                                style: TextStyle(fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                  color: _userType == 'parent'
                                                    ? SMSTheme.primaryColor
                                                    : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _userType = 'student';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: _userType == 'student' 
                                              ? SMSTheme.primaryColor.withOpacity(0.2) 
                                              : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _userType == 'student'
                                                ? SMSTheme.primaryColor
                                                : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.school,
                                                color: _userType == 'student'
                                                  ? SMSTheme.primaryColor
                                                  : Colors.grey.shade600,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Student',
                                                style: TextStyle(fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                  color: _userType == 'student'
                                                    ? SMSTheme.primaryColor
                                                    : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Name field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
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
                                    prefixIcon: Icon(Icons.person, color: SMSTheme.primaryColor),
                                    labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
                                    hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.name,
                                  style: TextStyle(fontFamily: 'Poppins',),
                                  validator: _validateName,
                                  textInputAction: TextInputAction.next,
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
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red.shade300),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: Icon(Icons.email, color: SMSTheme.primaryColor),
                                    labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
                                    hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontFamily: 'Poppins',),
                                  validator: _validateEmail,
                                  textInputAction: TextInputAction.next,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Contact number field
                                TextFormField(
                                  controller: _contactNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Contact Number',
                                    hintText: '+63XXXXXXXXXX or 09XXXXXXXXX',
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
                                    prefixIcon: Icon(Icons.phone, color: SMSTheme.primaryColor),
                                    labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
                                    hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                    LengthLimitingTextInputFormatter(13),
                                  ],
                                  style: TextStyle(fontFamily: 'Poppins',),
                                  validator: _validateContactNumber,
                                  textInputAction: TextInputAction.next,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Create a strong password',
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
                                    prefixIcon: Icon(Icons.lock, color: SMSTheme.primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                        color: SMSTheme.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
                                    hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  style: TextStyle(fontFamily: 'Poppins',),
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
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red.shade300),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: Icon(Icons.lock_outline, color: SMSTheme.primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                        color: SMSTheme.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                    labelStyle: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textSecondaryColor),
                                    hintStyle: TextStyle(fontFamily: 'Poppins',color: Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  obscureText: !_isConfirmPasswordVisible,
                                  style: TextStyle(fontFamily: 'Poppins',),
                                  validator: _validateConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _registerUser(),
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
                                
                                // Login link
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Row(
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer text
                    Text(
                      '© ${DateTime.now().year} PBTS Colleges Inc.',
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}