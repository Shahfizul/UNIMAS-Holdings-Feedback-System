import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../complaint/maintainer_job_detail.dart'; // Creating this next

class MaintainerHomeScreen extends StatelessWidget {
  const MaintainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the Current Maintainer's ID
    final user = Provider.of<UserModel?>(context);

    // 2. Listen to ONLY their assigned jobs
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

class JobList extends StatelessWidget {
  final String statusFilter;
  const JobList({super.key, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final allJobs = Provider.of<List<ComplaintModel>>(context);
    
    // FILTER LOGIC UPDATED
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
              // Navigate to Detail to complete the job
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