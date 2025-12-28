import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../complaint/complaint_detail_screen.dart';

class AdminComplaintList extends StatelessWidget {
  final String filterType; // 'active', 'verify', or 'history'

  const AdminComplaintList({super.key, required this.filterType});

  @override
  Widget build(BuildContext context) {
    // 1. Get ALL complaints from the stream
    final complaints = Provider.of<List<ComplaintModel>>(context);

    // 2. Filter them based on the tab
    List<ComplaintModel> filteredList = [];

    if (filterType == 'active') {
      // Show NEW or IN PROGRESS
      filteredList = complaints.where((c) => 
        c.status == 'Pending' || c.status == 'In Progress'
      ).toList();
    } else if (filterType == 'verify') {
      // Show ONLY those waiting for Admin
      filteredList = complaints.where((c) => 
        c.status == 'Pending Verification'
      ).toList();
    } else if (filterType == 'history') {
      // Show CLOSED jobs
      filteredList = complaints.where((c) => 
        c.status == 'Resolved'
      ).toList();
    }

    // 3. Handle Empty State
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text("No complaints here.", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 4. Build the List
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final complaint = filteredList[index];
        
        // Priority Color Logic
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
            subtitle: Text(
              "${complaint.category} • ${complaint.status}",
              style: TextStyle(
                color: complaint.status == 'Pending Verification' ? Colors.orange[800] : Colors.grey[700],
                fontWeight: complaint.status == 'Pending Verification' ? FontWeight.bold : FontWeight.normal
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
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