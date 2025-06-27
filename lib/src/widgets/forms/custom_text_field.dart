import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// REMOVED: // REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? value;
  final Function(String) onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final String? hintText;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final bool isRequired;
  final bool hasError;
  final bool showValidation;
  final InputBorder? errorBorder;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final bool autofocus;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.hintText,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.prefixIcon,
    this.focusNode,
    this.isRequired = false,
    this.hasError = false,
    this.showValidation = false,
    this.errorBorder,
    this.enabledBorder,
    this.focusedBorder,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.isRequired ? '${widget.label} *' : widget.label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins', // LOCAL FONT
          color: (widget.hasError && widget.showValidation)
              ? Colors.red
              : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: widget.enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (widget.hasError && widget.showValidation)
                    ? Colors.red
                    : Colors.grey.shade300,
                width: (widget.hasError && widget.showValidation) ? 2 : 1,
              ),
            ),
        focusedBorder: widget.focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (widget.hasError && widget.showValidation)
                    ? Colors.red
                    : SMSTheme.primaryColor,
                width: 2,
              ),
            ),
        errorBorder: widget.errorBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.white : Colors.grey[100],
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                color: (widget.hasError && widget.showValidation)
                    ? Colors.red
                    : SMSTheme.primaryColor)
            : null,
        errorStyle: TextStyle(
          fontFamily: 'Poppins', // LOCAL FONT
          color: Colors.red[700],
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Poppins', // LOCAL FONT
      ),
      onChanged: widget.onChanged,
      validator: widget.showValidation ? widget.validator : null,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      focusNode: widget.focusNode,
      autovalidateMode: widget.showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      autofocus: widget.autofocus,
    );
  }
}