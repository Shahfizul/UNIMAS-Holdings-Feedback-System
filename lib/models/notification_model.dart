import 'package:cloud_firestore/cloud_firestore.dart';

// Model class representing a single Notification document in Firestore.
// Used to display alerts and updates to the user.
class NotificationModel {
  final String id;          // The Firestore Document ID
  final String title;       // The headline of the notification (e.g., "Complaint Resolved")
  final String body;        // The detailed message (e.g., "Your issue regarding Wi-Fi has been fixed.")
  final String type;        // 'info', 'alert', 'success' - Used to determine icon/color in UI
  final bool isRead;        // Tracks if the user has opened/seen this notification
  final DateTime timestamp; // When the notification was sent
  final String? complaintId; // <--- NEW FIELD: Used for navigation (tapping notification opens this specific complaint)

  // --- CONSTRUCTOR ---
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.timestamp,
    this.complaintId, // <--- Add to constructor
  });

  // --- FACTORY: Convert Firestore Map to Object ---
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'info', // Default to 'info' if type is missing
      isRead: map['isRead'] ?? false, // Default to unread
      // Convert Firestore Timestamp to Dart DateTime safely
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      complaintId: map['complaintId'], // <--- Read from Map
    );
  }
}