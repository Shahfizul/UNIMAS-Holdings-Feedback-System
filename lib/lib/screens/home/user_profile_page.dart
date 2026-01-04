import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _userData = UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8), // Neutral professional background
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF003366)))
          : _userData == null
              ? const Center(child: Text("User data not found"))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. The Header with the Profile Image
                    _buildHeader(),

                    // 2. The Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: Column(
                          children: [
                            _buildIdentificationCard(),
                            const SizedBox(height: 20),
                            _buildContactCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF003366),
      // This creates the "Professional" transition
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          _userData!.fullName ?? "Profile",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Dark Blue Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(255, 42, 111, 180), Color(0xFF003366)],
                ),
              ),
            ),
            // Decorative elements to make it look "Pro"
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
            ),
            // Profile Image
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 45, color: Color(0xFF003366)),
                    ),
                  ),
                  const SizedBox(height: 45), // Space for the pinned title
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationCard() {
    return _buildProfessionalCard(
      title: "Identification",
      children: [
        _infoTile(Icons.person_outline, "Full Name", _userData!.fullName ?? "N/A"),
        _infoTile(Icons.fingerprint, _userData!.idType ?? "ID", _userData!.idNumber ?? "N/A"),
      ],
    );
  }

  Widget _buildContactCard() {
    return _buildProfessionalCard(
      title: "Contact & Role",
      children: [
        _infoTile(Icons.email_outlined, "Email Address", _userData!.email),
        _infoTile(Icons.phone_android, "Mobile Number", _userData!.contactNumber ?? "N/A"),
        _infoTile(Icons.badge_outlined, "System Role", _userData!.role),
      ],
    );
  }

  Widget _buildProfessionalCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 20),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF003366), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}