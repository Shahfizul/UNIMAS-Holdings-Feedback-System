import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MaintainerHomeScreen extends StatelessWidget {
  const MaintainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintainer Tasks"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          )
        ],
      ),
      body: const Center(child: Text("Welcome Maintainer!")),
    );
  }
}