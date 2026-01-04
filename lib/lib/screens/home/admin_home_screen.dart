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
import 'user_approval_screen.dart';
import '../../widgets/notification_badge.dart';
import 'admin_stats_screen.dart';
import 'manage_maintainers_screen.dart'; // <--- NEW IMPORT
import '../home/user_profile_page.dart'; // Reusing profile page

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

  // --- LOGOUT DIALOG ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Logout",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          content: const Text(
            "Are you sure you want to exit the system?",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 45),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  } else if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_outline, size: 20),
                      title: Text('My Profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout, color: Colors.red, size: 20),
                      title: Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                child: Center(
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ADMIN DASHBOARD',
                  style: TextStyle(
                    color: Colors.yellow.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Staff Work Portal'.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: NotificationBadge(userId: user!.uid),
              ),
            ],
            bottom: const TabBar(
              labelColor: Color(0xFF003366),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF003366),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12),
              isScrollable: true,
              tabs: [
                Tab(text: "Active"),
                Tab(text: "Verify"),
                Tab(text: "History"),
                Tab(text: "Ideas"),
                Tab(text: "Stats"),
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