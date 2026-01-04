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
import '../home/user_profile_page.dart'; // Reusing profile page if applicable

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

  // --- LOGOUT DIALOG (Matches User UI) ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Logout",
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          content: const Text(
            "Are you sure you want to exit the system?",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
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
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  } else if (value == 'profile') {
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
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout, color: Colors.red, size: 20),
                      title: Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                child: Center(
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MAINTENANCE UNIT',
                  style: TextStyle(
                    color: Colors.yellow.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Staff Work Portal'.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: NotificationBadge(userId: user.uid),
              ),
            ],
            bottom: TabBar(
              labelColor: Colors.yellow.shade900,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(text: "Active Jobs"),
                Tab(text: "Work History"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              JobTabList(statusFilter: 'In Progress'),
              JobTabList(statusFilter: 'History'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW COMPONENT: JOB TAB LIST WITH INDIVIDUAL FILTERS ---
class JobTabList extends StatefulWidget {
  final String statusFilter;
  const JobTabList({super.key, required this.statusFilter});

  @override
  State<JobTabList> createState() => _JobTabListState();
}

class _JobTabListState extends State<JobTabList> {
  String _sortBy = 'Latest';
  String _priorityFilter = 'All';

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sort & Filter Jobs", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                const Text("Order", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Latest"),
                      selected: _sortBy == 'Latest',
                      onSelected: (s) { setState(() => _sortBy = 'Latest'); setModalState(() {}); },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Oldest"),
                      selected: _sortBy == 'Oldest',
                      onSelected: (s) { setState(() => _sortBy = 'Oldest'); setModalState(() {}); },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Priority", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                Wrap(
                  spacing: 8,
                  children: ["All", "Low", "Medium", "High"].map((p) => ChoiceChip(
                    label: Text(p),
                    selected: _priorityFilter == p,
                    onSelected: (s) { setState(() => _priorityFilter = p); setModalState(() {}); },
                  )).toList(),
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
    
    // 1. Filter by Status
    List<ComplaintModel> filteredJobs;
    if (widget.statusFilter == 'In Progress') {
      filteredJobs = allJobs.where((job) => job.status == 'In Progress').toList();
    } else {
      filteredJobs = allJobs.where((job) => 
        job.status == 'Pending Verification' || job.status == 'Resolved'
      ).toList();
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
        // Professional Filter Chip (Matches User interface)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ActionChip(
                avatar: Icon(Icons.tune, size: 16, color: Colors.yellow.shade800,),
                label: Text("Sort: $_sortBy • $_priorityFilter", 
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.yellow.shade900)),
                backgroundColor: Colors.white,
                onPressed: _showFilterOptions,
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) => _buildJobCard(context, filteredJobs[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.statusFilter == 'In Progress' ? Icons.task_alt : Icons.history, 
            size: 80, color: Colors.grey[200]
          ),
          const SizedBox(height: 10),
          Text(
            widget.statusFilter == 'In Progress' ? "No active work orders." : "No job history yet.",
            style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, ComplaintModel job) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Icon(
            widget.statusFilter == 'In Progress' ? Icons.build_circle : Icons.verified, 
            color: Colors.orange
          ),
        ),
        title: Text(
          job.title, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Poppins'),
          maxLines: 1, 
          overflow: TextOverflow.ellipsis
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("${job.category} • ${job.priority} Priority", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MaintainerJobDetail(job: job)),
          );
        },
      ),
    );
  }
}