import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/simple_video_player.dart';

// Screen for Residents to view the full details and progress of their submitted complaint.
// Allows them to see status updates, maintenance reports, and submit feedback/ratings.
class ResidentComplaintDetail extends StatefulWidget {
  final ComplaintModel job;

  const ResidentComplaintDetail({super.key, required this.job});

  @override
  State<ResidentComplaintDetail> createState() => _ResidentComplaintDetailState();
}

class _ResidentComplaintDetailState extends State<ResidentComplaintDetail> {

  // --- COLOR HELPERS ---
  // Returns specific colors for different status tags
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'In Progress': return Colors.blue;
      case 'Pending Verification': return Colors.purple;
      case 'Resolved': return Colors.green;
      case 'Invalid': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Returns specific colors for priority levels
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  // --- OPENS FULL SCREEN GALLERY ---
  // Allows the user to view their attached images in a zoomable full-screen viewer.
  void _openGallery(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              "${initialIndex + 1} / ${urls.length}",
              style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14),
            ),
          ),
          body: PageView.builder(
            itemCount: urls.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: urls[index],
                    child: Image.network(urls[index], fit: BoxFit.contain),
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
    // Listen to the specific complaint document for real-time updates.
    // This ensures the resident sees status changes (e.g., "In Progress" -> "Resolved") instantly.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').doc(widget.job.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        // Convert Firestore data back to ComplaintModel
        var data = snapshot.data!.data() as Map<String, dynamic>;
        ComplaintModel job = ComplaintModel.fromMap(data, widget.job.id);

        Color statusColor = _getStatusColor(job.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            title: const Text(
              "Complaint Details",
              style: TextStyle(color: Color(0xFF003366), fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF003366), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: STATUS HEADER ---
                // Displays the current status of the complaint clearly at the top.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Text("CURRENT STATUS", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontFamily: 'Poppins', letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(job.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    ],
                  ),
                ),

                // If Admin rejected/invalidated the complaint, show the reason here.
                if (job.status == 'Invalid' && job.adminRemarks != null) ...[
                  const SizedBox(height: 20),
                  _buildRejectionBox(job.adminRemarks!),
                ],

                const SizedBox(height: 24),

                // --- SECTION 2: ISSUE DETAILS ---
                // Shows the Title, Priority, Category, and Description provided by the resident.
                _buildSectionTitle("Issue Information"),
                _buildInfoContainer([
                  _detailRow("Job Title", job.title),

                  // Pills Row (Priority & Category tags)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildPill(job.priority, _getPriorityColor(job.priority)),
                        const SizedBox(width: 8),
                        _buildPill(job.category, Colors.blueGrey),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 12),

                  // Description Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Description",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.description,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, fontFamily: 'Poppins', color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ]),

                const SizedBox(height: 24),

                // --- SECTION 3: LOCATION ---
                // Shows where the issue is located.
                _buildSectionTitle("Location Details"),
                _buildInfoContainer([
                  _detailRow("Building", job.building),
                  _detailRow("Room Number", job.roomNumber),
                  _detailRow("Date Reported", DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp)),
                ]),

                const SizedBox(height: 24),

                // --- SECTION 4: EVIDENCE ---
                // Displays thumbnails of images and the video player if attachments exist.
                if (job.imageUrls.isNotEmpty || (job.videoUrl != null && job.videoUrl!.isNotEmpty)) ...[
                  _buildSectionTitle("Your Attachments"),
                  _buildEvidenceContainer(job),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 5: MAINTENANCE REPORT (If done) ---
                // Once the maintainer resolves the issue, this section appears showing what was done.
                if (job.status == 'Resolved' || job.status == 'Pending Verification') ...[
                  _buildSectionTitle("Maintenance Report"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_turned_in, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Work Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const Divider(height: 20),
                        _detailRow("Findings", job.findings.isNotEmpty ? job.findings : "N/A"),
                        _detailRow("Action Taken", job.actionTaken.isNotEmpty ? job.actionTaken : "N/A"),
                        _detailRow("Result", job.inspectionResult.isNotEmpty ? job.inspectionResult : "N/A"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 6: RATING ---
                // If the job is fully Resolved, show the rating section.
                // It either shows the "Rate Service" button or the submitted review.
                if (job.status == 'Resolved') ...[
                  _buildSectionTitle("Feedback"),
                  _buildRatingSection(job),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 15, color: Color(0xFF003366))),
    );
  }

  // Helper to wrap content in a white, shadowed card
  Widget _buildInfoContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Helper for simple key-value rows
  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w500))),
          Expanded(child: Text(value ?? 'N/A', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Poppins', color: Colors.black87))),
        ],
      ),
    );
  }

  // Helper for colored tags (Priority/Category)
  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
    );
  }

  // Red box to display rejection/invalid remarks
  Widget _buildRejectionBox(String remarks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.info_outline, color: Colors.red, size: 20), SizedBox(width: 10), Text("Rejection Remarks", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'Poppins'))]),
          const SizedBox(height: 8),
          Text(remarks, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  // Horizontal scroller for images and video player
  Widget _buildEvidenceContainer(ComplaintModel job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.imageUrls.isNotEmpty) ...[
            const Row(children: [Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF003366)), SizedBox(width: 8), Text("Photos", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: job.imageUrls.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _openGallery(context, job.imageUrls, index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(job.imageUrls[index], fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (job.videoUrl != null && job.videoUrl!.isNotEmpty) ...[
            if (job.imageUrls.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
            const Row(children: [Icon(Icons.videocam_outlined, size: 18, color: Color(0xFF003366)), SizedBox(width: 8), Text("Video", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: 200, child: SimpleVideoPlayer(videoUrl: job.videoUrl!)),
            ),
          ]
        ],
      ),
    );
  }

  // Determines whether to show the "Rate Now" button or the "Feedback" display
  Widget _buildRatingSection(ComplaintModel job) {
    if (job.rating > 0) {
      // If already rated, show the stars and review
      return _buildInfoContainer([
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => Icon(index < job.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32)),
        ),
        if (job.review.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text("\"${job.review}\"", style: const TextStyle(fontStyle: FontStyle.italic, fontFamily: 'Poppins'), textAlign: TextAlign.center),
        ],
      ]);
    }
    // If not rated, show button
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.star_rate_rounded, color: Colors.black87),
        label: const Text("Rate Service", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black87)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: () => _showRatingDialog(job.id),
      ),
    );
  }

  // --- FIXED RATING DIALOG ---
  // Popup allows user to select stars (1-5) and write a comment.
  void _showRatingDialog(String complaintId) {
    double tempRating = 5.0;
    String tempReview = "";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Rate Service", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. REPLACED IconButton WITH GestureDetector FOR EXACT SIZING
              // 2. WRAPPED IN FittedBox TO PREVENT OVERFLOW ON SMALL SCREENS
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => tempRating = index + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Consistent spacing
                        child: Icon(
                          index < tempRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 40, // Nice large touch target
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: "Optional comment...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 2,
                onChanged: (val) => tempReview = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
              onPressed: () async {
                // Submit rating to Firebase
                await ComplaintService().submitRating(complaintId, tempRating, tempReview);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}