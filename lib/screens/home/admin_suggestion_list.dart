import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/suggestion_model.dart';
import '../../services/suggestion_service.dart';
import '../../screens/suggestion/suggestion_detail_screen.dart';

class AdminSuggestionList extends StatelessWidget {
  const AdminSuggestionList({super.key});

  // --- Helper for Category Colors ---
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
          if (suggestions.isEmpty) {
            return const Center(child: Text("No suggestions yet.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final item = suggestions[index];
              final catColor = _getCategoryColor(item.category);

              return Card(
                elevation: item.isRead ? 1 : 4, // Higher shadow for unread
                margin: const EdgeInsets.only(bottom: 12),
                color: item.isRead ? Colors.white : Colors.blue[50], // Tint unread items
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: catColor.withOpacity(0.2),
                    child: Icon(Icons.lightbulb, color: catColor),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // --- UNREAD DOT ---
                      if (!item.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
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
                          border: Border.all(color: catColor.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.fullName} • ${DateFormat('dd MMM').format(item.timestamp)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Mark as read immediately when tapped
                    if (!item.isRead) {
                      SuggestionService().markAsRead(item.id);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SuggestionDetailScreen(suggestion: item)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}