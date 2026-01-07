import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/suggestion_model.dart';
import '../../services/suggestion_service.dart';
import '../../screens/suggestion/suggestion_detail_screen.dart';

// Screen for Admins to view a list of all user suggestions/feedback.
// Features include filtering by category, sorting by New/Unread, and marking items as read.
class AdminSuggestionList extends StatefulWidget {
  const AdminSuggestionList({super.key});

  @override
  State<AdminSuggestionList> createState() => _AdminSuggestionListState();
}

class _AdminSuggestionListState extends State<AdminSuggestionList> {
  // --- STATE VARIABLES ---
  // Tracks the currently selected filter category (defaults to 'All')
  String _selectedCategory = 'All';

  // Hardcoded list of categories matching the ones users can select
  final List<String> _suggestionCategories = [
    'All',
    'Safety & Security',
    'IT & Wi-Fi',
    'Facility Improvement',
    'Cleanliness',
    'Event Idea',
    'General'
  ];

  // --- HELPER: CATEGORY COLORS ---
  // Returns a specific color based on the suggestion category for visual distinction
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

  // --- HELPER: CATEGORY ICONS ---
  // Returns a specific icon based on the suggestion category
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

  @override
  Widget build(BuildContext context) {
    // StreamProvider listens to the stream of all suggestions from Firestore.
    // This ensures the list updates in real-time when new feedback arrives.
    return StreamProvider<List<SuggestionModel>>.value(
      value: SuggestionService().allSuggestions,
      initialData: const [],
      child: Consumer<List<SuggestionModel>>(
        builder: (context, suggestions, child) {

          // 1. FILTER LOGIC
          // Create a new list containing only items matching the selected category
          List<SuggestionModel> filteredList = suggestions.where((item) {
            if (_selectedCategory == 'All') return true;
            return item.category == _selectedCategory;
          }).toList();

          // 2. SORT LOGIC
          // Custom sort: Unread ('isRead' is false) items appear at the top.
          // Secondary sort: Newest timestamp first.
          filteredList.sort((a, b) {
            if (a.isRead != b.isRead) {
              return a.isRead ? 1 : -1; // Unread comes first
            }
            return b.timestamp.compareTo(a.timestamp); // Then compare dates
          });

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
            body: Column(
              children: [
                // --- TOP HEADER & DROPDOWN ---
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stats Text (shows count of filtered items)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Feedback Inbox",
                            style: TextStyle(
                              color: Colors.blueGrey[800],
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                              "${filteredList.length} Items",
                              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),

                      // CLEAN DROPDOWN FOR FILTERING
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _suggestionCategories.contains(_selectedCategory) ? _selectedCategory : 'All',
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF003366)),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF003366), fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                            borderRadius: BorderRadius.circular(12),
                            items: _suggestionCategories.map((String c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val!),
                          ),
                        ),
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
                    itemBuilder: (context, index) {
                      return _buildSuggestionItem(context, filteredList[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- EMPTY STATE ---
  // Displayed when there are no suggestions matching the filter.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
            child: Icon(Icons.inbox_outlined, size: 50, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text("No suggestions found.", style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  // --- ITEM BUILDER (With Swipe Actions) ---
  // Wraps the card in a Dismissible widget so Admins can swipe to "Mark as Read".
  Widget _buildSuggestionItem(BuildContext context, SuggestionModel item) {
    // Only allow swiping if it's currently unread
    return item.isRead
        ? _buildSuggestionCard(context, item)
        : Dismissible(
      key: Key(item.id),
      direction: DismissDirection.startToEnd, // Swipe Left-to-Right
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(children: [Icon(Icons.check, color: Colors.white), SizedBox(width: 10), Text("Mark Read", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
      ),
      onDismissed: (direction) {
        // Call service to update 'isRead' in Firestore
        SuggestionService().markAsRead(item.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked as Read"), duration: Duration(milliseconds: 700)));
      },
      child: _buildSuggestionCard(context, item),
    );
  }

  // --- MAIN CARD UI ---
  // Displays the content of the suggestion.
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
        // Highlights Unread items with a subtle blue border
        border: !item.isRead ? Border.all(color: const Color(0xFF003366).withOpacity(0.3), width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Mark as read when opened
            if (!item.isRead) SuggestionService().markAsRead(item.id);
            // Navigate to full details
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SuggestionDetailScreen(suggestion: item)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Category + Date
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

                          // Title (Bold if unread)
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Subtitle (Submitter Name)
                          Row(
                            children: [
                              Icon(Icons.person, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                item.fullName,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right Side: "NEW" Badge or Arrow
                    const SizedBox(width: 12),
                    if (!item.isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "NEW",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
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