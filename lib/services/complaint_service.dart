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

  // 3. GET ALL COMPLAINTS (Live Stream for Admin)
  Stream<List<ComplaintModel>> get allComplaints {
    return complaintCollection
        .orderBy('timestamp', descending: true) // Newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 4. ASSIGN MAINTAINER
  Future<void> assignMaintainer(String complaintId, String maintainerId) async {
    return await complaintCollection.doc(complaintId).update({
      'assignedTo': maintainerId,
      'status': 'In Progress', // Automatically move status forward
    });
  }

  // 5. GET JOBS ASSIGNED TO SPECIFIC MAINTAINER
  Stream<List<ComplaintModel>> getAssignedComplaints(String maintainerUid) {
    return complaintCollection
        .where('assignedTo', isEqualTo: maintainerUid) // <--- The Filter
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 6. MARK AS RESOLVED (Matches CCF Sections 2, 3, & 4)
  Future<void> resolveComplaint({
    required String complaintId,
    required String findings,        // Section 2
    required String actionTaken,     // Section 3
    required String inspectionResult // Section 4
  }) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification',
      'resolvedAt': FieldValue.serverTimestamp(),
      'findings': findings,
      'actionTaken': actionTaken,
      'inspectionResult': inspectionResult,
    });
  }

  // 7. ADMIN VERIFY (Final Approval - Section 5)
  Future<void> verifyComplaint(String complaintId) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'Resolved', // <--- NOW this is the final status
      'isVerified': true, // New Field
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  // 8. ADMIN REJECT (Re-opens the job)
  Future<void> rejectComplaint(String complaintId, String reason) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'In Progress', // Send back to Maintainer!
      'isVerified': false,
      'adminRemarks': reason, // Tell them why
    });
  }

  // 9. UNDO VERIFICATION (Fix accidental clicks)
  Future<void> undoVerification(String complaintId) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification', // Send back to "To Verify" tab
      'isVerified': false,
      'verifiedAt': FieldValue.delete(), // Remove the timestamp
    });
  }
}