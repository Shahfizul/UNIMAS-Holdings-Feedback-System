import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path; 
import '../../models/user_model.dart';
import '../../services/complaint_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Section 1 Fields (Personal)
  String fullName = '';
  String matricNo = '';
  String contactNumber = '';
  
  // Logic for "Others" User Type
  String userType = 'Student'; 
  String otherUserType = ''; 
  
  // Section 1 Fields (Premise)
  String building = 'Kolej Dahlia'; 
  String roomNumber = '';

  // Damage Details
  String title = '';
  String description = '';
  
  // Logic for "Others" Category
  String category = 'Furniture'; 
  String otherCategory = ''; 
  
  // Lists
  final List<String> categories = ['Furniture', 'Mechanical', 'Electrical', 'Plumbing/Sink', 'Waste Water', 'Wi-Fi', 'Other'];
  final List<String> userTypes = ['Student', 'Staff', 'Tenant', 'Others'];
  final List<String> buildings = ['Kolej Dahlia', 'Kolej Allamanda Premium', 'Kolej Sebayor'];

  // --- MULTIPLE IMAGE LOGIC ---
  final List<File> _selectedImages = []; // List instead of single file
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; 

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- AUTO-FILL LOGIC ---
  Future<void> _loadUserProfile() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            if (fullName.isEmpty) fullName = data['fullName'] ?? '';
            if (contactNumber.isEmpty) contactNumber = data['contactNumber'] ?? '';
            if (matricNo.isEmpty) matricNo = data['idNumber'] ?? '';
            
            String type = data['idType'] ?? '';
            if (type == 'Matric No') userType = 'Student';
            else if (type == 'Staff ID') userType = 'Staff';
            
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    }
  }

  // --- PICK MULTIPLE IMAGES ---
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(); // Allows selecting multiple
    if (pickedFiles.isNotEmpty) {
      setState(() {
        // Convert XFile to File and add to our list
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  // --- UPLOAD LOOP ---
  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];
    
    for (var imageFile in _selectedImages) {
      try {
        String fileName = "${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}";
        Reference storageRef = FirebaseStorage.instance.ref().child('complaints/$fileName');
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String url = await snapshot.ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        print("Error uploading file: $e");
        // Continue uploading others even if one fails
      }
    }
    return downloadUrls;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text("New Complaint (CCF Sec 1)")),
      body: _isUploading 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Uploading Images...")],
          )) 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingProfile) const LinearProgressIndicator(),

                    // --- SECTION 1: PERSONAL DETAILS ---
                    const Text("Section 1: Complainant Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    const SizedBox(height: 10),
                    
                    TextFormField(
                      initialValue: fullName, 
                      decoration: const InputDecoration(labelText: 'Full Name (Block Letters)', border: OutlineInputBorder()),
                      onChanged: (val) => fullName = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField(
                            value: userTypes.contains(userType) ? userType : 'Student',
                            isExpanded: true, 
                            items: userTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) => setState(() => userType = val.toString()),
                            decoration: const InputDecoration(labelText: 'User Type', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            key: Key(matricNo), 
                            initialValue: matricNo,
                            decoration: const InputDecoration(
                              labelText: 'ID / Matric / Passport', 
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => matricNo = val,
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    
                    if (userType == 'Others') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Please Specify (User Type)', border: OutlineInputBorder()),
                        onChanged: (val) => otherUserType = val,
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ],

                    const SizedBox(height: 10),
                    TextFormField(
                      key: Key(contactNumber), 
                      initialValue: contactNumber,
                      decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => contactNumber = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 20),
                    const Text("Premise Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    DropdownButtonFormField(
                      value: building,
                      items: buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) => setState(() => building = val.toString()),
                      decoration: const InputDecoration(labelText: 'Building / College', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Room / Block / Stall No.', border: OutlineInputBorder()),
                      onChanged: (val) => roomNumber = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 20),
                    const Text("Type of Damage(s)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    const SizedBox(height: 10),

                    DropdownButtonFormField(
                      value: category,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => category = val.toString()),
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),

                    if (category == 'Other') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Please Specify', border: OutlineInputBorder()),
                        onChanged: (val) => otherCategory = val,
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ],

                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Issue Title', border: OutlineInputBorder()),
                      onChanged: (val) => title = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description in Detail', border: OutlineInputBorder()),
                      maxLines: 3,
                      onChanged: (val) => description = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 20),
                    
                    // --- MULTIPLE PHOTO UI ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Photos Evidence", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text("Add Photos"),
                          onPressed: _pickImages,
                        ),
                      ],
                    ),
                    
                    // Display Selected Images Horizontal List
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Delete Button
                                Positioned(
                                  top: 0,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      )
                    else 
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Center(child: Text("No photos selected", style: TextStyle(color: Colors.grey))),
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text("SUBMIT COMPLAINT", style: TextStyle(fontSize: 18, color: Colors.white)),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isUploading = true);
                            
                            // Upload Loop
                            List<String> uploadedUrls = await _uploadImages();
                            
                            String finalUserType = userType == 'Others' ? otherUserType : userType;
                            String finalCategory = category == 'Other' ? otherCategory : category;

                            await ComplaintService().submitComplaint(
                              uid: user.uid, 
                              email: user.email,
                              title: title,
                              description: description,
                              category: finalCategory, 
                              imageUrls: uploadedUrls, // Send LIST
                              fullName: fullName,
                              userType: finalUserType, 
                              matricNo: matricNo,
                              contactNumber: contactNumber,
                              building: building,
                              roomNumber: roomNumber,
                            );

                            setState(() => _isUploading = false);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Submitted Successfully!')));
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