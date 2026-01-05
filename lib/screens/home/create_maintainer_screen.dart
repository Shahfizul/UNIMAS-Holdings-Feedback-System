import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class CreateMaintainerScreen extends StatefulWidget {
  const CreateMaintainerScreen({super.key});

  @override
  State<CreateMaintainerScreen> createState() => _CreateMaintainerScreenState();
}

class _CreateMaintainerScreenState extends State<CreateMaintainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  // State Variables
  String email = '';
  String password = '';
  String fullName = '';
  String contactNumber = '';
  String specialization = 'General';
  bool _obscurePassword = true; // For password visibility toggle
  bool _isLoading = false;

  final List<String> specializations = [
    'General', 'Plumber', 'Electrician', 'Carpenter', 'IT/Network', 'Cleaner', 'Civil Works'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF003366), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Register Staff",
          style: TextStyle(color: Color(0xFF003366), fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  const Text(
                    "Create New Profile",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Color(0xFF003366)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "This account will be auto-approved and ready for job assignment immediately.",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 25),

                  // --- FORM CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader("Personal Information"),
                        const SizedBox(height: 15),
                        
                        // Full Name
                        TextFormField(
                          decoration: _inputDecoration("Full Name", Icons.person_outline),
                          onChanged: (val) => fullName = val,
                          validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 15),

                        // Contact Number
                        TextFormField(
                          decoration: _inputDecoration("Contact Number", Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          onChanged: (val) => contactNumber = val,
                          validator: (val) => val == null || val.isEmpty ? 'Contact is required' : null,
                        ),
                        const SizedBox(height: 15),

                        // Specialization Dropdown
                        DropdownButtonFormField<String>(
                          value: specialization,
                          decoration: _inputDecoration("Specialization", Icons.work_outline),
                          items: specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => specialization = val.toString()),
                        ),

                        const SizedBox(height: 30),
                        _sectionHeader("Account Credentials"),
                        const SizedBox(height: 15),

                        // Email
                        TextFormField(
                          decoration: _inputDecoration("Email Address", Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (val) => email = val,
                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 15),

                        // Password with Toggle
                        TextFormField(
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Default Password",
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF003366)),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onChanged: (val) => password = val,
                          validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ chars' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SUBMIT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        "Create Account", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  // --- HELPER METHODS ---

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.bold, 
        color: Colors.grey, 
        letterSpacing: 1.0
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF003366)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Removes default border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      String? error = await _auth.createMaintainerAccount(
        email: email,
        password: password,
        fullName: fullName,
        contactNumber: contactNumber,
        specialization: specialization,
      );

      setState(() => _isLoading = false);

      if (error == null) {
        if (mounted) {
          Navigator.pop(context); // Close screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Staff Registered Successfully!"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $error"), 
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      }
    }
  }
}