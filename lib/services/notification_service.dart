import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

// Service class handling the creation, retrieval, and management of Notifications.
// It interacts with Firestore to store notification logs and Firebase Messaging for permissions/tokens.
class NotificationService {
  final CollectionReference notifCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  // --- 1. INITIALIZE FCM (FIREBASE CLOUD MESSAGING) ---
  // Called when the app starts. It requests permission to show notifications
  // and saves the device's "Token" to the user's profile so we can send them alerts later.
  Future<void> initNotifications(String uid) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for alerts, badges, and sounds
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get the unique device token
      String? token = await messaging.getToken();
      if (token != null) {
        // Save token to Firestore User Profile
        await userCollection.doc(uid).update({
          'fcmToken': token,
        });
        print("FCM Token Updated: $token");
      }
    }
  }

  // --- 2. SEND NOTIFICATION (Updated for Flexibility) ---
  // Creates a notification document in Firestore.
  // This supports both old "Complaint" notifications and generic ones (via Payload).
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
    String? complaintId, // Keeping for backward compatibility
    Map<String, dynamic>? payload, // <--- NEW: Generic Data Container (e.g., for Suggestions)
  }) async {

    // Create the base data structure
    Map<String, dynamic> notificationData = {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      // Server timestamp ensures everyone sees the same time
      'timestamp': FieldValue.serverTimestamp(),
      'complaintId': complaintId, // Legacy field
    };

    // If we have extra data (like 'suggestionId'), merge it into the document
    if (payload != null) {
      notificationData.addAll(payload);
    }

    // Write to Firestore
    await notifCollection.add(notificationData);
  }

  // --- 3. GET USER NOTIFICATIONS ---
  // Returns a stream of notifications for a specific user, ordered by newest first.
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return notifCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- 4. MARK AS READ ---
  // Updates the 'isRead' flag to true so the UI knows to stop highlighting it.
  Future<void> markAsRead(String notificationId) async {
    await notifCollection.doc(notificationId).update({'isRead': true});
  }

  // --- 5. NOTIFY ADMINS ---
  // Helper function to send a notification to ALL Admin users.
  // Useful for new complaints, suggestions, or critical system events.
  Future<void> notifyAdmins({
    required String title,
    required String body,
    required String type,
    String? complaintId,
    Map<String, dynamic>? payload, // <--- NEW PARAMETER
  }) async {
    try {
      // 1. Fetch all users with 'role' == 'admin'
      final adminSnapshot = await userCollection
          .where('role', isEqualTo: 'admin')
          .get();

      // 2. Loop through every admin and send them the notification
      for (var doc in adminSnapshot.docs) {
        await sendNotification(
          userId: doc.id,
          title: title,
          body: body,
          type: type,
          complaintId: complaintId,
          payload: payload, // <--- Pass generic data through
        );
      }
    } catch (e) {
      print("Error notifying admins: $e");
    }
  }
}