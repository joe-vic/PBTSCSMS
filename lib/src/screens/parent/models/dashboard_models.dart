/// 🎯 PURPOSE: Data models specifically for parent dashboard
/// 📝 WHAT IT CONTAINS: Models for announcements, events, notifications
/// 🔧 HOW TO USE: Import and use these models in your dashboard

/// 📢 School announcement model
class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final AnnouncementPriority priority;
  final String? imageUrl;
  final bool isRead;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.priority,
    this.imageUrl,
    this.isRead = false,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] is DateTime ? map['date'] : DateTime.now(),
      priority: AnnouncementPriority.fromString(map['priority']),
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'priority': priority.toString(),
      'imageUrl': imageUrl,
      'isRead': isRead,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    AnnouncementPriority? priority,
    String? imageUrl,
    bool? isRead,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// 🚨 Announcement priority levels
enum AnnouncementPriority {
  low,
  medium,
  high,
  urgent;

  static AnnouncementPriority fromString(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return AnnouncementPriority.high;
      case 'urgent':
        return AnnouncementPriority.urgent;
      case 'medium':
        return AnnouncementPriority.medium;
      case 'low':
      default:
        return AnnouncementPriority.low;
    }
  }

  @override
  String toString() {
    switch (this) {
      case AnnouncementPriority.urgent:
        return 'urgent';
      case AnnouncementPriority.high:
        return 'high';
      case AnnouncementPriority.medium:
        return 'medium';
      case AnnouncementPriority.low:
        return 'low';
    }
  }
}

/// 📅 School event model
class SchoolEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? time;
  final String? location;
  final EventType type;
  final bool isAllDay;
  final List<String> participantGrades;

  const SchoolEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.time,
    this.location,
    required this.type,
    this.isAllDay = false,
    this.participantGrades = const [],
  });

  factory SchoolEvent.fromMap(Map<String, dynamic> map) {
    return SchoolEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: map['date'] is DateTime ? map['date'] : DateTime.now(),
      endDate: map['endDate'],
      time: map['time'],
      location: map['location'],
      type: EventType.fromString(map['type']),
      isAllDay: map['isAllDay'] ?? false,
      participantGrades: List<String>.from(map['participantGrades'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': startDate,
      'endDate': endDate,
      'time': time,
      'location': location,
      'type': type.toString(),
      'isAllDay': isAllDay,
      'participantGrades': participantGrades,
    };
  }

  bool get isMultiDay => endDate != null && 
      startDate.day != endDate!.day;

  Duration get duration {
    if (endDate != null) {
      return endDate!.difference(startDate);
    }
    return const Duration(hours: 1); // Default duration
  }
}

/// 📅 Event types
enum EventType {
  academic,
  extracurricular,
  holiday,
  meeting,
  assessment,
  sports,
  cultural,
  other;

  static EventType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'academic':
        return EventType.academic;
      case 'extracurricular':
        return EventType.extracurricular;
      case 'holiday':
        return EventType.holiday;
      case 'meeting':
        return EventType.meeting;
      case 'assessment':
        return EventType.assessment;
      case 'sports':
        return EventType.sports;
      case 'cultural':
        return EventType.cultural;
      default:
        return EventType.other;
    }
  }

  @override
  String toString() {
    switch (this) {
      case EventType.academic:
        return 'academic';
      case EventType.extracurricular:
        return 'extracurricular';
      case EventType.holiday:
        return 'holiday';
      case EventType.meeting:
        return 'meeting';
      case EventType.assessment:
        return 'assessment';
      case EventType.sports:
        return 'sports';
      case EventType.cultural:
        return 'cultural';
      case EventType.other:
        return 'other';
    }
  }
}

/// 🔔 Notification model
class DashboardNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  const DashboardNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.actionUrl,
    this.data,
  });

  factory DashboardNotification.fromMap(Map<String, dynamic> map) {
    return DashboardNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] is DateTime ? map['timestamp'] : DateTime.now(),
      type: NotificationType.fromString(map['type']),
      isRead: map['isRead'] ?? false,
      actionUrl: map['actionUrl'],
      data: map['data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'type': type.toString(),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'data': data,
    };
  }

  DashboardNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) {
    return DashboardNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
    );
  }
}

