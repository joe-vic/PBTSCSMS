import 'package:flutter/material.dart';
// REMOVED: import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../widgets/metric_cards.dart';
import '../services/parent_data_service.dart';

/// 🎯 PURPOSE: DepEd school calendar and events tab
/// 📝 WHAT IT SHOWS: School year info, upcoming events, quarter schedule
/// 🔧 HOW TO USE: CalendarTab()
class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  // 📊 DATA VARIABLES
  final ParentDataService _dataService = ParentDataService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  /// 📥 Loads calendar data
  Future<void> _loadCalendarData() async {
    try {
      setState(() => _isLoading = true);
      
      final events = await _dataService.getEvents();
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading calendar: $e'),
            backgroundColor: SMSTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadCalendarData,
      color: SMSTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📋 HEADER
            _buildHeaderSection(),
            const SizedBox(height: 24),
            
            // 📅 SCHOOL YEAR INFO
            _buildSchoolYearInfo(),
            const SizedBox(height: 24),
            
            // 📅 UPCOMING EVENTS
            _buildUpcomingEventsSection(),
            const SizedBox(height: 24),
            
            // 📊 ACADEMIC CALENDAR OVERVIEW
            _buildAcademicCalendarOverview(),
          ],
        ),
      ),
    );
  }

  /// ⏳ Shows loading spinner
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SMSTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Calendar...',
            style: TextStyle(fontFamily: 'Poppins',
              color: SMSTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Builds header section
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DepEd School Calendar',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: SMSTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Official school calendar based on DepEd Order No. 7, s. 2024',
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            color: SMSTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// 📅 Builds school year information card
  Widget _buildSchoolYearInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'School Year 2023-2024',
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSchoolYearStat('Classes Started', 'August 29, 2023'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSchoolYearStat('Classes End', 'July 5, 2024'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSchoolYearStat('Total School Days', '200 days'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSchoolYearStat('Current Quarter', '2nd Quarter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Builds school year stat
  Widget _buildSchoolYearStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 📅 Builds upcoming events section
  Widget _buildUpcomingEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming School Events',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            Text(
              '${_events.length} events',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12,
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_events.isEmpty)
          _buildEmptyEvents()
        else
          ..._events.map((event) => _buildEventCard(event)).toList(),
      ],
    );
  }

  /// 🫙 Shows empty events state
  Widget _buildEmptyEvents() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_outlined,
              size: 48,
              color: SMSTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Upcoming Events',
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: SMSTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'School events will appear here when scheduled',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                color: SMSTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📅 Builds individual event card
  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventInfo = _getEventInfo(event['type'] as String?);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 🎨 EVENT ICON
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: eventInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                eventInfo['icon'],
                color: eventInfo['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // 📝 EVENT DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Untitled Event',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SMSTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'] ?? 'No description',
                    style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14,
                      color: SMSTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // 📅 DATE AND TIME
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: SMSTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatEventDate(event),
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            color: SMSTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // 📍 LOCATION
                  if (event['location'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: SMSTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event['location'],
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 12,
                              color: SMSTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // 🏷️ EVENT TYPE BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: eventInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: eventInfo['color'].withOpacity(0.3)),
              ),
              child: Text(
                (event['type'] ?? 'event').toString().toUpperCase(),
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: eventInfo['color'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Builds academic calendar overview
  Widget _buildAcademicCalendarOverview() {
    return InfoCard(
      title: 'Academic Calendar Highlights',
      color: Colors.teal,
      icon: Icons.calendar_month,
      child: _buildQuarterSchedule(),
    );
  }

  /// 📊 Builds quarter schedule
  Widget _buildQuarterSchedule() {
    final quarters = [
      {
        'quarter': '1st Quarter',
        'start': 'Aug 29, 2023',
        'end': 'Oct 27, 2023',
        'status': 'completed'
      },
      {
        'quarter': '2nd Quarter', 
        'start': 'Oct 30, 2023',
        'end': 'Jan 12, 2024',
        'status': 'current'
      },
      {
        'quarter': '3rd Quarter',
        'start': 'Jan 15, 2024',
        'end': 'Mar 22, 2024',
        'status': 'upcoming'
      },
      {
        'quarter': '4th Quarter',
        'start': 'Mar 25, 2024',
        'end': 'July 5, 2024',
        'status': 'upcoming'
      },
    ];

    return Column(
      children: quarters.map((quarter) {
        final statusInfo = _getQuarterStatusInfo(quarter['status'] as String);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusInfo['color'].withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                statusInfo['icon'],
                color: statusInfo['color'],
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quarter['quarter']!,
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SMSTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '${quarter['start']} - ${quarter['end']}',
                      style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12,
                        color: SMSTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quarter['status']!.toUpperCase(),
                  style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusInfo['color'],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 HELPER METHODS

  /// 🎨 Gets event type info (color and icon)
  Map<String, dynamic> _getEventInfo(String? type) {
    switch (type) {
      case 'academic':
        return {
          'color': SMSTheme.primaryColor,
          'icon': Icons.school,
        };
      case 'event':
        return {
          'color': SMSTheme.successColor,
          'icon': Icons.event,
        };
      case 'holiday':
        return {
          'color': SMSTheme.errorColor,
          'icon': Icons.beach_access,
        };
      case 'meeting':
        return {
          'color': SMSTheme.warningColor,
          'icon': Icons.meeting_room,
        };
      case 'assessment':
        return {
          'color': Colors.purple,
          'icon': Icons.assignment,
        };
      default:
        return {
          'color': SMSTheme.textSecondaryColor,
          'icon': Icons.info,
        };
    }
  }

  /// 🎨 Gets quarter status info (color and icon)
  Map<String, dynamic> _getQuarterStatusInfo(String status) {
    switch (status) {
      case 'completed':
        return {
          'color': SMSTheme.successColor,
          'icon': Icons.check_circle,
        };
      case 'current':
        return {
          'color': SMSTheme.warningColor,
          'icon': Icons.play_circle_filled,
        };
      default:
        return {
          'color': SMSTheme.textSecondaryColor,
          'icon': Icons.schedule,
        };
    }
  }

  /// 📅 Formats event date and time
  String _formatEventDate(Map<String, dynamic> event) {
    final date = event['date'] as DateTime?;
    final endDate = event['endDate'] as DateTime?;
    final time = event['time'] as String?;

    if (date == null) return 'Date not set';

    if (endDate != null) {
      return '${DateFormat('MMM dd').format(date)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
    } else {
      final dateStr = DateFormat('MMM dd, yyyy').format(date);
      if (time != null) {
        return '$dateStr • $time';
      }
      return dateStr;
    }
  }
}