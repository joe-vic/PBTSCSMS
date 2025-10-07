import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'src/config/theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/services/firestore_service.dart';

// Screens
import 'src/screens/auth/login_screen.dart';
import 'src/screens/parent/parent_dashboard.dart';
import 'src/screens/admin/admin_dashboard.dart';
import 'src/screens/teacher/screens/teacher_dashboard_screen.dart';
import 'src/screens/registrar/registrar_dashboard.dart';
import 'src/screens/cashier/dashboard/CashierDashboard.dart';
import 'src/screens/auth/user_type_selection_screen.dart';
import 'src/screens/auth/user_registration_screen.dart';
import 'src/screens/auth/parent_registration_screen.dart';
import 'src/screens/auth/student_registration_screen.dart';
 
// // REMOVED: import 'package:google_fonts/google_fonts.dart'; // If you still have this dependency


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

 
  //  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'School Management System',
        debugShowCheckedModeBanner: false,
        theme: SMSTheme.lightTheme,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/select-role': (context) => const UserTypeSelectionScreen(),
          '/register/parent': (context) => const ParentRegistrationScreen(),
          '/register/student': (context) => const StudentRegistrationScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/teacher': (context) => TeacherDashboardScreen(),
          '/parent': (context) => const ParentDashboard(),
          '/registrar': (context) => RegistrarDashboard(),
          '/cashier': (context) => const CashierDashboard(),
        },
        home: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (!auth.isAuthenticated) {
              return const LoginScreen();
            }

            // Wait until user role is loaded
            if (auth.isLoadingRole || auth.userRole == null) {
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
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading your dashboard...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Navigate based on role
            switch (auth.userRole) {
              case 'admin':
                return const AdminDashboard();
              case 'teacher':
                return TeacherDashboardScreen();
              case 'parent':
                return const ParentDashboard();
              case 'registrar':
                return RegistrarDashboard();
              case 'cashier':
                return const CashierDashboard();
              default:
                return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
