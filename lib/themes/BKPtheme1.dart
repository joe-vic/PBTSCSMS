import 'package:flutter/material.dart';

class SMSTheme {
  static const Color primaryColor = Color(0xFF6A9C89); // Dark Teal
  static const Color secondaryColor = Color(0xFFFFA725); // Orange
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardColor = Color(0xFFF5F5F5); // Light Gray for cards
  static const Color textPrimaryColor = Color(0xFF212121); // Dark Gray
  static const Color textSecondaryColor = Color(0xFF757575); // Medium Gray
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  static const Color adBackgroundColor = Color(0xFFE0E0E0); // Very Light Gray

  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: secondaryColor,
        error: errorColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textPrimaryColor),
        bodySmall: TextStyle(color: textSecondaryColor),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
      ),
      iconTheme: const IconThemeData(
        color: secondaryColor,
      ),
    );
  }
}