import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- 1. Add this import
import '../../models/user_model.dart';   // <--- 2. Add this import
import '../../services/auth_service.dart';
import '../complaint/report_screen.dart';
import '../../widgets/notification_badge.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    final user = Provider.of<UserModel?>(context); // <--- 3. Get current user

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Dashboard"),
        backgroundColor: Colors.blue[900],
        actions: [
          
          // --- REPLACED SECTION START ---
          if (user != null) 
             NotificationBadge(userId: user.uid), // <--- The new live badge
          // --- REPLACED SECTION END ---

          const SizedBox(width: 10), // Add a little spacing

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome Resident!"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Report New Issue"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}