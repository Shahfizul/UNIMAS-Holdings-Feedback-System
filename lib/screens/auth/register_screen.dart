import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final Function toggleView;
  const RegisterScreen({super.key, required this.toggleView});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Text Field States
  String email = '';
  String password = '';
  String fullName = '';
  String idNumber = '';
  String contactNumber = '';
  String idType = 'Matric No'; // Default

  // Dropdown Options
  final List<String> idTypes = ['Matric No', 'Passport', 'NRIC'];

  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0.0,
        title: const Text('Register for UHFS'),
        actions: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.person, color: Colors.white),
            label: const Text('Sign In', style: TextStyle(color: Colors.white)),
            onPressed: () => widget.toggleView(),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),

                // --- 1. EMAIL & PASSWORD ---
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email (Siswa Mail Preferred)',
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) => setState(() => email = val),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password (6+ chars)',
                  ),
                  obscureText: true,
                  validator: (val) =>
                      val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) => setState(() => password = val),
                ),
                const SizedBox(height: 20.0),

                // --- 2. PERSONAL DETAILS (New) ---
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name (as per ID)',
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) => setState(() => fullName = val),
                ),
                const SizedBox(height: 20.0),

                // ID Type and Number Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField(
                        isExpanded: true, // <--- ADD THIS LINE
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
                        decoration: const InputDecoration(
                          labelText: 'ID Type',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ), // Optional: Make it compact
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'ID Number',
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                        onChanged: (val) => setState(() => idNumber = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val!.isEmpty ? 'Required for emergencies' : null,
                  onChanged: (val) => setState(() => contactNumber = val),
                ),
                const SizedBox(height: 20.0),

                // --- 3. SUBMIT BUTTON ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                  child: const Text('Register', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);
                      
                      // Call the updated service
                      String? errorResult = await _auth.registerWithEmailAndPassword(
                        email: email, 
                        password: password,
                        fullName: fullName,
                        idType: idType,
                        idNumber: idNumber,
                        contactNumber: contactNumber,
                      );
                      
                      if (errorResult == null) {
                        // SUCCESS! 
                        setState(() => loading = false);
                        
                        // Show Success Dialog
                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false, // User must click button
                            builder: (context) => AlertDialog(
                              title: const Text("Registration Successful"),
                              content: const Text(
                                "Your account has been created and is pending Admin approval.\n\n"
                                "Please wait for the admin to verify your details before logging in."
                              ),
                              actions: [
                                TextButton(
                                  child: const Text("OK, Go to Login"),
                                  onPressed: () {
                                    Navigator.pop(context); // Close Dialog
                                    widget.toggleView(); // Switch to Login Screen
                                  },
                                )
                              ],
                            ),
                          );
                        }
                      } else {
                        // FAILURE
                        setState(() {
                          error = errorResult;
                          loading = false;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12.0),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
