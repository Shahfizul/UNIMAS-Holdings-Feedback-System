import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../widgets/simple_video_player.dart';

class MaintainerJobDetail extends StatefulWidget {
  final ComplaintModel job;

  const MaintainerJobDetail({super.key, required this.job});

  @override
  State<MaintainerJobDetail> createState() => _MaintainerJobDetailState();
}

class _MaintainerJobDetailState extends State<MaintainerJobDetail> {
  
  // --- COLOR RULES ---
  Color _getPriorityColor(String priority) {
    if (priority == 'High') return Colors.red;
    if (priority == 'Medium') return Colors.orange; 
    if (priority == 'Low') return Colors.green;
    return Colors.grey;
  }

  Color _getStatusColor(String status) {
    if (status == 'Pending') return Colors.orange; // Though Maintainer won't see "Pending" usually
    if (status == 'In Progress') return Colors.blue;
    if (status == 'Pending Verification') return Colors.purple;
    if (status == 'Resolved') return Colors.green;
    if (status == 'Invalid') return Colors.red;
    return Colors.grey;
  }

  // --- OPENS FULL SCREEN GALLERY ---
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').doc(widget.job.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
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
              "Work Order Details",
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

                // Show Admin Remarks if rejected/re-opened
                if (job.adminRemarks != null && job.adminRemarks!.isNotEmpty && (job.status == 'In Progress' || job.status == 'Invalid')) ...[
                  const SizedBox(height: 20),
                  _buildRejectionBox(
                    job.status == 'Invalid' ? "Job Rejected by Admin" : "Re-opened by Admin", 
                    job.adminRemarks!
                  ),
                ],

                const SizedBox(height: 24),

                // --- SECTION 2: ISSUE DETAILS ---
                _buildSectionTitle("Issue Information"),
                _buildInfoContainer([
                  _detailRow("Job Title", job.title),
                  
                  // Pills Row (Priority & Category)
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
                  
                  // Description
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

                // --- SECTION 3: LOCATION & CONTACT ---
                _buildSectionTitle("Location & Resident"),
                _buildInfoContainer([
                  _detailRow("Building", job.building),
                  _detailRow("Room Number", job.roomNumber),
                  const Divider(),
                  _detailRow("Resident Name", job.fullName),
                  _detailRow("Phone Contact", job.contactNumber),
                  _detailRow("Date Reported", DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp)),
                ]),

                const SizedBox(height: 24),

                // --- SECTION 4: EVIDENCE ---
                if (job.imageUrls.isNotEmpty || (job.videoUrl != null && job.videoUrl!.isNotEmpty)) ...[
                  _buildSectionTitle("Evidence Attached"),
                  _buildEvidenceContainer(job),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 5: ACTIONS / REPORT ---
                if (job.status == 'In Progress') ...[
                  // ACTION BUTTON
                  _buildSectionTitle("Action Required"),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text("SUBMIT COMPLETION REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 21, 192, 41),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: () => _showCompletionDialog(job),
                    ),
                  ),
                ] else if (job.status == 'Pending Verification' || job.status == 'Resolved') ...[
                  // COMPLETED REPORT VIEW
                  _buildSectionTitle("Work Completion Report"),
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
                            Text("Job Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const Divider(height: 20),
                        _detailRow("Findings", job.findings.isNotEmpty ? job.findings : "N/A"),
                        _detailRow("Action Taken", job.actionTaken.isNotEmpty ? job.actionTaken : "N/A"),
                        _detailRow("Result", job.inspectionResult.isNotEmpty ? job.inspectionResult : "N/A"),
                      ],
                    ),
                  ),
                ],

                // --- SECTION 6: RESIDENT FEEDBACK ---
                if (job.rating > 0) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle("Resident Feedback"),
                  _buildFeedbackBox(job),
                ],

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
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 15, color: Color(0xFF003366))),
    );
  }

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

  Widget _buildEvidenceContainer(ComplaintModel job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                      child: Image.network(
                        job.imageUrls[index], 
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (job.videoUrl != null && job.videoUrl!.isNotEmpty) ...[
            if (job.imageUrls.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
            const Row(children: [Icon(Icons.videocam_outlined, size: 18, color: Color(0xFF003366)), SizedBox(width: 8), Text("Video Evidence", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12), 
              child: Container(
                color: Colors.black12,
                height: 200,
                width: double.infinity,
                child: SimpleVideoPlayer(videoUrl: job.videoUrl!)
              )
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionBox(String title, String remarks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.info_outline, color: Colors.red, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'Poppins'))]),
          const SizedBox(height: 8),
          Text(remarks, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFeedbackBox(ComplaintModel job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => Icon(index < job.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 30)),
          ),
          const SizedBox(height: 10),
          Text(
            job.review.isNotEmpty ? "\"${job.review}\"" : "No written comment provided.",
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, fontFamily: 'Poppins', fontSize: 14, color: Colors.amber.shade900),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(ComplaintModel job) {
    final findingsController = TextEditingController(text: job.findings);
    final actionController = TextEditingController(text: job.actionTaken);
    final resultController = TextEditingController(text: job.inspectionResult);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Completion Report", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: findingsController, decoration: const InputDecoration(labelText: "Findings", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: actionController, decoration: const InputDecoration(labelText: "Action Taken", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: resultController, decoration: const InputDecoration(labelText: "Result (e.g. Fixed)", border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (findingsController.text.isEmpty) return;
              await ComplaintService().resolveComplaint(
                complaintId: job.id,
                findings: findingsController.text,
                actionTaken: actionController.text,
                inspectionResult: resultController.text,
              );
              if (mounted) { Navigator.pop(context); Navigator.pop(context); }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}