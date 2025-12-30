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
import 'admin_stats_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        NotificationService().initNotifications(user.uid);
      }
    });
    _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    Map<String, dynamic> data = message.data;
    if (data['complaintId'] != null) {
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
        length: 5, 
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            backgroundColor: Colors.red[800], // Slightly darker red for professionalism
            elevation: 0, // Flat look, let content shadow define depth
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: NotificationBadge(userId: user.uid),
                ),

              IconButton(
                icon: const Icon(Icons.how_to_reg_outlined), 
                tooltip: "Approvals",
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserApprovalScreen())),
              ),

              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                tooltip: "Add Staff",
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateMaintainerScreen())),
              ),
              
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: "Logout",
                onPressed: () => AuthService().signOut(),
              ),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 4,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.assignment_outlined), text: "Active"),
                Tab(icon: Icon(Icons.fact_check_outlined), text: "Verify"),
                Tab(icon: Icon(Icons.history_outlined), text: "History"),
                Tab(icon: Icon(Icons.lightbulb_outline), text: "Ideas"),
                Tab(icon: Icon(Icons.bar_chart_outlined), text: "Stats"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AdminComplaintList(filterType: 'active'),
              AdminComplaintList(filterType: 'verify'),
              AdminComplaintList(filterType: 'history'),
              AdminSuggestionList(), 
              AdminStatsScreen(),
            ],
          ),
        ),
      ),
    );
  }
}