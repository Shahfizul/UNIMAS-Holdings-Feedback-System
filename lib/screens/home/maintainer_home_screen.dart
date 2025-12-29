import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart'; // <--- ADD IMPORT
import '../complaint/maintainer_job_detail.dart'; 
import '../../widgets/notification_badge.dart';

// 1. CONVERT TO STATEFUL WIDGET
class MaintainerHomeScreen extends StatefulWidget {
  const MaintainerHomeScreen({super.key});

  @override
  State<MaintainerHomeScreen> createState() => _MaintainerHomeScreenState();
}

class _MaintainerHomeScreenState extends State<MaintainerHomeScreen> {

  // 2. INIT NOTIFICATIONS ON LOAD
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        // Ask for permission & save token
        NotificationService().initNotifications(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    // Listen to ONLY their assigned jobs
    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().getAssignedComplaints(user!.uid),
      initialData: const [],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("My Work Orders"),
            backgroundColor: Colors.orange,
            bottom: const TabBar(
              tabs: [
                Tab(text: "Active Jobs"),
                Tab(text: "History"),
              ],
            ),
            actions: [
              NotificationBadge(userId: user.uid),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => AuthService().signOut(),
              )
            ],
          ),
          body: const TabBarView(
            children: [
              JobList(statusFilter: 'In Progress'),
              JobList(statusFilter: 'Resolved'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- KEEP EXISTING JOB LIST (No Changes Needed Here) ---
class JobList extends StatelessWidget {
  final String statusFilter;
  const JobList({super.key, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final allJobs = Provider.of<List<ComplaintModel>>(context);
    
    // FILTER LOGIC
    List<ComplaintModel> filteredJobs;
    
    if (statusFilter == 'In Progress') {
      // Active Jobs
      filteredJobs = allJobs.where((job) => job.status == 'In Progress').toList();
    } else {
      // History Tab (Show both Waiting & Finished)
      filteredJobs = allJobs.where((job) => 
        job.status == 'Pending Verification' || job.status == 'Resolved'
      ).toList();
    }

    if (filteredJobs.isEmpty) {
      return Center(
        child: Text(
          statusFilter == 'In Progress' 
            ? "No active jobs. Relax!" 
            : "No completed jobs yet."
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(
              statusFilter == 'Resolved' ? Icons.check_circle : Icons.build,
              color: statusFilter == 'Resolved' ? Colors.green : Colors.orange,
            ),
            title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${job.category} • ${job.priority} Priority"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MaintainerJobDetail(job: job)),
              );
            },
          ),
        );
      },
    );
  }
}