/// 🔔 Notification types
enum NotificationType {
  general,
  academic,
  payment,
  attendance,
  emergency,
  reminder;

  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'academic':
        return NotificationType.academic;
      case 'payment':
        return NotificationType.payment;
      case 'attendance':
        return NotificationType.attendance;
      case 'emergency':
        return NotificationType.emergency;
      case 'reminder':
        return NotificationType.reminder;
      case 'general':
      default:
        return NotificationType.general;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NotificationType.general:
        return 'general';
      case NotificationType.academic:
        return 'academic';
      case NotificationType.payment:
        return 'payment';
      case NotificationType.attendance:
        return 'attendance';
      case NotificationType.emergency:
        return 'emergency';
      case NotificationType.reminder:
        return 'reminder';
    }
  }
}

/// 📊 Dashboard summary model
class DashboardSummary {
  final int totalStudents;
  final double averageGPA;
  final double averageAttendance;
  final double totalPendingFees;
  final double totalPaidFees;
  final int upcomingEvents;
  final int unreadNotifications;
  final DateTime lastUpdated;

  const DashboardSummary({
    required this.totalStudents,
    required this.averageGPA,
    required this.averageAttendance,
    required this.totalPendingFees,
    required this.totalPaidFees,
    required this.upcomingEvents,
    required this.unreadNotifications,
    required this.lastUpdated,
  });

  factory DashboardSummary.empty() {
    return DashboardSummary(
      totalStudents: 0,
      averageGPA: 0.0,
      averageAttendance: 0.0,
      totalPendingFees: 0.0,
      totalPaidFees: 0.0,
      upcomingEvents: 0,
      unreadNotifications: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    return DashboardSummary(
      totalStudents: map['totalStudents'] ?? 0,
      averageGPA: map['averageGPA']?.toDouble() ?? 0.0,
      averageAttendance: map['averageAttendance']?.toDouble() ?? 0.0,
      totalPendingFees: map['totalPendingFees']?.toDouble() ?? 0.0,
      totalPaidFees: map['totalPaidFees']?.toDouble() ?? 0.0,
      upcomingEvents: map['upcomingEvents'] ?? 0,
      unreadNotifications: map['unreadNotifications'] ?? 0,
      lastUpdated: map['lastUpdated'] is DateTime 
          ? map['lastUpdated'] 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalStudents': totalStudents,
      'averageGPA': averageGPA,
      'averageAttendance': averageAttendance,
      'totalPendingFees': totalPendingFees,
      'totalPaidFees': totalPaidFees,
      'upcomingEvents': upcomingEvents,
      'unreadNotifications': unreadNotifications,
      'lastUpdated': lastUpdated,
    };
  }

  double get totalFees => totalPendingFees + totalPaidFees;
  
  double get paymentCompletionRate => totalFees > 0 
      ? (totalPaidFees / totalFees) * 100 
      : 0.0;

  bool get hasOutstandingItems => 
      totalPendingFees > 0 || 
      unreadNotifications > 0 ||
      averageAttendance < 85.0;
}

/// 📈 Quick stat model for dashboard metrics
class QuickStat {
  final String title;
  final String value;
  final String? subtitle;
  final String iconName;
  final String colorName;
  final double? percentage;
  final bool isGood;

  const QuickStat({
    required this.title,
    required this.value,
    this.subtitle,
    required this.iconName,
    required this.colorName,
    this.percentage,
    this.isGood = true,
  });

  factory QuickStat.fromMap(Map<String, dynamic> map) {
    return QuickStat(
      title: map['title'] ?? '',
      value: map['value'] ?? '',
      subtitle: map['subtitle'],
      iconName: map['iconName'] ?? 'info',
      colorName: map['colorName'] ?? 'primary',
      percentage: map['percentage']?.toDouble(),
      isGood: map['isGood'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      'subtitle': subtitle,
      'iconName': iconName,
      'colorName': colorName,
      'percentage': percentage,
      'isGood': isGood,
    };
  }
}