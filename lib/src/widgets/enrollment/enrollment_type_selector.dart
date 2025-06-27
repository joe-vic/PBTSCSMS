import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../providers/enrollment_payment_provider.dart';
import '../../config/theme.dart';

/// A widget for selecting enrollment type
class EnrollmentTypeSelector extends StatelessWidget {
  const EnrollmentTypeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EnrollmentPaymentProvider>(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrollment Type',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the enrollment type that best fits the student\'s situation',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.indigo.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid of enrollment type options
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: EnrollmentType.values.map((type) => _buildEnrollmentTypeCard(
              context,
              type: type,
              isSelected: provider.enrollmentType == type,
              onTap: () => provider.setEnrollmentType(type),
            )).toList(),
          ),

          const SizedBox(height: 16),
          _buildEnrollmentTypeDescription(provider.enrollmentType),
        ],
      ),
    );
  }
  
  /// Build a card for an enrollment type option
  Widget _buildEnrollmentTypeCard(
    BuildContext context, {
    required EnrollmentType type,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color baseColor = _getColorForEnrollmentType(type);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? baseColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForEnrollmentType(type),
              color: isSelected ? baseColor : Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? baseColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the description box for the selected enrollment type
  Widget _buildEnrollmentTypeDescription(EnrollmentType type) {
    final Color baseColor = _getColorForEnrollmentType(type);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: baseColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getIconForEnrollmentType(type), color: baseColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type.description,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: baseColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get the appropriate color for an enrollment type
  Color _getColorForEnrollmentType(EnrollmentType type) {
    switch (type) {
      case EnrollmentType.standard:
        return Colors.blue.shade700;
      case EnrollmentType.flexible:
        return Colors.green.shade600;
      case EnrollmentType.emergency:
        return Colors.orange.shade700;
      case EnrollmentType.scholarship:
        return Colors.purple.shade600;
    }
  }
  
  /// Get the appropriate icon for an enrollment type
  IconData _getIconForEnrollmentType(EnrollmentType type) {
    switch (type) {
      case EnrollmentType.standard:
        return Icons.assignment;
      case EnrollmentType.flexible:
        return Icons.swap_horiz;
      case EnrollmentType.emergency:
        return Icons.priority_high;
      case EnrollmentType.scholarship:
        return Icons.school;
    }
  }
}