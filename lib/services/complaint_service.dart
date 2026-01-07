import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/complaint_model.dart';
import 'notification_service.dart';

// Service to handle all Complaint-related operations in Firestore & Storage.
class ComplaintService {
  // Reference to the 'complaints' collection in Firestore
  final CollectionReference complaintCollection =
  FirebaseFirestore.instance.collection('complaints');

  // Reference to Firebase Storage for handling media uploads
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- UPLOAD VIDEO ---
  // Uploads an MP4 video to Firebase Storage and returns the download URL.
  Future<String?> uploadVideo(File videoFile) async {
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
      Reference ref = _storage.ref().child('complaint_videos/$fileName');
      UploadTask uploadTask = ref.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading video: $e");
      return null;
    }
  }

  // --- UPLOAD IMAGE ---
  // Uploads a JPG image to Firebase Storage and returns the download URL.
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

  // 2. SUBMIT COMPLAINT
  // Creates a new complaint document in Firestore.
  // Sets status to 'Pending' and triggers a notification to Admins.
  Future<void> submitComplaint({
    required String uid,
    required String email,
    required String title,
    required String description,
    required String category,
    List<String> imageUrls = const [],
    String? videoUrl,
    required String fullName,
    required String userType,
    required String matricNo,
    required String contactNumber,
    required String building,
    required String roomNumber,
  }) async {

    // Priority is initially just a placeholder; Admin/AI sets it later
    String priority = "Analyzing...";
    DocumentReference docRef = complaintCollection.doc();

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
      videoUrl: videoUrl,
      timestamp: DateTime.now(),
      fullName: fullName,
      userType: userType,
      matricNo: matricNo,
      contactNumber: contactNumber,
      building: building,
      roomNumber: roomNumber,
      assignedTo: null,
    );

    // Write data to Firestore
    await docRef.set(complaint.toMap());

    // Notify Admins about the new submission
    await NotificationService().notifyAdmins(
      title: "New Complaint Received",
      body: "$fullName ($userType) reported: $title",
      type: 'alert',
      complaintId: docRef.id,
    );
  }

  // 3. GET ALL COMPLAINTS (ADMIN VIEW)
  // Returns a stream of all complaints ordered by newest first.
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
  // Admin assigns a job to a specific maintainer.
  // Updates status to 'In Progress' and notifies both the Maintainer and Resident.
  Future<void> assignComplaint(String complaintId, String maintainerId) async {
    await complaintCollection.doc(complaintId).update({
      'assignedTo': maintainerId,
      'status': 'In Progress',
    });

    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // Notify Maintainer
    await NotificationService().sendNotification(
      userId: maintainerId,
      title: "New Job Assigned",
      body: "You have been assigned to '$title'.",
      type: 'alert',
      complaintId: complaintId,
    );

    // Notify Resident
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Update",
      body: "Your complaint '$title' is now In Progress.",
      type: 'info',
      complaintId: complaintId,
    );
  }

  // 5. GET ASSIGNED JOBS (MAINTAINER VIEW)
  // Returns only complaints assigned to the logged-in maintainer.
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

  // 6. MARK AS RESOLVED (MAINTAINER ACTION)
  // Maintainer fills in the Digital Completion Report (DCP) fields.
  // Status changes to 'Pending Verification'. Admins and Resident are notified.
  Future<void> resolveComplaint({
    required String complaintId,
    required String findings,
    required String actionTaken,
    required String inspectionResult
  }) async {
    await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification',
      'resolvedAt': FieldValue.serverTimestamp(),
      'findings': findings,
      'actionTaken': actionTaken,
      'inspectionResult': inspectionResult,
    });

    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // Notify Resident
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Work Completed",
      body: "Maintainer finished '$title'. Pending Admin verification.",
      type: 'info',
      complaintId: complaintId,
    );

    // Notify Admins
    await NotificationService().notifyAdmins(
      title: "Verification Required",
      body: "Maintainer has resolved '$title'. Please review the DCP.",
      type: 'success',
      complaintId: complaintId,
    );
  }

  // 7. ADMIN VERIFY (FINAL APPROVAL)
  // Admin approves the maintainer's work. Status becomes 'Resolved'.
  // Case is effectively closed.
  Future<void> verifyComplaint(String complaintId) async {
    await complaintCollection.doc(complaintId).update({
      'status': 'Resolved',
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');
    String? maintainerId = doc.get('assignedTo');

    // Notify Resident
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Resolved",
      body: "Your complaint '$title' has been verified and closed.",
      type: 'success',
      complaintId: complaintId,
    );

    // Notify Maintainer
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

  // 8. ADMIN REJECT (WORK NOT SATISFACTORY)
  // Admin sends the job back to 'In Progress' for the maintainer to fix.
  Future<void> rejectComplaint(String complaintId, String reason) async {
    await complaintCollection.doc(complaintId).update({
      'status': 'In Progress',
      'isVerified': false,
      'adminRemarks': reason,
    });

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
  // Allows Admin to revert a 'Resolved' status if clicked by mistake.
  Future<void> undoVerification(String complaintId) async {
    return await complaintCollection.doc(complaintId).update({
      'status': 'Pending Verification',
      'isVerified': false,
      'verifiedAt': FieldValue.delete(),
    });
  }

  // 10. SUBMIT SERVICE RATING
  // Resident rates the service after the job is done.
  Future<void> submitRating(String complaintId, double rating, String review) async {
    await complaintCollection.doc(complaintId).update({
      'rating': rating,
      'review': review,
    });

    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String title = doc.get('title');
    String? maintainerId = doc.get('assignedTo');
    String residentName = doc.get('fullName');

    // Notify Admins
    await NotificationService().notifyAdmins(
      title: "New Feedback Received",
      body: "$residentName rated '$title': $rating Stars ⭐",
      type: 'success',
      complaintId: complaintId,
    );

    // Notify Maintainer
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

  // 11. GET USER COMPLAINTS (RESIDENT VIEW)
  // Returns only complaints created by the logged-in resident.
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

  // FR-17: MARK AS INVALID
  // Admin marks a complaint as invalid (e.g., duplicate, prank, non-issue).
  Future<void> markAsInvalid(String complaintId, String reason) async {
    await complaintCollection.doc(complaintId).update({
      'status': 'Invalid',
      'adminRemarks': reason,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    DocumentSnapshot doc = await complaintCollection.doc(complaintId).get();
    String residentId = doc.get('uid');
    String title = doc.get('title');

    // Send notification so resident knows why it was closed
    await NotificationService().sendNotification(
      userId: residentId,
      title: "Complaint Closed",
      body: "Admin marked '$title' as Invalid: $reason",
      type: 'alert',
      complaintId: complaintId,
    );
  }
}