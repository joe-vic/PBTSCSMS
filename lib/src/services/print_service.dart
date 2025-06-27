import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/print_models.dart';

class PrintService {
  
  // Generate Payment Schedule based on grade level and payment scheme
  static List<PaymentSchedule> generatePaymentSchedule({
    required String gradeLevel,
    required String paymentScheme,
    required double balance,
    required bool hasBookFee,
    required double bookFee,
  }) {
    List<PaymentSchedule> schedule = [];
    
    if (paymentScheme.contains('Installment') && balance > 0) {
      if (gradeLevel == 'College') {
        // College: 4 months (July, August, September, October)
        double monthlyAmount = balance / 4;
        List<String> months = ['July', 'August', 'September', 'October'];
        
        for (int i = 0; i < 4; i++) {
          schedule.add(PaymentSchedule(
            month: months[i],
            dueDate: DateTime(DateTime.now().year, 7 + i, 15), // 15th of each month
            amount: monthlyAmount,
            description: 'Tuition Fee - ${months[i]}',
          ));
        }
      } else {
        // Elementary/JHS: 2 months + book fee
        double monthlyAmount = balance / 2;
        
        schedule.add(PaymentSchedule(
          month: 'July',
          dueDate: DateTime(DateTime.now().year, 7, 15),
          amount: monthlyAmount,
          description: 'Tuition Fee - July',
        ));
        
        schedule.add(PaymentSchedule(
          month: 'August',
          dueDate: DateTime(DateTime.now().year, 8, 15),
          amount: monthlyAmount,
          description: 'Tuition Fee - August',
        ));
        
        if (hasBookFee) {
          schedule.add(PaymentSchedule(
            month: 'September',
            dueDate: DateTime(DateTime.now().year, 9, 15),
            amount: bookFee,
            description: 'Book Fee',
          ));
        }
      }
    }
    
    return schedule;
  }
  
