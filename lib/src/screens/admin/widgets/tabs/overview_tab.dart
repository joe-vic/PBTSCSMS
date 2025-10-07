import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/config/theme.dart';
import 'package:school_management_system/src/providers/dashboard_provider.dart';
 
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final metrics = provider.metrics;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(context, isMobile),
          SizedBox(height: isMobile ? 20 : 28),
          
          // Key Metrics
          _buildMetricsSection(metrics, isMobile, isTablet),
          SizedBox(height: isMobile ? 20 : 28),
          
          // Activity & Stats Row (Side by side on tablet/desktop)
          _buildActivityAndStats(context, metrics, isMobile, isTablet),
          SizedBox(height: isMobile ? 20 : 28),
          
          // Quick Actions
          _buildQuickActionsSection(context, isMobile, isTablet),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, bool isMobile) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny_rounded;
    
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_rounded;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.primaryColor,
            SMSTheme.primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: SMSTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile 
          ? _buildWelcomeBannerMobile(greeting, greetingIcon)
          : _buildWelcomeBannerDesktop(greeting, greetingIcon),
    );
  }

  Widget _buildWelcomeBannerMobile(String greeting, IconData greetingIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(greetingIcon, color: Colors.white.withOpacity(0.9), size: 20),
            const SizedBox(width: 8),
            Text(
              greeting,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'PBTS Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'All systems operational',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBannerDesktop(String greeting, IconData greetingIcon) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(greetingIcon, color: Colors.white.withOpacity(0.9), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'PBTS Admin Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'All systems operational',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(DashboardMetrics metrics, bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
    double childAspectRatio = isMobile ? 1.2 : (isTablet ? 1.3 : 1.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Key Metrics', isMobile),
        SizedBox(height: isMobile ? 16 : 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricCard(
              title: 'Total Students',
              value: metrics.totalStudents.toString(),
              icon: Icons.school_rounded,
              gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              trend: '+12%',
              trendUp: true,
              isMobile: isMobile,
            ),
            _buildMetricCard(
              title: 'Active Teachers',
              value: metrics.totalTeachers.toString(),
              icon: Icons.people_rounded,
              gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
              trend: '+5%',
              trendUp: true,
              isMobile: isMobile,
            ),
            _buildMetricCard(
              title: 'Total Courses',
              value: metrics.totalCourses.toString(),
              icon: Icons.book_rounded,
              gradientColors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              trend: '+8%',
              trendUp: true,
              isMobile: isMobile,
            ),
            _buildMetricCard(
              title: 'Pending Items',
              value: metrics.pendingEnrollments.toString(),
              icon: Icons.pending_actions_rounded,
              gradientColors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              trend: '-3%',
              trendUp: false,
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isMobile ? 20 : 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required String trend,
    required bool trendUp,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: trendUp ? SMSTheme.successLight : SMSTheme.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: trendUp ? SMSTheme.successDark : SMSTheme.errorDark,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: trendUp ? SMSTheme.successDark : SMSTheme.errorDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: SMSTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityAndStats(BuildContext context, DashboardMetrics metrics, bool isMobile, bool isTablet) {
    if (isMobile) {
      // Stack vertically on mobile
      return Column(
        children: [
          _buildActivityOverview(metrics, isMobile),
          const SizedBox(height: 20),
          _buildQuickStats(isMobile),
        ],
      );
    } else {
      // Side by side on tablet/desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isTablet ? 1 : 2,
            child: _buildActivityOverview(metrics, isMobile),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildQuickStats(isMobile),
          ),
        ],
      );
    }
  }

  Widget _buildActivityOverview(DashboardMetrics metrics, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SMSTheme.primaryColor.withOpacity(0.05),
            SMSTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(
          color: SMSTheme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: SMSTheme.primaryColor,
                size: isMobile ? 20 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildActivityItem(
            icon: Icons.person_add_rounded,
            title: 'New enrollments',
            count: '${metrics.pendingEnrollments} pending',
            color: SMSTheme.primaryColor,
            isMobile: isMobile,
          ),
          Divider(height: isMobile ? 20 : 24),
          _buildActivityItem(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Assignments submitted',
            count: '156 today',
            color: SMSTheme.successColor,
            isMobile: isMobile,
          ),
          Divider(height: isMobile ? 20 : 24),
          _buildActivityItem(
            icon: Icons.event_rounded,
            title: 'Upcoming events',
            count: '3 this week',
            color: SMSTheme.infoColor,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          ),
          child: Icon(icon, color: color, size: isMobile ? 18 : 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 13 : 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                style: TextStyle(
                  color: SMSTheme.textSecondaryLight,
                  fontSize: isMobile ? 11 : 13,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: isMobile ? 14 : 16,
          color: SMSTheme.neutralGray400,
        ),
      ],
    );
  }

  Widget _buildQuickStats(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: SMSTheme.primaryColor,
                size: isMobile ? 20 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _buildStatRow('Attendance Rate', '92.5%', Icons.check_circle_rounded, SMSTheme.successColor, isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          _buildStatRow('Average Score', '85.2%', Icons.trending_up_rounded, Color(0xFF3B82F6), isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          _buildStatRow('Collection Rate', '94.8%', Icons.payments_rounded, SMSTheme.primaryColor, isMobile),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          ),
          child: Icon(icon, color: color, size: isMobile ? 18 : 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions', isMobile),
        SizedBox(height: isMobile ? 16 : 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.0 : 1.1,
          children: [
            _buildActionCard(
              context,
              'Manage Students',
              Icons.school_rounded,
              [Color(0xFF3B82F6), Color(0xFF2563EB)],
              () {},
              isMobile,
            ),
            _buildActionCard(
              context,
              'Manage Teachers',
              Icons.people_rounded,
              [Color(0xFF10B981), Color(0xFF059669)],
              () {},
              isMobile,
            ),
            _buildActionCard(
              context,
              'Fee Management',
              Icons.payments_rounded,
              [SMSTheme.primaryColor, SMSTheme.secondaryColor],
              () {},
              isMobile,
            ),
            _buildActionCard(
              context,
              'View Reports',
              Icons.assessment_rounded,
              [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              () {},
              isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: isMobile ? 24 : 32),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12 : 15,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}