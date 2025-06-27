import 'package:flutter/services.dart';

class NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits and decimal points
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Handle decimal points
    final parts = digitsOnly.split('.');
    if (parts.length > 2) {
      return oldValue; // Invalid input, keep old value
    }

    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Add commas to integer part
    if (integerPart.length > 3) {
      final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      integerPart =
          integerPart.replaceAllMapped(regex, (Match m) => '${m[1]},');
    }

    // Combine parts
    String formatted = integerPart;
    if (parts.length > 1) {
      formatted += '.$decimalPart';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 