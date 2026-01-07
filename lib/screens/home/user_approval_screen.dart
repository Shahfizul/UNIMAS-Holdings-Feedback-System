import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

// Screen for Admins to view and approve/reject new resident registrations.
// Residents cannot log in until their account is approved here.
class UserApprovalScreen extends StatelessWidget {
  const UserApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamProvider listens to real-time updates from Firestore.
    // It fetches all users where 'isApproved' is false (pending status).
    return StreamProvider<List<UserModel>>.value(
      value: DatabaseService().pendingResidents,
      initialData: const [],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            "Pending Registrations",
            style: TextStyle(
              color: Color(0xFF003366),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF003366), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Separate widget for the list content to keep build method clean
        body: const _PendingUserList(),
      ),
    );
  }
}

// Consumes the provided user list and renders the UI
class _PendingUserList extends StatelessWidget {
  const _PendingUserList();

  @override
  Widget build(BuildContext context) {
    // Access the list of pending users provided by StreamProvider
    final users = Provider.of<List<UserModel>>(context);

    // --- 1. EMPTY STATE ---
    // Shown when there are no new registrations to review
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No pending approvals.",
              style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins', fontSize: 16),
            ),
          ],
        ),
      );
    }

    // --- 2. LIST VIEW ---
    // Renders a card for each pending user
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(context, users[index]);
      },
    );
  }

  // --- USER CARD UI ---
  // Displays the applicant's details and action buttons
  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // --- HEADER: Avatar, Name & Role ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Initials Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF003366).withOpacity(0.1),
                  child: Text(
                    _getInitials(user.fullName),
                    style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Role Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? "Unknown Name",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // --- BODY: Contact & ID Details ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(Icons.badge_outlined, "ID / Matric", "${user.idType ?? 'ID'}: ${user.idNumber ?? 'N/A'}"),
                const SizedBox(height: 8),
                _infoRow(Icons.email_outlined, "Email", user.email),
                const SizedBox(height: 8),
                _infoRow(Icons.phone_outlined, "Phone", user.contactNumber ?? "N/A"),
              ],
            ),
          ),

          // --- FOOTER: Approve / Reject Buttons ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Reject Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectUser(context, user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),

                // Approve Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveUser(context, user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: INFO ROW ---
  // Standardized row for icon + label + value
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }

  // --- HELPER: GET INITIALS ---
  // Turns "John Doe" into "JD" for the avatar
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "?";
    List<String> parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return parts[0][0].toUpperCase();
  }

  // --- ACTION: APPROVE USER ---
  // Calls the database service to set 'isApproved' to true.
  Future<void> _approveUser(BuildContext context, UserModel user) async {
    await DatabaseService().approveUser(user.uid);
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text("${user.fullName} Approved!")
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // --- ACTION: REJECT USER ---
  // Shows a confirmation dialog, then deletes the user request if confirmed.
  Future<void> _rejectUser(BuildContext context, UserModel user) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Reject Registration?", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to reject ${user.fullName}? They will need to register again."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Calls database service to delete the user document
      await DatabaseService().rejectUser(user.uid);
    }
  }
}