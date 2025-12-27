import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintService {
  final CollectionReference complaintCollection =
      FirebaseFirestore.instance.collection('complaints');

  // 1. SIMULATED AI PRIORITY LOGIC
  // We scan the text for "urgent" words to set priority automatically.
  String _analyzePriority(String description, String category) {
    String descLower = description.toLowerCase();
    
    // High Priority Keywords
    if (descLower.contains('fire') || 
        descLower.contains('leak') || 
        descLower.contains('danger') ||
        descLower.contains('broken') ||
        descLower.contains('emergency')) {
      return 'High';
    }
    
    // Medium Priority
    if (category == 'Electrical' || category == 'Security') {
      return 'Medium';
    }

    // Default
    return 'Low';
  }

  // 2. SUBMIT COMPLAINT
  Future<void> submitComplaint({
    required String uid,
    required String email,
    required String title,
    required String description,
    required String category,
    String? imageUrl,
  }) async {
    
    // Auto-calculate priority before saving
    String aiPriority = _analyzePriority(description, category);

    // Create a new document ref (so we get the ID)
    DocumentReference docRef = complaintCollection.doc();

    // Create the model
    ComplaintModel complaint = ComplaintModel(
      id: docRef.id,
      uid: uid,
      email: email,
      title: title,
      description: description,
      category: category,
      status: 'Pending', // Default status
      priority: aiPriority, // AI determined this
      imageUrl: imageUrl,
      timestamp: DateTime.now(), // Placeholder, server will overwrite
    );

    // Save to Firestore
    await docRef.set(complaint.toMap());
  }
}