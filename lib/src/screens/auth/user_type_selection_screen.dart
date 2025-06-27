import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'user_registration_screen.dart'; // Updated import
import 'package:animate_do/animate_do.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and header
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: 120,
                        height: 120,
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
                                  size: 80,
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
                    
                    const SizedBox(height: 40),
                    
                    // Role selection card
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Text(
                                'REGISTER AS',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: SMSTheme.primaryColor,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Select your account type',
                                style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: SMSTheme.textSecondaryColor,
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Role selection options
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Parent Option
                                  _buildRoleOption(
                                    context, 
                                    'Parent',
                                    'parent',
                                    Icons.family_restroom,
                                  ),
                                  
                                  // Student Option
                                  _buildRoleOption(
                                    context, 
                                    'Student',
                                    'student',
                                    Icons.school,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Back button
                              TextButton.icon(
                                onPressed: () {
                                   Navigator.of(context).pushReplacementNamed('/login');
                                },
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: SMSTheme.primaryColor,
                                  size: 20,
                                ),
                                label: Text(
                                  'Back to Login',
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
      ),
    );
  }
  
  // Build each role option button with icon and consistent theme
  Widget _buildRoleOption(BuildContext context, String label, String role, IconData icon) {
    return InkWell(
      onTap: () {
        // Navigate to registration screen with the selected role
          if (role == 'parent') {
            Navigator.of(context).pushNamed('/register/parent');
          } else if (role == 'student') {
            Navigator.of(context).pushNamed('/register/student');
          }
      },
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: SMSTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: SMSTheme.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: SMSTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}