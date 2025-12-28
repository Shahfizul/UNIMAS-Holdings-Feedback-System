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
  
  // --- CHANGED: Now a List of Strings ---
  final List<String> imageUrls; 
  
  final DateTime timestamp;
  final String? assignedTo;
  
  // Maintainer DCR
  final String? findings;         
  final String? actionTaken;      
  final String? inspectionResult; 
  final String? adminRemarks;

  // CCF Section 1 Fields
  final String? fullName;
  final String? userType; 
  final String? matricNo;
  final String? contactNumber;
  final String? building;
  final String? roomNumber;

  ComplaintModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.imageUrls, // Updated Constructor
    required this.timestamp,
    this.assignedTo,
    this.findings,
    this.actionTaken,
    this.inspectionResult,
    this.adminRemarks,
    this.fullName,
    this.userType,
    this.matricNo,
    this.contactNumber,
    this.building,
    this.roomNumber,
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
      'imageUrls': imageUrls, // Save as List
      'timestamp': FieldValue.serverTimestamp(),
      'assignedTo': assignedTo,
      'findings': findings,
      'actionTaken': actionTaken,
      'inspectionResult': inspectionResult,
      'adminRemarks': adminRemarks,
      'fullName': fullName,
      'userType': userType,
      'matricNo': matricNo,
      'contactNumber': contactNumber,
      'building': building,
      'roomNumber': roomNumber,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> data, String documentId) {
    // --- SAFE MIGRATION LOGIC ---
    // This prevents crashes if the database still has old "imageUrl" fields.
    List<String> images = [];
    
    if (data['imageUrls'] != null) {
      // If it's the new format (List), use it
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      // If it's the old format (String), wrap it in a List
      images = [data['imageUrl']];
    }

    return ComplaintModel(
      id: documentId,
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'Pending',
      priority: data['priority'] ?? 'Low',
      imageUrls: images, // Use our safe list
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: data['assignedTo'],
      findings: data['findings'],
      actionTaken: data['actionTaken'],
      inspectionResult: data['inspectionResult'],
      adminRemarks: data['adminRemarks'],
      fullName: data['fullName'],
      userType: data['userType'],
      matricNo: data['matricNo'],
      contactNumber: data['contactNumber'],
      building: data['building'],
      roomNumber: data['roomNumber'],
    );
  }
}