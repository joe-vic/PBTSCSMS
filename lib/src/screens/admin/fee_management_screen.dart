import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({Key? key}) : super(key: key);

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  
  // Data variables
  Map<String, dynamic> feeConfiguration = {};
  Map<String, dynamic> tuitionConfiguration = {};  
  Map<String, dynamic> paymentSchemes = {};

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  // Form controllers
  final _feeNameController = TextEditingController();
  final _feeAmountController = TextEditingController();
  String _selectedPaymentType = 'uponEnrollment';
  bool _feeEnabled = true;

  // ADD THESE NEW FORM CONTROLLERS:
  final _schemeNameController = TextEditingController();
  final _minimumAmountController = TextEditingController();
  final _downPaymentPercentageController = TextEditingController();
  final _maxInstallmentsController = TextEditingController();
  final _descriptionController = TextEditingController();


  // Categories for filtering
  final List<String> _categories = [
    'All', 'NKP', 'Elementary', 'JHS', 'SHS', 'College'
  ];
 
 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFeeConfiguration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feeNameController.dispose();
    _feeAmountController.dispose();

      // Add these new controllers
  _schemeNameController.dispose();
  _minimumAmountController.dispose();
  _downPaymentPercentageController.dispose();
  _maxInstallmentsController.dispose();
  _descriptionController.dispose();
    super.dispose();


 

 
}
  

  Future<void> _loadFeeConfiguration() async {
    setState(() => _isLoading = true);
    
    try {
      // Load fee configuration
      final feeDoc = await _firestore
          .collection('adminSettings')
          .doc('feeConfiguration')
          .get();
      
      // Load tuition configuration  
      final tuitionDoc = await _firestore
          .collection('adminSettings')
          .doc('tuitionConfiguration')
          .get();
            
            // Add this line after loading tuition configuration:
      final paymentSchemesDoc = await _firestore
          .collection('adminSettings')
          .doc('paymentSchemes')
          .get();

      // Add this in setState:
      paymentSchemes = paymentSchemesDoc.exists ? paymentSchemesDoc.data() ?? {} : {};
      
      if (feeDoc.exists && tuitionDoc.exists) {
        setState(() {
          feeConfiguration = feeDoc.data() ?? {};
          tuitionConfiguration = tuitionDoc.data() ?? {};
           paymentSchemes = paymentSchemesDoc.exists ? paymentSchemesDoc.data() ?? {} : {};
        });
      } else {
        _showErrorSnackBar('Fee configuration not found. Please initialize the database first.');
      }




    } catch (e) {
      _showErrorSnackBar('Error loading fee configuration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
Future<void> _savePaymentSchemes() async {
  try {
    await _firestore
        .collection('adminSettings')
        .doc('paymentSchemes')
        .set(paymentSchemes);
    
    _showSuccessSnackBar('Payment schemes saved successfully!');
  } catch (e) {
    _showErrorSnackBar('Error saving payment schemes: $e');
  }
}


  Future<void> _saveFeeConfiguration() async {
    try {
      await _firestore
          .collection('adminSettings')
          .doc('feeConfiguration')
          .set(feeConfiguration);
      
      _showSuccessSnackBar('Fee configuration saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Error saving fee configuration: $e');
    }
  }

  Future<void> _saveTuitionConfiguration() async {
    try {
      await _firestore
          .collection('adminSettings')
          .doc('tuitionConfiguration')
          .set(tuitionConfiguration);
      
      _showSuccessSnackBar('Tuition configuration saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Error saving tuition configuration: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: SMSTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: SMSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        backgroundColor: SMSTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeeConfiguration,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportFeeConfiguration();
                  break;
                case 'import':
                  _showImportDialog();
                  break;
                case 'backup':
                  _createBackup();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Configuration'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Import Configuration'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text('Create Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Miscellaneous Fees', icon: Icon(Icons.receipt)),
            Tab(text: 'Tuition Fees', icon: Icon(Icons.school)),
            Tab(text: 'Payment Schemes', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
              ),
            )
          : Column(
              children: [
                // Search and Filter Bar
                _buildSearchAndFilterBar(),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMiscellaneousFeesTab(),
                      _buildTuitionFeesTab(),
                      _buildPaymentSchemesTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFeeDialog(),
        backgroundColor: SMSTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Fee', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search fees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Category Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'All';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiscellaneousFeesTab() {
    final gradeLevels = feeConfiguration['gradeLevels'] as Map<String, dynamic>? ?? {};
    final filteredGradeLevels = _filterGradeLevels(gradeLevels);

    if (filteredGradeLevels.isEmpty) {
      return _buildEmptyState('No miscellaneous fees found', Icons.receipt);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredGradeLevels.length,
      itemBuilder: (context, index) {
        final gradeLevel = filteredGradeLevels.keys.elementAt(index);
        final fees = filteredGradeLevels[gradeLevel]['miscFees'] as List<dynamic>? ?? [];
        
        return _buildGradeLevelCard(gradeLevel, fees, 'misc');
      },
    );
  }

  Widget _buildTuitionFeesTab() {
    final gradeLevels = tuitionConfiguration['gradeLevels'] as Map<String, dynamic>? ?? {};
    final filteredGradeLevels = _filterTuitionGradeLevels(gradeLevels);

    if (filteredGradeLevels.isEmpty) {
      return _buildEmptyState('No tuition fees found', Icons.school);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredGradeLevels.length,
      itemBuilder: (context, index) {
        final gradeLevel = filteredGradeLevels.keys.elementAt(index);
        final tuitionData = filteredGradeLevels[gradeLevel];
        
        return _buildTuitionCard(gradeLevel, tuitionData);
      },
    );
  }
 
 
Widget _buildPaymentSchemesTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Scheme Configuration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SMSTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure payment options for students',
                  style: TextStyle(
                    fontSize: 14,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddPaymentSchemeDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Scheme', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Payment Schemes List
        if (paymentSchemes.isEmpty)
          _buildEmptyPaymentSchemesState()
        else
          _buildPaymentSchemesList(),
      ],
    ),
  );
}

Widget _buildEmptyPaymentSchemesState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.payment,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No Payment Schemes Configured',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add payment schemes to provide flexible payment options for students',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showAddPaymentSchemeDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add First Payment Scheme', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: SMSTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPaymentSchemesList() {
  return Column(
    children: paymentSchemes.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPaymentSchemeCard(entry.key, entry.value as Map<String, dynamic>),
      );
    }).toList(),
  );
}

