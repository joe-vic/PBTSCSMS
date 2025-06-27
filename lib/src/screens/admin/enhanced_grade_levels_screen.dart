import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme.dart';

class EnhancedGradeLevelsScreen extends StatefulWidget {
  const EnhancedGradeLevelsScreen({super.key});

  @override
  State<EnhancedGradeLevelsScreen> createState() => _EnhancedGradeLevelsScreenState();
}

class _EnhancedGradeLevelsScreenState extends State<EnhancedGradeLevelsScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gradeLevelController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  List<Map<String, dynamic>> _gradeLevels = [];
  List<Map<String, dynamic>> _filteredGradeLevels = [];
  bool _isLoading = true;
  bool _isGridView = false;
  String _sortBy = 'name'; // name, dateCreated, studentCount
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadGradeLevels();
    _searchController.addListener(_filterGradeLevels);
  }

  void _initializeControllers() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    _gradeLevelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGradeLevels() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate loading grade levels from Firestore
      await Future.delayed(const Duration(milliseconds: 500)); // Remove this in real implementation
      
      // Replace with actual Firestore query
      final gradeLevelsData = [
        {
          'id': '1',
          'name': 'Grade 7',
          'description': 'Junior High School Grade 7',
          'studentCount': 125,
          'dateCreated': DateTime.now().subtract(const Duration(days: 365)),
          'isActive': true,
        },
        {
          'id': '2',
          'name': 'Grade 8',
          'description': 'Junior High School Grade 8',
          'studentCount': 118,
          'dateCreated': DateTime.now().subtract(const Duration(days: 300)),
          'isActive': true,
        },
        {
          'id': '3',
          'name': 'Grade 9',
          'description': 'Junior High School Grade 9',
          'studentCount': 132,
          'dateCreated': DateTime.now().subtract(const Duration(days: 250)),
          'isActive': true,
        },
        {
          'id': '4',
          'name': 'Grade 10',
          'description': 'Junior High School Grade 10',
          'studentCount': 98,
          'dateCreated': DateTime.now().subtract(const Duration(days: 200)),
          'isActive': true,
        },
        {
          'id': '5',
          'name': 'Grade 11',
          'description': 'Senior High School Grade 11',
          'studentCount': 87,
          'dateCreated': DateTime.now().subtract(const Duration(days: 150)),
          'isActive': true,
        },
        {
          'id': '6',
          'name': 'Grade 12',
          'description': 'Senior High School Grade 12',
          'studentCount': 76,
          'dateCreated': DateTime.now().subtract(const Duration(days: 100)),
          'isActive': true,
        },
        {
          'id': '7',
          'name': 'College',
          'description': 'College Level Programs',
          'studentCount': 234,
          'dateCreated': DateTime.now().subtract(const Duration(days: 50)),
          'isActive': true,
        },
      ];
      
      setState(() {
        _gradeLevels = gradeLevelsData;
        _filteredGradeLevels = gradeLevelsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load grade levels: $e');
    }
  }

  void _filterGradeLevels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGradeLevels = _gradeLevels.where((gradeLevel) {
        final name = gradeLevel['name'].toString().toLowerCase();
        final description = gradeLevel['description'].toString().toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    });
    _sortGradeLevels();
  }

  void _sortGradeLevels() {
    setState(() {
      _filteredGradeLevels.sort((a, b) {
        dynamic aValue, bValue;
        
        switch (_sortBy) {
          case 'name':
            aValue = a['name'].toString().toLowerCase();
            bValue = b['name'].toString().toLowerCase();
            break;
          case 'dateCreated':
            aValue = a['dateCreated'] as DateTime;
            bValue = b['dateCreated'] as DateTime;
            break;
          case 'studentCount':
            aValue = a['studentCount'] as int;
            bValue = b['studentCount'] as int;
            break;
          default:
            aValue = a['name'].toString().toLowerCase();
            bValue = b['name'].toString().toLowerCase();
        }
        
        final comparison = Comparable.compare(aValue, bValue);
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: SMSTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: SMSTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 1200;
    final isMediumScreen = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(isLargeScreen, isMediumScreen),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SMSTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_back_rounded, color: SMSTheme.primaryColor),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grade_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grade Levels',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              Text(
                'Manage academic grade levels',
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // View Toggle
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isGridView = false),
                icon: Icon(
                  Icons.list_rounded,
                  color: !_isGridView ? SMSTheme.primaryColor : Colors.grey,
                ),
                tooltip: 'List View',
              ),
              IconButton(
                onPressed: () => setState(() => _isGridView = true),
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: _isGridView ? SMSTheme.primaryColor : Colors.grey,
                ),
                tooltip: 'Grid View',
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Grade Levels...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isLargeScreen, bool isMediumScreen) {
    return Column(
      children: [
        // Search and Filter Bar
        _buildSearchAndFilterBar(),
        
        // Stats Cards
        _buildStatsCards(),
        
        // Grade Levels Content
        Expanded(
          child: _buildGradeLevelsContent(isLargeScreen, isMediumScreen),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search grade levels...',
                      prefixIcon: Icon(Icons.search_rounded, color: SMSTheme.textSecondaryColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: Icon(Icons.sort_rounded, color: SMSTheme.textSecondaryColor),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                      DropdownMenuItem(value: 'dateCreated', child: Text('Sort by Date')),
                      DropdownMenuItem(value: 'studentCount', child: Text('Sort by Students')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                        _sortGradeLevels();
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Sort Direction
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _sortGradeLevels();
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: SMSTheme.primaryColor,
                ),
                tooltip: _sortAscending ? 'Ascending' : 'Descending',
              ),
            ],
          ),
          
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Found ${_filteredGradeLevels.length} grade levels',
                  style: TextStyle(
                    fontSize: 14,
                    color: SMSTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _filterGradeLevels();
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalStudents = _gradeLevels.fold<int>(0, (sum, grade) => sum + (grade['studentCount'] as int));
    final activeGrades = _gradeLevels.where((grade) => grade['isActive'] == true).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Grades',
              _gradeLevels.length.toString(),
              Icons.grade_rounded,
              SMSTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Active Grades',
              activeGrades.toString(),
              Icons.check_circle_rounded,
              SMSTheme.successColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Students',
              totalStudents.toString(),
              Icons.people_rounded,
              const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Avg per Grade',
              totalStudents > 0 ? (totalStudents / _gradeLevels.length).round().toString() : '0',
              Icons.analytics_rounded,
              const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up_rounded, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeLevelsContent(bool isLargeScreen, bool isMediumScreen) {
    if (_filteredGradeLevels.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: _isGridView 
          ? _buildGridView(isLargeScreen, isMediumScreen)
          : _buildListView(),
    );
  }

  Widget _buildGridView(bool isLargeScreen, bool isMediumScreen) {
    int crossAxisCount = isLargeScreen ? 4 : isMediumScreen ? 3 : 2;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredGradeLevels.length,
      itemBuilder: (context, index) {
        final gradeLevel = _filteredGradeLevels[index];
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: _buildGradeLevelCard(gradeLevel, isGridView: true),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      itemCount: _filteredGradeLevels.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final gradeLevel = _filteredGradeLevels[index];
        return FadeInLeft(
          delay: Duration(milliseconds: 50 * index),
          child: _buildGradeLevelCard(gradeLevel, isGridView: false),
        );
      },
    );
  }

  Widget _buildGradeLevelCard(Map<String, dynamic> gradeLevel, {required bool isGridView}) {
    final color = _getGradeLevelColor(gradeLevel['name']);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showGradeLevelDetails(gradeLevel),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isGridView ? _buildGridCardContent(gradeLevel, color) : _buildListCardContent(gradeLevel, color),
        ),
      ),
    );
  }

  Widget _buildGridCardContent(Map<String, dynamic> gradeLevel, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.grade_rounded, color: color, size: 20),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, color: SMSTheme.textSecondaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: SMSTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 18, color: SMSTheme.errorColor),
                      const SizedBox(width: 8),
                      const Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(value.toString(), gradeLevel),
            ),
          ],
        ),
        
        const Spacer(),
        
        Text(
          gradeLevel['name'],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          gradeLevel['description'],
          style: TextStyle(
            fontSize: 12,
            color: SMSTheme.textSecondaryColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${gradeLevel['studentCount']} students',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListCardContent(Map<String, dynamic> gradeLevel, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.grade_rounded, color: color, size: 24),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gradeLevel['name'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gradeLevel['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: SMSTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${gradeLevel['studentCount']} students',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created ${DateFormat('MMM d, yyyy').format(gradeLevel['dateCreated'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: SMSTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        PopupMenuButton(
          icon: Icon(Icons.more_vert_rounded, color: SMSTheme.textSecondaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18, color: SMSTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 18, color: SMSTheme.errorColor),
                  const SizedBox(width: 8),
                  const Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleMenuAction(value.toString(), gradeLevel),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.grade_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Grade Levels Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SMSTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'No grade levels match your search criteria'
                : 'Start by adding your first grade level',
            style: TextStyle(
              fontSize: 14,
              color: SMSTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddGradeLevelDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Grade Level'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _fabController.forward().then((_) => _fabController.reverse());
          _showAddGradeLevelDialog();
        },
        backgroundColor: SMSTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Grade Level'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Color _getGradeLevelColor(String gradeName) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Yellow
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
    ];
    
    final index = gradeName.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _handleMenuAction(String action, Map<String, dynamic> gradeLevel) {
    switch (action) {
      case 'edit':
        _showEditGradeLevelDialog(gradeLevel);
        break;
      case 'delete':
        _showDeleteConfirmDialog(gradeLevel);
        break;
    }
  }

  void _showGradeLevelDetails(Map<String, dynamic> gradeLevel) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SMSTheme.primaryColor, SMSTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grade_rounded, color: Colors.white, size: 32),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                gradeLevel['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                gradeLevel['description'],
                style: TextStyle(
                  fontSize: 16,
                  color: SMSTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailItem(
                    'Students',
                    gradeLevel['studentCount'].toString(),
                    Icons.people_rounded,
                    SMSTheme.primaryColor,
                  ),
                  _buildDetailItem(
                    'Status',
                    gradeLevel['isActive'] ? 'Active' : 'Inactive',
                    Icons.check_circle_rounded,
                    gradeLevel['isActive'] ? SMSTheme.successColor : SMSTheme.errorColor,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Created: ${DateFormat('MMMM d, yyyy').format(gradeLevel['dateCreated'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: SMSTheme.textSecondaryColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditGradeLevelDialog(gradeLevel);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SMSTheme.primaryColor,
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  void _showAddGradeLevelDialog() {
    _gradeLevelController.clear();
    _descriptionController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SMSTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_rounded, color: SMSTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            const Text('Add Grade Level'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _gradeLevelController,
                decoration: InputDecoration(
                  labelText: 'Grade Level Name',
                  hintText: 'e.g., Grade 7, College',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.grade_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of this grade level',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 3,
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
            onPressed: () {
              if (_gradeLevelController.text.isNotEmpty) {
                Navigator.pop(context);
                _addGradeLevel();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditGradeLevelDialog(Map<String, dynamic> gradeLevel) {
    _gradeLevelController.text = gradeLevel['name'];
    _descriptionController.text = gradeLevel['description'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SMSTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_rounded, color: SMSTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            const Text('Edit Grade Level'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _gradeLevelController,
                decoration: InputDecoration(
                  labelText: 'Grade Level Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.grade_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 3,
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
            onPressed: () {
              if (_gradeLevelController.text.isNotEmpty) {
                Navigator.pop(context);
                _editGradeLevel(gradeLevel);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> gradeLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SMSTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_rounded, color: SMSTheme.errorColor),
            ),
            const SizedBox(width: 12),
            const Text('Delete Grade Level'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${gradeLevel['name']}"? This action cannot be undone and will affect ${gradeLevel['studentCount']} students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGradeLevel(gradeLevel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SMSTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addGradeLevel() {
    // Simulate adding to Firestore
    final newGradeLevel = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _gradeLevelController.text,
      'description': _descriptionController.text,
      'studentCount': 0,
      'dateCreated': DateTime.now(),
      'isActive': true,
    };
    
    setState(() {
      _gradeLevels.add(newGradeLevel);
      _filterGradeLevels();
    });
    
    _showSuccessSnackBar('Grade level "${_gradeLevelController.text}" added successfully');
  }

  void _editGradeLevel(Map<String, dynamic> gradeLevel) {
    // Simulate updating in Firestore
    final index = _gradeLevels.indexWhere((g) => g['id'] == gradeLevel['id']);
    if (index != -1) {
      setState(() {
        _gradeLevels[index]['name'] = _gradeLevelController.text;
        _gradeLevels[index]['description'] = _descriptionController.text;
        _filterGradeLevels();
      });
      
      _showSuccessSnackBar('Grade level updated successfully');
    }
  }

  void _deleteGradeLevel(Map<String, dynamic> gradeLevel) {
    // Simulate deleting from Firestore
    setState(() {
      _gradeLevels.removeWhere((g) => g['id'] == gradeLevel['id']);
      _filterGradeLevels();
    });
    
    _showSuccessSnackBar('Grade level "${gradeLevel['name']}" deleted successfully');
  }
}