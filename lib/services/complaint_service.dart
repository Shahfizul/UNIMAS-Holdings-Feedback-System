import 'dart:io'; // <--- 1. NEEDED FOR FILE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <--- 2. NEEDED FOR UPLOAD
import '../models/complaint_model.dart';
import 'notification_service.dart';

class ComplaintService {
  final CollectionReference complaintCollection =
      FirebaseFirestore.instance.collection('complaints');
      
  // 3. STORAGE INSTANCE (Required for video upload)
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- NEW: UPLOAD VIDEO METHOD ---
  Future<String?> uploadVideo(File videoFile) async {
    try {
      // Create a unique filename using timestamp
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
      
      // Create reference: complaint_videos/12345678.mp4
      Reference ref = _storage.ref().child('complaint_videos/$fileName');
      
      // Start Upload
      UploadTask uploadTask = ref.putFile(videoFile);
      
      // Wait for completion
      TaskSnapshot snapshot = await uploadTask;
      
      // Get the URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading video: $e");
      return null;
    }
  }

  // --- NEW: UPLOAD IMAGE METHOD (If you don't have it yet) ---
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child('complaint_images/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // 2. SUBMIT COMPLAINT (Updated)
  Future<void> submitComplaint({
    required String uid,
    required String email,
    required String title,
    required String description,
    required String category,
    List<String> imageUrls = const [],
    String? videoUrl, // <--- 4. NEW PARAMETER
    required String fullName,
    required String userType,
    required String matricNo,
    required String contactNumber,
    required String building,
    required String roomNumber,
  }) async {
    
    // 1. SET DEFAULT PRIORITY
    String priority = "Analyzing..."; 

    // 2. GENERATE DOCUMENT REFERENCE
    DocumentReference docRef = complaintCollection.doc();

    // 3. CREATE MODEL
    ComplaintModel complaint = ComplaintModel(
      id: docRef.id,
      uid: uid,
      email: email,
      title: title,
      description: description,
      category: category,
      status: 'Pending',
      priority: priority, 
      
      imageUrls: imageUrls,
      videoUrl: videoUrl, // <--- 5. SAVE IT HERE
      
      timestamp: DateTime.now(),
      fullName: fullName,
      userType: userType,
      matricNo: matricNo,
      contactNumber: contactNumber,
      building: building,
      roomNumber: roomNumber,
      
      // Explicitly set these to match your Model structure if needed, 
      // but your Model class handles defaults nicely.
      assignedTo: null, 
    );

    // 4. SAVE TO FIRESTORE
    await docRef.set(complaint.toMap());

    // 5. NOTIFY ADMINS
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
        .orderBy('timestamp', descending: true)
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

    // B. Fetch Complaint Data
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // C. NOTIFY MAINTAINER
    await NotificationService().sendNotification(
      userId: maintainerId,
      title: "New Job Assigned",
      body: "You have been assigned to '$title'.",
      type: 'alert',
      complaintId: complaintId,
    );

    // D. NOTIFY RESIDENT
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Update",
      body: "Your complaint '$title' is now In Progress.",
      type: 'info',
      complaintId: complaintId,
    );
  }

  // 5. GET JOBS ASSIGNED TO SPECIFIC MAINTAINER
  Stream<List<ComplaintModel>> getAssignedComplaints(String maintainerUid) {
    return complaintCollection
        .where('assignedTo', isEqualTo: maintainerUid)
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

    // B. Fetch Data
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // C. Notify Resident
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Work Completed",
      body: "Maintainer finished '$title'. Pending Admin verification.",
      type: 'info',
      complaintId: complaintId,
    );

    // D. NOTIFY ADMINS
    await NotificationService().notifyAdmins(
      title: "Verification Required",
      body: "Maintainer has resolved '$title'. Please review the DCP.",
      type: 'success',
      complaintId: complaintId,
    );
  }

  // 7. ADMIN VERIFY
  Future<void> verifyComplaint(String complaintId) async {
    // A. Update Status
    await complaintCollection.doc(complaintId).update({
      'status': 'Resolved', 
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    // B. Fetch details
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');
    String? maintainerId = doc.get('assignedTo');

    // C. Notify Resident
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Resolved",
      body: "Your complaint '$title' has been verified and closed.",
      type: 'success',
      complaintId: complaintId, 
    );

    // D. NOTIFY MAINTAINER
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

  // 8. ADMIN REJECT
  Future<void> rejectComplaint(String complaintId, String reason) async {
    await complaintCollection.doc(complaintId).update({
      'status': 'In Progress',
      'isVerified': false,
      'adminRemarks': reason,
    });

    // Notify Maintainer
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

  // 9. UNDO VERIFICATION
  Future<void> undoVerification(String complaintId) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification', 
      'isVerified': false,
      'verifiedAt': FieldValue.delete(),
    });
  }

  // 10. SUBMIT SERVICE RATING (Updated with Notifications)
  Future<void> submitRating(String complaintId, double rating, String review) async {
    // A. Update Database
    await complaintCollection.doc(complaintId).update({
      'rating': rating,
      'review': review,
    });

    // B. Fetch Data (We need to know WHO to notify)
    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String title = doc.get('title');
    String? maintainerId = doc.get('assignedTo');
    String residentName = doc.get('fullName');

    // C. NOTIFY ADMINS (General Alert)
    await NotificationService().notifyAdmins(
      title: "New Feedback Received",
      body: "$residentName rated '$title': $rating Stars ⭐",
      type: 'success',
      complaintId: complaintId,
    );

    // D. NOTIFY MAINTAINER (Personal Achievement)
    if (maintainerId != null) {
      await NotificationService().sendNotification(
        userId: maintainerId,
        title: "You got a Rating!",
        body: "Resident gave you $rating Stars for '$title'.",
        type: 'success',
        complaintId: complaintId,
      );
    }
  }

  // 11. GET COMPLAINTS FOR SPECIFIC RESIDENT
  Stream<List<ComplaintModel>> getUserComplaints(String uid) {
    return complaintCollection
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}