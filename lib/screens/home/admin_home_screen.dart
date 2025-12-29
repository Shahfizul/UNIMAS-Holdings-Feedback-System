import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart';
import 'admin_complaint_list.dart'; 
import 'admin_suggestion_list.dart'; 
import 'create_maintainer_screen.dart';
import 'user_approval_screen.dart';
import '../../widgets/notification_badge.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {

  @override
  void initState() {
    super.initState();
    
    // 1. Init Notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        NotificationService().initNotifications(user.uid);
      }
    });

    // 2. Setup Listener
    _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // --- SAFE & SIMPLE HANDLER ---
  void _handleMessage(RemoteMessage message) {
    Map<String, dynamic> data = message.data;

    // Only handle standard complaints.
    // If it's a suggestion (complaintId is null), this block is skipped,
    // and the app just opens naturally to the dashboard. No errors.
    if (data['complaintId'] != null) {
       // Optional: Switch to Active tab if it's a complaint
       if(mounted) DefaultTabController.of(context).animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().allComplaints,
      initialData: const [],
      child: DefaultTabController(
        length: 4, 
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard"),
            backgroundColor: Colors.redAccent,
            actions: [
              if (user != null)
                NotificationBadge(userId: user.uid),

              IconButton(
                icon: const Icon(Icons.how_to_reg), 
                tooltip: "Pending Approvals",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserApprovalScreen()),
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: "Register Staff",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateMaintainerScreen()),
                  );
                },
              ),
              
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => AuthService().signOut(),
              ),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.assignment), text: "Active"),
                Tab(icon: Icon(Icons.verified_user), text: "To Verify"),
                Tab(icon: Icon(Icons.history), text: "History"),
                Tab(icon: Icon(Icons.lightbulb), text: "Ideas"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AdminComplaintList(filterType: 'active'),
              AdminComplaintList(filterType: 'verify'),
              AdminComplaintList(filterType: 'history'),
              AdminSuggestionList(), 
            ],
          ),
        ),
      ),
    );
  }
}