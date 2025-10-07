import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Function(DateTime?) onChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final FocusNode? focusNode;
  final bool isRequired;
  final bool showValidation;

  const DatePickerField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.readOnly = false,
    this.focusNode,
    this.isRequired = false,
    this.showValidation = false,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    if (readOnly) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: SMSTheme.primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: SMSTheme.primaryColor),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = value != null ? DateFormat('MM/dd/yyyy').format(value!) : '';
    final hasError = showValidation && validator?.call(dateStr) != null;

    return TextFormField(
      // **Use initialValue instead of a controller** so we don’t lose focus every rebuild
      initialValue: dateStr,
      readOnly: true, // keep it non-editable, but still tappable
      onTap: () {
        _selectDate(context);
      },
      focusNode: focusNode,
      validator: showValidation ? (v) => validator?.call(dateStr) : null,
      autovalidateMode: showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: hasError ? Colors.red : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(Icons.calendar_today,
            color: hasError ? Colors.red : SMSTheme.primaryColor),
        suffixIcon: dateStr.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: readOnly ? null : () => onChanged(null),
                color:
                    hasError ? Colors.red : SMSTheme.primaryColor,
              )
            : null,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.shade300,
              width: hasError ? 2 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: hasError ? Colors.red : SMSTheme.primaryColor,
              width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Poppins',
      ),
    );
  }
}
