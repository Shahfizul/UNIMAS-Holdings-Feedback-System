import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// This widget acts as a container to switch between the Login and Register screens.
// It holds the state (showSignIn) to decide which screen to render.
class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  // Boolean flag: true = Show Login, false = Show Register
  bool showSignIn = true;

  // This function is passed down to the Login/Register screens.
  // When called (e.g., user clicks "Create Account"), it flips the flag
  // and rebuilds this widget to show the other screen.
  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    // Conditional rendering based on the flag
    if (showSignIn) {
      // Pass the toggle function so the Login screen can switch to Register
      return LoginScreen(toggleView: toggleView);
    } else {
      // Pass the toggle function so the Register screen can switch back to Login
      return RegisterScreen(toggleView: toggleView);
    }
  }
}