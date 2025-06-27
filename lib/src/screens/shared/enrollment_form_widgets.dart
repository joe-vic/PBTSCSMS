// import 'package:flutter/material.dart';
// // REMOVED: import 'package:google_fonts/google_fonts.dart';
// import '../../config/theme.dart';

// /// Shared widgets for both online and cashier enrollment forms
// class EnrollmentFormWidgets {
//   /// Builds a text field with consistent styling
//   static Widget buildTextField({
//     required String label,
//     required TextEditingController? controller,
//     required String? Function(String?)? validator,
//     required void Function(String)? onChanged,
//     TextInputType keyboardType = TextInputType.text,
//     List<TextInputFormatter>? inputFormatters,
//     bool readOnly = false,
//     IconData prefixIcon = Icons.edit,
//     VoidCallback? onTap,
//     String? initialValue,
//     bool isRequired = false,
//   }) {
//     return TextFormField(
//       controller: controller,
//       initialValue: controller == null ? initialValue : null,
//       readOnly: readOnly,
//       keyboardType: keyboardType,
//       inputFormatters: inputFormatters,
//       decoration: InputDecoration(
//         labelText: isRequired ? '$label *' : label,
//         labelStyle: TextStyle(color: SMSTheme.textSecondaryColor),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: SMSTheme.primaryColor, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         prefixIcon: Icon(prefixIcon, color: SMSTheme.primaryColor),
//         suffixIcon: readOnly && onTap != null
//             ? Icon(Icons.arrow_drop_down, color: SMSTheme.primaryColor)
//             : null,
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: SMSTheme.errorColor),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: SMSTheme.errorColor, width: 2),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       ),
//       style: TextStyle(fontFamily: 'Poppins',color: SMSTheme.textPrimaryColor),
//       cursorColor: SMSTheme.primaryColor,
//       validator: validator,
//       onChanged: onChanged,
//       onTap: onTap,
//     );
//   }

//   /// Builds a section header
//   static Widget buildSectionHeader(String title, {String? subtitle}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(fontFamily: 'Poppins',
//             fontSize: 20, 
//             fontWeight: FontWeight.bold, 
//             color: SMSTheme.primaryColor,
//           ),
//         ),
//         if (subtitle != null) ...[
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: TextStyle(fontFamily: 'Poppins',
//               fontSize: 14, 
//               color: SMSTheme.textSecondaryColor,
//             ),
//           ),
//         ],
//         const SizedBox(height: 16),
//       ],
//     );
//   }
  
//   /// Builds a review item (label: value)
//   static Widget buildReviewItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label + ':',
//               style: TextStyle(fontFamily: 'Poppins',
//                 fontWeight: FontWeight.w600,
//                 color: SMSTheme.textSecondaryColor,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(fontFamily: 'Poppins',
//                 color: SMSTheme.textPrimaryColor,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   /// Builds an info card with icon
//   static Widget buildInfoCard({
//     required IconData icon, 
//     required Color color, 
//     required String title, 
//     required String message,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(icon, color: color),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(fontFamily: 'Poppins',
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       message,
//                       style: TextStyle(fontFamily: 'Poppins',
//                         fontSize: 13,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }