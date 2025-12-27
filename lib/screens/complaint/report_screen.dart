import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path; // Helper for file names
import '../../models/user_model.dart';
import '../../services/complaint_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Fields
  String title = '';
  String description = '';
  String category = 'General';
  final List<String> categories = ['General', 'Plumbing', 'Electrical', 'Civil', 'Security'];

  // Image Logic
  File? _imageFile; // Stores the photo on the phone temporarily
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; // To show loading spinner

  // Function to Pick Image
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to Upload Image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      // Create a unique filename (e.g., 'complaints/12345_image.jpg')
      String fileName = path.basename(_imageFile!.path);
      Reference storageRef = FirebaseStorage.instance.ref().child('complaints/$fileName');

      // Upload
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;

      // Get the Download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Report an Issue")),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator()) // Show loading while uploading
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView( // Added scrolling for small screens
                child: Column(
                  children: [
                    // --- IMAGE PREVIEW AREA ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _imageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                  Text("Tap to add photo"),
                                ],
                              )
                            : Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- FORM FIELDS ---
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (val) => title = val,
                      validator: (val) => val!.isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      onChanged: (val) => description = val,
                      validator: (val) => val!.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField(
                      value: category,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => category = val.toString()),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 20),

                    // --- SUBMIT BUTTON ---
                    ElevatedButton(
                      child: const Text('Submit Report'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isUploading = true); // Start Loading

                          // 1. Upload Image First
                          String? imageUrl = await _uploadImage();

                          // 2. Submit Data
                          await ComplaintService().submitComplaint(
                            uid: user!.uid,
                            email: user.email,
                            title: title,
                            description: description,
                            category: category,
                            imageUrl: imageUrl, // Pass the URL here
                          );

                          setState(() => _isUploading = false); // Stop Loading
                          
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report & Photo Submitted!'))
                            );
                          }
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
    );
  }
}