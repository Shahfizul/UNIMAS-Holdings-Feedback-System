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
        backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            "Staff Management",
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
          bottom: const TabBar(
            labelColor: Color(0xFF003366),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF003366),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Active Staff"),
              Tab(text: "Archived"),
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
          backgroundColor: const Color(0xFF003366),
          elevation: 4,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text("Register Staff", style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
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

class _MaintainerList extends StatefulWidget {
  final bool isActive;
  const _MaintainerList({required this.isActive});

  @override
  State<_MaintainerList> createState() => _MaintainerListState();
}

class _MaintainerListState extends State<_MaintainerList> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    Stream<List<UserModel>> stream = widget.isActive
        ? DatabaseService().maintainers
        : DatabaseService().archivedMaintainers;

    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var allStaff = snapshot.data!;
        
        // --- CLIENT-SIDE SEARCH LOGIC ---
        var filteredStaff = allStaff.where((staff) {
          final name = staff.fullName?.toLowerCase() ?? "";
          final spec = staff.specialization?.toLowerCase() ?? "";
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || spec.contains(query);
        }).toList();

        return Column(
          children: [
            // --- SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by name or role...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // --- LIST VIEW ---
            Expanded(
              child: filteredStaff.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredStaff.length,
                      itemBuilder: (context, index) {
                        return _buildStaffCard(context, filteredStaff[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.isActive ? Icons.group_off_outlined : Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            widget.isActive ? "No staff found." : "No archived staff.",
            style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, UserModel staff) {
    String specialization = staff.specialization ?? "General";
    
    // Color coding for specialization pills
    Color pillColor = Colors.blue;
    if (specialization.contains("Plumb")) pillColor = Colors.cyan;
    else if (specialization.contains("Elect")) pillColor = Colors.amber.shade700;
    else if (specialization.contains("IT")) pillColor = Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.isActive ? const Color(0xFF003366) : Colors.grey, 
                width: 4
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 1. AVATAR (Initials)
                CircleAvatar(
                  radius: 22,
                  backgroundColor: widget.isActive ? const Color(0xFF003366).withOpacity(0.1) : Colors.grey.shade100,
                  child: Text(
                    _getInitials(staff.fullName),
                    style: TextStyle(
                      color: widget.isActive ? const Color(0xFF003366) : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 2. INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName ?? "Unknown Name",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: widget.isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Specialization Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pillColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              specialization,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pillColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Email with Icon
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              staff.email, 
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Contact with Icon (NEW ADDITION)
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            staff.contactNumber ?? "No Contact", 
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. ACTIONS MENU
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') _showEditDialog(context, staff);
                    if (value == 'toggle') _confirmToggleStatus(context, staff);
                  },
                  itemBuilder: (context) => [
                    if (widget.isActive)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 10), Text("Edit Details")],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(widget.isActive ? Icons.archive : Icons.restore, 
                               size: 18, 
                               color: widget.isActive ? Colors.orange : Colors.green), 
                          const SizedBox(width: 10), 
                          Text(widget.isActive ? "Archive Staff" : "Restore Staff")
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "?";
    List<String> parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return parts[0][0].toUpperCase();
  }

  // --- DIALOGS ---

  void _showEditDialog(BuildContext context, UserModel staff) {
    final nameCtrl = TextEditingController(text: staff.fullName);
    final phoneCtrl = TextEditingController(text: staff.contactNumber);
    String spec = staff.specialization ?? 'General';
    final List<String> specs = ['General', 'Plumber', 'Electrician', 'Carpenter', 'IT/Network', 'Cleaner', 'Civil Works'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Edit Staff Details", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Full Name", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: "Contact Number", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: specs.contains(spec) ? spec : 'General',
                    decoration: InputDecoration(
                      labelText: "Specialization", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                    items: specs.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => spec = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(widget.isActive ? "Archive Staff?" : "Restore Staff?", style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(widget.isActive 
          ? "This will remove ${staff.fullName} from the active assignment list. They will not be able to receive new jobs." 
          : "This will reactivate ${staff.fullName} for new assignments."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isActive ? Colors.orange : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(widget.isActive ? "Archive" : "Restore", style: const TextStyle(color: Colors.white)),
            onPressed: () async {
              await DatabaseService().toggleMaintainerStatus(staff.uid, !widget.isActive);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}