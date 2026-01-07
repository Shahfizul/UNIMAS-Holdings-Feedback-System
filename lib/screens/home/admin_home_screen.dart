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

// The main dashboard for Admin users.
// Provides an overview of all complaints categorized by status and access to management tools.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize Notification Service when screen loads.
    // This requests permission and saves the FCM token so the Admin can receive alerts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        NotificationService().initNotifications(user.uid);
      }
    });

    // Setup listener for handling notification clicks (Deep Linking)
    _setupInteractedMessage();
  }

  // --- NOTIFICATION HANDLING ---
  // Checks if the app was opened via a notification click.
  Future<void> _setupInteractedMessage() async {
    // 1. App was completely closed (Terminated state)
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 2. App was in background but running
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Logic to navigate when a notification is clicked
  void _handleMessage(RemoteMessage message) {
    Map<String, dynamic> data = message.data;
    // If the notification relates to a complaint, switch to the first tab ('Pending')
    // or navigate specifically if needed (currently defaults to Tab 0)
    if (data['complaintId'] != null) {
      if (mounted) DefaultTabController.of(context).animateTo(0);
    }
  }

  // --- LOGOUT DIALOG ---
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

    // Safety check: Show loader if user data isn't ready
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // StreamProvider creates a live stream of ALL complaints in the system.
    // This data is passed down to the child widgets (AdminComplaintList).
    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().allComplaints,
      initialData: const [],
      child: DefaultTabController(
        // 1. TAB CONFIGURATION: 4 Tabs (Pending, Progress, Verify, History)
        length: 4,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            // Custom Grid Menu Icon on the left
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
              // Notification Bell (Top Right)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: NotificationBadge(userId: user.uid),
              ),
            ],
            // 2. TAB BAR UI
            bottom: const TabBar(
              isScrollable: false, // Forces tabs to fill width equally
              labelColor: Color(0xFF003366),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF003366),
              indicatorWeight: 3,
              labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
              tabs: [
                Tab(text: "Pending"),  // New/Unassigned Jobs
                Tab(text: "Progress"), // Jobs assigned to Staff
                Tab(text: "Verify"),   // Jobs completed by Staff, awaiting approval
                Tab(text: "History"),  // Closed or Invalid jobs
              ],
            ),
          ),
          // 3. TAB CONTENT VIEWS
          // Reuses 'AdminComplaintList' but passes a different filterType
          body: const TabBarView(
            children: [
              AdminComplaintList(filterType: 'pending'),
              AdminComplaintList(filterType: 'in_progress'),
              AdminComplaintList(filterType: 'verify'),
              AdminComplaintList(filterType: 'history'),
            ],
          ),
        ),
      ),
    );
  }

  // --- MENU DRAWER BUTTON ---
  // Builds the popup menu for accessing other admin features.
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      // The trigger icon (Grid View)
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
              // Wrap Stats Screen in Provider to give it access to complaint data
              builder: (context) => StreamProvider<List<ComplaintModel>>.value(
                value: ComplaintService().allComplaints,
                initialData: const [],
                child: const AdminStatsScreen(),
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