import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String uid; // Who submitted it?
  final String email; // Contact info
  final String title;
  final String description;
  final String category; // 'Plumbing', 'Electrical', etc.
  final String status; // 'Pending', 'In Progress', 'Completed'
  final String priority; // 'High', 'Medium', 'Low' (AI sets this)
  final String? imageUrl; // Optional photo
  final DateTime timestamp;

  ComplaintModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.imageUrl,
    required this.timestamp,
  });

  // Convert to Map (Saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(), // Let Server decide time
    };
  }

  // Convert from Firestore (Reading data)
  factory ComplaintModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ComplaintModel(
      id: documentId,
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'Pending',
      priority: data['priority'] ?? 'Low',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}