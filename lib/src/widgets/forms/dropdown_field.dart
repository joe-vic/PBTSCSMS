import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../config/theme.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool isExpanded;
  final IconData? icon;
  final FocusNode? focusNode;
  final bool isRequired;

  const DropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.isExpanded = true,
    this.icon,
    this.focusNode,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIXED: Remove duplicates but PRESERVE ORDER - no sorting!
    final uniqueItems = _removeDuplicatesPreserveOrder(items);

    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Search',
            prefixIcon: Icon(Icons.search, color: SMSTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        menuProps: MenuProps(
          borderRadius: BorderRadius.circular(12),
        ),
        fit: FlexFit.loose,
        constraints: BoxConstraints(maxHeight: 300),
      ),
      items: uniqueItems,
      selectedItem: value,
      onChanged: onChanged,
      validator: validator,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            fontFamily: 'Poppins', // LOCAL FONT
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SMSTheme.primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SMSTheme.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SMSTheme.errorColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          prefixIcon:
              icon != null ? Icon(icon, color: SMSTheme.primaryColor) : null,
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(
            fontFamily: 'Poppins', // LOCAL FONT
            color: Colors.red[700],
          ),
        ),
      ),
    );
  }

  // FIXED: Helper method to remove duplicates while preserving order
  List<String> _removeDuplicatesPreserveOrder(List<String> items) {
    final Set<String> seen = <String>{};
    final List<String> result = <String>[];
    
    for (final item in items) {
      if (seen.add(item)) { // add() returns true if item was not already in set
        result.add(item);
      }
    }
    
    return result;
  }
}