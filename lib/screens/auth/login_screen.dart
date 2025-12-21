import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function? toggleView; // Made optional for now to avoid errors
  const LoginScreen({super.key, this.toggleView});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign In"),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person_add, color: Colors.blue),
            label: const Text('Register', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            onPressed: () {
              // This switches the view
              if (widget.toggleView != null) {
                widget.toggleView!();
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Login"),
              onPressed: () async {
                await _auth.signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
              },
            ),
          ],
        ),
      ),
    );
  }
}