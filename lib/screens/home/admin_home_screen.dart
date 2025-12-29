import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart'; // <--- ADD IMPORT
import 'admin_complaint_list.dart'; 
import 'create_maintainer_screen.dart';
import 'user_approval_screen.dart';
import '../../widgets/notification_badge.dart';

// 1. CONVERT TO STATEFUL WIDGET
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {

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

    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().allComplaints,
      initialData: const [],
      child: DefaultTabController(
        length: 3, 
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard"),
            backgroundColor: Colors.redAccent,
            actions: [
              if (user != null)
                NotificationBadge(userId: user.uid),

              // User Approvals Button
              IconButton(
                icon: const Icon(Icons.how_to_reg), 
                tooltip: "Pending Approvals",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserApprovalScreen(),
                    ),
                  );
                },
              ),

              // Add Maintainer Button
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: "Register Staff",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateMaintainerScreen(),
                    ), 
                  );
                },
              ),
              
              // Logout
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => AuthService().signOut(),
              ),
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
              AdminComplaintList(filterType: 'active'),
              AdminComplaintList(filterType: 'verify'),
              AdminComplaintList(filterType: 'history'),
            ],
          ),
        ),
      ),
    );
  }
}