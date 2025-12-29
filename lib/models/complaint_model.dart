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
  final List<String> imageUrls; 
  final String? videoUrl; // <--- NEW FIELD ADDED
  final DateTime timestamp;
  final String? assignedTo; // Kept your original field name
  
  // Maintainer Fields
  final String findings;         
  final String actionTaken;      
  final String inspectionResult; 
  final String? adminRemarks;

  // Rating Fields
  final double rating;
  final String review;

  // Resident Info
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
    required this.imageUrls,
    this.videoUrl, // <--- Added to Constructor
    required this.timestamp,
    this.assignedTo,
    this.findings = '', 
    this.actionTaken = '',
    this.inspectionResult = '',
    this.adminRemarks,
    
    this.rating = 0.0, 
    this.review = '',

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
      'imageUrls': imageUrls,
      'videoUrl': videoUrl, // <--- Added to Map
      'timestamp': FieldValue.serverTimestamp(),
      'assignedTo': assignedTo,
      'findings': findings,
      'actionTaken': actionTaken,
      'inspectionResult': inspectionResult,
      'adminRemarks': adminRemarks,
      
      'rating': rating,
      'review': review,

      'fullName': fullName,
      'userType': userType,
      'matricNo': matricNo,
      'contactNumber': contactNumber,
      'building': building,
      'roomNumber': roomNumber,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> data, String documentId) {
    List<String> images = [];
    if (data['imageUrls'] != null) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
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
      imageUrls: images, 
      videoUrl: data['videoUrl'], // <--- Added to Factory
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: data['assignedTo'],
      findings: data['findings'] ?? '',
      actionTaken: data['actionTaken'] ?? '',
      inspectionResult: data['inspectionResult'] ?? '',
      adminRemarks: data['adminRemarks'],
      
      rating: (data['rating'] ?? 0.0).toDouble(),
      review: data['review'] ?? '',

      fullName: data['fullName'],
      userType: data['userType'],
      matricNo: data['matricNo'],
      contactNumber: data['contactNumber'],
      building: data['building'],
      roomNumber: data['roomNumber'],
    );
  }
}