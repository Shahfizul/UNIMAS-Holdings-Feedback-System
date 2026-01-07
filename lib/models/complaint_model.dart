import 'package:cloud_firestore/cloud_firestore.dart';

// Model class representing a Complaint document in Firestore.
// This handles converting data between the App and Firebase.
class ComplaintModel {
  // --- CORE IDENTIFIERS ---
  final String id;        // The Firestore Document ID
  final String uid;       // The User ID of the person who made the complaint
  final String email;     // User's email for contact/reference

  // --- COMPLAINT DETAILS ---
  final String title;
  final String description;
  final String category;  // e.g., 'Electrical', 'Plumbing'

  // --- STATUS & TRIAGE ---
  final String status;    // e.g., 'Pending', 'In Progress', 'Resolved', 'Invalid'
  final String priority;  // e.g., 'Low', 'Medium', 'High'

  // --- MEDIA ATTACHMENTS ---
  final List<String> imageUrls;
  final String? videoUrl; // <--- NEW FIELD ADDED (Optional video proof)

  final DateTime timestamp; // When the complaint was created
  final String? assignedTo; // UID of the Maintainer assigned to this job

  // --- MAINTAINER UPDATES ---
  // Fields filled by the maintainer during/after the job
  final String findings;
  final String actionTaken;
  final String inspectionResult;
  final String? adminRemarks;    // Notes from Admin (e.g., reason for rejection)

  // --- FEEDBACK SECTION ---
  // Filled by the Resident after the job is resolved
  final double rating;
  final String review;

  // --- RESIDENT SNAPSHOT ---
  // We store user details directly on the complaint so they remain
  // even if the user profile changes later.
  final String? fullName;
  final String? userType;
  final String? matricNo;
  final String? contactNumber;
  final String? building;
  final String? roomNumber;

  // --- CONSTRUCTOR ---
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

    // Default values for maintainer fields to avoid null errors
    this.findings = '',
    this.actionTaken = '',
    this.inspectionResult = '',
    this.adminRemarks,

    // Default values for rating
    this.rating = 0.0,
    this.review = '',

    this.fullName,
    this.userType,
    this.matricNo,
    this.contactNumber,
    this.building,
    this.roomNumber,
  });

  // --- CONVERT TO MAP (Write to Firestore) ---
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
      // Use server timestamp to ensure accurate sorting on the backend
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

  // --- CREATE FROM MAP (Read from Firestore) ---
  factory ComplaintModel.fromMap(Map<String, dynamic> data, String documentId) {
    // Logic to handle both old single-image ('imageUrl') and new multi-image ('imageUrls') formats
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
      // Convert Firestore Timestamp to Dart DateTime
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: data['assignedTo'],

      // Safety checks: use empty string if field is missing
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