Widget _buildPaymentSchemeCard(String schemeKey, Map<String, dynamic> schemeData) {
  final isEnabled = schemeData['enabled'] as bool? ?? true;
  final schemeName = _getSchemeDisplayName(schemeKey);
  final schemeIcon = _getSchemeIcon(schemeKey);
  final schemeColor = _getSchemeColor(schemeKey);
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isEnabled ? schemeColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? schemeColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  schemeIcon,
                  color: isEnabled ? schemeColor : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          schemeName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isEnabled ? SMSTheme.textPrimaryColor : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isEnabled ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isEnabled ? 'ACTIVE' : 'DISABLED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSchemeDescription(schemeKey, schemeData),
                      style: TextStyle(
                        fontSize: 14,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle Switch
              Switch(
                value: isEnabled,
                onChanged: (value) => _togglePaymentScheme(schemeKey, value),
                activeColor: SMSTheme.primaryColor,
              ),
              // More Options
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditPaymentSchemeDialog(schemeKey, schemeData);
                      break;
                    case 'duplicate':
                      _duplicatePaymentScheme(schemeKey, schemeData);
                      break;
                    case 'delete':
                      _showDeletePaymentSchemeDialog(schemeKey);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, size: 20),
                      title: Text('Edit Scheme'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy, size: 20),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, size: 20, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Scheme Details
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildSchemeDetails(schemeKey, schemeData),
        ),
      ],
    ),
  );
}

Widget _buildSchemeDetails(String schemeKey, Map<String, dynamic> schemeData) {
  switch (schemeKey) {
    case 'standardInstallment':
      return _buildStandardInstallmentDetails(schemeData);
    case 'flexibleInstallment':
      return _buildFlexibleInstallmentDetails(schemeData);
    case 'emergencyPlan':
      return _buildEmergencyPlanDetails(schemeData);
    case 'scholarshipPlan':
      return _buildScholarshipPlanDetails(schemeData);
    default:
      return _buildCustomSchemeDetails(schemeData);
  }
}

Widget _buildStandardInstallmentDetails(Map<String, dynamic> schemeData) {
  final downPaymentPercentage = (schemeData['downPaymentPercentage'] as num?)?.toDouble() ?? 20.0;
  
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildDetailCard(
              'Down Payment',
              '${downPaymentPercentage.toStringAsFixed(0)}%',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDetailCard(
              'Remaining Balance',
              '${(100 - downPaymentPercentage).toStringAsFixed(0)}%',
              Icons.schedule,
              Colors.orange,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        'Students pay ${downPaymentPercentage.toStringAsFixed(0)}% upfront and the remaining balance in installments.',
        Icons.info_outline,
      ),
    ],
  );
}

Widget _buildFlexibleInstallmentDetails(Map<String, dynamic> schemeData) {
  final minimumAmount = (schemeData['minimumAmount'] as num?)?.toDouble() ?? 1000.0;
  
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildDetailCard(
              'Minimum Payment',
              '₱${NumberFormat('#,##0.00').format(minimumAmount)}',
              Icons.money,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDetailCard(
              'Payment Frequency',
              'Flexible',
              Icons.schedule,
              Colors.purple,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        'Students can pay any amount above ₱${NumberFormat('#,##0').format(minimumAmount)} at their own pace.',
        Icons.info_outline,
      ),
    ],
  );
}

