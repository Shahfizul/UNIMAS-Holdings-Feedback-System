import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

// Screen for new users (Residents) to sign up.
// It captures user details and sends them to AuthService.
class RegisterScreen extends StatefulWidget {
  // Callback function to switch back to the Login Screen
  final Function toggleView;
  const RegisterScreen({super.key, required this.toggleView});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>(); // Key to validate the form

  // --- HANDLER: PROCESS REGISTRATION ---
  Future<void> _handleRegistration() async {
    setState(() => loading = true); // Show loading spinner

    // 1. Call AuthService to create user in Firebase Auth & Firestore
    String? errorResult = await _auth.registerWithEmailAndPassword(
      email: email,
      password: password,
      fullName: fullName,
      idType: idType,
      idNumber: idNumber,
      contactNumber: contactNumber,
    );

    if (mounted) {
      setState(() => loading = false); // Hide spinner

      if (errorResult == null) {
        // SUCCESS: Result is null on success.
        // The AuthService automatically signs the user out after creation (because they need approval).
        // We switch the view back to the Login Screen so they can see the success message there.
        widget.toggleView();
      } else {
        // FAILURE: Show the error message (e.g., "Email already in use")
        setState(() => error = errorResult);
      }
    }
  }

  // --- FORM STATE VARIABLES ---
  String email = '';
  String password = '';
  String fullName = '';
  String idNumber = '';
  String contactNumber = '';
  String idType = 'Matric No'; // Default dropdown value

  // Dropdown Options
  final List<String> idTypes = ['Matric No', 'Passport', 'NRIC'];

  // --- UI STATE VARIABLES ---
  String error = '';
  bool loading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      // Custom App Bar with Back Button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // Clicking back switches to Login View
          onPressed: () => widget.toggleView(),
        ),
      ),
      // If loading, show spinner. Else, show the form.
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Form(
          // CRITICAL: Added Form widget to enable validation
          key: _formKey,
          child: Column(
            children: [
              // --- LOGO ---
              Image.asset(
                'assets/images/UHSB_Logo.png',
                width: 130,
                height: 130,
              ),

              const SizedBox(height: 10),

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

              // --- REGISTRATION CARD ---
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
                      const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Please fill in all the details below to sign up.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- INPUT: EMAIL ---
                      const Text(
                        'Email (Siswa Mail Preferred)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) =>
                        val!.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) => setState(() => email = val),
                      ),

                      const SizedBox(height: 20.0),

                      // --- INPUT: PASSWORD ---
                      const Text(
                        'Password (6+ characters)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        obscureText: _obscurePassword, // Hides text
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
                        validator: (val) => val!.isEmpty
                            ? 'Enter a password 6+ chars long'
                            : null,
                        onChanged: (val) =>
                            setState(() => password = val),
                      ),

                      const SizedBox(height: 20.0),

                      // --- INPUT: FULL NAME ---
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
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
                        validator: (val) =>
                        val!.isEmpty ? 'Enter your name' : null,
                        onChanged: (val) =>
                            setState(() => fullName = val),
                      ),

                      const SizedBox(height: 20),

                      // --- INPUT: ID TYPE DROPDOWN ---
                      const Text(
                        'ID Type',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField(
                              isExpanded: true, // Prevents overflow error
                              value: idType,
                              items: idTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    overflow: TextOverflow
                                        .ellipsis, // Optional: cuts off text if screen is TINY
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => idType = val.toString()),
                              decoration: InputDecoration(
                                hintText: 'Select role',
                                prefixIcon: const Icon(
                                  Icons.people_rounded,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- INPUT: ID NUMBER ---
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'ID number',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) =>
                        val!.isEmpty ? 'Required' : null,
                        onChanged: (val) =>
                            setState(() => idNumber = val),
                      ),

                      const SizedBox(height: 20),

                      // --- INPUT: PHONE NUMBER ---
                      const Text(
                        'Contact Number',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'e.g. 012-3456789',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(Icons.phone),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) => val!.isEmpty
                            ? 'Enter your contact number'
                            : null,
                        onChanged: (val) =>
                            setState(() => contactNumber = val),
                      ),
                      const SizedBox(height: 20),

                      //  --- 3. SUBMIT BUTTON ---
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
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            // Validate all fields
                            if (_formKey.currentState!.validate()) {
                              // Show the "Warning/Info" dialog BEFORE signing up
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  title: const Text("Account Approval"),
                                  content: const Text(
                                      "By proceeding, your account will be created but will remain inactive until an Admin approves your registration."
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context), // Cancel
                                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        _handleRegistration();  // Start the actual sign up
                                      },
                                      child: const Text("Proceed to Sign Up"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),


                      const SizedBox(height: 16),

                      // --- ERROR DISPLAY ---
                      Text(
                        error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}