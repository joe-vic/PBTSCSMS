// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// // REMOVED: import 'package:google_fonts/google_fonts.dart';
// import '../../providers/enrollment_payment_provider.dart';
// import '../../models/enrollment.dart';
// import '../cashier/CashierEnrollmentScreen.dart'; // Your original screen
// import './payment_wizard_screen.dart'; // Our new wizard screen
// import '../../config/theme.dart';

// /// A wrapper screen that allows toggling between the old and new enrollment UI
// class CashierEnrollmentWrapper extends StatefulWidget {
//   final Enrollment? enrollment;
//   final bool isWalkIn;

//   const CashierEnrollmentWrapper({
//     Key? key,
//     this.enrollment,
//     this.isWalkIn = true,
//   }) : super(key: key);

//   @override
//   _CashierEnrollmentWrapperState createState() => _CashierEnrollmentWrapperState();
// }

// class _CashierEnrollmentWrapperState extends State<CashierEnrollmentWrapper> {
//   bool _useNewUI = true; // Default to new UI
  
//   // Student information (will be collected in Steps 1-4 of original form)
//   String? _studentId;
//   Map<String, dynamic> _studentInfo = {};
//   Map<String, dynamic> _parentInfo = {};
//   List<Map<String, dynamic>>? _additionalContacts;
//   String _gradeLevel = '';
  
//   bool _readyForPayment = false;
  
//   @override
//   void initState() {
//     super.initState();
    
//     // If editing an existing enrollment, pre-populate the data
//     if (widget.enrollment != null) {
//       _studentId = widget.enrollment!.studentId;
//       _studentInfo = widget.enrollment!.studentInfo;
//       _parentInfo = widget.enrollment!.parentInfo;
//       _additionalContacts = widget.enrollment!.additionalContacts;
//       _gradeLevel = widget.enrollment!.studentInfo['gradeLevel'] as String? ?? '';
//       _readyForPayment = true;
//     }
//   }
  
//   /// Callback when student information is collected from original form steps
//   void _onStudentInfoCollected({
//     required String studentId,
//     required Map<String, dynamic> studentInfo,
//     required Map<String, dynamic> parentInfo,
//     List<Map<String, dynamic>>? additionalContacts,
//   }) {
//     setState(() {
//       _studentId = studentId;
//       _studentInfo = studentInfo;
//       _parentInfo = parentInfo;
//       _additionalContacts = additionalContacts;
//       _gradeLevel = studentInfo['gradeLevel'] as String? ?? '';
//       _readyForPayment = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // If using old UI, just return the original screen
//     if (!_useNewUI) {
//       return CashierEnrollmentScreen(
//         enrollment: widget.enrollment,
//         isWalkIn: widget.isWalkIn,
//       );
//     }
    
//     // If using new UI but not ready for payment wizard, show steps 1-4 of original form
//     if (!_readyForPayment) {
//       // Here you would need to create a modified version of the original screen
//       // that only shows steps 1-4 and calls _onStudentInfoCollected when done
//       // For now, we'll just use the original screen
//       return CashierEnrollmentScreen(
//         enrollment: widget.enrollment,
//         isWalkIn: widget.isWalkIn,
//       );
//     }
    
//     // If using new UI and ready for payment wizard, show the payment wizard
//     return ChangeNotifierProvider(
//       create: (_) => EnrollmentPaymentProvider(),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             widget.isWalkIn ? 'Walk-in Enrollment' : 'Update Enrollment',
//             style: TextStyle(fontFamily: 'Poppins',),
//           ),
//           actions: [
//             // Toggle UI button
//             TextButton.icon(
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: Text('Switch UI Mode', style: TextStyle(fontFamily: 'Poppins',)),
//                     content: Text(
//                       'Would you like to use the classic enrollment form?',
//                       style: TextStyle(fontFamily: 'Poppins',),
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         child: Text('No', style: TextStyle(fontFamily: 'Poppins',)),
//                       ),
//                       ElevatedButton(
//                         onPressed: () {
//                           setState(() => _useNewUI = false);
//                           Navigator.of(context).pop();
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: SMSTheme.primaryColor,
//                         ),
//                         child: Text(
//                           'Yes, Use Classic Form',
//                           style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               icon: Icon(Icons.swap_horiz, color: Colors.white),
//               label: Text(
//                 'Classic UI',
//                 style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//         body: PaymentWizardScreen(
//           studentId: _studentId!,
//           enrollmentId: widget.enrollment?.enrollmentId,
//           studentInfo: _studentInfo,
//           parentInfo: _parentInfo,
//           additionalContacts: _additionalContacts,
//           gradeLevel: _gradeLevel,
//           isEditing: widget.enrollment != null,
//         ),
//       ),
//     );
//   }
// }