Widget _buildEmergencyPlanDetails(Map<String, dynamic> schemeData) {
  final minimumAmount = (schemeData['minimumAmount'] as num?)?.toDouble() ?? 500.0;
  
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildDetailCard(
              'Emergency Minimum',
              '₱${NumberFormat('#,##0.00').format(minimumAmount)}',
              Icons.warning,
              Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDetailCard(
              'Special Terms',
              'Emergency Only',
              Icons.emergency,
              Colors.orange,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        'Special payment plan for students facing financial emergencies. Minimum payment of ₱${NumberFormat('#,##0').format(minimumAmount)}.',
        Icons.warning_amber,
      ),
    ],
  );
}

Widget _buildScholarshipPlanDetails(Map<String, dynamic> schemeData) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildDetailCard(
              'Discount Type',
              'Variable',
              Icons.school,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDetailCard(
              'Eligibility',
              'Merit Based',
              Icons.star,
              Colors.yellow.shade700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        'Scholarship program for eligible students with academic merit or financial need.',
        Icons.school,
      ),
    ],
  );
}

Widget _buildCustomSchemeDetails(Map<String, dynamic> schemeData) {
  final details = <Widget>[];
  
  if (schemeData['minimumAmount'] != null) {
    final minimumAmount = (schemeData['minimumAmount'] as num).toDouble();
    details.add(
      _buildDetailCard(
        'Minimum Amount',
        '₱${NumberFormat('#,##0.00').format(minimumAmount)}',
        Icons.money,
        Colors.green,
      ),
    );
  }
  
  if (schemeData['downPaymentPercentage'] != null) {
    final percentage = (schemeData['downPaymentPercentage'] as num).toDouble();
    details.add(
      _buildDetailCard(
        'Down Payment',
        '${percentage.toStringAsFixed(0)}%',
        Icons.account_balance_wallet,
        Colors.blue,
      ),
    );
  }
  
  if (details.isEmpty) {
    return _buildInfoCard(
      'Custom payment scheme with special terms and conditions.',
      Icons.info_outline,
    );
  }
  
  return Column(
    children: [
      if (details.length == 1)
        details.first
      else
        Row(
          children: [
            Expanded(child: details[0]),
            if (details.length > 1) ...[
              const SizedBox(width: 16),
              Expanded(child: details[1]),
            ],
          ],
        ),
      if (details.length > 2) ...[
        const SizedBox(height: 16),
        Row(
          children: details.skip(2).take(2).map((detail) => Expanded(child: detail)).toList(),
        ),
      ],
    ],
  );
}

Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: SMSTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildInfoCard(String message, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    ),
  );
}




  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddFeeDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add New Fee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _filterGradeLevels(Map<String, dynamic> gradeLevels) {
    Map<String, dynamic> filtered = {};
    
    for (var entry in gradeLevels.entries) {
      final gradeLevel = entry.key;
      final data = entry.value as Map<String, dynamic>;
      
      // Filter by category
      if (_selectedCategory != 'All') {
        final category = _getGradeLevelCategory(gradeLevel);
        if (category != _selectedCategory) continue;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final fees = data['miscFees'] as List<dynamic>? ?? [];
        bool hasMatchingFee = fees.any((fee) {
          final feeName = (fee['name'] as String? ?? '').toLowerCase();
          return feeName.contains(_searchQuery) || gradeLevel.toLowerCase().contains(_searchQuery);
        });
        
        if (!hasMatchingFee) continue;
      }
      
      filtered[gradeLevel] = data;
    }
    
    return filtered;
  }

  Map<String, dynamic> _filterTuitionGradeLevels(Map<String, dynamic> gradeLevels) {
    Map<String, dynamic> filtered = {};
    
    for (var entry in gradeLevels.entries) {
      final gradeLevel = entry.key;
      final data = entry.value as Map<String, dynamic>;
      
      // Filter by category
      if (_selectedCategory != 'All') {
        final category = data['category'] as String? ?? '';
        if (category != _selectedCategory) continue;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        if (!gradeLevel.toLowerCase().contains(_searchQuery)) continue;
      }
      
      filtered[gradeLevel] = data;
    }
    
    return filtered;
  }

  String _getGradeLevelCategory(String gradeLevel) {
    if (['Nursery', 'Kinder 1', 'Kinder 2', 'Preparatory'].contains(gradeLevel)) {
      return 'NKP';
    } else if (gradeLevel.startsWith('Grade') && int.tryParse(gradeLevel.split(' ')[1]) != null) {
      final grade = int.parse(gradeLevel.split(' ')[1]);
      if (grade <= 6) return 'Elementary';
      if (grade <= 10) return 'JHS';
      return 'SHS';
    } else if (['BSIT', 'BSBA', 'BSHM', 'BSed', 'BEed', 'BSEtrep'].contains(gradeLevel)) {
      return 'College';
    }
    return 'Other';
  }

  // Helper methods for actions
  void _exportFeeConfiguration() {
    _showSuccessSnackBar('Export feature coming soon!');
  }

  void _showImportDialog() {
    _showSuccessSnackBar('Import feature coming soon!');
  }

  void _createBackup() {
    _showSuccessSnackBar('Backup created successfully!');
  }

  // Add these methods to your _FeeManagementScreenState class

