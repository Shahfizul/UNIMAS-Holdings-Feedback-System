import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/simple_video_player.dart';

class ResidentComplaintDetail extends StatefulWidget {
  final ComplaintModel job;

  const ResidentComplaintDetail({super.key, required this.job});

  @override
  State<ResidentComplaintDetail> createState() => _ResidentComplaintDetailState();
}

class _ResidentComplaintDetailState extends State<ResidentComplaintDetail> {
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.job.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text("Error loading details")));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var data = snapshot.data!.data() as Map<String, dynamic>;
        ComplaintModel currentJob = ComplaintModel.fromMap(data, widget.job.id);

        // 1. UPDATE STATUS COLORS (Added 'Invalid')
        Color statusColor = Colors.grey;
        if (currentJob.status == 'In Progress') statusColor = Colors.orange;
        if (currentJob.status == 'Resolved') statusColor = Colors.green;
        if (currentJob.status == 'Pending Verification') statusColor = Colors.blue;
        if (currentJob.status == 'Invalid') statusColor = Colors.red; // <--- NEW

        return Scaffold(
          appBar: AppBar(
            title: const Text("Complaint Details"),
            backgroundColor: Colors.blue[900],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                      Text("Current Status", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(
                        currentJob.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // --- NEW: REJECTION REASON BOX (Only if Invalid) ---
                if (currentJob.status == 'Invalid' && currentJob.adminRemarks != null) ...[
                  const SizedBox(height: 20),
                  Container(
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
                            Icon(Icons.info_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Why was this rejected?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentJob.adminRemarks!,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),

                // --- SECTION 2: LOCATION & CONTACT ---
                const Text("📍 Premise Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildRow("Building:", currentJob.building),
                      const Divider(),
                      _buildRow("Room:", currentJob.roomNumber),
                      const Divider(),
                      _buildRow("Contact:", currentJob.contactNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- SECTION 3: ISSUE DETAILS ---
                const Text("📄 Issue Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                Text(currentJob.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Chip(
                      label: Text(currentJob.priority),
                      backgroundColor: currentJob.priority == 'High' ? Colors.red[100] : Colors.orange[100],
                    ),
                    const SizedBox(width: 10),
                    Chip(label: Text(currentJob.category)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currentJob.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),

                // --- SECTION 4: PHOTOS ---
                if (currentJob.imageUrls.isNotEmpty) ...[
                  const Text("📸 Evidence Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: currentJob.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              currentJob.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- SECTION 4.5: VIDEO ---
                if (currentJob.videoUrl != null && currentJob.videoUrl!.isNotEmpty) ...[
                  const Text("🎥 Video Evidence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 250, 
                    child: SimpleVideoPlayer(videoUrl: currentJob.videoUrl!),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- SECTION 5: MAINTAINER REPORT (Only if valid) ---
                // We hide this if status is Invalid because no maintenance was done.
                if (currentJob.status != 'Invalid' && (currentJob.findings.isNotEmpty || currentJob.actionTaken.isNotEmpty)) ...[
                  const Divider(thickness: 2),
                  const Text("🛠️ Maintenance Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  if (currentJob.findings.isNotEmpty) ...[
                    const Text("Findings:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currentJob.findings),
                    const SizedBox(height: 10),
                  ],
                  if (currentJob.actionTaken.isNotEmpty) ...[
                    const Text("Action Taken:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currentJob.actionTaken),
                    const SizedBox(height: 10),
                  ],
                ],

                const Divider(height: 40),

                // --- SECTION 6: RATING (Only if Resolved) ---
                if (currentJob.status == 'Resolved') 
                  _buildRatingSection(currentJob),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ComplaintModel job) {
    if (job.rating > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          border: Border.all(color: Colors.amber),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Text("Your Feedback", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < job.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              job.review.isEmpty ? "No written review provided." : "\"${job.review}\"",
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          const Text("How was the service?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.star),
            label: const Text("Rate Service"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () => _showRatingDialog(job.id),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(String complaintId) {
    double tempRating = 5.0; 
    String tempReview = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Rate Service"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Tap stars to rate:"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            tempRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(hintText: "Optional comment...", border: OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (val) => tempReview = val,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    await ComplaintService().submitRating(complaintId, tempRating, tempReview);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}