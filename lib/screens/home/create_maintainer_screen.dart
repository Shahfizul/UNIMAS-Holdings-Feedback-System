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

  String email = '';
  String password = '';
  String fullName = '';
  String contactNumber = '';
  String specialization = 'General';
  
  final List<String> specializations = ['General', 'Plumber', 'Electrician', 'Carpenter', 'IT/Network', 'Cleaner'];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register New Staff")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text("Create Maintainer Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text("This user will be Auto-Approved.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      onChanged: (val) => fullName = val,
                      // FIX: Handle null safety
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                      onChanged: (val) => email = val,
                      // FIX: Handle null safety
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Default Password', border: OutlineInputBorder()),
                      obscureText: true,
                      onChanged: (val) => password = val,
                      // FIX: Handle null safety
                      validator: (val) => val == null || val.length < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => contactNumber = val,
                      // FIX: Handle null safety
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField(
                      value: specialization,
                      items: specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => specialization = val.toString()),
                      decoration: const InputDecoration(labelText: 'Specialization', border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text("Create Account", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.all(15)),
                        onPressed: () async {
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
                                  const SnackBar(content: Text("Maintainer Account Created Successfully!"))
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red)
                                );
                              }
                            }
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
    );
  }
}