// Helper Methods for Payment Schemes
String _getSchemeDisplayName(String schemeKey) {
  switch (schemeKey) {
    case 'standardInstallment':
      return 'Standard Installment';
    case 'flexibleInstallment':
      return 'Flexible Installment';
    case 'emergencyPlan':
      return 'Emergency Plan';
    case 'scholarshipPlan':
      return 'Scholarship Plan';
    default:
      return schemeKey.replaceAll(RegExp(r'[A-Z]'), ' \$0').trim().split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
  }
}

IconData _getSchemeIcon(String schemeKey) {
  switch (schemeKey) {
    case 'standardInstallment':
      return Icons.account_balance;
    case 'flexibleInstallment':
      return Icons.schedule;
    case 'emergencyPlan':
      return Icons.emergency;
    case 'scholarshipPlan':
      return Icons.school;
    default:
      return Icons.payment;
  }
}

Color _getSchemeColor(String schemeKey) {
  switch (schemeKey) {
    case 'standardInstallment':
      return Colors.blue;
    case 'flexibleInstallment':
      return Colors.green;
    case 'emergencyPlan':
      return Colors.red;
    case 'scholarshipPlan':
      return Colors.orange;
    default:
      return SMSTheme.primaryColor;
  }
}

String _getSchemeDescription(String schemeKey, Map<String, dynamic> schemeData) {
  switch (schemeKey) {
    case 'standardInstallment':
      final percentage = (schemeData['downPaymentPercentage'] as num?)?.toDouble() ?? 20.0;
      return 'Pay ${percentage.toStringAsFixed(0)}% down payment, balance in installments';
    case 'flexibleInstallment':
      final minimum = (schemeData['minimumAmount'] as num?)?.toDouble() ?? 1000.0;
      return 'Flexible payments with ₱${NumberFormat('#,##0').format(minimum)} minimum';
    case 'emergencyPlan':
      final minimum = (schemeData['minimumAmount'] as num?)?.toDouble() ?? 500.0;
      return 'Emergency payment plan with ₱${NumberFormat('#,##0').format(minimum)} minimum';
    case 'scholarshipPlan':
      return 'Merit-based scholarship program for eligible students';
    default:
      return 'Custom payment scheme with special terms';
  }
}

