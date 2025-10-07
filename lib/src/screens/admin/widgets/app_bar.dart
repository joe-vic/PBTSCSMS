import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/config/theme.dart';
import 'package:school_management_system/src/providers/dashboard_provider.dart';

class DashboardAppBar extends StatelessWidget {
  final bool isPanelOpen;
  final VoidCallback onMenuPressed;
  final TabController tabController;

  const DashboardAppBar({
    super.key,
    required this.isPanelOpen,
    required this.onMenuPressed,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    DashboardProvider? provider;
    try {
      provider = Provider.of<DashboardProvider>(context, listen: true);
    } catch (e) {
      provider = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section with Gradient Accent
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SMSTheme.primaryColor.withOpacity(0.05),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Animated Menu Button
                  _buildAnimatedMenuButton(),
                  const SizedBox(width: 16),
                  
                  // Logo and Title with Subtitle
                  Expanded(child: _buildBrandingSection()),
                  
                  // Action Buttons Row
                  _buildActionButtons(context, provider),
                ],
              ),
            ),
            
            // Enhanced Tab Bar
            _buildEnhancedTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMenuButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.primaryColor,
            SMSTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMenuPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isPanelOpen ? Icons.close_rounded : Icons.menu_rounded,
                key: ValueKey(isPanelOpen),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Row(
      children: [
        // Logo with gradient background
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SMSTheme.primaryColor.withOpacity(0.1),
                SMSTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.school_rounded,
            color: SMSTheme.primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        
        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PBTS Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SMSTheme.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SMSTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SMSTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DashboardProvider? provider) {
    final isRefreshing = provider?.isRefreshing ?? false;
    final pendingCount = provider?.metrics.pendingEnrollments ?? 0;

    return Row(
      children: [
        // Refresh Button
        _buildActionButton(
          icon: isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(SMSTheme.primaryColor),
                  ),
                )
              : Icon(Icons.refresh_rounded, size: 22),
          onPressed: isRefreshing ? null : () => provider?.fetchDashboardData(),
          tooltip: 'Refresh',
        ),
        
        const SizedBox(width: 8),
        
        // Notifications with Badge
        _buildNotificationButton(pendingCount),
        
        const SizedBox(width: 8),
        
        // User Profile Button
        _buildProfileButton(),
      ],
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SMSTheme.neutralGray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(int pendingCount) {
    return Tooltip(
      message: 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SMSTheme.neutralGray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: SMSTheme.textPrimaryLight,
                ),
              ),
            ),
          ),
          if (pendingCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  pendingCount > 99 ? '99+' : pendingCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return Tooltip(
      message: 'Profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SMSTheme.primaryColor.withOpacity(0.1),
                  SMSTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: SMSTheme.primaryColor,
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SMSTheme.neutralGray100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SMSTheme.primaryColor,
              SMSTheme.primaryColor.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: SMSTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: SMSTheme.neutralGray600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: [
          _buildTab(Icons.dashboard_rounded, 'Overview'),
          _buildTab(Icons.analytics_rounded, 'Analytics'),
          _buildTab(Icons.settings_rounded, 'Management'),
          _buildTab(Icons.assessment_rounded, 'Reports'),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}