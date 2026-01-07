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

// The main dashboard for Residents (Students/Staff).
// Displays their complaints categorized by status and allows them to submit new reports or suggestions.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // --- FAB STATE ---
  // Controls the visibility of the expandable Floating Action Button menu
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    // Initialize Notification Service when screen loads.
    // Requests permission and saves the FCM token so the user can receive updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        NotificationService().initNotifications(user.uid);
      }
    });
  }

  // --- LOGOUT DIALOG ---
  // Confirms if the user wants to sign out.
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
  // Creates the small text label next to the mini-FABs (e.g. "Report Issue")
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
    final AuthService auth = AuthService();
    final user = Provider.of<UserModel?>(context);

    // Safety check: Show loading if user data isn't ready
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // StreamProvider listens to the list of complaints submitted by THIS user.
    // We fetch ALL complaints once here, and pass them down to the tabs for filtering.
    return StreamBuilder<List<ComplaintModel>>(
      stream: ComplaintService().getUserComplaints(user.uid),
      builder: (context, snapshot) {
        List<ComplaintModel> allComplaints = snapshot.data ?? [];

        return DefaultTabController(
          // --- 4 TABS ---
          // 1. Requested (Pending)
          // 2. Updates (In Progress/Verify)
          // 3. History (Resolved/Invalid)
          // 4. My Ideas (Suggestions)
          length: 4,
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              centerTitle: true,

              // --- 1. PROFILE MENU (LEFT) ---
              leading: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildProfileMenu(context, auth),
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
                // --- 2. NOTIFICATION BADGE (RIGHT) ---
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: NotificationBadge(userId: user.uid),
                ),
              ],

              // --- TAB BAR CONFIGURATION ---
              bottom: const TabBar(
                isScrollable: false, // Forces tabs to fill width
                labelColor: Color(0xFF003366),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF003366),
                indicatorWeight: 3,
                labelPadding: EdgeInsets.zero,
                labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: "Requested"), // Pending
                  Tab(text: "Updates"),   // In Progress + Verification
                  Tab(text: "History"),   // Resolved + Invalid
                  Tab(text: "My Ideas"),  // Suggestions
                ],
              ),
            ),

            // Expandable Floating Action Button
            floatingActionButton: _buildExpandableFab(context),

            // --- TAB CONTENT ---
            body: Stack(
              children: [
                TabBarView(
                  children: [
                    // Tab 1: Pending (Requested)
                    ResidentComplaintList(allComplaints: allComplaints, filterType: 'pending'),

                    // Tab 2: Updates (In Progress + Verification)
                    ResidentComplaintList(allComplaints: allComplaints, filterType: 'active'),

                    // Tab 3: History (Resolved + Invalid)
                    ResidentComplaintList(allComplaints: allComplaints, filterType: 'history'),

                    // Tab 4: Suggestions (My Ideas)
                    ResidentSuggestionList(userUid: user.uid),
                  ],
                ),
                // Show loading spinner if waiting for initial data
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator()),

                // Overlay to dim background when FAB menu is open
                if (_isMenuOpen)
                  GestureDetector(
                    onTap: () => setState(() => _isMenuOpen = false),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET BREAKDOWNS ---

  // Builds the circular profile icon with a popup menu
  Widget _buildProfileMenu(BuildContext context, AuthService auth) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          _showLogoutDialog(context, auth);
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
      // The trigger icon
      child: Center(
        child: CircleAvatar(
          radius: 15,
          backgroundColor: Colors.grey.shade200,
          child: const Icon(Icons.person, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  // Builds the expandable FAB menu (Report Issue / Send Feedback)
  Widget _buildExpandableFab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Button 1: Send Feedback
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _isMenuOpen ? 1.0 : 0.0,
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
        const SizedBox(height: 12),
        // Button 2: Report Issue
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isMenuOpen ? 1.0 : 0.0,
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
        const SizedBox(height: 12),
        // Main Trigger Button (Rotates when open)
        FloatingActionButton(
          heroTag: "mainFab",
          backgroundColor: _isMenuOpen ? Colors.grey[300] : const Color.fromARGB(255, 24, 109, 149),
          onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: _isMenuOpen ? 0.375 : 0, // Rotates 135 degrees
            child: Icon(
                Icons.add,
                color: _isMenuOpen ? Colors.black87 : Colors.white,
                size: 28
            ),
          ),
        ),
      ],
    );
  }
}

// --- RESIDENT SUGGESTION LIST COMPONENT ---
// Displays the "My Ideas" tab content.
class ResidentSuggestionList extends StatefulWidget {
  final String userUid;
  const ResidentSuggestionList({super.key, required this.userUid});

  @override
  State<ResidentSuggestionList> createState() => _ResidentSuggestionListState();
}

class _ResidentSuggestionListState extends State<ResidentSuggestionList> {
  String _sortBy = 'Latest';

