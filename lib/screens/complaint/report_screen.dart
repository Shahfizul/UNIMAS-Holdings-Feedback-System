import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../../models/user_model.dart';
import '../../services/complaint_service.dart';

// Screen that allows Residents to submit a new complaint.
// It includes a form for details, auto-fills user info, and handles media uploads.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>(); // Key to validate the form before submission

  // --- FORM STATE VARIABLES ---

  // Section 1: Personal Details (Auto-filled)
  String fullName = '';
  String matricNo = '';
  String contactNumber = '';
  String userType = 'Student';
  String otherUserType = '';

  // Section 2: Premise/Location
  String building = 'Kolej Dahlia';
  String roomNumber = '';

  // Section 3: Damage Details
  String title = '';
  String description = '';
  String category = 'Furniture';
  String otherCategory = ''; // Used if 'Other' is selected

  // --- DROPDOWN DATA OPTIONS ---
  final List<String> categories = [
    'Furniture',
    'Mechanical',
    'Electrical',
    'Plumbing/Sink',
    'Waste Water',
    'Wi-Fi',
    'Other',
  ];
  final List<String> userTypes = ['Student', 'Staff', 'Tenant', 'Others'];
  final List<String> buildings = [
    'Kolej Dahlia',
    'Kolej Allamanda Premium',
    'Kolej Sebayor',
  ];

  // --- MEDIA HANDLING ---
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;

  // --- UI LOADING STATES ---
  bool _isUploading = false; // True during submission process
  // ignore: unused_field
  bool _isLoadingProfile = true; // True while fetching user data

  @override
  void initState() {
    super.initState();
    // Load user profile data immediately when screen opens
    _loadUserProfile();
  }

  // --- 1. FETCH USER PROFILE ---
  // Gets current user details from Firestore to auto-fill the form.
  Future<void> _loadUserProfile() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            fullName = data['fullName'] ?? '';
            contactNumber = data['contactNumber'] ?? '';
            matricNo = data['idNumber'] ?? '';
            // Map ID Type to User Type
            String type = data['idType'] ?? '';
            if (type == 'Matric No')
              userType = 'Student';
            else if (type == 'Staff ID')
              userType = 'Staff';
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    }
  }

  // --- 2. PICK IMAGES ---
  // Allows selecting multiple images from the gallery.
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  // --- 3. PICK VIDEO ---
  // Allows selecting one video from the gallery (max 30 seconds).
  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (pickedFile != null) {
      setState(() => _selectedVideo = File(pickedFile.path));
    }
  }

  // --- 4. UPLOAD IMAGES TO FIREBASE ---
  // Returns a list of download URLs after uploading.
  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];
    for (var imageFile in _selectedImages) {
      try {
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}";
        Reference storageRef = FirebaseStorage.instance.ref().child(
          'complaints/$fileName',
        );
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String url = await snapshot.ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        debugPrint("Error uploading image: $e");
      }
    }
    return downloadUrls;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    // Wait for auth to be ready
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Report New Issue",
          style: TextStyle(
            color: Color(0xFF003366),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF003366)),
      ),
      // Show loading spinner if currently submitting
      body: _isUploading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF003366)),
            SizedBox(height: 20),
            Text(
              "Submitting Complaint...",
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // --- MAIN FORM CARD ---
              Card(
                elevation: 8,
                shadowColor: Colors.black26,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SECTION 1: PERSONAL DETAILS ---
                      const Text(
                        'Complainant Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Information auto-filled from your profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Full Name:'),
                      TextFormField(
                        initialValue: fullName,
                        key: Key("name_$fullName"),
                        readOnly: true, // User cannot edit this
                        decoration: _inputDeco(
                          Icons.person_outline,
                          Colors.grey.shade100,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- USER TYPE DROPDOWN ---
                      _buildLabel('User Type:'),
                      DropdownButtonFormField<String>(
                        value: userTypes.contains(userType)
                            ? userType
                            : 'Student',
                        items: userTypes
                            .map(
                              (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => userType = val!),
                        decoration: _inputDeco(
                          Icons.people_outline,
                          const Color(0xFFF5F6FA),
                        ),
                      ),

                      // --- SPECIFY OTHERS USER TYPE ---
                      if (userType == 'Others') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration:
                          _inputDeco(
                            Icons.edit_note,
                            const Color(0xFFF5F6FA),
                          ).copyWith(
                            hintText: 'Please specify your role',
                          ),
                          onChanged: (val) => otherUserType = val,
                          validator: (val) =>
                          val!.isEmpty ? 'Required' : null,
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildLabel('ID / Matric No:'),
                      TextFormField(
                        initialValue: matricNo,
                        key: Key("id_$matricNo"),
                        readOnly: true,
                        decoration: _inputDeco(
                          Icons.badge_outlined,
                          Colors.grey.shade100,
                        ),
                      ),

                      const SizedBox(height: 20),
                      _buildLabel('Phone Number:'),
                      TextFormField(
                        initialValue: contactNumber,
                        key: Key("phone_$contactNumber"),
                        readOnly: true,
                        decoration: _inputDeco(
                          Icons.phone_android_outlined,
                          const Color(0xFFF5F6FA),
                        ),
                        onChanged: (val) => contactNumber = val,
                        validator: (val) =>
                        val!.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),

                      // --- SECTION 2: PREMISE DETAILS ---
                      const Text(
                        'Premise Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('College / Building:'),
                      DropdownButtonFormField<String>(
                        value: building,
                        items: buildings
                            .map(
                              (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => building = val!),
                        decoration: _inputDeco(
                          Icons.school_outlined,
                          const Color(0xFFF5F6FA),
                        ),
                      ),

                      const SizedBox(height: 20),
                      _buildLabel('Premise Detail (Room/Block):'),
                      TextFormField(
                        decoration: _inputDeco(
                          Icons.apartment_outlined,
                          const Color(0xFFF5F6FA),
                        ).copyWith(hintText: 'e.g. B1 L1 A1', hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),),
                        onChanged: (val) => roomNumber = val,
                        validator: (val) =>
                        val!.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),

                      // --- SECTION 3: DAMAGE DETAILS ---
                      const Text(
                        'Type of Damage(s)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Category:'),
                      DropdownButtonFormField<String>(
                        value: category,
                        items: categories
                            .map(
                              (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => category = val!),
                        decoration: _inputDeco(
                          Icons.build_circle_outlined,
                          const Color(0xFFF5F6FA),
                        ),
                      ),

                      // Show extra field if 'Other' is selected
                      if (category == 'Other') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDeco(
                            Icons.edit_note,
                            const Color(0xFFF5F6FA),
                          ).copyWith(hintText: 'Please specify category', hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey,
                          ),),
                          onChanged: (val) => otherCategory = val,
                          validator: (val) =>
                          val!.isEmpty ? 'Required' : null,
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildLabel('Issue Title:'),
                      TextFormField(
                        decoration: _inputDeco(
                          Icons.title,
                          const Color(0xFFF5F6FA),
                        ).copyWith(hintText: 'Please enter your issue',hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),),
                        onChanged: (val) => title = val,
                        validator: (val) =>
                        val!.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 20),

                      _buildLabel('Detailed Description:'),
                      TextFormField(
                        maxLines: 5,
                        maxLength: 300,
                        minLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          hintText: 'PLease describe the issue in detail',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => description = val,
                        validator: (val) =>
                        val!.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 30),
                      _buildLabel('Attach Evidence (Photos/Video):'),
                      const SizedBox(height: 8),

                      // Media Selection Area
                      _buildMediaUploader(),

                      const SizedBox(height: 40),

                      // --- SUBMIT BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Submit Complaint',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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

  // --- UI HELPER: LABEL TEXT ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  // --- UI HELPER: INPUT STYLE ---
  InputDecoration _inputDeco(IconData icon, Color fill) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF003366), size: 20),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // --- UI COMPONENT: MEDIA UPLOADER ---
  Widget _buildMediaUploader() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _mediaBtn(
                Icons.camera_enhance,
                "Photos",
                _pickImages,
                Colors.blue.shade50,
                Colors.blue.shade900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _mediaBtn(
                Icons.videocam,
                _selectedVideo == null ? "Video" : "Video OK",
                _pickVideo,
                Colors.orange.shade50,
                Colors.orange.shade900,
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) _buildImagePreview(),
        if (_selectedVideo != null) _buildVideoIndicator(),
      ],
    );
  }

  // Helper for Media Buttons
  Widget _mediaBtn(
      IconData icon,
      String label,
      VoidCallback tap,
      Color bg,
      Color fg,
      ) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Image Horizontal Scroll Preview
  Widget _buildImagePreview() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) => Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_selectedImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Remove Button
            Positioned(
              top: 0,
              right: 10,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImages.removeAt(index)),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Video Status Indicator
  Widget _buildVideoIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Video attached",
              style: TextStyle(fontSize: 11, fontFamily: 'Poppins'),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedVideo = null),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // --- 5. SUBMIT FORM ---
  // Validates input, uploads media, calls service, and closes screen.
  Future<void> _submitForm() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true); // Start Loading

      // 1. Upload Images to Firebase Storage
      List<String> uploadedUrls = await _uploadImages();

      // 2. Upload Video (if selected)
      String? videoDownloadUrl;
      if (_selectedVideo != null) {
        videoDownloadUrl = await ComplaintService().uploadVideo(
          _selectedVideo!,
        );
      }

      // 3. Determine Final Category
      String finalCategory = category == 'Other' ? otherCategory : category;

      // 4. Submit Data to Firestore
      await ComplaintService().submitComplaint(
        uid: user!.uid,
        email: user.email,
        title: title,
        description: description,
        category: finalCategory,
        imageUrls: uploadedUrls,
        videoUrl: videoDownloadUrl,
        fullName: fullName,
        userType: userType,
        matricNo: matricNo,
        contactNumber: contactNumber,
        building: building,
        roomNumber: roomNumber,
      );

      // 5. Finish & Close
      if (mounted) {
        setState(() => _isUploading = false);
        Navigator.pop(context); // Go back to Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint Submitted Successfully!')),
        );
      }
    }
  }
}