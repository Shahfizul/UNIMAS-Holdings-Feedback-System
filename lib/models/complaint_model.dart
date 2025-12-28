import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String uid; 
  final String email;
  final String title;
  final String description;
  final String category;
  final String status; 
  final String priority; 
  final String? imageUrl;
  final DateTime timestamp;
  final String? assignedTo;
  
  // --- NEW: CCF Digital Completion Fields ---
  final String? findings;         // Section 2: Validation/Investigation
  final String? actionTaken;      // Section 3: Action Plan/Rectification
  final String? inspectionResult; // Section 4: Work Inspection/Status
  final String? adminRemarks; // <--- NEW: Stores the rejection reason

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
    this.assignedTo,
    // --- NEW ---
    this.findings,
    this.actionTaken,
    this.inspectionResult,
    this.adminRemarks, // <--- Add to constructor
  });

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
      'timestamp': FieldValue.serverTimestamp(),
      'assignedTo': assignedTo,
      // --- NEW ---
      'findings': findings,
      'actionTaken': actionTaken,
      'inspectionResult': inspectionResult,
      'adminRemarks': adminRemarks,
    };
  }

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
      assignedTo: data['assignedTo'],
      // --- NEW ---
      findings: data['findings'],
      actionTaken: data['actionTaken'],
      inspectionResult: data['inspectionResult'],
      adminRemarks: data['adminRemarks'], // <--- Read from Firestore
    );
  }
}