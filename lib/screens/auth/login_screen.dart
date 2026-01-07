import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter/gestures.dart';

class LoginScreen extends StatefulWidget {
  // Callback function to switch between Login and Register views
  final Function? toggleView; // Made optional for now to avoid errors
  const LoginScreen({super.key, this.toggleView});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Instance of AuthService to handle sign-in logic
  final AuthService _auth = AuthService();

  // Controllers to retrieve text input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variable to manage password visibility toggling
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // --- POST-FRAME CALLBACKS (MESSAGE HANDLING) ---
    // These blocks run immediately after the widget finishes building.
    // They check for global messages set by AuthService (e.g., from Registration or Errors).

    // 1. Check for Pending Approval Error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService.pendingErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.pendingErrorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // CLEAR the message so it doesn't show again on every rebuild
        AuthService.pendingErrorMessage = null;
      }
    });

    // 2. Check for Registration Success Message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService.registrationSuccessMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.registrationSuccessMessage!),
            backgroundColor: Colors.green, // Green for success
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
        // Clear the message
        AuthService.registrationSuccessMessage = null;
      }
    });

    // --- UI STRUCTURE ---
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 250), // Off-white background
      body: SingleChildScrollView(
        // Scroll view prevents overflow when keyboard appears
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// LOGO
            Image.asset('assets/images/UHSB_Logo.png', width: 130, height: 130),

            const SizedBox(height: 10),

            /// APP TITLE
            const Text(
              'Complaint and Feedback System',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 55, 51, 51),
              ),
            ),

            const SizedBox(height: 30),

            // --- LOGIN FORM CARD ---
            Card(
              elevation: 8,
              shadowColor: const Color.fromARGB(206, 0, 0, 0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// WELCOME TEXT
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color.fromARGB(255, 33, 33, 33),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please login to your account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// EMAIL & PASSWORD FIELDS + LOGIN BUTTON
                    /// EMAIL LABEL
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // EMAIL TEXTFIELD
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// PASSWORD LABEL
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// PASSWORD TEXTFIELD
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword, // Hides input if true
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        // Toggle Visibility Icon
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- LOGIN BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            93,
                            171,
                            235,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          // Attempt Sign In
                          String? result = await _auth.signInWithEmail(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );

                          if (result == null) {
                            // Success! Result is null on success.
                            // The StreamWrapper in main.dart will detect user change and redirect.
                          } else {
                            // Failure! Result contains the error string (e.g., "Account pending").
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- SWITCH TO SIGN UP ---
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color.fromARGB(255, 55, 51, 51),
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              // Gesture Recognizer to handle click on "Sign Up"
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (widget.toggleView != null) {
                                    // Calls the function in Authenticate.dart to swap screens
                                    widget.toggleView!();
                                  }
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}