import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;
  final String color;
  final String priority;

  Activity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.priority,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      icon: map['icon'] ?? '',
      color: map['color'] ?? '',
      priority: map['priority'] ?? 'low',
    );
  }
}