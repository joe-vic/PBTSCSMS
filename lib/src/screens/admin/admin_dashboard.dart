import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
 
import 'dashboard_repository.dart';
import 'widgets/app_bar.dart';
import 'widgets/navigation_panel.dart';
import 'widgets/tabs/overview_tab.dart';
import 'widgets/tabs/analytics_tab.dart';
import 'widgets/tabs/management_tab.dart';
import 'widgets/tabs/reports_tab.dart';
import 'package:school_management_system/src/providers/dashboard_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;
  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data when the dashboard is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Main Content
          _buildMainContent(),
          
          // Navigation Panel Overlay
          if (_isPanelOpen)
            GestureDetector(
              onTap: _togglePanel,
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),

          // Navigation Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isPanelOpen ? 0 : -320,
            top: 0,
            bottom: 0,
            width: 320,
            child: NavigationPanel(
              onItemSelected: (index, action) {
                _togglePanel();
                action();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar 
            DashboardAppBar(
              isPanelOpen: _isPanelOpen,
              onMenuPressed: _togglePanel,
              tabController: _tabController,
            ),

            // Content Area
            Expanded(
              child: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  // Use the isLoading property
                  return provider.isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading Dashboard...'),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: const [
                            OverviewTab(),
                            AnalyticsTab(),
                            ManagementTab(),
                            ReportsTab(),
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}