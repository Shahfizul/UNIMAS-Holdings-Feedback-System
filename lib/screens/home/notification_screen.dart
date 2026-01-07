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

// SCREENS (The 3 Paths for Deep Linking)
import '../complaint/maintainer_job_detail.dart';     // Path 1: Maintainer View
import '../complaint/complaint_detail_screen.dart';   // Path 2: Admin View
import '../complaint/resident_complaint_detail.dart'; // Path 3: Resident View

// Screen that displays a list of notifications for the current user.
// It handles real-time updates and "Deep Linking" (navigating to a specific complaint when clicked).
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the current logged-in user from the Provider
    final user = Provider.of<UserModel?>(context);

    // Safety check: Show loading if user data isn't ready
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
      // Listen to the stream of notifications for THIS specific user
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService().getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<NotificationModel> allNotifs = snapshot.data!;
          if (allNotifs.isEmpty) return _buildEmptyState();

          // Separate notifications into "New" (Unread) and "Earlier" (Read) lists
          List<NotificationModel> unread = allNotifs.where((n) => !n.isRead).toList();
          List<NotificationModel> read = allNotifs.where((n) => n.isRead).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section 1: Unread Messages
              if (unread.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("New", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ),
                ...unread.map((n) => _buildNotificationCard(n, context)),
                const SizedBox(height: 20),
              ],

              // Section 2: Read Messages
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

  // --- UI: EMPTY STATE ---
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

  // --- UI: NOTIFICATION CARD ---
  Widget _buildNotificationCard(NotificationModel notif, BuildContext context) {
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    // Customize Icon/Color based on notification type
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
        // Add a blue border if the item is unread
        border: notif.isRead ? null : Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        // Title is bold if unread
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

        // --- TAP HANDLER (DEEP LINKING LOGIC) ---
        onTap: () async {
          // 1. Mark notification as Read in Firestore
          if (!notif.isRead) {
            NotificationService().markAsRead(notif.id);
          }

          // 2. Navigate to the relevant screen if a Complaint ID is attached
          if (notif.complaintId != null) {
            try {
              // Get current UID safely
              final authUser = Provider.of<UserModel?>(context, listen: false);

              if (authUser != null) {
                // --- STEP A: FETCH FRESH USER PROFILE ---
                // We fetch the profile from Firestore again to ensure we have the correct Role (Admin/Maintainer/Resident).
                // The Provider value might be slightly stale or incomplete regarding the 'role' field.
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(authUser.uid)
                    .get();

                String role = 'resident'; // Default fallback
                if (userDoc.exists && userDoc.data() != null) {
                  Map<String, dynamic> userData = userDoc.data()! as Map<String, dynamic>;
                  role = (userData['role'] ?? 'resident').toString().trim().toLowerCase();
                }

                print("DEBUG: Fresh Role Fetch -> '$role'");

                // --- STEP B: FETCH COMPLAINT DOCUMENT ---
                // We need the full complaint data to pass it to the details screen.
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

                  // --- STEP C: ROUTE BASED ON ROLE ---
                  // Different roles see different details screens.
                  if (role == 'admin') {
                    destinationScreen = ComplaintDetailScreen(complaint: job);
                  }
                  else if (role == 'maintainer') {
                    destinationScreen = MaintainerJobDetail(job: job);
                  }
                  else {
                    destinationScreen = ResidentComplaintDetail(job: job);
                  }

                  // Navigate to the determined screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => destinationScreen),
                  );
                } else {
                  // Handle case where complaint was deleted
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