  // Helper for Category Colors
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Safety & Security': return Colors.red;
      case 'IT & Wi-Fi': return Colors.blue;
      case 'Facility Improvement': return Colors.orange;
      case 'Cleanliness': return Colors.green;
      case 'Event Idea': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // Helper for Category Icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Safety & Security': return Icons.security;
      case 'IT & Wi-Fi': return Icons.wifi;
      case 'Facility Improvement': return Icons.build;
      case 'Cleanliness': return Icons.cleaning_services;
      case 'Event Idea': return Icons.event;
      default: return Icons.lightbulb_outline;
    }
  }

  // Bottom sheet to select sorting order
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
    // Fetches suggestions specific to this user
    return StreamProvider<List<SuggestionModel>>.value(
      value: SuggestionService().getUserSuggestions(widget.userUid),
      initialData: const [],
      child: Consumer<List<SuggestionModel>>(
        builder: (context, suggestions, child) {
          // Sort the list locally based on _sortBy state
          List<SuggestionModel> displayList = List.from(suggestions);
          displayList.sort((a, b) => _sortBy == 'Latest'
              ? b.timestamp.compareTo(a.timestamp)
              : a.timestamp.compareTo(b.timestamp));

          return Column(
            children: [
              // Filter/Sort Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.sort, size: 16, color: Colors.teal),
                      label: Text("Sort: $_sortBy", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.teal)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: _showSortOptions,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // List Content
              Expanded(
                child: displayList.isEmpty
                    ? const Center(child: Text("No suggestions yet.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    return _buildSuggestionCard(context, displayList[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // UI for a single suggestion item
  Widget _buildSuggestionCard(BuildContext context, SuggestionModel item) {
    final catColor = _getCategoryColor(item.category);
    final catIcon = _getCategoryIcon(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SuggestionDetailScreen(suggestion: item))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catIcon, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 16),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Category Text
                              Text(
                                item.category.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5),
                              ),
                              const Spacer(),
                              // Date
                              Text(
                                DateFormat('dd MMM').format(item.timestamp),
                                style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Title
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),

                // Description Preview (Optional)
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- RESIDENT COMPLAINT LIST COMPONENT ---
// Reusable list for the "Requested", "Updates", and "History" tabs.
class ResidentComplaintList extends StatefulWidget {
  final List<ComplaintModel> allComplaints;
  final String filterType; // 'pending', 'active', 'history'

  const ResidentComplaintList({super.key, required this.allComplaints, required this.filterType});

  @override
  State<ResidentComplaintList> createState() => _ResidentComplaintListState();
}

class _ResidentComplaintListState extends State<ResidentComplaintList> {
  String _sortBy = 'Latest';
  String _priorityFilter = 'All';

  // --- COLOR HELPERS ---
  Color _getStatusColor(String status) {
    if (status == 'Pending') return Colors.orange;
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

  // Filter Bottom Sheet
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
                const Text("Date Order", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
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
                const SizedBox(height: 20),
                const Text("Priority Level", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
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
    // 1. Filter by Tab Logic (using filterType passed from parent)
    List<ComplaintModel> filteredList = widget.allComplaints.where((job) {
      if (widget.filterType == 'pending') {
        return job.status == 'Pending';
      } else if (widget.filterType == 'active') {
        return job.status == 'In Progress' || job.status == 'Pending Verification';
      } else {
        // history
        return job.status == 'Resolved' || job.status == 'Invalid';
      }
    }).toList();

    // 2. Filter by Priority (if selected)
    if (_priorityFilter != "All") {
      filteredList = filteredList.where((job) => job.priority == _priorityFilter).toList();
    }

    // 3. Sort by Date
    filteredList.sort((a, b) => _sortBy == 'Latest'
        ? b.timestamp.compareTo(a.timestamp)
        : a.timestamp.compareTo(b.timestamp));

    return Column(
      children: [
        // --- FILTER BAR ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.tune, size: 16, color: Color(0xFF003366)),
                label: Text("Sort & Priority ($_priorityFilter)", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF003366))),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: _showFilterOptions,
              ),
              const Spacer(),
              Text(
                  "${filteredList.length} items",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // --- LIST VIEW ---
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) => _buildJobCard(context, filteredList[index]),
          ),
        ),
      ],
    );
  }

  // --- EMPTY STATE UI ---
  Widget _buildEmptyState() {
    String message = "No items found.";
    IconData icon = Icons.history_edu;

    if (widget.filterType == 'pending') {
      message = "No pending requests.";
      icon = Icons.send_and_archive;
    } else if (widget.filterType == 'active') {
      message = "No active work in progress.";
      icon = Icons.build_circle_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 16, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  // --- JOB CARD COMPONENT ---
  // Visual representation of a complaint.
  Widget _buildJobCard(BuildContext context, ComplaintModel job) {
    Color statusColor = _getStatusColor(job.status);
    Color priorityColor = _getPriorityColor(job.priority);

    // Icon logic
    IconData statusIcon = Icons.info;
    if (job.status == 'In Progress') statusIcon = Icons.build_circle;
    else if (job.status == 'Pending') statusIcon = Icons.hourglass_empty;
    else if (job.status == 'Resolved') statusIcon = Icons.check_circle;
    else if (job.status == 'Pending Verification') statusIcon = Icons.fact_check;
    else if (job.status == 'Invalid') statusIcon = Icons.cancel;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Navigate to details screen on tap
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ResidentComplaintDetail(job: job))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Status + Menu Arrow
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
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
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

              // Rejected Message Highlight (Only if Invalid)
              if (job.status == 'Invalid') ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "Reason: ${job.adminRemarks ?? 'No reason given'}",
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],

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