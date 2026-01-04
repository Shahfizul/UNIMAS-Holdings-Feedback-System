import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Models & Services
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
import '../../models/suggestion_model.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/suggestion_service.dart';
import '../../services/notification_service.dart';

// Screens
import '../complaint/report_screen.dart';
import '../complaint/resident_complaint_detail.dart';
import '../suggestion/suggestion_screen.dart';
import '../suggestion/suggestion_detail_screen.dart';
import '../../widgets/notification_badge.dart';
import '../home/user_profile_page.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // --- FAB STATE ---
  bool _isMenuOpen = false;

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

  // --- LOGOUT DIALOG ---
  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Logout",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          content: const Text(
            "Are you sure you want to exit the system?",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- FAB LABEL HELPER ---
  Widget _buildFabLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<List<ComplaintModel>>(
      stream: ComplaintService().getUserComplaints(user.uid),
      builder: (context, snapshot) {
        List<ComplaintModel> allComplaints = snapshot.data ?? [];

        return DefaultTabController(
          length: 3,
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
                      _showLogoutDialog(context, _auth);
                    } else if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
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
                  const Text(
                    'UNIMAS Holdings Sdn Bhd',
                    style: TextStyle(
                      color: Color(0xFF003366),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Complaint System'.toUpperCase(),
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
              bottom: const TabBar(
                labelColor: Color(0xFF003366),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF003366),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: "Active Issues"),
                  Tab(text: "History Log"),
                  Tab(text: "My Ideas"),
                ],
              ),
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isMenuOpen ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    offset: _isMenuOpen ? Offset.zero : const Offset(0, 0.5),
                    child: Visibility(
                      visible: _isMenuOpen,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFabLabel("Send Feedback"),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: "suggestionBtn",
                            mini: true,
                            backgroundColor: Colors.teal,
                            onPressed: () {
                              setState(() => _isMenuOpen = false);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionScreen()));
                            },
                            child: const Icon(Icons.lightbulb_outline, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isMenuOpen ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 200),
                    offset: _isMenuOpen ? Offset.zero : const Offset(0, 0.5),
                    child: Visibility(
                      visible: _isMenuOpen,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFabLabel("Report Issue"),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: "reportBtn",
                            mini: true,
                            backgroundColor: const Color(0xFF003366),
                            onPressed: () {
                              setState(() => _isMenuOpen = false);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
                            },
                            child: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "mainFab",
                  backgroundColor: _isMenuOpen ? Colors.grey[300] : const Color.fromARGB(255, 24, 109, 149),
                  onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isMenuOpen ? 0.375 : 0,
                    child: Icon(
                      Icons.add, 
                      color: _isMenuOpen ? Colors.black87 : Colors.white, 
                      size: 28
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                TabBarView(
                  children: [
                    ResidentComplaintList(allComplaints: allComplaints, isHistory: false),
                    ResidentComplaintList(allComplaints: allComplaints, isHistory: true),
                    ResidentSuggestionList(userUid: user.uid),
                  ],
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator()),
                
                if (_isMenuOpen)
                  GestureDetector(
                    onTap: () => setState(() => _isMenuOpen = false),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- UPDATED SUGGESTION LIST WITH FILTER ---
class ResidentSuggestionList extends StatefulWidget {
  final String userUid;
  const ResidentSuggestionList({super.key, required this.userUid});

  @override
  State<ResidentSuggestionList> createState() => _ResidentSuggestionListState();
}

class _ResidentSuggestionListState extends State<ResidentSuggestionList> {
  String _sortBy = 'Latest';

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Sort Suggestions", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text("Latest to Oldest", style: TextStyle(fontFamily: 'Poppins')),
                trailing: _sortBy == 'Latest' ? const Icon(Icons.check, color: Colors.teal) : null,
                onTap: () { setState(() => _sortBy = 'Latest'); Navigator.pop(context); },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text("Oldest to Latest", style: TextStyle(fontFamily: 'Poppins')),
                trailing: _sortBy == 'Oldest' ? const Icon(Icons.check, color: Colors.teal) : null,
                onTap: () { setState(() => _sortBy = 'Oldest'); Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<SuggestionModel>>.value(
      value: SuggestionService().getUserSuggestions(widget.userUid),
      initialData: const [],
      child: Consumer<List<SuggestionModel>>(
        builder: (context, suggestions, child) {
          List<SuggestionModel> displayList = List.from(suggestions);
          displayList.sort((a, b) => _sortBy == 'Latest' 
              ? b.timestamp.compareTo(a.timestamp) 
              : a.timestamp.compareTo(b.timestamp));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.sort, size: 16, color: Colors.teal),
                    label: Text(_sortBy, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.teal)),
                    backgroundColor: Colors.white,
                    
                    onPressed: _showSortOptions,
                  ),
                ),
              ),
              Expanded(
                child: displayList.isEmpty 
                  ? const Center(child: Text("No suggestions yet.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final item = displayList[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200, width: 1)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withOpacity(0.1),
                              child: const Icon(Icons.lightbulb, color: Colors.teal),
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              "${item.category} • ${DateFormat('dd MMM').format(item.timestamp)}",
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SuggestionDetailScreen(suggestion: item))),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- UPDATED COMPLAINT LIST WITH FILTERS ---
class ResidentComplaintList extends StatefulWidget {
  final List<ComplaintModel> allComplaints;
  final bool isHistory;

  const ResidentComplaintList({super.key, required this.allComplaints, required this.isHistory});

  @override
  State<ResidentComplaintList> createState() => _ResidentComplaintListState();
}

class _ResidentComplaintListState extends State<ResidentComplaintList> {
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
                const Text("Sort & Filter", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                const Text("Date Order", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                const Text("Priority Level", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    // 1. Filter by History status
    List<ComplaintModel> filteredList = widget.allComplaints.where((job) {
      if (widget.isHistory) {
        return job.status == 'Resolved' || job.status == 'Pending Verification' || job.status == 'Invalid';
      } else {
        return job.status == 'Pending' || job.status == 'In Progress';
      }
    }).toList();

    // 2. Filter by Priority
    if (_priorityFilter != "All") {
      filteredList = filteredList.where((job) => job.priority == _priorityFilter).toList();
    }

    // 3. Sort by Date
    filteredList.sort((a, b) => _sortBy == 'Latest' 
      ? b.timestamp.compareTo(a.timestamp) 
      : a.timestamp.compareTo(b.timestamp));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.filter_list, size: 16, color: Color(0xFF003366)),
                label: Text("Filters: $_sortBy • $_priorityFilter", 
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF003366))),
                backgroundColor: Colors.white,
                onPressed: _showFilterOptions,
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) => _buildJobCard(context, filteredList[index]),
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
          Icon(widget.isHistory ? Icons.history : Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(widget.isHistory ? "No past history." : "No active complaints.", 
            style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, ComplaintModel job) {
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
        title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ResidentComplaintDetail(job: job))),
      ),
    );
  }
}