import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/simple_video_player.dart';

class ResidentComplaintDetail extends StatefulWidget {
  final ComplaintModel job;

  const ResidentComplaintDetail({super.key, required this.job});

  @override
  State<ResidentComplaintDetail> createState() =>
      _ResidentComplaintDetailState();
}

class _ResidentComplaintDetailState extends State<ResidentComplaintDetail> {
  // --- NEW FUNCTION: OPENS FULL SCREEN GALLERY (Swipe & Zoom) ---
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
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ),
          body: PageView.builder(
            itemCount: urls.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: urls[index],
                    child: Image.network(
                      urls[index],
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.job.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error loading details")),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        ComplaintModel currentJob = ComplaintModel.fromMap(data, widget.job.id);

        Color statusColor = Colors.grey;
        if (currentJob.status == 'In Progress') statusColor = Colors.orange;
        if (currentJob.status == 'Resolved') statusColor = Colors.green;
        if (currentJob.status == 'Pending Verification')
          statusColor = Colors.blue;
        if (currentJob.status == 'Invalid') statusColor = Colors.red;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            title: const Text(
              "Complaint Details",
              style: TextStyle(
                color: Color(0xFF003366),
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF003366),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: STATUS HEADER ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Current Status",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentJob.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                if (currentJob.status == 'Invalid' &&
                    currentJob.adminRemarks != null) ...[
                  const SizedBox(height: 20),
                  _buildRejectionBox(currentJob.adminRemarks!),
                ],

                const SizedBox(height: 32),

                // --- SECTION 2: PREMISE DETAILS ---
                _buildSectionTitle("Premise Details"),
                _buildInfoContainer([
                  _detailRow("Building", currentJob.building ?? "N/A"),
                  _detailRow("Room Number", currentJob.roomNumber ?? "N/A"),
                  _detailRow("Contact", currentJob.contactNumber ?? "N/A"),
                  _detailRow(
                    "Date Reported",
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(currentJob.timestamp),
                  ),
                ]),

                const SizedBox(height: 32),

                // --- SECTION 3: ISSUE DESCRIPTION ---
                _buildSectionTitle("Issue Description"),
                _buildInfoContainer([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // We use _detailRow for the Title to keep the "Label on left, Value on right" look
                      _detailRow("Issue Title", currentJob.title),

                      // We use _detailRow for the Priority/Category to keep alignment
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .end, // Aligns pills to the right like other values
                                children: [
                                  _buildPill(
                                    currentJob.priority,
                                    currentJob.priority == 'High'
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildPill(
                                    currentJob.category,
                                    Colors.blueGrey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),

                      // Description is usually long, so we keep it stacked instead of a Row
                      const SizedBox(height: 8),
                      Text(
                        "Description",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentJob.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ]),

                const SizedBox(height: 32),

                // --- SECTION 4: ORGANIZED EVIDENCE (CLEAN LAYOUT) ---
                // --- SECTION 4: ORGANIZED EVIDENCE (SUGGESTION STYLE) ---
                if (currentJob.imageUrls.isNotEmpty ||
                    (currentJob.videoUrl != null &&
                        currentJob.videoUrl!.isNotEmpty)) ...[
                  _buildSectionTitle("Evidence Attached"),
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
                        // --- Photo Header with Icon and Count ---
                        if (currentJob.imageUrls.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                                color: Color(0xFF003366),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Attached Photos",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${currentJob.imageUrls.length} Pictures",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color.fromARGB(255, 60, 60, 60),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: currentJob.imageUrls.length,
                              itemBuilder: (context, index) =>
                                  _buildModernThumbnail(
                                    context,
                                    currentJob.imageUrls,
                                    index,
                                  ),
                            ),
                          ),
                        ],

                        // --- Divider if both exist ---
                        if (currentJob.imageUrls.isNotEmpty &&
                            currentJob.videoUrl != null &&
                            currentJob.videoUrl!.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),

                        // --- Video Header with Icon ---
                        if (currentJob.videoUrl != null &&
                            currentJob.videoUrl!.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                size: 18,
                                color: Color(0xFF003366),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Video Evidence",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: SimpleVideoPlayer(
                                videoUrl: currentJob.videoUrl!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // --- SECTION 5: MAINTENANCE REPORT ---
                if (currentJob.status != 'Invalid' &&
                    (currentJob.findings.isNotEmpty ||
                        currentJob.actionTaken.isNotEmpty)) ...[
                  _buildSectionTitle("Maintenance Report"),
                  _buildInfoContainer([
                    if (currentJob.findings.isNotEmpty)
                      _detailRow("Findings", currentJob.findings),
                    if (currentJob.actionTaken.isNotEmpty)
                      _detailRow("Action Taken", currentJob.actionTaken),
                  ]),
                  const SizedBox(height: 32),
                ],

                // --- SECTION 6: RATING ---
                if (currentJob.status == 'Resolved')
                  _buildRatingSection(currentJob),

                const SizedBox(height: 40),
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

  Widget _buildInfoContainer(List<Widget> children) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(children: children),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label on the left
          SizedBox(
            width: 120, // Slightly wider since there is no icon taking up space
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

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // --- MODERN CLICKABLE THUMBNAIL ---
  Widget _buildModernThumbnail(
    BuildContext context,
    List<String> urls,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _openGallery(context, urls, index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Hero(
          tag: urls[index],
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              urls[index],
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRejectionBox(String remarks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red, size: 18),
              SizedBox(width: 10),
              Text(
                "Rejection Remarks",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            remarks,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ComplaintModel job) {
    if (job.rating > 0) {
      return _buildInfoContainer([
        const Text(
          "Your Feedback",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Icon(
              index < job.rating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 32,
            ),
          ),
        ),
        if (job.review.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            "\"${job.review}\"",
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ]);
    }
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.star_outline_rounded),
        label: const Text(
          "Rate Service",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _showRatingDialog(job.id),
      ),
    );
  }

  void _showRatingDialog(String complaintId) {
    double tempRating = 5.0;
    String tempReview = "";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Rate Service",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < tempRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () =>
                        setDialogState(() => tempRating = index + 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Optional comment...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                onChanged: (val) => tempReview = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await ComplaintService().submitRating(
                  complaintId,
                  tempRating,
                  tempReview,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Thank you!")));
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
