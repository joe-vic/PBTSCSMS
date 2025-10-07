import 'package:flutter/foundation.dart';

class DashboardMetrics {
  final double totalRevenue;
  final double thisMonthRevenue;
  final Map<String, int> studentsByGradeLevel;
  final int totalStudents;
  final int totalTeachers;
  final int totalCourses;
  final int pendingEnrollments;
  final int activeEnrollments;

  const DashboardMetrics({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.studentsByGradeLevel,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalCourses,
    required this.pendingEnrollments,
    required this.activeEnrollments,
  });
}

class DashboardProvider with ChangeNotifier {
  String _selectedTab = 'dashboard';
  DashboardMetrics _metrics = const DashboardMetrics(
    totalRevenue: 0.0,
    thisMonthRevenue: 0.0,
    studentsByGradeLevel: {},
    totalStudents: 0,
    totalTeachers: 0,
    totalCourses: 0,
    pendingEnrollments: 0,
    activeEnrollments: 0,
  );
  bool _isRefreshing = false;
  bool _isLoading = true;
  
  String get selectedTab => _selectedTab;
  DashboardMetrics get metrics => _metrics;
  bool get isRefreshing => _isRefreshing;
  bool get isLoading => _isLoading;
  
  void setSelectedTab(String tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }
  
  Future<void> fetchDashboardData() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous calls
    
    _isRefreshing = true;
    notifyListeners();
    
    try {
      // Simulate API call with timeout
      await Future.delayed(const Duration(seconds: 2));
      
      // Update with complete mock data
      _metrics = const DashboardMetrics(
        totalRevenue: 125000.0,
        thisMonthRevenue: 12500.0,
        studentsByGradeLevel: {
          '1': 45,
          '2': 50,
          '3': 48,
          '4': 52,
          '5': 47,
          '6': 43,
        },
        totalStudents: 245,
        totalTeachers: 32,
        totalCourses: 15,
        pendingEnrollments: 5,
        activeEnrollments: 240,
      );
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      _isRefreshing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadInitialData() {
    if (!_isLoading) return; // Prevent multiple initial loads
    
    _isLoading = true;
    notifyListeners();
    
    Future.delayed(const Duration(seconds: 1), () {
      _metrics = const DashboardMetrics(
        totalRevenue: 125000.0,
        thisMonthRevenue: 12500.0,
        studentsByGradeLevel: {
          '1': 45,
          '2': 50,
          '3': 48,
          '4': 52,
          '5': 47,
          '6': 43,
        },
        totalStudents: 245,
        totalTeachers: 32,
        totalCourses: 15,
        pendingEnrollments: 5,
        activeEnrollments: 240,
      );
      _isLoading = false;
      notifyListeners();
    });
  }
}