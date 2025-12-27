import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../complaint/complaint_detail_screen.dart'; // We will create this next

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().allComplaints,
      initialData: const [],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Colors.redAccent,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().signOut(),
            )
          ],
        ),
        body: const ComplaintList(),
      ),
    );
  }
}

class ComplaintList extends StatelessWidget {
  const ComplaintList({super.key});

  @override
  Widget build(BuildContext context) {
    final complaints = Provider.of<List<ComplaintModel>>(context);

    if (complaints.isEmpty) {
      return const Center(child: Text("No complaints yet. Good job!"));
    }

    return ListView.builder(
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        
        // Color Code Priority
        Color priorityColor = Colors.green;
        if (complaint.priority == 'High') priorityColor = Colors.red;
        if (complaint.priority == 'Medium') priorityColor = Colors.orange;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: priorityColor,
              child: Text(complaint.priority[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${complaint.category} • ${complaint.status}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to Details for Assignment
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComplaintDetailScreen(complaint: complaint),
                ),
              );
            },
          ),
        );
      },
    );
  }
}