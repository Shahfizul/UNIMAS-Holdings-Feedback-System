import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import 'create_maintainer_screen.dart';

class ManageMaintainersScreen extends StatelessWidget {
  const ManageMaintainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Staff Management"),
          backgroundColor: Colors.blue[900],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Active Staff"),
              Tab(icon: Icon(Icons.archive), text: "Archived"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MaintainerList(isActive: true),
            _MaintainerList(isActive: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.blue[900],
          icon: const Icon(Icons.person_add),
          label: const Text("Register Staff"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateMaintainerScreen()),
            );
          },
        ),
      ),
    );
  }
}

class _MaintainerList extends StatelessWidget {
  final bool isActive;
  const _MaintainerList({required this.isActive});

  @override
  Widget build(BuildContext context) {
    // Switch stream based on tab
    Stream<List<UserModel>> stream = isActive 
        ? DatabaseService().maintainers 
        : DatabaseService().archivedMaintainers;

    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var staffList = snapshot.data!;

        if (staffList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isActive ? Icons.group_off : Icons.inbox, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  isActive ? "No active staff found." : "No archived staff.",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: staffList.length,
          itemBuilder: (context, index) {
            return _buildStaffCard(context, staffList[index]);
          },
        );
      },
    );
  }

  Widget _buildStaffCard(BuildContext context, UserModel staff) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue[100] : Colors.grey[300],
          child: Icon(
            Icons.person,
            color: isActive ? Colors.blue[800] : Colors.grey[600],
          ),
        ),
        title: Text(
          staff.fullName ?? "Unknown Name",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(staff.specialization ?? "General Staff"),
            Text(staff.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EDIT BUTTON (Only for Active)
            if (isActive)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: "Edit Details",
                onPressed: () => _showEditDialog(context, staff),
              ),
            
            // ARCHIVE / RESTORE BUTTON
            IconButton(
              icon: Icon(
                isActive ? Icons.archive : Icons.restore,
                color: isActive ? Colors.orange : Colors.green,
              ),
              tooltip: isActive ? "Archive" : "Restore",
              onPressed: () => _confirmToggleStatus(context, staff),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS ---

  void _showEditDialog(BuildContext context, UserModel staff) {
    final nameCtrl = TextEditingController(text: staff.fullName);
    final phoneCtrl = TextEditingController(text: staff.contactNumber);
    String spec = staff.specialization ?? 'General';
    final List<String> specs = ['General', 'Plumber', 'Electrician', 'Carpenter', 'IT/Network', 'Cleaner'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Staff Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: "Contact Number", border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: specs.contains(spec) ? spec : 'General',
                    decoration: const InputDecoration(labelText: "Specialization", border: OutlineInputBorder()),
                    items: specs.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => spec = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                child: const Text("Save Changes"),
                onPressed: () async {
                  await DatabaseService().updateMaintainerDetails(
                    uid: staff.uid,
                    fullName: nameCtrl.text,
                    contactNumber: phoneCtrl.text,
                    specialization: spec,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmToggleStatus(BuildContext context, UserModel staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? "Archive Staff?" : "Restore Staff?"),
        content: Text(isActive 
          ? "This will remove ${staff.fullName} from the active assignment list." 
          : "This will reactivate ${staff.fullName} for new assignments."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange : Colors.green,
            ),
            child: Text(isActive ? "Archive" : "Restore", style: const TextStyle(color: Colors.white)),
            onPressed: () async {
              await DatabaseService().toggleMaintainerStatus(staff.uid, !isActive);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}