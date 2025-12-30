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

  // --- 1. FIXED: CATEGORIES MATCHING REPORT SCREEN ---
  // These must match the lists in report_screen.dart exactly.
  final List<String> _standardCategories = [
    'Furniture', 
    'Mechanical', 
    'Electrical', 
    'Plumbing/Sink', 
    'Waste Water', 
    'Wi-Fi',
    // Note: Anything else (like user typed custom text) falls under "Other"
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

      // C. Smart Category Filter
      bool categoryMatch = false;
      if (_selectedCategory == 'All') {
        categoryMatch = true;
      } else if (_selectedCategory == 'Other') {
        // Match if the job's category is NOT in our standard list
        categoryMatch = !_standardCategories.contains(job.category);
      } else {
        // Direct match
        categoryMatch = job.category == _selectedCategory;
      }

      return tabMatch && buildingMatch && categoryMatch;
    }).toList();

    // 2. SAFE LIST GENERATION
    final List<String> buildings = ['All'];
    buildings.addAll(allComplaints
        .map((e) => e.building)
        .whereType<String>()
        .toSet());

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
              // Building Filter
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
              // Category Filter
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
              
              // --- 2. FIX: PREVENT OVERFLOW ---
              // selectedItemBuilder tells Flutter how to render the text WHEN SELECTED.
              // We force it to use ellipsis (...) if it's too long.
              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((String item) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis, // <--- Stops overflow!
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList();
              },

              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Row(
                    children: [
                      if (val == 'All') Icon(icon, size: 14, color: Colors.blue[800]),
                      if (val == 'All') const SizedBox(width: 8),
                      // Flexible prevents overflow inside the popup list too
                      Flexible(child: Text(val, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
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
    if (job.status == 'Pending') statusColor = Colors.orange;
    else if (job.status == 'In Progress') statusColor = Colors.blue;
    else if (job.status == 'Pending Verification') statusColor = Colors.purple;
    else if (job.status == 'Resolved') statusColor = Colors.green;
    else if (job.status == 'Invalid') statusColor = Colors.red;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 5)),
        ),
        child: InkWell( // Use InkWell for better touch feedback
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ComplaintDetailScreen(complaint: job)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                    ),
                    if (job.status == 'Pending')
                      IconButton(
                        constraints: const BoxConstraints(), // Compact button
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        tooltip: "Reject",
                        onPressed: () => _markAsInvalid(context, job),
                      )
                    else
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Badges Row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("${job.building} • ${job.category}", style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      job.status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),

                // --- 3. BETTER HISTORY VIEW (Extra Details) ---
                // Only show this block if we are in the History tab context
                if (job.status == 'Invalid') ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      "Reason: ${job.adminRemarks ?? 'N/A'}",
                      style: TextStyle(color: Colors.red[800], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else if (job.status == 'Resolved') ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 5),
                        Text(
                          "Verified on ${DateFormat('dd MMM').format(job.timestamp)}", // Ideally use verifiedAt
                          style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (job.rating > 0) ...[
                          const Spacer(),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(" ${job.rating}", style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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