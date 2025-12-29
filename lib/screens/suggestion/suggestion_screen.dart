import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/suggestion_service.dart'; // <--- Use New Service
import '../../services/complaint_service.dart'; // Keep for uploadImage/Video helper

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String title = '';
  String description = '';
  String category = 'Facility Improvement'; // Default
  
  // Smart Categories
  final List<String> categories = [
    'Facility Improvement', 
    'Safety & Security', 
    'IT & Wi-Fi', 
    'Cleanliness', 
    'Event Idea',
    'General Feedback'
  ];

  // User Data
  String _fullName = '';
  String _userType = 'Resident';
  String _matricNo = '';
  String _contactNumber = '';
  bool _isLoadingProfile = true;

  // Media
  final List<File> _selectedImages = []; 
  File? _selectedVideo; 
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _fullName = data['fullName'] ?? 'Anonymous';
            _contactNumber = data['contactNumber'] ?? '';
            _matricNo = data['idNumber'] ?? ''; 
            String type = data['idType'] ?? '';
            if (type == 'Matric No') _userType = 'Student';
            else if (type == 'Staff ID') _userType = 'Staff';
            else _userType = 'Resident';
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(); 
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles.map((x) => File(x.path))));
    }
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
    if (pickedFile != null) {
      setState(() => _selectedVideo = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Suggestion"), backgroundColor: Colors.teal),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingProfile) const LinearProgressIndicator(),
                    
                    const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    DropdownButtonFormField(
                      value: category,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => category = val.toString()),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Topic / Title', border: OutlineInputBorder()),
                      onChanged: (val) => title = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description / Improvement Idea', border: OutlineInputBorder()),
                      maxLines: 5,
                      onChanged: (val) => description = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo),
                            label: Text("Photos (${_selectedImages.length})"),
                            onPressed: _pickImages,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.videocam),
                            label: Text(_selectedVideo == null ? "Video" : "Video Added"),
                            style: _selectedVideo != null ? OutlinedButton.styleFrom(backgroundColor: Colors.teal[50]) : null,
                            onPressed: _pickVideo,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text("SEND SUGGESTION", style: TextStyle(fontSize: 18, color: Colors.white)),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && user != null) {
                            setState(() => _isUploading = true);

                            // We can reuse ComplaintService for uploading media (Dry Principle)
                            List<String> imageUrls = [];
                            for(var img in _selectedImages) {
                              String? url = await ComplaintService().uploadImage(img);
                              if(url != null) imageUrls.add(url);
                            }
                            String? videoUrl;
                            if(_selectedVideo != null) {
                              videoUrl = await ComplaintService().uploadVideo(_selectedVideo!);
                            }

                            // Submit to SuggestionService
                            await SuggestionService().submitSuggestion(
                              uid: user.uid,
                              title: title,
                              description: description,
                              category: category,
                              imageUrls: imageUrls,
                              videoUrl: videoUrl,
                              fullName: _fullName,
                              userType: _userType,
                              matricNo: _matricNo,
                              contactNumber: _contactNumber,
                            );

                            setState(() => _isUploading = false);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion Sent!')));
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}