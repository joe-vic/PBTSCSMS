import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/print_models.dart';

class ReceiptService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get next BIR receipt number
  static Future<String> getNextReceiptNumber() async {
    try {
      final doc = await _firestore.collection('settings').doc('receipt_counter').get();
      
      int currentNumber = 1;
      if (doc.exists) {
        currentNumber = (doc.data()?['lastReceiptNumber'] ?? 0) + 1;
      }
      
      // Update counter
      await _firestore.collection('settings').doc('receipt_counter').set({
        'lastReceiptNumber': currentNumber,
        'lastUpdated': Timestamp.now(),
      });
      
      // Format as BIR receipt number (e.g., REC-2024-000001)
      final year = DateTime.now().year;
      return 'REC-$year-${currentNumber.toString().padLeft(6, '0')}';
      
    } catch (e) {
      print('Error generating receipt number: $e');
      return 'REC-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Record BIR receipt
  static Future<void> recordReceipt(BIRReceipt receipt) async {
    try {
      await _firestore.collection('bir_receipts').add({
        'receiptNumber': receipt.receiptNumber,
        'studentId': receipt.studentId,
        'studentName': receipt.studentName,
        'amount': receipt.amount,
        'issuedDate': Timestamp.fromDate(receipt.issuedDate),
        'cashierName': receipt.cashierName,
        'paymentFor': receipt.paymentFor,
      });
    } catch (e) {
      print('Error recording receipt: $e');
      throw e;
    }
  }
  
  // Get receipts for a student
  static Future<List<BIRReceipt>> getStudentReceipts(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('bir_receipts')
          .where('studentId', isEqualTo: studentId)
          .orderBy('issuedDate', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BIRReceipt(
          receiptNumber: data['receiptNumber'],
          studentId: data['studentId'],
          studentName: data['studentName'],
          amount: data['amount'].toDouble(),
          issuedDate: (data['issuedDate'] as Timestamp).toDate(),
          cashierName: data['cashierName'],
          paymentFor: data['paymentFor'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching receipts: $e');
      return [];
    }
  }
}