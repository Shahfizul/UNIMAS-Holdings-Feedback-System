import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'home/user_home_screen.dart';
import 'home/admin_home_screen.dart';
import 'home/maintainer_home_screen.dart';
import 'auth/authenticate.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the user from the Provider (defined in main.dart)
    final user = Provider.of<UserModel?>(context);

    // 2. If not logged in, show Login
    if (user == null) {
      return const Authenticate();
    }

    // 3. If logged in, we need to check their Role from Firestore
    // We use a StreamBuilder to listen to their specific document
    return StreamBuilder<UserModel>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        
        // Show loading while fetching role...
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 4. Get the role data
        UserModel? userData = snapshot.data;
        
        // 5. Route to the correct dashboard
        if (userData?.role == 'admin') {
          return AdminHomeScreen();
        } else if (userData?.role == 'maintainer') {
          return MaintainerHomeScreen();
        } else {
          // Default to resident
          return UserHomeScreen();
        }
      },
    );
  }
}