import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class ReceiptGenerationScreen extends StatefulWidget {
  final String? paymentId; // Add this optional parameter

  const ReceiptGenerationScreen({super.key, this.paymentId});

  @override
  _ReceiptGenerationScreenState createState() =>
      _ReceiptGenerationScreenState();
}

class _ReceiptGenerationScreenState extends State<ReceiptGenerationScreen> {
  final TextEditingController _paymentIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If a payment ID was provided, pre-fill the text field
    if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
      _paymentIdController.text = widget.paymentId!;
      // Optionally auto-generate the receipt if a payment ID was provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateReceipt();
      });
    }
  }

  Future<void> _generateReceipt() async {
    if (_paymentIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a payment ID'),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(_paymentIdController.text)
          .get();

      setState(() {
        _isLoading = false;
      });

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment ID not found'),
            backgroundColor: SMSTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Generating receipt for ${data['studentId']} - ₱${data['amount'].toStringAsFixed(2)}'),
          backgroundColor: SMSTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Don't clear the payment ID if it was pre-filled, otherwise clear it
      if (widget.paymentId == null) {
        _paymentIdController.clear();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating receipt: $e'),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Theme(
      data: SMSTheme.getTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generate Receipt'),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SMSTheme.backgroundColorConst, const Color(0xFFFFF7EB)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Payment ID to Generate Receipt',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentIdController,
                  decoration: const InputDecoration(labelText: 'Payment ID'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a payment ID' : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _generateReceipt,
                          child: const Text('Generate Receipt'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
