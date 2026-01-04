import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../complaint/complaint_detail_screen.dart';

class AdminComplaintList extends StatefulWidget {
  final String filterType; 
  const AdminComplaintList({super.key, required this.filterType});

  @override
  State<AdminComplaintList> createState() => _AdminComplaintListState();
}

class _AdminComplaintListState extends State<AdminComplaintList> {
  String _selectedBuilding = 'All';
  String _selectedCategory = 'All';

  // Categories matching report_screen.dart
  final List<String> _standardCategories = [
    'Furniture', 
    'Mechanical', 
    'Electrical', 
    'Plumbing/Sink', 
    'Waste Water', 
    'Wi-Fi',
  ];

  @override
  Widget build(BuildContext context) {
    final allComplaints = Provider.of<List<ComplaintModel>>(context);

    // 1. FILTER LOGIC
    List<ComplaintModel> filteredList = allComplaints.where((job) {
      // A. Tab Filter
      bool tabMatch = false;
      if (widget.filterType == 'active') {
        tabMatch = job.status == 'Pending' || job.status == 'In Progress';
      } else if (widget.filterType == 'verify') {
        tabMatch = job.status == 'Pending Verification';
      } else {
        tabMatch = job.status == 'Resolved' || job.status == 'Invalid';
      }

      // B. Building Filter
      bool buildingMatch = _selectedBuilding == 'All' || job.building == _selectedBuilding;

      // C. Category Filter
      bool categoryMatch = false;
      if (_selectedCategory == 'All') {
        categoryMatch = true;
      } else if (_selectedCategory == 'Other') {
        categoryMatch = !_standardCategories.contains(job.category);
      } else {
        categoryMatch = job.category == _selectedCategory;
      }

      return tabMatch && buildingMatch && categoryMatch;
    }).toList();

    // 2. SORTING (Newest First)
    filteredList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 3. DROPDOWN LISTS
    final List<String> buildings = ['All'];
    buildings.addAll(allComplaints.map((e) => e.building ?? 'Unknown').whereType<String>().toSet());

    final List<String> categories = ['All', ..._standardCategories, 'Other'];

    return Column(
      children: [
        // --- FILTER BAR ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Property",
                  value: _selectedBuilding,
                  items: buildings,
                  onChanged: (val) => setState(() => _selectedBuilding = val!),
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildDropdown(
                  label: "Category",
                  value: _selectedCategory,
                  items: categories,
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  icon: Icons.category,
                ),
              ),
            ],
          ),
        ),

        // --- LIST VIEW ---
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text("No tasks found", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return _buildAdminCard(context, filteredList[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : 'All',
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((String item) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                }).toList();
              },
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(BuildContext context, ComplaintModel job) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    switch (job.status) {
      case 'Pending': statusColor = Colors.orange; statusIcon = Icons.hourglass_empty; break;
      case 'In Progress': statusColor = Colors.blue; statusIcon = Icons.build; break;
      case 'Pending Verification': statusColor = Colors.purple; statusIcon = Icons.fact_check; break;
      case 'Resolved': statusColor = Colors.green; statusIcon = Icons.check_circle; break;
      case 'Invalid': statusColor = Colors.red; statusIcon = Icons.cancel; break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.grey.shade200, width: 1)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(statusIcon, color: statusColor)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (job.status == 'Pending')
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: "Reject",
                onPressed: () => _markAsInvalid(context, job),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("${job.category} • ${job.priority} Priority"),
            const SizedBox(height: 5),
            if (job.status == 'Invalid')
              Text("Rejected: ${job.adminRemarks ?? 'No reason given'}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp), style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 109, 109, 109))),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailScreen(complaint: job))),
      ),
    );
  }

  void _markAsInvalid(BuildContext context, ComplaintModel job) {
    String reason = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Text("Reject Request?")],
        ),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: "Reason", hintText: "e.g. Duplicate", border: OutlineInputBorder()),
          onChanged: (val) => reason = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Confirm Reject"),
            onPressed: () async {
              if (reason.isNotEmpty) {
                await ComplaintService().markAsInvalid(job.id, reason);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}