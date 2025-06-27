import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/fee_calculator_service.dart';

/// A screen for administrators to edit the fee structure
class FeeStructureEditorScreen extends StatefulWidget {
  const FeeStructureEditorScreen({Key? key}) : super(key: key);

  @override
  _FeeStructureEditorScreenState createState() => _FeeStructureEditorScreenState();
}

class _FeeStructureEditorScreenState extends State<FeeStructureEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FeeCalculatorService _feeCalculator = FeeCalculatorService();
  
  String _academicYear = '';
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _feeStructure = {};
  
  final List<String> _gradeLevels = [
    'Nursery',
    'Kinder 1',
    'Kinder 2',
    'Preparatory',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
    'College',
  ];
  
  final List<String> _enrollmentTypes = [
    'Standard Enrollment',
    'Flexible Enrollment',
    'Emergency Enrollment',
    'Scholarship Enrollment',
  ];
  
  @override
  void initState() {
    super.initState();
    _initAcademicYear();
    _loadFeeStructure();
  }
  
  /// Initialize the academic year based on current date
  void _initAcademicYear() {
    final now = DateTime.now();
    final year = now.month >= 6 ? now.year : now.year - 1; // Academic year starts in June
    _academicYear = '$year-${year + 1}';
  }
  
  /// Load fee structure from Firestore
  Future<void> _loadFeeStructure() async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await _firestore
          .collection('feeStructures')
          .doc(_academicYear)
          .get();
      
      if (doc.exists) {
        setState(() {
          _feeStructure = doc.data() ?? {};
        });
      } else {
        // Initialize with default structure if none exists
        _initializeDefaultStructure();
      }
    } catch (e) {
      print('Error loading fee structure: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading fee structure: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _initializeDefaultStructure();
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Initialize a default fee structure
  void _initializeDefaultStructure() {
    final Map<String, dynamic> defaultStructure = {
      'academicYear': _academicYear,
      'lastUpdated': Timestamp.now(),
      'updatedBy': Provider.of<AuthProvider>(context, listen: false).user?.displayName ?? 'Admin',
      
      // Base tuition fees by grade level
      'Nursery': {'standardFee': 8500.0},
      'Kinder 1': {'standardFee': 8500.0},
      'Kinder 2': {'standardFee': 8500.0},
      'Preparatory': {'standardFee': 8500.0},
      'Grade 1': {'standardFee': 8500.0},
      'Grade 2': {'standardFee': 8500.0},
      'Grade 3': {'standardFee': 8500.0},
      'Grade 4': {'standardFee': 8500.0},
      'Grade 5': {'standardFee': 8500.0},
      'Grade 6': {'standardFee': 8500.0},
      'Grade 7': {'standardFee': 8500.0},
      'Grade 8': {'standardFee': 8500.0},
      'Grade 9': {'standardFee': 8500.0},
      'Grade 10': {'standardFee': 8500.0},
      'Grade 11': {
        'standardFee': 17500.0,
        'voucherFee': 0.0,
      },
      'Grade 12': {
        'standardFee': 17500.0,
        'voucherFee': 0.0,
      },
      'College': {
        '1st Semester': {
          'cashFee': 8500.0,
          'installmentFee': 10000.0,
        },
        '2nd Semester': {
          'cashFee': 8500.0,
          'installmentFee': 10000.0,
        },
      },
      
      // ID fees
      'idFees': {
        'default': 150.0,
        'College': 250.0,
      },
      
      // System fees
      'systemFees': {
        'default': 120.0,
      },
      
      // Book fees
      'bookFees': {
        'default': 0.0,
      },
      
      // Payment policies
      'paymentPolicies': {
        'Standard Enrollment': {
          'minimumPercentage': 0.2,
          'minimumAmount': 1000.0,
          'recommendedPercentage': 0.3,
          'recommendedAmount': 1500.0,
        },
        'Flexible Enrollment': {
          'tieredMinimum': true,
          'tiers': [
            {'maxAmount': 5000.0, 'minimumPayment': 500.0},
            {'maxAmount': 10000.0, 'minimumPayment': 1000.0},
            {'maxAmount': 15000.0, 'minimumPayment': 1500.0},
            {'maxAmount': 999999.0, 'minimumPayment': 2000.0},
          ],
          'recommendedPercentage': 0.25,
          'recommendedAmount': 1200.0,
        },
        'Emergency Enrollment': {
          'minimumPercentage': 0.05,
          'minimumAmount': 500.0,
          'recommendedPercentage': 0.15,
          'recommendedAmount': 800.0,
        },
        'Scholarship Enrollment': {
          'minimumPercentage': 0.1,
          'minimumAmount': 300.0,
          'recommendedPercentage': 0.2,
          'recommendedAmount': 600.0,
        },
      },
    };
    
    setState(() {
      _feeStructure = defaultStructure;
    });
  }
  
  /// Save fee structure to Firestore
  Future<void> _saveFeeStructure() async {
    setState(() => _isSaving = true);
    
    try {
      // Update metadata
      _feeStructure['lastUpdated'] = Timestamp.now();
      _feeStructure['updatedBy'] = Provider.of<AuthProvider>(context, listen: false).user?.displayName ?? 'Admin';
      
      await _firestore
          .collection('feeStructures')
          .doc(_academicYear)
          .set(_feeStructure);
      
      // Clear the fee calculator cache to force refresh
      _feeCalculator.clearCache();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fee structure saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving fee structure: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving fee structure: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fee Structure Editor', style: TextStyle(fontFamily: 'Poppins',)),
        actions: [
          // Academic year selector
          DropdownButton<String>(
            value: _academicYear,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            style: TextStyle(fontFamily: 'Poppins',color: Colors.white),
            dropdownColor: Colors.indigo.shade800,
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _academicYear) {
                setState(() {
                  _academicYear = newValue;
                });
                _loadFeeStructure();
              }
            },
            items: _generateAcademicYearItems(),
          ),
          const SizedBox(width: 16),
          
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Fee Structure',
            onPressed: _isSaving ? null : _saveFeeStructure,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildFeeStructureEditor(),
    );
  }
  
  /// Generate academic year dropdown items
  List<DropdownMenuItem<String>> _generateAcademicYearItems() {
    final currentYear = DateTime.now().year;
    final items = <DropdownMenuItem<String>>[];
    
    // Include previous, current, and next academic year
    for (int year = currentYear - 1; year <= currentYear + 1; year++) {
      final academicYear = '$year-${year + 1}';
      items.add(DropdownMenuItem(
        value: academicYear,
        child: Text(academicYear),
      ));
    }
    
    return items;
  }
  
  /// Build the fee structure editor UI
  Widget _buildFeeStructureEditor() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.grey.shade100,
            child: TabBar(
              tabs: [
                Tab(text: 'Tuition Fees', icon: Icon(Icons.school)),
                Tab(text: 'Other Fees', icon: Icon(Icons.attach_money)),
                Tab(text: 'Payment Policies', icon: Icon(Icons.policy)),
                Tab(text: 'Preview', icon: Icon(Icons.preview)),
              ],
              labelColor: SMSTheme.primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: SMSTheme.primaryColor,
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                // Tuition Fees Tab
                _buildTuitionFeesTab(),
                
                // Other Fees Tab
                _buildOtherFeesTab(),
                
                // Payment Policies Tab
                _buildPaymentPoliciesTab(),
                
                // Preview Tab
                _buildPreviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the tuition fees tab
  Widget _buildTuitionFeesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuition Fees by Grade Level',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Regular grade levels
          for (final level in _gradeLevels.where((level) => 
              level != 'Grade 11' && level != 'Grade 12' && level != 'College'))
            _buildStandardFeeEditor(level),
          
          const Divider(height: 32),
          
          // Senior High School
          Text(
            'Senior High School Fees',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSeniorHighFeeEditor('Grade 11'),
          _buildSeniorHighFeeEditor('Grade 12'),
          
          const Divider(height: 32),
          
          // College
          Text(
            'College Fees',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildCollegeFeeEditor(),
        ],
      ),
    );
  }
  
  /// Build a standard fee editor for a grade level
  Widget _buildStandardFeeEditor(String gradeLevel) {
    // Initialize if not exists
    if (!_feeStructure.containsKey(gradeLevel)) {
      _feeStructure[gradeLevel] = {'standardFee': 8500.0};
    }
    
    final standardFee = _feeStructure[gradeLevel]['standardFee'] as double? ?? 8500.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                gradeLevel,
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: standardFee.toString(),
                decoration: InputDecoration(
                  labelText: 'Standard Fee',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onChanged: (value) {
                  final fee = double.tryParse(value) ?? 0.0;
                  setState(() {
                    _feeStructure[gradeLevel]['standardFee'] = fee;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build fee editor for Senior High School
  Widget _buildSeniorHighFeeEditor(String gradeLevel) {
    // Initialize if not exists
    if (!_feeStructure.containsKey(gradeLevel)) {
      _feeStructure[gradeLevel] = {
        'standardFee': 17500.0,
        'voucherFee': 0.0,
      };
    }
    
    final standardFee = _feeStructure[gradeLevel]['standardFee'] as double? ?? 17500.0;
    final voucherFee = _feeStructure[gradeLevel]['voucherFee'] as double? ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gradeLevel,
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: standardFee.toString(),
                    decoration: InputDecoration(
                      labelText: 'Standard Fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure[gradeLevel]['standardFee'] = fee;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: voucherFee.toString(),
                    decoration: InputDecoration(
                      labelText: 'Voucher Beneficiary Fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure[gradeLevel]['voucherFee'] = fee;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build fee editor for College
  Widget _buildCollegeFeeEditor() {
    // Initialize if not exists
    if (!_feeStructure.containsKey('College')) {
      _feeStructure['College'] = {
        '1st Semester': {
          'cashFee': 8500.0,
          'installmentFee': 10000.0,
        },
        '2nd Semester': {
          'cashFee': 8500.0,
          'installmentFee': 10000.0,
        },
      };
    }
    
    final firstSemester = _feeStructure['College']['1st Semester'] as Map<String, dynamic>? ?? 
        {'cashFee': 8500.0, 'installmentFee': 10000.0};
    
    final secondSemester = _feeStructure['College']['2nd Semester'] as Map<String, dynamic>? ?? 
        {'cashFee': 8500.0, 'installmentFee': 10000.0};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'College',
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 1st Semester
            Text(
              '1st Semester',
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: (firstSemester['cashFee'] as double? ?? 8500.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Cash Fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['College']['1st Semester']['cashFee'] = fee;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: (firstSemester['installmentFee'] as double? ?? 10000.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Installment Fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['College']['1st Semester']['installmentFee'] = fee;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 2nd Semester
            Text(
              '2nd Semester',
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: (secondSemester['cashFee'] as double? ?? 8500.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Cash Fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['College']['2nd Semester']['cashFee'] = fee;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: (secondSemester['installmentFee'] as double? ?? 10000.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Installment Fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['College']['2nd Semester']['installmentFee'] = fee;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the other fees tab
  Widget _buildOtherFeesTab() {
    // Initialize if not exists
    if (!_feeStructure.containsKey('idFees')) {
      _feeStructure['idFees'] = {
        'default': 150.0,
        'College': 250.0,
      };
    }
    
    if (!_feeStructure.containsKey('systemFees')) {
      _feeStructure['systemFees'] = {
        'default': 120.0,
      };
    }
    
    if (!_feeStructure.containsKey('bookFees')) {
      _feeStructure['bookFees'] = {
        'default': 0.0,
      };
    }
    
    final idFees = _feeStructure['idFees'] as Map<String, dynamic>;
    final systemFees = _feeStructure['systemFees'] as Map<String, dynamic>;
    final bookFees = _feeStructure['bookFees'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID Fees
          Text(
            'ID Fees',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Default ID Fee
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Default ID Fee',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: (idFees['default'] as double? ?? 150.0).toString(),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₱',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (value) {
                            final fee = double.tryParse(value) ?? 0.0;
                            setState(() {
                              _feeStructure['idFees']['default'] = fee;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // College ID Fee
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'College ID Fee',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: (idFees['College'] as double? ?? 250.0).toString(),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₱',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (value) {
                            final fee = double.tryParse(value) ?? 0.0;
                            setState(() {
                              _feeStructure['idFees']['College'] = fee;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // System Fees
          Text(
            'System Fees',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Default System Fee',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: (systemFees['default'] as double? ?? 120.0).toString(),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (value) {
                        final fee = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _feeStructure['systemFees']['default'] = fee;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Book Fees
          Text(
            'Book Fees',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Default Book Fee',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: (bookFees['default'] as double? ?? 0.0).toString(),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (value) {
                        final fee = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _feeStructure['bookFees']['default'] = fee;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the payment policies tab
  Widget _buildPaymentPoliciesTab() {
    // Initialize if not exists
    if (!_feeStructure.containsKey('paymentPolicies')) {
      _feeStructure['paymentPolicies'] = {
        'Standard Enrollment': {
          'minimumPercentage': 0.2,
          'minimumAmount': 1000.0,
          'recommendedPercentage': 0.3,
          'recommendedAmount': 1500.0,
        },
        'Flexible Enrollment': {
          'tieredMinimum': true,
          'tiers': [
            {'maxAmount': 5000.0, 'minimumPayment': 500.0},
            {'maxAmount': 10000.0, 'minimumPayment': 1000.0},
            {'maxAmount': 15000.0, 'minimumPayment': 1500.0},
            {'maxAmount': 999999.0, 'minimumPayment': 2000.0},
          ],
          'recommendedPercentage': 0.25,
          'recommendedAmount': 1200.0,
        },
        'Emergency Enrollment': {
          'minimumPercentage': 0.05,
          'minimumAmount': 500.0,
          'recommendedPercentage': 0.15,
          'recommendedAmount': 800.0,
        },
        'Scholarship Enrollment': {
          'minimumPercentage': 0.1,
          'minimumAmount': 300.0,
          'recommendedPercentage': 0.2,
          'recommendedAmount': 600.0,
        },
      };
    }
    
    final paymentPolicies = _feeStructure['paymentPolicies'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Policies by Enrollment Type',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Standard Enrollment
          _buildStandardPolicyEditor(
            'Standard Enrollment',
            paymentPolicies['Standard Enrollment'] as Map<String, dynamic>,
          ),
          
          // Flexible Enrollment
          _buildTieredPolicyEditor(
            'Flexible Enrollment',
            paymentPolicies['Flexible Enrollment'] as Map<String, dynamic>,
          ),
          
          // Emergency Enrollment
          _buildStandardPolicyEditor(
            'Emergency Enrollment',
            paymentPolicies['Emergency Enrollment'] as Map<String, dynamic>,
          ),
          
          // Scholarship Enrollment
          _buildStandardPolicyEditor(
            'Scholarship Enrollment',
            paymentPolicies['Scholarship Enrollment'] as Map<String, dynamic>,
          ),
        ],
      ),
    );
  }
  
  /// Build a standard policy editor
  Widget _buildStandardPolicyEditor(String policyName, Map<String, dynamic> policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              policyName,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SMSTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Minimum Payment Settings
            Text(
              'Minimum Payment',
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: ((policy['minimumPercentage'] as double? ?? 0.2) * 100).toString(),
                    decoration: InputDecoration(
                      labelText: 'Percentage',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final percentage = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['paymentPolicies'][policyName]['minimumPercentage'] = percentage / 100;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: (policy['minimumAmount'] as double? ?? 1000.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Minimum Amount',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['paymentPolicies'][policyName]['minimumAmount'] = amount;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recommended Payment Settings
            Text(
              'Recommended Payment',
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: ((policy['recommendedPercentage'] as double? ?? 0.3) * 100).toString(),
                    decoration: InputDecoration(
                      labelText: 'Percentage',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final percentage = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['paymentPolicies'][policyName]['recommendedPercentage'] = percentage / 100;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: (policy['recommendedAmount'] as double? ?? 1500.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Minimum Amount',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['paymentPolicies'][policyName]['recommendedAmount'] = amount;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a tiered policy editor
  Widget _buildTieredPolicyEditor(String policyName, Map<String, dynamic> policy) {
    final tiers = policy['tiers'] as List<dynamic>? ?? [
      {'maxAmount': 5000.0, 'minimumPayment': 500.0},
      {'maxAmount': 10000.0, 'minimumPayment': 1000.0},
      {'maxAmount': 15000.0, 'minimumPayment': 1500.0},
      {'maxAmount': 999999.0, 'minimumPayment': 2000.0},
    ];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              policyName,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: SMSTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tiered payment system
            Row(
              children: [
                Checkbox(
                  value: policy['tieredMinimum'] as bool? ?? true,
                  onChanged: (value) {
                    setState(() {
                      _feeStructure['paymentPolicies'][policyName]['tieredMinimum'] = value ?? true;
                    });
                  },
                ),
                Text(
                  'Use Tiered Minimum Payment System',
                  style: TextStyle(fontFamily: 'Poppins',),
                ),
              ],
            ),
            
            if (policy['tieredMinimum'] as bool? ?? true) ...[
              const SizedBox(height: 16),
              
              // Tier headers
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fee Range (up to)',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Minimum Payment',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40), // Space for action buttons
                ],
              ),
              
              const Divider(height: 24),
              
              // Tier items
              for (int i = 0; i < tiers.length; i++)
                _buildTierItem(i, tiers[i] as Map<String, dynamic>, policyName),
              
              // Add tier button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      final newTier = {
                        'maxAmount': 999999.0,
                        'minimumPayment': 2000.0,
                      };
                      
                      (policy['tiers'] as List<dynamic>).add(newTier);
                    });
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Tier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SMSTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              // Standard policy fields
              const SizedBox(height: 16),
              
              // Minimum Payment Settings
              Text(
                'Minimum Payment',
                style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: ((policy['minimumPercentage'] as double? ?? 0.2) * 100).toString(),
                      decoration: InputDecoration(
                        labelText: 'Percentage',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (value) {
                        final percentage = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _feeStructure['paymentPolicies'][policyName]['minimumPercentage'] = percentage / 100;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: (policy['minimumAmount'] as double? ?? 1000.0).toString(),
                      decoration: InputDecoration(
                        labelText: 'Minimum Amount',
                        prefixText: '₱',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0.0;
                        setState(() {
                          _feeStructure['paymentPolicies'][policyName]['minimumAmount'] = amount;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Recommended Payment Settings
            Text(
              'Recommended Payment',
              style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: ((policy['recommendedPercentage'] as double? ?? 0.25) * 100).toString(),
                    decoration: InputDecoration(
                      labelText: 'Percentage',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final percentage = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['paymentPolicies'][policyName]['recommendedPercentage'] = percentage / 100;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: (policy['recommendedAmount'] as double? ?? 1200.0).toString(),
                    decoration: InputDecoration(
                      labelText: 'Minimum Amount',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _feeStructure['paymentPolicies'][policyName]['recommendedAmount'] = amount;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a tier item row
  Widget _buildTierItem(int index, Map<String, dynamic> tier, String policyName) {
    final maxAmount = tier['maxAmount'] as double? ?? 999999.0;
    final minimumPayment = tier['minimumPayment'] as double? ?? 2000.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: maxAmount == 999999.0 ? '∞' : maxAmount.toString(),
              decoration: InputDecoration(
                labelText: 'Max Fee',
                prefixText: '₱',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (value) {
                double maxAmount;
                if (value == '∞' || value.isEmpty) {
                  maxAmount = 999999.0;
                } else {
                  maxAmount = double.tryParse(value) ?? 999999.0;
                }
                
                setState(() {
                  (_feeStructure['paymentPolicies'][policyName]['tiers'] as List<dynamic>)[index]['maxAmount'] = maxAmount;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: minimumPayment.toString(),
              decoration: InputDecoration(
                labelText: 'Min Payment',
                prefixText: '₱',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (value) {
                final payment = double.tryParse(value) ?? 0.0;
                setState(() {
                  (_feeStructure['paymentPolicies'][policyName]['tiers'] as List<dynamic>)[index]['minimumPayment'] = payment;
                });
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () {
                setState(() {
                  (_feeStructure['paymentPolicies'][policyName]['tiers'] as List<dynamic>).removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the preview tab
  Widget _buildPreviewTab() {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Structure Preview',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SMSTheme.primaryColor,
            ),
          ),
          Text(
            'Academic Year: $_academicYear',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Tuition fee preview
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tuition Fees',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SMSTheme.primaryColor,
                    ),
                  ),
                  const Divider(height: 24),
                  
                  // Regular grade levels
                  for (final level in _gradeLevels.where((level) => 
                      level != 'Grade 11' && level != 'Grade 12' && level != 'College' &&
                      _feeStructure.containsKey(level)))
                    _buildFeeSummaryRow(
                      label: level,
                      value: _feeStructure[level]['standardFee'] as double? ?? 8500.0,
                      currencyFormat: currencyFormat,
                    ),
                  
                  const Divider(height: 24),
                  
                  // Senior High School
                  Text(
                    'Senior High School',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  for (final level in ['Grade 11', 'Grade 12'])
                    if (_feeStructure.containsKey(level))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeeSummaryRow(
                            label: '$level - Regular',
                            value: _feeStructure[level]['standardFee'] as double? ?? 17500.0,
                            currencyFormat: currencyFormat,
                          ),
                          _buildFeeSummaryRow(
                            label: '$level - Voucher',
                            value: _feeStructure[level]['voucherFee'] as double? ?? 0.0,
                            currencyFormat: currencyFormat,
                          ),
                        ],
                      ),
                  
                  const Divider(height: 24),
                  
                  // College
                  if (_feeStructure.containsKey('College'))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          '1st Semester',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        _buildFeeSummaryRow(
                          label: 'Cash Payment',
                          value: (_feeStructure['College']['1st Semester'] as Map<String, dynamic>)['cashFee'] as double? ?? 8500.0,
                          currencyFormat: currencyFormat,
                        ),
                        _buildFeeSummaryRow(
                          label: 'Installment',
                          value: (_feeStructure['College']['1st Semester'] as Map<String, dynamic>)['installmentFee'] as double? ?? 10000.0,
                          currencyFormat: currencyFormat,
                        ),
                        
                        const SizedBox(height: 8),
                        Text(
                          '2nd Semester',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        _buildFeeSummaryRow(
                          label: 'Cash Payment',
                          value: (_feeStructure['College']['2nd Semester'] as Map<String, dynamic>)['cashFee'] as double? ?? 8500.0,
                          currencyFormat: currencyFormat,
                        ),
                        _buildFeeSummaryRow(
                          label: 'Installment',
                          value: (_feeStructure['College']['2nd Semester'] as Map<String, dynamic>)['installmentFee'] as double? ?? 10000.0,
                          currencyFormat: currencyFormat,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Other fees preview
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Fees',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SMSTheme.primaryColor,
                    ),
                  ),
                  const Divider(height: 24),
                  
                  // ID Fees
                  Text(
                    'ID Fees',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_feeStructure.containsKey('idFees'))
                    Column(
                      children: [
                        _buildFeeSummaryRow(
                          label: 'Default',
                          value: (_feeStructure['idFees'] as Map<String, dynamic>)['default'] as double? ?? 150.0,
                          currencyFormat: currencyFormat,
                        ),
                        _buildFeeSummaryRow(
                          label: 'College',
                          value: (_feeStructure['idFees'] as Map<String, dynamic>)['College'] as double? ?? 250.0,
                          currencyFormat: currencyFormat,
                        ),
                      ],
                    ),
                  
                  const Divider(height: 24),
                  
                  // System Fees
                  Text(
                    'System Fees',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_feeStructure.containsKey('systemFees'))
                    _buildFeeSummaryRow(
                      label: 'Default',
                      value: (_feeStructure['systemFees'] as Map<String, dynamic>)['default'] as double? ?? 120.0,
                      currencyFormat: currencyFormat,
                    ),
                  
                  const Divider(height: 24),
                  
                  // Book Fees
                  Text(
                    'Book Fees',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_feeStructure.containsKey('bookFees'))
                    _buildFeeSummaryRow(
                      label: 'Default',
                      value: (_feeStructure['bookFees'] as Map<String, dynamic>)['default'] as double? ?? 0.0,
                      currencyFormat: currencyFormat,
                    ),
                ],
              ),
            ),
          ),
          
          // Payment policies preview
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Policies',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SMSTheme.primaryColor,
                    ),
                  ),
                  const Divider(height: 24),
                  
                  if (_feeStructure.containsKey('paymentPolicies'))
                    for (final policyName in _enrollmentTypes)
                      if ((_feeStructure['paymentPolicies'] as Map<String, dynamic>).containsKey(policyName))
                        _buildPolicySummary(
                          policyName,
                          (_feeStructure['paymentPolicies'] as Map<String, dynamic>)[policyName] as Map<String, dynamic>,
                          currencyFormat,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a fee summary row
  Widget _buildFeeSummaryRow({
    required String label,
    required double value,
    required NumberFormat currencyFormat,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a policy summary
  Widget _buildPolicySummary(
    String policyName,
    Map<String, dynamic> policy,
    NumberFormat currencyFormat,
  ) {
    final bool isTiered = policy['tieredMinimum'] as bool? ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          policyName,
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Minimum payment
        if (isTiered) ...[
          Text(
            'Tiered Minimum Payment:',
            style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          
          for (final tier in policy['tiers'] as List<dynamic>)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Up to ${(tier as Map<String, dynamic>)['maxAmount'] == 999999.0 ? '∞' : currencyFormat.format((tier)['maxAmount'])}:',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormat.format((tier)['minimumPayment']),
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          Row(
            children: [
              Text(
                'Minimum Payment:',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${((policy['minimumPercentage'] as double? ?? 0.2) * 100).toStringAsFixed(0)}% or ${currencyFormat.format(policy['minimumAmount'] as double? ?? 1000.0)}, whichever is higher',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        
        // Recommended payment
        Row(
          children: [
            Text(
              'Recommended Payment:',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${((policy['recommendedPercentage'] as double? ?? 0.3) * 100).toStringAsFixed(0)}% or ${currencyFormat.format(policy['recommendedAmount'] as double? ?? 1500.0)}, whichever is higher',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const Divider(height: 24),
      ],
    );
  }
}