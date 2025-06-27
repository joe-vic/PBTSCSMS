import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

/// Dialog to show when duplicate students or enrollments are found
class DuplicateCheckDialog extends StatelessWidget {
  final String title;
  final String message;
  final Map<String, dynamic>? existingData;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;
  final String? proceedButtonText;
  final String? cancelButtonText;

  const DuplicateCheckDialog({
    super.key,
    required this.title,
    required this.message,
    this.existingData,
    this.onProceed,
    this.onCancel,
    this.proceedButtonText,
    this.cancelButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: SMSTheme.textPrimaryLight,
              ),
            ),
            if (existingData != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Existing Record:',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildExistingDataDisplay(existingData!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(
            cancelButtonText ?? 'Cancel',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryLight,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onProceed ?? () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            proceedButtonText ?? 'Proceed',
            style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingDataDisplay(Map<String, dynamic> data) {
    // Determine if this is student or enrollment data
    final isStudent =
        data.containsKey('firstName') && data.containsKey('lastName');
    final isEnrollment =
        data.containsKey('enrollmentId') || data.containsKey('studentId');

    if (isStudent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataRow('Name',
              '${data['firstName']} ${data['middleName']} ${data['lastName']}'),
          if (data['dateOfBirth'] != null)
            _buildDataRow(
                'Birth Date',
                DateFormat('MMM dd, yyyy')
                    .format((data['dateOfBirth'] as Timestamp).toDate())),
          if (data['gradeLevel'] != null)
            _buildDataRow('Grade Level', data['gradeLevel']),
          if (data['gender'] != null) _buildDataRow('Gender', data['gender']),
        ],
      );
    } else if (isEnrollment) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataRow('Enrollment ID', data['enrollmentId'] ?? 'N/A'),
          _buildDataRow('Status', data['status'] ?? 'N/A'),
          _buildDataRow('Payment Status', data['paymentStatus'] ?? 'N/A'),
          if (data['createdAt'] != null)
            _buildDataRow(
                'Created',
                DateFormat('MMM dd, yyyy')
                    .format((data['createdAt'] as Timestamp).toDate())),
        ],
      );
    } else {
      return Text(
        'Data available',
        style: TextStyle(fontFamily: 'Poppins',
          fontSize: 12,
          color: SMSTheme.textSecondaryLight,
        ),
      );
    }
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: SMSTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 11,
                color: SMSTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show duplicate student dialog
Future<bool?> showDuplicateStudentDialog({
  required BuildContext context,
  required Map<String, dynamic> existingStudentData,
  required String newStudentName,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DuplicateCheckDialog(
      title: 'Duplicate Student Found',
      message:
          'A student with the name "$newStudentName" already exists in the system. '
          'Would you like to use the existing student record or create a new one?',
      existingData: existingStudentData,
      proceedButtonText: 'Use Existing',
      cancelButtonText: 'Create New',
    ),
  );
}

/// Show duplicate enrollment dialog
Future<bool?> showDuplicateEnrollmentDialog({
  required BuildContext context,
  required Map<String, dynamic> existingEnrollmentData,
  required String studentName,
  required String academicYear,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DuplicateCheckDialog(
      title: 'Duplicate Enrollment Found',
      message:
          'Student "$studentName" already has an enrollment for academic year $academicYear. '
          'Would you like to view the existing enrollment or proceed with a new one?',
      existingData: existingEnrollmentData,
      proceedButtonText: 'View Existing',
      cancelButtonText: 'Create New',
    ),
  );
}