// Dialog Methods
void _showAddPaymentSchemeDialog() {
  String selectedSchemeType = 'standardInstallment';
  _schemeNameController.clear();
  _minimumAmountController.clear();
  _downPaymentPercentageController.clear();
  _maxInstallmentsController.clear();
  _descriptionController.clear();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add Payment Scheme'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scheme Type Selection
                DropdownButtonFormField<String>(
                  value: selectedSchemeType,
                  decoration: InputDecoration(
                    labelText: 'Scheme Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'standardInstallment',
                      child: Text('Standard Installment'),
                    ),
                    DropdownMenuItem(
                      value: 'flexibleInstallment',
                      child: Text('Flexible Installment'),
                    ),
                    DropdownMenuItem(
                      value: 'emergencyPlan',
                      child: Text('Emergency Plan'),
                    ),
                    DropdownMenuItem(
                      value: 'scholarshipPlan',
                      child: Text('Scholarship Plan'),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('Custom Scheme'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSchemeType = value ?? 'standardInstallment';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Custom Name Field (for custom schemes)
                if (selectedSchemeType == 'custom')
                  Column(
                    children: [
                      TextFormField(
                        controller: _schemeNameController,
                        decoration: InputDecoration(
                          labelText: 'Scheme Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.label),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Scheme-specific fields
                if (selectedSchemeType == 'standardInstallment')
                  TextFormField(
                    controller: _downPaymentPercentageController,
                    decoration: InputDecoration(
                      labelText: 'Down Payment Percentage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),

                if (selectedSchemeType == 'flexibleInstallment' || 
                   selectedSchemeType == 'emergencyPlan' ||
                   selectedSchemeType == 'custom')
                  TextFormField(
                    controller: _minimumAmountController,
                    decoration: InputDecoration(
                      labelText: 'Minimum Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.money),
                      prefixText: '₱',
                    ),
                    keyboardType: TextInputType.number,
                  ),

                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addPaymentScheme(selectedSchemeType),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Scheme'),
          ),
        ],
      ),
    ),
  );
}

void _showEditPaymentSchemeDialog(String schemeKey, Map<String, dynamic> schemeData) {
  // Pre-fill controllers with existing data
  _minimumAmountController.text = (schemeData['minimumAmount'] as num?)?.toString() ?? '';
  _downPaymentPercentageController.text = (schemeData['downPaymentPercentage'] as num?)?.toString() ?? '';
  _descriptionController.text = schemeData['description'] as String? ?? '';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit ${_getSchemeDisplayName(schemeKey)}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Different fields based on scheme type
              if (schemeKey == 'standardInstallment')
                TextFormField(
                  controller: _downPaymentPercentageController,
                  decoration: InputDecoration(
                    labelText: 'Down Payment Percentage',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.percent),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                ),

              if (schemeKey == 'flexibleInstallment' || schemeKey == 'emergencyPlan')
                TextFormField(
                  controller: _minimumAmountController,
                  decoration: InputDecoration(
                    labelText: 'Minimum Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.money),
                    prefixText: '₱',
                  ),
                  keyboardType: TextInputType.number,
                ),

              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _updatePaymentScheme(schemeKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: SMSTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

void _showDeletePaymentSchemeDialog(String schemeKey) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Payment Scheme'),
      content: Text(
        'Are you sure you want to delete "${_getSchemeDisplayName(schemeKey)}"? '
        'This action cannot be undone and may affect existing enrollments.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _deletePaymentScheme(schemeKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// CRUD Operations for Payment Schemes
void _addPaymentScheme(String schemeType) {
  String schemeKey = schemeType;
  
  // For custom schemes, use the provided name
  if (schemeType == 'custom') {
    if (_schemeNameController.text.isEmpty) {
      _showErrorSnackBar('Please enter a scheme name');
      return;
    }
    schemeKey = _schemeNameController.text.toLowerCase().replaceAll(' ', '_');
  }

  // Check if scheme already exists
  if (paymentSchemes.containsKey(schemeKey)) {
    _showErrorSnackBar('A scheme with this name already exists');
    return;
  }

  // Create scheme data based on type
  Map<String, dynamic> schemeData = {
    'enabled': true,
    'createdAt': Timestamp.now(),
  };

  if (schemeType == 'standardInstallment') {
    final percentage = double.tryParse(_downPaymentPercentageController.text);
    if (percentage == null || percentage <= 0 || percentage >= 100) {
      _showErrorSnackBar('Please enter a valid percentage (1-99)');
      return;
    }
    schemeData['downPaymentPercentage'] = percentage;
  } else if (schemeType == 'flexibleInstallment' || schemeType == 'emergencyPlan' || schemeType == 'custom') {
    final amount = double.tryParse(_minimumAmountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid minimum amount');
      return;
    }
    schemeData['minimumAmount'] = amount;
  }

  if (_descriptionController.text.isNotEmpty) {
    schemeData['description'] = _descriptionController.text;
  }

  // Add to payment schemes
  setState(() {
    paymentSchemes[schemeKey] = schemeData;
  });

  // Save to Firestore
  _savePaymentSchemes().then((_) {
    Navigator.pop(context);
  });
}

void _updatePaymentScheme(String schemeKey) {
  final schemeData = Map<String, dynamic>.from(paymentSchemes[schemeKey] as Map<String, dynamic>);

  // Update based on scheme type
  if (schemeKey == 'standardInstallment') {
    final percentage = double.tryParse(_downPaymentPercentageController.text);
    if (percentage == null || percentage <= 0 || percentage >= 100) {
      _showErrorSnackBar('Please enter a valid percentage (1-99)');
      return;
    }
    schemeData['downPaymentPercentage'] = percentage;
  } else if (schemeKey == 'flexibleInstallment' || schemeKey == 'emergencyPlan') {
    final amount = double.tryParse(_minimumAmountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid minimum amount');
      return;
    }
    schemeData['minimumAmount'] = amount;
  }

  if (_descriptionController.text.isNotEmpty) {
    schemeData['description'] = _descriptionController.text;
  }

  schemeData['updatedAt'] = Timestamp.now();

  // Update payment schemes
  setState(() {
    paymentSchemes[schemeKey] = schemeData;
  });

  // Save to Firestore
  _savePaymentSchemes().then((_) {
    Navigator.pop(context);
  });
}

void _deletePaymentScheme(String schemeKey) {
  setState(() {
    paymentSchemes.remove(schemeKey);
  });

  // Save to Firestore
  _savePaymentSchemes().then((_) {
    Navigator.pop(context);
  });
}

void _togglePaymentScheme(String schemeKey, bool enabled) {
  final schemeData = Map<String, dynamic>.from(paymentSchemes[schemeKey] as Map<String, dynamic>);
  schemeData['enabled'] = enabled;
  schemeData['updatedAt'] = Timestamp.now();

  setState(() {
    paymentSchemes[schemeKey] = schemeData;
  });

  // Save to Firestore
  _savePaymentSchemes();
}

void _duplicatePaymentScheme(String originalSchemeKey, Map<String, dynamic> originalData) {
  final newSchemeKey = '${originalSchemeKey}_copy_${DateTime.now().millisecondsSinceEpoch}';
  final newSchemeData = Map<String, dynamic>.from(originalData);
  
  // Update metadata
  newSchemeData['createdAt'] = Timestamp.now();
  newSchemeData.remove('updatedAt');
  
  setState(() {
    paymentSchemes[newSchemeKey] = newSchemeData;
  });

  // Save to Firestore
  _savePaymentSchemes().then((_) {
    _showSuccessSnackBar('Payment scheme duplicated successfully');
  });
}


  //<---------- Part 2 --->
  Widget _buildGradeLevelCard(String gradeLevel, List<dynamic> fees, String type) {
    final category = _getGradeLevelCategory(gradeLevel);
    final categoryColor = _getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gradeLevel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '$category • ${fees.length} fees',
                        style: TextStyle(
                          fontSize: 12,
                          color: SMSTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'add':
                        _showAddFeeDialog(gradeLevel: gradeLevel);
                        break;
                      case 'edit_all':
                        _showBulkEditDialog(gradeLevel, fees);
                        break;
                      case 'delete_all':
                        _showDeleteAllFeesDialog(gradeLevel);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add',
                      child: ListTile(
                        leading: Icon(Icons.add, size: 20),
                        title: Text('Add Fee'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit_all',
                      child: ListTile(
                        leading: Icon(Icons.edit, size: 20),
                        title: Text('Bulk Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: ListTile(
                        leading: Icon(Icons.delete, size: 20, color: Colors.red),
                        title: Text('Delete All', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Fees List
          if (fees.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fees.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final fee = fees[index] as Map<String, dynamic>;
                return _buildFeeItem(gradeLevel, fee, index);
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No fees configured for this grade level',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFeeDialog(gradeLevel: gradeLevel),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Fee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SMSTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String gradeLevel, Map<String, dynamic> fee, int index) {
    final isEnabled = fee['enabled'] as bool? ?? true;
    final paymentType = fee['paymentType'] as String? ?? 'uponEnrollment';
    final amount = (fee['amount'] as num?)?.toDouble() ?? 0.0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled 
              ? SMSTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          paymentType == 'uponEnrollment' ? Icons.payment : Icons.schedule,
          color: isEnabled ? SMSTheme.primaryColor : Colors.grey,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fee['name'] as String? ?? 'Unnamed Fee',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isEnabled ? SMSTheme.textPrimaryColor : Colors.grey,
                decoration: isEnabled ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (!isEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DISABLED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₱${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled ? SMSTheme.primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: paymentType == 'uponEnrollment' 
                      ? Colors.green.shade100 
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  paymentType == 'uponEnrollment' ? 'Upon Enrollment' : 'Separate Payment',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: paymentType == 'uponEnrollment' 
                        ? Colors.green.shade700 
                        : Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Order: ${fee['order'] ?? index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditFeeDialog(gradeLevel, fee, index),
            tooltip: 'Edit Fee',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _showDeleteFeeDialog(gradeLevel, fee, index),
            tooltip: 'Delete Fee',
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionCard(String gradeLevel, Map<String, dynamic> tuitionData) {
    final cashFee = (tuitionData['tuitionFee_cash'] as num?)?.toDouble() ?? 0.0;
    final installmentFee = (tuitionData['tuitionFee_installment'] as num?)?.toDouble() ?? 0.0;
    final category = tuitionData['category'] as String? ?? '';
    final fullName = tuitionData['fullName'] as String?;
    final isEnabled = tuitionData['enabled'] as bool? ?? true;
    final categoryColor = _getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gradeLevel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: SMSTheme.textPrimaryColor,
                        ),
                      ),
                      if (fullName != null)
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) => _toggleTuitionStatus(gradeLevel, value),
                  activeColor: SMSTheme.primaryColor,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditTuitionDialog(gradeLevel, tuitionData),
                  tooltip: 'Edit Tuition',
                ),
              ],
            ),
          ),
          
          // Tuition Fees
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTuitionFeeCard(
                    'Cash Payment',
                    cashFee,
                    Icons.money,
                    Colors.green,
                    isEnabled,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTuitionFeeCard(
                    'Installment',
                    installmentFee,
                    Icons.schedule,
                    Colors.blue,
                    isEnabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuitionFeeCard(String title, double amount, IconData icon, Color color, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isEnabled ? color : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isEnabled ? SMSTheme.textPrimaryColor : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₱${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
 
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'NKP':
        return Colors.pink;
      case 'Elementary':
        return Colors.green;
      case 'JHS':
        return Colors.blue;
      case 'SHS':
        return Colors.orange;
      case 'College':
        return Colors.purple;
      default:
        return SMSTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'NKP':
        return Icons.child_care;
      case 'Elementary':
        return Icons.school;
      case 'JHS':
        return Icons.menu_book;
      case 'SHS':
        return Icons.auto_stories;
      case 'College':
        return Icons.school_outlined;
      default:
        return Icons.grade;
    }
  }
  //<---------- Part 3 --->

void _showAddFeeDialog({String? gradeLevel}) {
    _feeNameController.clear();
    _feeAmountController.clear();
    _selectedPaymentType = 'uponEnrollment';
    _feeEnabled = true;
    
    String? selectedGradeLevel = gradeLevel;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Fee'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grade Level Selection (if not provided)
                if (gradeLevel == null)
                  DropdownButtonFormField<String>(
                    value: selectedGradeLevel,
                    decoration: InputDecoration(
                      labelText: 'Grade Level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    hint: const Text('Select Grade Level'),
                    items: _getGradeLevelOptions(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGradeLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a grade level';
                      }
                      return null;
                    },
                  ),
                if (gradeLevel == null) const SizedBox(height: 16),
                
                // Fee Name
                TextFormField(
                  controller: _feeNameController,
                  decoration: InputDecoration(
                    labelText: 'Fee Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fee name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Fee Amount
                TextFormField(
                  controller: _feeAmountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.money),
                    prefixText: '₱ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Payment Type
                DropdownButtonFormField<String>(
                  value: _selectedPaymentType,
                  decoration: InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'uponEnrollment',
                      child: Text('Upon Enrollment'),
                    ),
                    DropdownMenuItem(
                      value: 'separatePayment',
                      child: Text('Separate Payment'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedPaymentType = value ?? 'uponEnrollment';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Enabled Switch
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: Text(_feeEnabled ? 'Fee is active' : 'Fee is disabled'),
                  value: _feeEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _feeEnabled = value;
                    });
                  },
                  activeColor: SMSTheme.primaryColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _addFee(selectedGradeLevel),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Fee'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFeeDialog(String gradeLevel, Map<String, dynamic> fee, int index) {
    _feeNameController.text = fee['name'] as String? ?? '';
    _feeAmountController.text = (fee['amount'] as num?)?.toString() ?? '';
    _selectedPaymentType = fee['paymentType'] as String? ?? 'uponEnrollment';
    _feeEnabled = fee['enabled'] as bool? ?? true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Fee - $gradeLevel'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fee Name
                TextFormField(
                  controller: _feeNameController,
                  decoration: InputDecoration(
                    labelText: 'Fee Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Fee Amount
                TextFormField(
                  controller: _feeAmountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.money),
                    prefixText: '₱ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Payment Type
                DropdownButtonFormField<String>(
                  value: _selectedPaymentType,
                  decoration: InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'uponEnrollment',
                      child: Text('Upon Enrollment'),
                    ),
                    DropdownMenuItem(
                      value: 'separatePayment',
                      child: Text('Separate Payment'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedPaymentType = value ?? 'uponEnrollment';
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Enabled Switch
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: Text(_feeEnabled ? 'Fee is active' : 'Fee is disabled'),
                  value: _feeEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _feeEnabled = value;
                    });
                  },
                  activeColor: SMSTheme.primaryColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateFee(gradeLevel, index),
              style: ElevatedButton.styleFrom(
                backgroundColor: SMSTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Fee'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteFeeDialog(String gradeLevel, Map<String, dynamic> fee, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee'),
        content: Text('Are you sure you want to delete "${fee['name']}" from $gradeLevel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteFee(gradeLevel, index),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditTuitionDialog(String gradeLevel, Map<String, dynamic> tuitionData) {
    final cashController = TextEditingController(
      text: (tuitionData['tuitionFee_cash'] as num?)?.toString() ?? '',
    );
    final installmentController = TextEditingController(
      text: (tuitionData['tuitionFee_installment'] as num?)?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Tuition - $gradeLevel'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cash Fee
              TextFormField(
                controller: cashController,
                decoration: InputDecoration(
                  labelText: 'Cash Payment Fee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.money),
                  prefixText: '₱ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Installment Fee
              TextFormField(
                controller: installmentController,
                decoration: InputDecoration(
                  labelText: 'Installment Fee',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.schedule),
                  prefixText: '₱ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateTuition(gradeLevel, cashController.text, installmentController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showBulkEditDialog(String gradeLevel, List<dynamic> fees) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Edit - $gradeLevel'),
        content: const Text('Bulk edit functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllFeesDialog(String gradeLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Fees'),
        content: Text('Are you sure you want to delete all fees for $gradeLevel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteAllFees(gradeLevel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSchemeDialog(String schemeKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Scheme Configuration'),
        content: const Text('Payment scheme configuration coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // CRUD Operations
  void _addFee(String? gradeLevel) {
    if (gradeLevel == null || _feeNameController.text.isEmpty || _feeAmountController.text.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    final amount = double.tryParse(_feeAmountController.text);
    if (amount == null) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    // Create new fee
    final newFee = {
      'id': '${gradeLevel.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      'name': _feeNameController.text,
      'amount': amount,
      'paymentType': _selectedPaymentType,
      'enabled': _feeEnabled,
      'order': _getNextFeeOrder(gradeLevel),
    };

    // Add to configuration
    final gradeLevels = feeConfiguration['gradeLevels'] as Map<String, dynamic>;
    if (gradeLevels[gradeLevel] == null) {
      gradeLevels[gradeLevel] = {'miscFees': []};
    }
    
    final fees = gradeLevels[gradeLevel]['miscFees'] as List<dynamic>;
    fees.add(newFee);

    // Save configuration
    _saveFeeConfiguration().then((_) {
      Navigator.pop(context);
      setState(() {});
    });
  }

  void _updateFee(String gradeLevel, int index) {
    if (_feeNameController.text.isEmpty || _feeAmountController.text.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    final amount = double.tryParse(_feeAmountController.text);
    if (amount == null) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    // Update fee
    final gradeLevels = feeConfiguration['gradeLevels'] as Map<String, dynamic>;
    final fees = gradeLevels[gradeLevel]['miscFees'] as List<dynamic>;
    
    fees[index] = {
      ...fees[index],
      'name': _feeNameController.text,
      'amount': amount,
      'paymentType': _selectedPaymentType,
      'enabled': _feeEnabled,
    };

    // Save configuration
    _saveFeeConfiguration().then((_) {
      Navigator.pop(context);
      setState(() {});
    });
  }

  void _deleteFee(String gradeLevel, int index) {
    final gradeLevels = feeConfiguration['gradeLevels'] as Map<String, dynamic>;
    final fees = gradeLevels[gradeLevel]['miscFees'] as List<dynamic>;
    
    fees.removeAt(index);

    // Save configuration
    _saveFeeConfiguration().then((_) {
      Navigator.pop(context);
      setState(() {});
    });
  }

  void _deleteAllFees(String gradeLevel) {
    final gradeLevels = feeConfiguration['gradeLevels'] as Map<String, dynamic>;
    gradeLevels[gradeLevel]['miscFees'] = [];

    // Save configuration
    _saveFeeConfiguration().then((_) {
      Navigator.pop(context);
      setState(() {});
    });
  }

  void _updateTuition(String gradeLevel, String cashAmount, String installmentAmount) {
    final cash = double.tryParse(cashAmount);
    final installment = double.tryParse(installmentAmount);
    
    if (cash == null || installment == null) {
      _showErrorSnackBar('Please enter valid amounts');
      return;
    }

    // Update tuition
    final gradeLevels = tuitionConfiguration['gradeLevels'] as Map<String, dynamic>;
    gradeLevels[gradeLevel]['tuitionFee_cash'] = cash;
    gradeLevels[gradeLevel]['tuitionFee_installment'] = installment;

    // Save configuration
    _saveTuitionConfiguration().then((_) {
      Navigator.pop(context);
      setState(() {});
    });
  }

  void _toggleTuitionStatus(String gradeLevel, bool enabled) {
    final gradeLevels = tuitionConfiguration['gradeLevels'] as Map<String, dynamic>;
    gradeLevels[gradeLevel]['enabled'] = enabled;

    // Save configuration
    _saveTuitionConfiguration().then((_) {
      setState(() {});
    });
  }

  // Helper methods
  List<DropdownMenuItem<String>> _getGradeLevelOptions() {
    final gradeLevels = ['Nursery', 'Kinder 1', 'Kinder 2', 'Preparatory'] +
        List.generate(12, (i) => 'Grade ${i + 1}') +
        ['BSIT', 'BSBA', 'BSHM', 'BSed', 'BEed', 'BSEtrep'];
    
    return gradeLevels.map((level) {
      return DropdownMenuItem(
        value: level,
        child: Text(level),
      );
    }).toList();
  }

  int _getNextFeeOrder(String gradeLevel) {
    final gradeLevels = feeConfiguration['gradeLevels'] as Map<String, dynamic>;
    if (gradeLevels[gradeLevel] == null) return 1;
    
    final fees = gradeLevels[gradeLevel]['miscFees'] as List<dynamic>;
    if (fees.isEmpty) return 1;
    
    int maxOrder = 0;
    for (var fee in fees) {
      final order = fee['order'] as int? ?? 0;
      if (order > maxOrder) maxOrder = order;
    }
    
    return maxOrder + 1;
  }
} 
