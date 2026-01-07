import 'package:flutter/material.dart';
import '../../models/suggestion_model.dart';
import '../../widgets/simple_video_player.dart';

// Screen for displaying the full details of a specific Suggestion/Feedback.
// Used by both Admins (to review ideas) and Residents (to view their own submissions).
class SuggestionDetailScreen extends StatelessWidget {
  final SuggestionModel suggestion;

  const SuggestionDetailScreen({super.key, required this.suggestion});

  // --- GALLERY VIEWER ---
  // Opens a full-screen, zoomable image viewer for the attached photos.
  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              "${initialIndex + 1} / ${suggestion.imageUrls.length}",
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ),
          // PageView allows swiping between multiple images
          body: PageView.builder(
            itemCount: suggestion.imageUrls.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0, // Allows zooming in up to 4x
                child: Center(
                  child: Hero(
                    tag: suggestion.imageUrls[index],
                    child: Image.network(
                      suggestion.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if media exists to determine layout
    bool hasPhotos = suggestion.imageUrls.isNotEmpty;
    bool hasVideo = suggestion.videoUrl != null && suggestion.videoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          "Suggestion Details",
          style: TextStyle(
            color: Color(0xFF003366),
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF003366), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: HEADER (Title & Category) ---
            _buildHeader(),

            const SizedBox(height: 32),

            // --- SECTION 2: DESCRIPTION CONTENT ---
            _buildSectionTitle("Improvement Idea"),
            _buildDescriptionBox(suggestion.description),

            const SizedBox(height: 32),

            // --- SECTION 3: SUBMITTER DETAILS ---
            _buildSectionTitle("Submitter Details"),
            _buildInfoCard([
              _detailRow("Full Name", suggestion.fullName),
              _detailRow("ID / Matric", suggestion.matricNo),
              _detailRow("User Type", suggestion.userType),
              _detailRow("Contact", suggestion.contactNumber),
            ]),

            const SizedBox(height: 32),

            // --- SECTION 4: MEDIA ATTACHMENTS ---
            // Only visible if photos or videos are attached
            if (hasPhotos || hasVideo) ...[
              _buildSectionTitle("Attachments"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Gallery (Horizontal List)
                    if (hasPhotos) ...[
                      Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF003366)),
                          const SizedBox(width: 8),
                          const Text(
                            "Attached Photos",
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            "${suggestion.imageUrls.length} Pictures",
                            style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 60, 60, 60)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestion.imageUrls.length,
                          itemBuilder: (context, index) => _buildModernThumbnail(context, index),
                        ),
                      ),
                    ],

                    // Divider if both photo and video exist
                    if (hasPhotos && hasVideo)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),

                    // Video Player
                    if (hasVideo) ...[
                      const Row(
                        children: [
                          Icon(Icons.videocam_outlined, size: 18, color: Color(0xFF003366)),
                          const SizedBox(width: 8),
                          Text(
                            "Video Presentation",
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          child: SimpleVideoPlayer(videoUrl: suggestion.videoUrl!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // --- REUSABLE UI HELPERS ---

  // Top box containing the Title and Category Pill
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text("My Idea", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Poppins')),
          const SizedBox(height: 5),
          Text(
            suggestion.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF003366),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          _buildPill(suggestion.category, const Color.fromARGB(255, 93, 171, 235)),
        ],
      ),
    );
  }

  // Standard section header text
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          fontSize: 15,
          color: Color(0xFF003366),
        ),
      ),
    );
  }

  // Box for the main description text
  Widget _buildDescriptionBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87, height: 1.6, fontSize: 14),
      ),
    );
  }

  // Card for personal details (Name, ID, etc.)
  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(children: children),
      ),
    );
  }

  // Single row for info card (Label ...... Value)
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label on the left
          SizedBox(
            width: 120, // Fixed width for alignment
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Value on the right
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Colored tag/chip for the category
  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
      ),
    );
  }

  // Thumbnail widget for images with a zoom icon overlay
  Widget _buildModernThumbnail(BuildContext context, int index) {
    final String url = suggestion.imageUrls[index];
    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with Hero animation for smooth transitions
            Hero(
              tag: url,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Zoom icon overlay
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.zoom_out_map, size: 12, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}