import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final CollectionReference notifCollection = FirebaseFirestore.instance.collection('notifications');

  // 1. SEND NOTIFICATION
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'info',
    String? complaintId, // <--- NEW PARAMETER (Optional)
  }) async {
    await notifCollection.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'complaintId': complaintId, // <--- Save to Firestore
    });
  }

  // 2. GET USER NOTIFICATIONS (Stream)
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

  // 3. MARK AS READ
  Future<void> markAsRead(String notificationId) async {
    await notifCollection.doc(notificationId).update({'isRead': true});
  }

  // Add this to NotificationService class
  Future<void> notifyAdmins({
    required String title, 
    required String body, 
    required String type,
    String? complaintId,
  }) async {
    try {
      // 1. Find all users with role 'admin'
      // FIX: Use 'FirebaseFirestore.instance' instead of '_firestore'
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin') 
          .get();

      // 2. Loop through and send notification to each
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