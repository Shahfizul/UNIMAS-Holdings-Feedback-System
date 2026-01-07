import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/suggestion_service.dart';
import '../../services/complaint_service.dart';

// Screen that allows users (Residents/Students) to submit feedback or improvement ideas.
// It includes a form for details and options to attach photos or video.
class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for validating the form

  // --- FORM FIELDS ---
  String title = '';
  String description = '';
  String category = 'Facility Improvement';

  // Dropdown options for the suggestion category
  final List<String> categories = [
    'Facility Improvement',
    'Safety & Security',
    'IT & Wi-Fi',
    'Cleanliness',
    'Event Idea',
    'General Feedback'
  ];

  // --- USER DATA (Auto-filled) ---
  String _fullName = '';
  String _userType = 'Resident';
  String _matricNo = '';
  String _contactNumber = '';

  // --- UI STATE ---
  bool _isLoadingProfile = true; // Shows progress bar while fetching user info
  bool _isUploading = false;     // Shows progress bar while submitting form

  // --- MEDIA HANDLING ---
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load user profile data immediately when the screen opens
    _loadUserProfile();
  }

  // --- UI HELPER: INPUT STYLING ---
  // Returns a consistent decoration for all text form fields.
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

  // --- 1. FETCH USER PROFILE ---
  // Gets the current user's details from Firestore to attach to the suggestion.
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
            // Determine User Type based on ID Type
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

  // --- 2. PICK IMAGES ---
  // Allows selecting multiple images from the device gallery.
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() => _selectedImages.addAll(pickedFiles.map((x) => File(x.path))));
    }
  }

  // --- 3. PICK VIDEO ---
  // Allows selecting a single video (max 30 seconds) from the gallery.
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
      backgroundColor: const Color(0xFFFAFAFA), // Light background color
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
      // Show loading spinner if submitting, otherwise show form
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Top progress bar while fetching user profile
            if (_isLoadingProfile) const LinearProgressIndicator(),

            const SizedBox(height: 20),

            // --- MAIN FORM CARD ---
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
                      // Header Text
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

                      // --- CATEGORY SELECTION ---
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

                      // --- TITLE FIELD ---
                      const Text('Topic / Title:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: _inputDecoration(Icons.title_rounded).copyWith(hintText: 'e.g. Wi-Fi in Kolej Dahlia'),
                        onChanged: (val) => title = val,
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // --- DESCRIPTION FIELD ---
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

                      // --- MEDIA ATTACHMENT BUTTONS ---
                      const Text('Attachments:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Photo Button
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
                          // Video Button
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

                      // --- SUBMIT BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 93, 171, 235), // Light Blue
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate() && user != null) {
                              setState(() => _isUploading = true); // Start Loading

                              // 1. Upload Images
                              List<String> imageUrls = [];
                              for(var img in _selectedImages) {
                                String? url = await ComplaintService().uploadImage(img);
                                if(url != null) imageUrls.add(url);
                              }

                              // 2. Upload Video
                              String? videoUrl;
                              if(_selectedVideo != null) {
                                videoUrl = await ComplaintService().uploadVideo(_selectedVideo!);
                              }

                              // 3. Submit Data to Firestore
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

                              setState(() => _isUploading = false); // Stop Loading

                              // 4. Success Message & Close
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