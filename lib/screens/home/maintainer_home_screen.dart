import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Models & Services
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart';

// Screens & Widgets
import '../complaint/maintainer_job_detail.dart'; 
import '../../widgets/notification_badge.dart';
import '../home/user_profile_page.dart';

class MaintainerHomeScreen extends StatefulWidget {
  const MaintainerHomeScreen({super.key});

  @override
  State<MaintainerHomeScreen> createState() => _MaintainerHomeScreenState();
}

class _MaintainerHomeScreenState extends State<MaintainerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        NotificationService().initNotifications(user.uid);
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Logout", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to end your shift?", style: TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamProvider<List<ComplaintModel>>.value(
      value: ComplaintService().getAssignedComplaints(user.uid),
      initialData: const [],
      child: DefaultTabController(
        length: 3, // 3 Tabs: Active, Pending, History
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            
            // --- 1. ORIGINAL PROFILE ICON RESTORED ---
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 45),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 24, color: Colors.grey),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'logout') _showLogoutDialog(context);
                  if (value == 'profile') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_outline, size: 20),
                      title: Text('My Profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout, color: Colors.red, size: 20),
                      title: Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Maintainer Dashboard',
                  style: TextStyle(
                    color: Color(0xFF003366),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'UNIMAS Holdings',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: NotificationBadge(userId: user.uid),
              ),
            ],
            bottom: const TabBar(
              labelColor: Color(0xFF003366),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF003366),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(text: "Active"),   // In Progress
                Tab(text: "Pending"),  // Verify / Waiting
                Tab(text: "History"),  // Done
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              JobTabList(tabType: 'active'),
              JobTabList(tabType: 'pending_verification'),
              JobTabList(tabType: 'history'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- JOB LIST COMPONENT ---
class JobTabList extends StatefulWidget {
  final String tabType; 
  const JobTabList({super.key, required this.tabType});

  @override
  State<JobTabList> createState() => _JobTabListState();
}

class _JobTabListState extends State<JobTabList> {
  String _sortBy = 'Latest';
  String _priorityFilter = 'All';

  // --- COLOR HELPERS (Your Rules) ---
  Color _getStatusColor(String status) {
    if (status == 'Pending') return Colors.orange; // or Yellow
    if (status == 'In Progress') return Colors.blue;
    if (status == 'Pending Verification') return Colors.purple;
    if (status == 'Resolved') return Colors.green;
    if (status == 'Invalid') return Colors.red;
    return Colors.grey;
  }

  Color _getPriorityColor(String priority) {
    if (priority == 'High') return Colors.red;
    if (priority == 'Medium') return Colors.orange; 
    if (priority == 'Low') return Colors.green;
    return Colors.grey;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sort & Filter", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                
                const Text("Date Order", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Latest First"),
                      selected: _sortBy == 'Latest',
                      selectedColor: const Color(0xFF003366).withOpacity(0.1),
                      labelStyle: TextStyle(color: _sortBy == 'Latest' ? const Color(0xFF003366) : Colors.black),
                      onSelected: (s) { setState(() => _sortBy = 'Latest'); setModalState(() {}); },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Oldest First"),
                      selected: _sortBy == 'Oldest',
                      selectedColor: const Color(0xFF003366).withOpacity(0.1),
                      labelStyle: TextStyle(color: _sortBy == 'Oldest' ? const Color(0xFF003366) : Colors.black),
                      onSelected: (s) { setState(() => _sortBy = 'Oldest'); setModalState(() {}); },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                const Text("Priority Level", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ["All", "High", "Medium", "Low"].map((p) {
                    return ChoiceChip(
                      label: Text(p),
                      selected: _priorityFilter == p,
                      selectedColor: _getPriorityColor(p).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _priorityFilter == p ? _getPriorityColor(p) : Colors.black,
                        fontWeight: _priorityFilter == p ? FontWeight.bold : FontWeight.normal
                      ),
                      onSelected: (s) { setState(() => _priorityFilter = p); setModalState(() {}); },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allJobs = Provider.of<List<ComplaintModel>>(context);
    
    // 1. Filter by Tab
    List<ComplaintModel> filteredJobs;
    if (widget.tabType == 'active') {
      filteredJobs = allJobs.where((job) => job.status == 'In Progress').toList();
    } else if (widget.tabType == 'pending_verification') {
      filteredJobs = allJobs.where((job) => job.status == 'Pending Verification').toList();
    } else {
      filteredJobs = allJobs.where((job) => job.status == 'Resolved' || job.status == 'Invalid').toList();
    }

    // 2. Filter by Priority
    if (_priorityFilter != "All") {
      filteredJobs = filteredJobs.where((job) => job.priority == _priorityFilter).toList();
    }

    // 3. Sort
    filteredJobs.sort((a, b) => _sortBy == 'Latest' 
      ? b.timestamp.compareTo(a.timestamp) 
      : a.timestamp.compareTo(b.timestamp));

    return Column(
      children: [
        // --- FILTER BUTTON ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.tune, size: 16, color: Colors.white),
                label: Text("Sort & Priority ($_priorityFilter)", style: const TextStyle(fontSize: 12, color: Colors.white)),
                backgroundColor: const Color(0xFF003366),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: _showSortOptions,
              ),
              const Spacer(),
              Text(
                "${filteredJobs.length} tasks", 
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),

        // --- LIST VIEW ---
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) => _buildJobCard(context, filteredJobs[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    IconData icon = Icons.check_circle_outline;
    String message = "No jobs found.";

    if (widget.tabType == 'active') {
      icon = Icons.handyman_outlined;
      message = "No active jobs. You're free!";
    } else if (widget.tabType == 'pending_verification') {
      icon = Icons.hourglass_empty;
      message = "No jobs waiting for approval.";
    } else {
      icon = Icons.history;
      message = "No job history yet.";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins', fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, ComplaintModel job) {
    Color statusColor = _getStatusColor(job.status);
    Color priorityColor = _getPriorityColor(job.priority);

    // Icon logic
    IconData statusIcon = Icons.info;
    if (job.status == 'In Progress') statusIcon = Icons.build_circle;
    else if (job.status == 'Pending Verification') statusIcon = Icons.hourglass_top;
    else if (job.status == 'Resolved') statusIcon = Icons.check_circle;
    else if (job.status == 'Invalid') statusIcon = Icons.cancel;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MaintainerJobDetail(job: job)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(job.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Row 2: Title
              Text(
                job.title, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              
              const SizedBox(height: 8),

              // Row 3: Priority & Category Pills
              Row(
                children: [
                  // Priority
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      "${job.priority} Priority", 
                      style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 10, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          job.category, 
                          style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Row 4: Location & Date
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${job.building}, ${job.roomNumber}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  Text(
                    DateFormat('dd MMM yyyy').format(job.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}