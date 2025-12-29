import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  final CollectionReference notifCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  // --- 1. INITIALIZE FCM (No changes here) ---
  Future<void> initNotifications(String uid) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      String? token = await messaging.getToken();
      if (token != null) {
        await userCollection.doc(uid).update({
          'fcmToken': token, 
        });
        print("FCM Token Updated: $token");
      }
    }
  }

  // --- 2. SEND NOTIFICATION (Updated for Flexibility) ---
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
    String? complaintId, // Keeping for backward compatibility
    Map<String, dynamic>? payload, // <--- NEW: Generic Data Container
  }) async {
    
    // Create the base data
    Map<String, dynamic> notificationData = {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'complaintId': complaintId, // Legacy field
    };

    // If we have a payload (like suggestionId), merge it or add it
    if (payload != null) {
      notificationData.addAll(payload);
    }

    await notifCollection.add(notificationData);
  }

  // --- 3. GET USER NOTIFICATIONS (No changes) ---
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

  // --- 4. MARK AS READ (No changes) ---
  Future<void> markAsRead(String notificationId) async {
    await notifCollection.doc(notificationId).update({'isRead': true});
  }

  // --- 5. NOTIFY ADMINS (Updated to accept Payload) ---
  Future<void> notifyAdmins({
    required String title, 
    required String body, 
    required String type,
    String? complaintId,
    Map<String, dynamic>? payload, // <--- NEW PARAMETER
  }) async {
    try {
      final adminSnapshot = await userCollection
          .where('role', isEqualTo: 'admin') 
          .get();

      for (var doc in adminSnapshot.docs) {
        await sendNotification(
          userId: doc.id,
          title: title,
          body: body,
          type: type,
          complaintId: complaintId,
          payload: payload, // <--- Pass it through
        );
      }
    } catch (e) {
      print("Error notifying admins: $e");
    }
  }
}