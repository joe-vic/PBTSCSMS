import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class AdminFeeManagementScreen extends StatefulWidget {
  const AdminFeeManagementScreen({super.key});

  @override
  _AdminFeeManagementScreenState createState() =>
      _AdminFeeManagementScreenState();
}

class _AdminFeeManagementScreenState extends State<AdminFeeManagementScreen> {
  String _selectedLevel = 'BSIT';
  String _year = '1';
  String _semester = '1st';
  bool _isAnnual = false;
  List<Map<String, dynamic>> _fees = [];
  double _cashAmount = 8500.0;
  double _installmentAmount = 10000.0;
  double _familyDiscount = 0.0;
  int _familyThreshold = 3;

  void _addFee() {
    setState(() {
      _fees.add({'name': '', 'amount': 0.0});
    });
  }

  void _saveFees() async {
    String docId =
        _isAnnual ? _selectedLevel : '${_selectedLevel}$_year-$_semester';
    if (_selectedLevel.contains('Grade') || _selectedLevel == 'NKP') {
      docId = _selectedLevel +
          (_selectedLevel.contains('Grade') && _selectedLevel != 'NKP'
              ? '_Payee'
              : '');
    }
    await FirebaseFirestore.instance.collection('fees').doc(docId).set({
      'type': _selectedLevel.contains('Grade') || _selectedLevel == 'NKP'
          ? 'gradeLevel'
          : 'college',
      'course': _selectedLevel,
      'year': _isAnnual ? null : int.parse(_year),
      'semester': _isAnnual ? null : _semester,
      'isAnnual': _isAnnual,
      'fees': _fees,
      'cashAmount': _cashAmount,
      'installmentAmount': _installmentAmount,
      'discountRules': {
        'familyThreshold': _familyThreshold,
        'familyDiscountAmount': _familyDiscount,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SMSTheme.getTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Fees')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButton<String>(
                value: _selectedLevel,
                items: ['BSIT', 'NKP', 'Grade3', 'Grade8', 'Grade11']
                    .map((level) =>
                        DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value!;
                    _isAnnual = !value.startsWith('BS');
                  });
                },
              ),
              if (!_isAnnual) ...[
                DropdownButton<String>(
                  value: _year,
                  items: ['1', '2', '3', '4']
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('Year $y')))
                      .toList(),
                  onChanged: (value) => setState(() => _year = value!),
                ),
                DropdownButton<String>(
                  value: _semester,
                  items: ['1st', '2nd']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setState(() => _semester = value!),
                ),
              ],
              TextField(
                decoration: const InputDecoration(labelText: 'Cash Amount (₱)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _cashAmount = double.tryParse(value) ?? 0.0,
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Installment Amount (₱)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _installmentAmount = double.tryParse(value) ?? 0.0,
              ),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Family Discount Amount (₱)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _familyDiscount = double.tryParse(value) ?? 0.0,
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Family Threshold'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _familyThreshold = int.tryParse(value) ?? 3,
              ),
              ..._fees.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> fee = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration:
                            InputDecoration(labelText: 'Fee Name ${index + 1}'),
                        onChanged: (value) => _fees[index]['name'] = value,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        decoration:
                            InputDecoration(labelText: 'Amount ${index + 1}'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _fees[index]['amount'] =
                            double.tryParse(value) ?? 0.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() => _fees.removeAt(index)),
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton(
                onPressed: _addFee,
                child: const Text('Add Fee'),
              ),
              ElevatedButton(
                onPressed: _saveFees,
                child: const Text('Save Fees'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