  // Generate Enrollment Form PDF
  static Future<pw.Document> generateEnrollmentForm(EnrollmentFormData data) async {
    final pdf = pw.Document();
    
    // Generate 4 copies with different purposes
    for (int copyNumber = 1; copyNumber <= 4; copyNumber++) {
      String copyPurpose = _getCopyPurpose(copyNumber);
      bool showPaymentSchedule = copyNumber >= 3; // Last 2 copies show payment details
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildFormHeader(copyPurpose, copyNumber),
                pw.SizedBox(height: 20),
                
                // Student Information
                _buildStudentInfoSection(data),
                pw.SizedBox(height: 15),
                
                // Parent Information  
                _buildParentInfoSection(data),
                pw.SizedBox(height: 15),
                
                // Academic Information
                _buildAcademicInfoSection(data),
                pw.SizedBox(height: 15),
                
                // Payment Information
                _buildPaymentInfoSection(data),
                
                // Payment Schedule (only for last 2 copies)
                if (showPaymentSchedule) ...[
                  pw.SizedBox(height: 20),
                  _buildPaymentScheduleSection(data),
                ],
                
                pw.Spacer(),
                
                // Footer
                _buildFormFooter(data),
              ],
            );
          },
        ),
      );
    }
    
    return pdf;
  }
  
  static String _getCopyPurpose(int copyNumber) {
    switch (copyNumber) {
      case 1: return 'SCHOOL COPY';
      case 2: return 'REGISTRAR COPY';
      case 3: return 'STUDENT COPY (with Payment Schedule)';
      case 4: return 'PARENT COPY (with Payment Schedule)';
      default: return 'COPY $copyNumber';
    }
  }
  
  static pw.Widget _buildFormHeader(String copyPurpose, int copyNumber) {
    return pw.Column(
      children: [
        pw.Text(
          'PHILIPPINE BUSINESS TRAINING SCHOOL',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'ENROLLMENT FORM',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(copyPurpose, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Copy $copyNumber of 4'),
          ],
        ),
        pw.Divider(),
      ],
    );
  }
  
  static pw.Widget _buildStudentInfoSection(EnrollmentFormData data) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('STUDENT INFORMATION', 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Student ID: ${data.studentId}')),
              pw.Expanded(child: pw.Text('Enrollment ID: ${data.enrollmentId}')),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Last Name: ${data.studentInfo['lastName']}')),
              pw.Expanded(child: pw.Text('First Name: ${data.studentInfo['firstName']}')),
              pw.Expanded(child: pw.Text('Middle Name: ${data.studentInfo['middleName'] ?? ''}')),
            ],
          ),
          // Add more student fields as needed
        ],
      ),
    );
  }
  
  static pw.Widget _buildParentInfoSection(EnrollmentFormData data) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PARENT/GUARDIAN INFORMATION', 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Name: ${data.parentInfo['firstName']} ${data.parentInfo['lastName']}')),
              pw.Expanded(child: pw.Text('Contact: ${data.parentInfo['contact']}')),
            ],
          ),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Relationship: ${data.parentInfo['relationship']}')),
              pw.Expanded(child: pw.Text('Facebook: ${data.parentInfo['facebook'] ?? ''}')),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildAcademicInfoSection(EnrollmentFormData data) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ACADEMIC INFORMATION', 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Grade Level: ${data.studentInfo['gradeLevel']}')),
              pw.Expanded(child: pw.Text('Branch: ${data.studentInfo['branch']}')),
            ],
          ),
          if (data.studentInfo['strand']?.isNotEmpty == true)
            pw.Text('Strand: ${data.studentInfo['strand']}'),
          if (data.studentInfo['course']?.isNotEmpty == true)
            pw.Text('Course: ${data.studentInfo['course']}'),
          pw.Text('Academic Year: ${data.academicYear}'),
        ],
      ),
    );
  }
  
  static pw.Widget _buildPaymentInfoSection(EnrollmentFormData data) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PAYMENT INFORMATION', 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Payment Scheme: ${data.paymentScheme}')),
              pw.Expanded(child: pw.Text('Total Fee: ₱${data.totalFee.toStringAsFixed(2)}')),
            ],
          ),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Initial Payment: ₱${data.initialPayment.toStringAsFixed(2)}')),
              pw.Expanded(child: pw.Text('Balance: ₱${data.balance.toStringAsFixed(2)}')),
            ],
          ),
          if (data.feeReductions.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text('Fee Reductions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...data.feeReductions.map((reduction) => 
              pw.Text('• ${reduction['type']}: ${reduction['category']} - ${reduction['percentage'] > 0 ? '${reduction['percentage']}%' : '₱${reduction['amount']}'}')),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _buildPaymentScheduleSection(EnrollmentFormData data) {
    final schedule = generatePaymentSchedule(
      gradeLevel: data.studentInfo['gradeLevel'],
      paymentScheme: data.paymentScheme,
      balance: data.balance,
      hasBookFee: true, // You'll need to pass this from your form
      bookFee: 500, // You'll need to pass this from your form
    );
    
    if (schedule.isEmpty) return pw.Container();
    
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PAYMENT SCHEDULE', 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              // Header
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Month', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Due Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              // Data rows
              ...schedule.map((payment) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(payment.month)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('₱${payment.amount.toStringAsFixed(2)}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(payment.description)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(payment.isPaid ? 'PAID' : 'UNPAID')),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFormFooter(EnrollmentFormData data) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date: ${data.enrollmentDate.day}/${data.enrollmentDate.month}/${data.enrollmentDate.year}'),
            pw.Text('Enrollment processed by SMS'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Column(
              children: [
                pw.Container(height: 1, width: 150, color: PdfColors.black),
                pw.Text('Student/Parent Signature'),
              ],
            ),
            pw.Column(
              children: [
                pw.Container(height: 1, width: 150, color: PdfColors.black),
                pw.Text('Cashier Signature'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}