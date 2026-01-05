import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Models & Services
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart';

// Screens
import 'admin_complaint_list.dart';
import 'admin_suggestion_list.dart';
import 'user_approval_screen.dart';
import '../../widgets/notification_badge.dart';
import 'admin_stats_screen.dart';
import 'manage_maintainers_screen.dart';
import '../home/user_profile_page.dart';

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
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    Map<String, dynamic> data = message.data;
    if (data['complaintId'] != null) {
      if (mounted) DefaultTabController.of(context).animateTo(0);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Logout",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366))),
          content: const Text("Are you sure you want to exit?",
              style: TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text("Logout",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().allComplaints,
      initialData: const [],
      child: DefaultTabController(
        // 1. CHANGED: Length is now 4 (Pending, Progress, Verify, History)
        length: 4,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildPopupMenu(context),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Color(0xFF003366),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'UNIMAS Holdings',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: NotificationBadge(userId: user.uid),
              ),
            ],
            // 2. UPDATED TABS
            bottom: const TabBar(
              isScrollable: false, // Forces 4 tabs to fit. If text is cut off, set to true.
              labelColor: Color(0xFF003366),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF003366),
              indicatorWeight: 3,
              labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
              tabs: [
                Tab(text: "Pending"), // New/Unassigned
                Tab(text: "Progress"), // Assigned
                Tab(text: "Verify"),
                Tab(text: "History"),
              ],
            ),
          ),
          // 3. UPDATED TAB VIEWS
          body: const TabBarView(
            children: [
              AdminComplaintList(filterType: 'pending'), // NEW
              AdminComplaintList(filterType: 'in_progress'), // NEW
              AdminComplaintList(filterType: 'verify'),
              AdminComplaintList(filterType: 'history'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.grid_view_rounded,
            color: Color(0xFF003366), size: 20),
      ),
      onSelected: (value) {
        if (value == 'logout') _showLogoutDialog(context);

        if (value == 'profile') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ProfilePage()));
        }
        if (value == 'staff') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ManageMaintainersScreen()));
        }
        if (value == 'residents') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UserApprovalScreen()));
        }
        if (value == 'ideas') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text("Resident Ideas", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF003366),
                  elevation: 0.5,
                ),
                body: const AdminSuggestionList(),
              ),
            ),
          );
        }
        if (value == 'stats') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StreamProvider<List<ComplaintModel>>.value(
                value: ComplaintService().allComplaints,
                initialData: const [],
                child: const AdminStatsScreen(), // Removed extra scaffold wrap since screen has one
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline, size: 20),
            title: Text('My Profile',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'staff',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.engineering_outlined,
                size: 20, color: Colors.orange),
            title: Text('Manage Staff',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ),
        ),
        const PopupMenuItem(
          value: 'residents',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.people_outline, size: 20, color: Colors.blue),
            title: Text('Approve Users',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'stats', 
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(Icons.bar_chart_rounded, size: 20, color: Colors.purple),
            title: Text('View Statistics',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ),
        ),
        const PopupMenuItem(
          value: 'ideas', 
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
            title: Text('View Suggestions',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: Colors.red, size: 20),
            title: Text('Logout',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}