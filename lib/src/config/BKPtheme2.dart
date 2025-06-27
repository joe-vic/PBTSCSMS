// import 'package:flutter/material.dart';
// // REMOVED: import 'package:google_fonts/google_fonts.dart';

// class SMSTheme {
//   // Primary Colors
//   static const Color primaryColor = Color(0xFF6A9C89); // Dark Teal
//   static const Color secondaryColor = Color(0xFFFFA725); // Orange
//   static const Color tertiaryColor = Color(0xFFFB8C00); // Darker Orange

//   // Surface Colors
//   static const Color surfaceColor = Color(0xFFFFFFFF);
//   static const Color backgroundColorLight = Color(0xFFF5F5F5);
//   static const Color backgroundColorDark = Color(0xFF202124);

//   // Text Colors
//   static const Color textPrimaryLight = Color(0xFF212121);
//   static const Color textSecondaryLight = Color(0xFF757575);
//   static const Color textPrimaryDark = Color(0xFFFFFFFF);
//   static const Color textSecondaryDark = Color(0xFFBDC1C6);

//   // Status Colors
//   static const Color successColor = Color(0xFF388E3C);
//   static const Color errorColor = Color(0xFFD32F2F);
//   static const Color warningColor = Color(0xFFFFA000);
//   static const Color infoColor = Color(0xFF6A9C89);

//   // Elevation Colors
//   static const List<Color> elevationLight = [
//     Color(0x0D000000),
//     Color(0x14000000),
//     Color(0x1F000000),
//   ];

//   static const List<Color> elevationDark = [
//     Color(0x0DFFFFFF),
//     Color(0x14FFFFFF),
//     Color(0x1FFFFFFF),
//   ];

//   // Light Theme
//   static ThemeData get lightTheme {
//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: ColorScheme.light(
//         primary: primaryColor,
//         secondary: secondaryColor,
//         tertiary: tertiaryColor,
//         surface: surfaceColor,
//         background: backgroundColorLight,
//         error: errorColor,
//         onPrimary: Colors.white,
//         onSecondary: Colors.black,
//         onTertiary: Colors.black,
//         onSurface: textPrimaryLight,
//         onBackground: textPrimaryLight,
//         onError: Colors.white,
//       ),
//       textTheme: GoogleFonts.poppinsTextTheme(),
//       appBarTheme: AppBarTheme(
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         titleTextStyle: TextStyle(fontFamily: 'Poppins',
//           fontSize: 20,
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//       ),
//       cardTheme: CardThemeData(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         color: surfaceColor,
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryColor,
//           foregroundColor: Colors.white,
//           elevation: 2,
//           padding: const EdgeInsets.symmetric(
//             horizontal: 24,
//             vertical: 12,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           textStyle: TextStyle(fontFamily: 'Poppins',
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: primaryColor,
//           padding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 8,
//           ),
//           textStyle: TextStyle(fontFamily: 'Poppins',
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: primaryColor,
//           side: BorderSide(color: primaryColor),
//           padding: const EdgeInsets.symmetric(
//             horizontal: 24,
//             vertical: 12,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           textStyle: TextStyle(fontFamily: 'Poppins',
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: backgroundColorLight,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide.none,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide.none,
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: primaryColor),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: errorColor),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         hintStyle: TextStyle(fontFamily: 'Poppins',
//           color: textSecondaryLight,
//         ),
//       ),
//       snackBarTheme: SnackBarThemeData(
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       dividerTheme: const DividerThemeData(
//         color: Color(0xFFE8EAED),
//         thickness: 1,
//         space: 1,
//       ),
//       tooltipTheme: TooltipThemeData(
//         decoration: BoxDecoration(
//           color: textPrimaryLight.withOpacity(0.9),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         textStyle: TextStyle(fontFamily: 'Poppins',
//           color: Colors.white,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   // Dark Theme (to be implemented)
//   static ThemeData get darkTheme {
//     // TODO: Implement dark theme
//     return lightTheme;
//   }
// }
