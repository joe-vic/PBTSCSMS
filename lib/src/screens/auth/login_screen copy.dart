import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as LocalAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_dashboard.dart'; // Adjust path as needed
import '../parent/parent_dashboard.dart'; // Adjust path as needed
import '../cashier/dashboard/CashierDashboard.dart'; // Adjust path as needed
import '../registrar/registrar_dashboard.dart'; // Adjust path as needed
import '../student/StudentDashboard.dart'; // Adjust path as needed
import '../teacher/screens/teacher_dashboard_screen.dart'; // Adjust path as needed

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
          'Starting email/password login for email: ${_emailController.text}');
      await Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false)
          .signIn(_emailController.text, _passwordController.text);

      final authProvider =
          Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      final userRole = authProvider.userRole;
      if (userId != null) {
        print('Waiting 500ms before checking user document for UID: $userId');
        await Future.delayed(const Duration(milliseconds: 500));
        print('Checking user document for UID: $userId, Role: $userRole');

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (!userDoc.exists) {
          print(
              'New user detected for UID: $userId, setting default role to parent');
          await FirebaseFirestore.instance.collection('users').doc(userId).set(
            {
              'role': 'parent',
              'email': _emailController.text,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else if (userRole == null) {
          print(
              'Existing user with no role for UID: $userId, setting to parent');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update(
            {
              'role': 'parent',
              'email': _emailController.text,
            },
          );
        }

        if (mounted) {
          Widget nextScreen;
          switch (userRole) {
            case 'admin':
              nextScreen = AdminDashboard();
              break;
            case 'parent':
              nextScreen = const ParentDashboard();
              break;
            case 'cashier':
              nextScreen = const CashierDashboard();
              break;
            case 'registrar':
              nextScreen = RegistrarDashboard();
              break;
            case 'student':
              nextScreen = StudentDashboard();
              break;
            case 'teacher':
              nextScreen = TeacherDashboardScreen();
              break;
            default:
              print('Unknown role: $userRole, defaulting to ParentDashboard');
              nextScreen = const ParentDashboard();
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      }
    } catch (e) {
      print('Login or document update error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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

  Future<void> _googleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false)
          .signInWithGoogle();

      final authProvider =
          Provider.of<LocalAuthProvider.AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      final userRole = authProvider.userRole;

      if (userId != null && mounted) {
        Widget nextScreen;
        switch (userRole) {
          case 'admin':
            nextScreen = AdminDashboard();
            break;
          case 'parent':
            nextScreen = const ParentDashboard();
            break;
          case 'cashier':
            nextScreen = const CashierDashboard();
            break;
          case 'registrar':
            nextScreen = RegistrarDashboard();
            break;
          case 'student':
            nextScreen = StudentDashboard();
            break;
          case 'teacher':
            nextScreen = TeacherDashboardScreen();
            break;
          default:
            print('Unknown role: $userRole, defaulting to ParentDashboard');
            nextScreen = const ParentDashboard();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } catch (e) {
      print('Google login error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A9C89), Color(0xFFC1D8C3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _animation,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome Back',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Login',
                                  style: TextStyle(fontSize: 16)),
                            ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              onPressed: _googleLogin,
                              icon: Icon(Icons.login,
                                  color: Theme.of(context).primaryColor),
                              label: Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                side: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
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
}
