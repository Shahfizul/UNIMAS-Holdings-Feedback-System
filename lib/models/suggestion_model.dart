import 'package:cloud_firestore/cloud_firestore.dart';

// Model class representing a User Suggestion or Feedback.
// This stores ideas submitted by residents (e.g., new gym equipment, Wi-Fi upgrades).
class SuggestionModel {
  final String id;          // The Firestore Document ID
  final String uid;         // The User ID of the person making the suggestion

  // --- CONTENT ---
  final String title;       // Short summary of the idea
  final String description; // Detailed explanation
  final String category;    // e.g., 'Facility', 'IT', 'General' - helps Admin filter ideas

  // --- STATUS & TRACKING ---
  final String status;      // e.g., 'New', 'Reviewed' - tracks if Admin has seen it
  final DateTime timestamp; // When the suggestion was submitted
  final bool isRead;        // <--- NEW FIELD: Tracks if the Admin has opened this specific suggestion

  // --- MEDIA ---
  final List<String> imageUrls; // List of image URLs for visual reference
  final String? videoUrl;       // Optional video link

  // --- USER SNAPSHOT ---
  // We store user details directly here so we know who sent it,
  // even if their main profile is updated later.
  final String fullName;
  final String userType;    // e.g., 'Student', 'Staff'
  final String matricNo;
  final String contactNumber;

  // --- CONSTRUCTOR ---
  SuggestionModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.imageUrls,
    this.videoUrl,
    required this.timestamp,
    this.isRead = false, // <--- Default false: New suggestions start as unread
    required this.fullName,
    required this.userType,
    required this.matricNo,
    required this.contactNumber,
  });

  // --- CONVERT TO MAP (Write to Firestore) ---
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      // Use server timestamp to ensure consistent ordering across all users
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,

      // Persist user details
      'fullName': fullName,
      'userType': userType,
      'matricNo': matricNo,
      'contactNumber': contactNumber,
    };
  }

  // --- FACTORY: Create Object from Map (Read from Firestore) ---
  factory SuggestionModel.fromMap(Map<String, dynamic> data, String id) {
    return SuggestionModel(
      id: id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'New',
      // Safely convert the dynamic list from Firestore to a List<String>
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      // Convert Firestore Timestamp to Dart DateTime
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false, // <--- Load read status, default to false if missing

      fullName: data['fullName'] ?? '',
      userType: data['userType'] ?? '',
      matricNo: data['matricNo'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
    );
  }
}