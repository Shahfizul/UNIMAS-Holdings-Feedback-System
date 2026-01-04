import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestionModel {
  final String id;
  final String uid;
  final String title;
  final String description;
  final String category; // e.g., Facility, IT, General
  final String status;   // 'New', 'Reviewed'
  final List<String> imageUrls;
  final String? videoUrl;
  final DateTime timestamp;
  final bool isRead; // <--- NEW FIELD

  // User Info (Auto-filled)
  final String fullName;
  final String userType;
  final String matricNo;
  final String contactNumber;

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
    this.isRead = false, // <--- Default false
    required this.fullName,
    required this.userType,
    required this.matricNo,
    required this.contactNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'fullName': fullName,
      'userType': userType,
      'matricNo': matricNo,
      'contactNumber': contactNumber,
    };
  }

  factory SuggestionModel.fromMap(Map<String, dynamic> data, String id) {
    return SuggestionModel(
      id: id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'New',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false, // <--- Load it
      fullName: data['fullName'] ?? '',
      userType: data['userType'] ?? '',
      matricNo: data['matricNo'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
    );
  }
}