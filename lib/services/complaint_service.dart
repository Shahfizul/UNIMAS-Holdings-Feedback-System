import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import 'notification_service.dart';

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

  // 2. SUBMIT COMPLAINT (Updated for Multiple Images)
  Future<void> submitComplaint({
    required String uid,
    required String email,
    required String title,
    required String description,
    required String category,
    List<String> imageUrls = const [], // <--- CHANGED to List
    required String fullName,
    required String userType,
    required String matricNo,
    required String contactNumber,
    required String building,
    required String roomNumber,
  }) async {
    
    String aiPriority = _analyzePriority(description, category);
    DocumentReference docRef = complaintCollection.doc();

    ComplaintModel complaint = ComplaintModel(
      id: docRef.id,
      uid: uid,
      email: email,
      title: title,
      description: description,
      category: category,
      status: 'Pending',
      priority: aiPriority,
      imageUrls: imageUrls, // <--- Pass the List
      timestamp: DateTime.now(),
      fullName: fullName,
      userType: userType,
      matricNo: matricNo,
      contactNumber: contactNumber,
      building: building,
      roomNumber: roomNumber,
    );

    await docRef.set(complaint.toMap());

    // --- NOTIFY ADMINS ---
    await NotificationService().notifyAdmins(
      title: "New Complaint Received",
      body: "$fullName ($userType) reported: $title",
      type: 'alert',
      complaintId: docRef.id,
    );
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
  Future<void> assignComplaint(String complaintId, String maintainerId) async {
    // A. Update Database
    await complaintCollection.doc(complaintId).update({
      'assignedTo': maintainerId,
      'status': 'In Progress',
    });

    // B. Fetch Complaint Data (Needed to find WHO the resident is)
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // C. NOTIFY MAINTAINER (Existing logic)
    await NotificationService().sendNotification(
      userId: maintainerId,
      title: "New Job Assigned",
      body: "You have been assigned to '$title'.",
      type: 'alert',
      complaintId: complaintId, // <--- AND HERE
    );

    // D. NOTIFY RESIDENT
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Update",
      body: "Your complaint '$title' is now In Progress.",
      type: 'info',
      complaintId: complaintId, // <--- PASS THE ID HERE
    );
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

  // 6. MARK AS RESOLVED
  Future<void> resolveComplaint({
    required String complaintId,
    required String findings,        
    required String actionTaken,     
    required String inspectionResult 
  }) async {
    // A. Update Database
    await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification',
      'resolvedAt': FieldValue.serverTimestamp(),
      'findings': findings,
      'actionTaken': actionTaken,
      'inspectionResult': inspectionResult,
    });

    // B. Fetch Data (Need Resident ID and Title)
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // C. Notify Resident (Existing)
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Work Completed",
      body: "Maintainer finished '$title'. Pending Admin verification.",
      type: 'info',
      complaintId: complaintId, // <--- PASS ID
    );

    // D. NOTIFY ADMINS (--- NEW ADDITION ---)
    await NotificationService().notifyAdmins(
      title: "Verification Required",
      body: "Maintainer has resolved '$title'. Please review the DCP.",
      type: 'success',
      complaintId: complaintId,
    );
  }

  // 7. ADMIN VERIFY (Final Approval - Section 5)
  Future<void> verifyComplaint(String complaintId) async {
    // A. Update Status in Database
    await complaintCollection.doc(complaintId).update({
      'status': 'Resolved', 
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    // B. Fetch the complaint details
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');
    String? maintainerId = doc.get('assignedTo'); // <--- Get Maintainer ID

    // C. Notify Resident (Existing)
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Resolved",
      body: "Your complaint '$title' has been verified and closed.",
      type: 'success',
      complaintId: complaintId, // <--- PASS ID
    );

    // D. NOTIFY MAINTAINER (--- NEW ADDITION ---)
    if (maintainerId != null) {
      await NotificationService().sendNotification(
        userId: maintainerId,
        title: "Job Verified",
        body: "Admin has verified the work for '$title'. Case closed.",
        type: 'success',
        complaintId: complaintId,
      );
    }
  }

  // 8. ADMIN REJECT (Re-opens the job)
  Future<void> rejectComplaint(String complaintId, String reason) async {
    await complaintCollection.doc(complaintId).update({
      'status': 'In Progress',
      'isVerified': false,
      'adminRemarks': reason,
    });

    // Notify Maintainer (We need to fetch the doc to get assignedTo)
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String? maintainerId = doc.get('assignedTo');

    if (maintainerId != null) {
      await NotificationService().sendNotification(
        userId: maintainerId,
        title: "DCR Rejected",
        body: "Admin rejected your report: $reason",
        type: 'alert'
      );
    }
  }

  // 9. UNDO VERIFICATION (Fix accidental clicks)
  Future<void> undoVerification(String complaintId) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification', // Send back to "To Verify" tab
      'isVerified': false,
      'verifiedAt': FieldValue.delete(), // Remove the timestamp
    });
  }

  // 10. SUBMIT SERVICE RATING
  Future<void> submitRating(String complaintId, double rating, String review) async {
    await complaintCollection.doc(complaintId).update({
      'rating': rating,
      'review': review,
    });
  }

  // 11. GET COMPLAINTS FOR SPECIFIC RESIDENT (FR-10)
  Stream<List<ComplaintModel>> getUserComplaints(String uid) {
    return complaintCollection
        .where('uid', isEqualTo: uid) // Filter by Resident ID
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}