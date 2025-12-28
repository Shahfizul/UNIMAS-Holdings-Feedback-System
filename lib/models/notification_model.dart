import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'info', 'alert', 'success'
  final bool isRead;
  final DateTime timestamp;
  final String? complaintId; // <--- NEW FIELD

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.timestamp,
    this.complaintId, // <--- Add to constructor
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info',
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      complaintId: map['complaintId'], // <--- Read from Map
    );
  }
}