import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../complaint/complaint_detail_screen.dart';

// Widget that displays a list of complaints filtered by status (Tabs).
// Used in the Admin Dashboard to show 'Pending', 'Progress', 'Verify', and 'History' lists.
class AdminComplaintList extends StatefulWidget {
  final String filterType; // 'pending', 'in_progress', 'verify', 'history'
  const AdminComplaintList({super.key, required this.filterType});

  @override
  State<AdminComplaintList> createState() => _AdminComplaintListState();
}

class _AdminComplaintListState extends State<AdminComplaintList> {
  // --- STATE VARIABLES ---
  // These control the local filtering and sorting within this specific tab
  String _sortBy = 'Latest';
  String _priorityFilter = 'All';
  String _selectedBuilding = 'All';
  String _selectedCategory = 'All';

  // Hardcoded categories for the filter dropdown logic
  final List<String> _standardCategories = [
    'Furniture', 'Mechanical', 'Electrical', 'Plumbing/Sink', 'Waste Water', 'Wi-Fi'
  ];

  // --- UNIFIED FILTER MODAL ---
  // Opens a bottom sheet allowing the Admin to apply multiple filters at once.
  void _showFilterModal(List<String> buildings, List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // Allows the sheet to take up more screen height
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Use StatefulBuilder to update the modal's UI internally when chips are clicked
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.85, // Use 85% of screen height
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Reset Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Filter & Sort", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
                    TextButton(
                      onPressed: () {
                        // Reset all filters to default
                        setState(() {
                          _sortBy = 'Latest';
                          _priorityFilter = 'All';
                          _selectedBuilding = 'All';
                          _selectedCategory = 'All';
                        });
                        setModalState(() {}); // Update Modal UI
                        Navigator.pop(context); // Close Modal
                      },
                      child: const Text("Reset All", style: TextStyle(color: Colors.red)),
                    )
                  ],
                ),
                const Divider(),

                // Scrollable content for filter options
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. SORT ORDER
                        _buildFilterSectionHeader("Sort Order"),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildModalChip("Latest First", _sortBy == 'Latest', () => setModalState(() => setState(() => _sortBy = 'Latest'))),
                            _buildModalChip("Oldest First", _sortBy == 'Oldest', () => setModalState(() => setState(() => _sortBy = 'Oldest'))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 2. PRIORITY LEVEL
                        _buildFilterSectionHeader("Priority Level"),
                        Wrap(
                          spacing: 8,
                          children: ["All", "High", "Medium", "Low"].map((p) {
                            return _buildModalChip(p, _priorityFilter == p, () => setModalState(() => setState(() => _priorityFilter = p)));
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // 3. PROPERTY / BUILDING
                        _buildFilterSectionHeader("Property / Building"),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: buildings.map((b) {
                            return _buildModalChip(b, _selectedBuilding == b, () => setModalState(() => setState(() => _selectedBuilding = b)));
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // 4. CATEGORY
                        _buildFilterSectionHeader("Category"),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((c) {
                            return _buildModalChip(c, _selectedCategory == c, () => setModalState(() => setState(() => _selectedCategory = c)));
                          }).toList(),
                        ),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ),

                // Apply Button (Closes modal)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Helper Widget for clickable filter chips in the modal
  Widget _buildModalChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF003366).withOpacity(0.1),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF003366) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? const Color(0xFF003366) : Colors.grey.shade300),
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildFilterSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Color _getPriorityColor(String priority) {
    if (priority == 'High') return Colors.red;
    if (priority == 'Medium') return Colors.orange;
    if (priority == 'Low') return Colors.green;
    return const Color(0xFF003366);
  }

  @override
  Widget build(BuildContext context) {
    // Access global complaint list from Provider
    final allComplaints = Provider.of<List<ComplaintModel>>(context);

    // --- 1. FILTER LOGIC ---
    // Apply multiple layers of filters to the raw list
    List<ComplaintModel> filteredList = allComplaints.where((job) {
      // Layer 1: Filter by Tab (Pending/Progress/Verify/History)
      bool tabMatch = false;
      if (widget.filterType == 'pending') tabMatch = job.status == 'Pending';
      else if (widget.filterType == 'in_progress') tabMatch = job.status == 'In Progress';
      else if (widget.filterType == 'verify') tabMatch = job.status == 'Pending Verification';
      else tabMatch = job.status == 'Resolved' || job.status == 'Invalid';

      // Layer 2: Building Filter
      bool buildingMatch = _selectedBuilding == 'All' || job.building == _selectedBuilding;

      // Layer 3: Category Filter
      bool categoryMatch = false;
      if (_selectedCategory == 'All') categoryMatch = true;
      else if (_selectedCategory == 'Other') categoryMatch = !_standardCategories.contains(job.category);
      else categoryMatch = job.category == _selectedCategory;

      // Layer 4: Priority Filter
      bool priorityMatch = _priorityFilter == 'All' || job.priority == _priorityFilter;

      return tabMatch && buildingMatch && categoryMatch && priorityMatch;
    }).toList();

    // --- 2. SORT LOGIC ---
    filteredList.sort((a, b) => _sortBy == 'Latest'
        ? b.timestamp.compareTo(a.timestamp)
        : a.timestamp.compareTo(b.timestamp));

    // --- 3. PREPARE DYNAMIC LISTS FOR MODAL ---
    // Extract unique buildings from data to populate dropdown
    final List<String> buildings = ['All'];
    buildings.addAll(allComplaints.map((e) => e.building ?? 'Unknown').whereType<String>().toSet());
    final List<String> categories = ['All', ..._standardCategories, 'Other'];

    // Check if any custom filter is active (to show visual indicators)
    bool isFiltered = _priorityFilter != 'All' || _selectedBuilding != 'All' || _selectedCategory != 'All';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TOP CONTROLS BAR ---
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // THE MAIN FILTER BUTTON
                  Expanded(
                    child: InkWell(
                      onTap: () => _showFilterModal(buildings, categories),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: const Color(0xFF003366)),
                            const SizedBox(width: 8),
                            const Text("Filters & Sort", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            // Red dot indicator if filters are active
                            if (isFiltered)
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Count Display
                  Text(
                      "${filteredList.length} tasks",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ],
              ),

              // --- ACTIVE FILTER CHIPS (Visual Feedback) ---
              // Shows small pills for active filters, allowing quick removal
              if (isFiltered) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_priorityFilter != 'All')
                        _buildActiveFilterChip("Priority: $_priorityFilter", () => setState(() => _priorityFilter = 'All')),

                      if (_selectedBuilding != 'All')
                        _buildActiveFilterChip("Prop: $_selectedBuilding", () => setState(() => _selectedBuilding = 'All')),

                      if (_selectedCategory != 'All')
                        _buildActiveFilterChip("Cat: $_selectedCategory", () => setState(() => _selectedCategory = 'All')),

                      TextButton(
                          onPressed: () {
                            setState(() {
                              _priorityFilter = 'All';
                              _selectedBuilding = 'All';
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Text("Clear All", style: TextStyle(fontSize: 11, color: Colors.red))
                      )
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),

        const Divider(height: 1),

        // --- LIST VIEW ---
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
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

  // Small pill widget showing an active filter with 'X' to remove
  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF003366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF003366), fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF003366)),
          )
        ],
      ),
    );
  }

  // Displayed when the list is empty
  Widget _buildEmptyState() {
    String message = "No tasks found";
    IconData icon = Icons.assignment_turned_in_outlined;

    if (widget.filterType == 'pending') {
      message = "All clear! No pending jobs.";
      icon = Icons.check_circle_outline;
    } else if (widget.filterType == 'in_progress') {
      message = "No jobs currently in progress.";
      icon = Icons.engineering_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  // Renders a single complaint card
  Widget _buildAdminCard(BuildContext context, ComplaintModel job) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    // Determine visual style based on status
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200, width: 1)
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Navigate to Details Screen
          Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailScreen(complaint: job)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Row 1: Icon, Title, Priority, Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            job.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Poppins'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(job.priority).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${job.priority} Priority",
                                style: TextStyle(fontSize: 10, color: _getPriorityColor(job.priority), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                job.category,
                                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Location & Date
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(
                          "${job.building}, ${job.roomNumber}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis
                      )
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(job.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              // Optional: Quick Reject Action (Only for Pending)
              if (job.status == 'Pending') ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => _markAsInvalid(context, job),
                      child: const Text("Reject", style: TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- QUICK REJECT DIALOG ---
  // Allows Admin to reject a pending complaint without opening the details screen.
  void _markAsInvalid(BuildContext context, ComplaintModel job) {
    String reason = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Complaint"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: "Reason", border: OutlineInputBorder()),
          onChanged: (val) => reason = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Reject"),
            onPressed: () async {
              if (reason.isNotEmpty) {
                // Call service to update Firestore
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