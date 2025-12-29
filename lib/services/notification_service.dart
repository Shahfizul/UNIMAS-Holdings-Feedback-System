import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- NEW IMPORT
import '../models/notification_model.dart';

class NotificationService {
  final CollectionReference notifCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users'); // <--- NEW REFERENCE

  // --- NEW: 1. INITIALIZE FCM (Ask Permission & Save Token) ---
  Future<void> initNotifications(String uid) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // A. Request Permission (Required for iOS, good practice for Android)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // B. Get the Device Token
      String? token = await messaging.getToken();
      
      // C. Save Token to User Profile
      if (token != null) {
        await userCollection.doc(uid).update({
          'fcmToken': token, 
        });
        print("FCM Token Updated: $token");
      }
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // --- EXISTING: 2. SEND NOTIFICATION (Internal Database Notification) ---
  // We keep this named "sendNotification" so your other files don't break.
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
    String? complaintId,
  }) async {
    await notifCollection.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'complaintId': complaintId,
    });
  }

  // --- EXISTING: 3. GET USER NOTIFICATIONS (Stream) ---
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

  // --- EXISTING: 4. MARK AS READ ---
  Future<void> markAsRead(String notificationId) async {
    await notifCollection.doc(notificationId).update({'isRead': true});
  }

  // --- EXISTING: 5. NOTIFY ADMINS ---
  Future<void> notifyAdmins({
    required String title, 
    required String body, 
    required String type,
    String? complaintId,
  }) async {
    try {
      // Find all users with role 'admin'
      final adminSnapshot = await userCollection
          .where('role', isEqualTo: 'admin') 
          .get();

      // Loop through and send notification to each
      for (var doc in adminSnapshot.docs) {
        await sendNotification(
          userId: doc.id,
          title: title,
          body: body,
          type: type,
          complaintId: complaintId,
        );
      }
    } catch (e) {
      print("Error notifying admins: $e");
    }
  }
}