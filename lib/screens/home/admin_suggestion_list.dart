import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/suggestion_model.dart';
import '../../services/suggestion_service.dart';
import '../../screens/suggestion/suggestion_detail_screen.dart';

class AdminSuggestionList extends StatefulWidget {
  const AdminSuggestionList({super.key});

  @override
  State<AdminSuggestionList> createState() => _AdminSuggestionListState();
}

class _AdminSuggestionListState extends State<AdminSuggestionList> {
  String _selectedCategory = 'All';

  // Define categories to match user submission form
  final List<String> _suggestionCategories = [
    'All',
    'Safety & Security',
    'IT & Wi-Fi',
    'Facility Improvement',
    'Cleanliness',
    'Event Idea',
    'General'
  ];

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

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<SuggestionModel>>.value(
      value: SuggestionService().allSuggestions,
      initialData: const [],
      child: Consumer<List<SuggestionModel>>(
        builder: (context, suggestions, child) {
          
          // 1. FILTER LOGIC
          List<SuggestionModel> filteredList = suggestions.where((item) {
            if (_selectedCategory == 'All') return true;
            return item.category == _selectedCategory;
          }).toList();

          return Column(
            children: [
              // --- FILTER BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, color: Colors.teal),
                    const SizedBox(width: 10),
                    const Text("Filter by:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _suggestionCategories.contains(_selectedCategory) ? _selectedCategory : 'All',
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                            items: _suggestionCategories.map((String c) {
                              return DropdownMenuItem<String>(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- LIST VIEW ---
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(child: Text("No suggestions found.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final catColor = _getCategoryColor(item.category);

                          return Card(
                            elevation: item.isRead ? 1 : 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: item.isRead ? Colors.white : Colors.blue[50],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: catColor.withOpacity(0.2),
                                child: Icon(Icons.lightbulb, color: catColor),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(item.category, style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${item.fullName} • ${DateFormat('dd MMM').format(item.timestamp)}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () {
                                if (!item.isRead) SuggestionService().markAsRead(item.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SuggestionDetailScreen(suggestion: item)),
                                );
                              },
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