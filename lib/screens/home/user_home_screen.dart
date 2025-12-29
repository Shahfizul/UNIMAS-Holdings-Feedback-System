import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Models & Services
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart'; // Import Notification Service

// Screens
import '../complaint/report_screen.dart';
import '../complaint/resident_complaint_detail.dart';
import '../../widgets/notification_badge.dart';

// 1. CONVERT TO STATEFUL WIDGET
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  
  // 2. INIT STATE (Triggers once when screen loads)
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        // Initialize Notifications (Ask Permission + Save Token)
        NotificationService().initNotifications(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    final user = Provider.of<UserModel?>(context);

    // Safety check
    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<List<ComplaintModel>>(
      stream: ComplaintService().getUserComplaints(user.uid),
      builder: (context, snapshot) {
        // Handle Errors
        if (snapshot.hasError) {
          print("FIRESTORE ERROR: ${snapshot.error}");
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        List<ComplaintModel> allComplaints = snapshot.data ?? [];

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: const Text("My Dashboard"),
              backgroundColor: Colors.blue[900],
              actions: [
                NotificationBadge(userId: user.uid),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await _auth.signOut();
                  },
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: "Active Issues"),
                  Tab(text: "History Log"),
                ],
              ),
            ),
            
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: Colors.blue[900],
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Report Issue"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
            ),

            body: TabBarView(
              children: [
                ResidentComplaintList(allComplaints: allComplaints, isHistory: false),
                ResidentComplaintList(allComplaints: allComplaints, isHistory: true),
              ],
            ),
          ),
        );
      }
    );
  }
}

// --- LIST WIDGET (Kept the same as before) ---
class ResidentComplaintList extends StatelessWidget {
  final List<ComplaintModel> allComplaints;
  final bool isHistory;

  const ResidentComplaintList({
    super.key, 
    required this.allComplaints, 
    required this.isHistory
  });

  @override
  Widget build(BuildContext context) {
    List<ComplaintModel> filteredList = allComplaints.where((job) {
      if (isHistory) {
        return job.status == 'Resolved' || job.status == 'Pending Verification';
      } else {
        return job.status == 'Pending' || job.status == 'In Progress';
      }
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isHistory ? Icons.history : Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              isHistory ? "No past history." : "No active complaints.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final job = filteredList[index];
        return _buildJobCard(context, job);
      },
    );
  }

  Widget _buildJobCard(BuildContext context, ComplaintModel job) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    switch (job.status) {
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      case 'Pending Verification':
        statusColor = Colors.purple;
        statusIcon = Icons.fact_check;
        break;
      case 'Resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("${job.category} • ${job.priority} Priority"),
            const SizedBox(height: 5),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (job.status == 'Resolved' && job.rating == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Waiting for your rating ⭐",
                  style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResidentComplaintDetail(job: job),
            ),
          );
        },
      ),
    );
  }
}