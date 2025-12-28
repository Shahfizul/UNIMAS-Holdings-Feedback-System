import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import 'admin_complaint_list.dart'; // Import the new file

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().allComplaints,
      initialData: const [],
      child: DefaultTabController(
        length: 3, // We now have 3 tabs
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
            bottom: const TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.assignment), text: "Active"),
                Tab(icon: Icon(Icons.verified_user), text: "To Verify"),
                Tab(icon: Icon(Icons.history), text: "History"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              // Tab 1: Active (Pending + In Progress)
              AdminComplaintList(filterType: 'active'),
              
              // Tab 2: To Verify (Pending Verification)
              AdminComplaintList(filterType: 'verify'),
              
              // Tab 3: History (Resolved)
              AdminComplaintList(filterType: 'history'),
            ],
          ),
        ),
      ),
    );
  }
}