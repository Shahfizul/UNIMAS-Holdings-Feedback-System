import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class UserApprovalScreen extends StatelessWidget {
  const UserApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Use StreamProvider to listen to the "pendingResidents" stream
    return StreamProvider<List<UserModel>>.value(
      value: DatabaseService().pendingResidents,
      initialData: const [],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Pending Registrations"),
          backgroundColor: Colors.blue[900], // Distinct color for User Mgmt
        ),
        body: const PendingUserList(),
      ),
    );
  }
}

class PendingUserList extends StatelessWidget {
  const PendingUserList({super.key});

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<List<UserModel>>(context);

    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text("No pending approvals.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name and ID Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user.fullName ?? "Unknown Name",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        user.idType ?? "ID",
                        style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                
                // Details
                _infoRow(Icons.badge, "ID Number:", user.idNumber ?? "N/A"),
                _infoRow(Icons.email, "Email:", user.email),
                _infoRow(Icons.phone, "Phone:", user.contactNumber ?? "N/A"),

                const SizedBox(height: 15),
                
                // Action Buttons
                Row(
                  children: [
                    // Reject Button
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text("Reject", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        onPressed: () async {
                           bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Reject User?"),
                              content: const Text("This will remove their request. They will need to register again."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reject")),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await DatabaseService().rejectUser(user.uid);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Approve Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () async {
                          await DatabaseService().approveUser(user.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${user.fullName} Approved!"))
                          );
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}