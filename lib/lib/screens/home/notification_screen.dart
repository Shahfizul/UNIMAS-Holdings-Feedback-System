import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

// MODELS
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../models/notification_model.dart';

// SERVICES
import '../../services/notification_service.dart';

// SCREENS (The 3 Paths)
import '../complaint/maintainer_job_detail.dart';     // Path 1: Maintainer
import '../complaint/complaint_detail_screen.dart';   // Path 2: Admin (Existing file)
import '../complaint/resident_complaint_detail.dart'; // Path 3: Resident

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService().getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<NotificationModel> allNotifs = snapshot.data!;
          if (allNotifs.isEmpty) return _buildEmptyState();

          // Split lists
          List<NotificationModel> unread = allNotifs.where((n) => !n.isRead).toList();
          List<NotificationModel> read = allNotifs.where((n) => n.isRead).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (unread.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("New", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ),
                ...unread.map((n) => _buildNotificationCard(n, context)),
                const SizedBox(height: 20),
              ],
              if (read.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("Earlier", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
                ...read.map((n) => _buildNotificationCard(n, context)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("You're all caught up!", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, BuildContext context) {
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    if (notif.type == 'alert') {
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    } else if (notif.type == 'success') {
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        border: notif.isRead ? null : Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notif.body, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            const SizedBox(height: 8),
            Text(DateFormat('MMM d, h:mm a').format(notif.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
        onTap: () async {
          // 1. Mark as Read
          if (!notif.isRead) {
            NotificationService().markAsRead(notif.id);
          }

          // 2. Deep Linking Logic
          if (notif.complaintId != null) {
            try {
              // Get UID from Provider (This part is safe)
              final authUser = Provider.of<UserModel?>(context, listen: false);

              if (authUser != null) {
                // --- STEP A: FETCH USER PROFILE FRESH FROM DB ---
                // We do this to ensure we get the REAL role, not a stale one.
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(authUser.uid)
                    .get();
                
                String role = 'resident'; // Default
                if (userDoc.exists && userDoc.data() != null) {
                   Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;
                   // Read role safely
                   role = (userData['role'] ?? 'resident').toString().trim().toLowerCase();
                }

                print("DEBUG: Fresh Role Fetch -> '$role'");

                // --- STEP B: FETCH COMPLAINT DOC ---
                DocumentSnapshot doc = await FirebaseFirestore.instance
                    .collection('complaints')
                    .doc(notif.complaintId)
                    .get();

                if (doc.exists && doc.data() != null) {
                  ComplaintModel job = ComplaintModel.fromMap(
                    doc.data()! as Map<String, dynamic>, 
                    doc.id
                  );

                  Widget destinationScreen;

                  // --- STEP C: ROUTING LOGIC ---
                  if (role == 'admin') {
                    destinationScreen = ComplaintDetailScreen(complaint: job);
                  } 
                  else if (role == 'maintainer') { 
                    destinationScreen = MaintainerJobDetail(job: job);
                  } 
                  else {
                    destinationScreen = ResidentComplaintDetail(job: job);
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => destinationScreen),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("This complaint is no longer available.")),
                  );
                }
              }
            } catch (e) {
              print("Error navigating: $e");
            }
          }
        },
      ),
    );
  }
}