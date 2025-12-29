import 'package:flutter/material.dart';
import '../../models/suggestion_model.dart';
import '../../widgets/simple_video_player.dart';

class SuggestionDetailScreen extends StatelessWidget {
  final SuggestionModel suggestion;

  const SuggestionDetailScreen({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suggestion Details"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${suggestion.userType} • ${suggestion.matricNo}", style: TextStyle(color: Colors.grey[600])),
                      Text(suggestion.contactNumber, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Text(suggestion.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Chip(label: Text(suggestion.category), backgroundColor: Colors.teal[50]),
            const SizedBox(height: 10),
            Text(suggestion.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Photos
            if (suggestion.imageUrls.isNotEmpty) ...[
              const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestion.imageUrls.length,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(suggestion.imageUrls[index]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Video
            if (suggestion.videoUrl != null) ...[
              const Text("Video", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: SimpleVideoPlayer(videoUrl: suggestion.videoUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}