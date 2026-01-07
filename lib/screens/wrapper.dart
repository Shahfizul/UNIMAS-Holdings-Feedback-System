import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'home/user_home_screen.dart';
import 'home/admin_home_screen.dart';
import 'home/maintainer_home_screen.dart';
import 'auth/authenticate.dart';

// The Wrapper widget acts as the "Traffic Control" for the app.
// It listens to the authentication state and decides whether to show
// the Login Screen (Authenticate) or the Home Screen (Dashboard).
class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the current Auth User from the Provider (stream defined in main.dart).
    // This tells us IF a user is logged in, but not WHAT their role is (Admin/Resident).
    final user = Provider.of<UserModel?>(context);

    // 2. If user is null, they are not logged in -> Show Login Screen.
    if (user == null) {
      return const Authenticate();
    }

    // 3. If logged in, we need to check their Role (Admin/Maintainer/Resident) from Firestore.
    // The Auth user object only has UID/Email. The 'role' is stored in the database.
    // We use StreamBuilder to listen to the user's document for real-time updates.
    return StreamBuilder<UserModel>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {

        // Show a loading spinner while we fetch the user's role data...
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 4. Get the full user data (including role & approval status)
        UserModel? userData = snapshot.data;

        // 5. ROUTING LOGIC: Decide which dashboard to show based on Role.

        // Security Check: If they are a Resident but NOT approved, kick them back to Login.
        if (userData?.role == 'resident' && userData?.isApproved == false) {
          return const Authenticate();
        }
        // If Admin -> Show Admin Dashboard
        else if (userData?.role == 'admin') {
          return AdminHomeScreen();
        }
        // If Maintainer -> Show Maintainer Dashboard
        else if (userData?.role == 'maintainer') {
          return MaintainerHomeScreen();
        }
        // Default -> Show Resident Dashboard
        else {
          return UserHomeScreen();
        }
      },
    );
  }
}