import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/suggestion_service.dart';
import '../../services/complaint_service.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String title = '';
  String description = '';
  String category = 'Facility Improvement'; 
  
  final List<String> categories = [
    'Facility Improvement', 
    'Safety & Security', 
    'IT & Wi-Fi', 
    'Cleanliness', 
    'Event Idea',
    'General Feedback'
  ];

  String _fullName = '';
  String _userType = 'Resident';
  String _matricNo = '';
  String _contactNumber = '';
  bool _isLoadingProfile = true;

  final List<File> _selectedImages = []; 
  File? _selectedVideo; 
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- UI Helper: Consistent Input Decoration ---
  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
    );
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
      backgroundColor: const Color(0xFFFAFAFA), // Background from feedback_form
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Submit Suggestion",
          style: TextStyle(
            color: Colors.teal,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF003366)),
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            child: Column(
              children: [
                if (_isLoadingProfile) const LinearProgressIndicator(),
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shadowColor: const Color.fromARGB(206, 0, 0, 0),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Improve Our Campus',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your ideas help make UNIMAS a better place for everyone.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color.fromARGB(255, 103, 103, 103)),
                          ),
                          const SizedBox(height: 25),

                          // --- Category Selection ---
                          const Text('Category:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: category,
                            items: categories.map((c) => DropdownMenuItem(
                              value: c, 
                              child: Text(c, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14))
                            )).toList(),
                            onChanged: (val) => setState(() => category = val!),
                            decoration: _inputDecoration(Icons.category_outlined),
                          ),
                          const SizedBox(height: 20),

                          // --- Title Field ---
                          const Text('Topic / Title:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextFormField(
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                            decoration: _inputDecoration(Icons.title_rounded).copyWith(hintText: 'e.g. Wi-Fi in Kolej Dahlia'),
                            onChanged: (val) => title = val,
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),

                          // --- Description Field ---
                          const Text('Detailed Suggestion:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextFormField(
                            maxLines: 5,
                              maxLength: 300,
                              minLines: 3,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Describe your idea or the issue...',
                              hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onChanged: (val) => description = val,
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 25),

                          // --- Media Attachment Section ---
                          const Text('Attachments:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                                  label: Text("Photos (${_selectedImages.length})", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                                  onPressed: _pickImages,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.videocam_outlined, size: 20),
                                  label: Text(_selectedVideo == null ? "Video" : "Added", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                                  onPressed: _pickVideo,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _selectedVideo != null ? Colors.blue.withOpacity(0.1) : null,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 35),

                          // --- Submit Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 93, 171, 235),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate() && user != null) {
                                  setState(() => _isUploading = true);

                                  List<String> imageUrls = [];
                                  for(var img in _selectedImages) {
                                    String? url = await ComplaintService().uploadImage(img);
                                    if(url != null) imageUrls.add(url);
                                  }
                                  String? videoUrl;
                                  if(_selectedVideo != null) {
                                    videoUrl = await ComplaintService().uploadVideo(_selectedVideo!);
                                  }

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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Suggestion submitted successfully!'))
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                "Submit Suggestion",
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Center(
                            child: Text(
                              'Your suggestions are vital for our continuous improvement.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color.fromARGB(255, 100, 100, 100)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}