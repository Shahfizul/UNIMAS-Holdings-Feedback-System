import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../../services/complaint_service.dart';
import '../../services/database_service.dart';
import '../../widgets/simple_video_player.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  String? selectedMaintainerId;

  // --- HELPER: OPEN GALLERY ---
  void _openGallery(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            itemCount: urls.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(child: Image.network(urls[index], fit: BoxFit.contain)),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- HELPER: PRIORITY COLOR ---
  Color _getPriorityColor(String priority) {
    if (priority == 'High') return Colors.red;
    if (priority == 'Medium') return Colors.orange;
    if (priority == 'Low') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').doc(widget.complaint.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var data = snapshot.data!.data() as Map<String, dynamic>;
        ComplaintModel job = ComplaintModel.fromMap(data, widget.complaint.id);

        Color statusColor = Colors.grey;
        if (job.status == 'Pending') statusColor = Colors.orange;
        else if (job.status == 'In Progress') statusColor = Colors.blue;
        else if (job.status == 'Pending Verification') statusColor = Colors.purple;
        else if (job.status == 'Resolved') statusColor = Colors.green;
        else if (job.status == 'Invalid') statusColor = Colors.red;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: true,
            title: const Text(
              "Complaint Details",
              style: TextStyle(color: Color(0xFF003366), fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
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
                // --- SECTION 1: HEADER & STATUS ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(job.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text("Reported on ${DateFormat('dd MMM yyyy, hh:mm a').format(job.timestamp)}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- SECTION 2: ISSUE DETAILS ---
                _buildSectionTitle("Issue Information"),
                _buildInfoContainer([
                  _detailRow("Title", job.title),
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
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("Description", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(job.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                ]),

                const SizedBox(height: 24),

                // --- SECTION 3: LOCATION & COMPLAINANT ---
                _buildSectionTitle("Location & Contact"),
                _buildInfoContainer([
                  _detailRow("Building", job.building),
                  _detailRow("Room / Block", job.roomNumber),
                  const Divider(),
                  _detailRow("Reported By", job.fullName),
                  _detailRow("Matric / ID", job.matricNo),
                  _detailRow("Phone", job.contactNumber),
                ]),

                const SizedBox(height: 24),

                // --- SECTION 4: EVIDENCE ---
                if (job.imageUrls.isNotEmpty || (job.videoUrl != null && job.videoUrl!.isNotEmpty)) ...[
                  _buildSectionTitle("Evidence"),
                  _buildEvidenceContainer(job),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 5: STAFF INFORMATION (Moved UP) ---
                if (job.status != 'Pending') ...[
                  _buildSectionTitle("Staff Information"),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(job.assignedTo).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      var staff = snapshot.data!.data() as Map<String, dynamic>?;
                      if (staff == null) return const Text("Staff info removed");
                      return _buildInfoContainer([
                        _detailRow("Assigned To", staff['fullName']),
                        _detailRow("Role", staff['specialization'] ?? "Maintainer"),
                        _detailRow("Contact", staff['contactNumber']),
                      ]);
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 6: MAINTENANCE REPORT & VERIFICATION (Moved DOWN) ---
                if (job.status == 'Pending Verification' || job.status == 'Resolved') ...[
                  _buildSectionTitle("Maintenance Report"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: job.status == 'Resolved' ? Colors.green.shade300 : Colors.purple.shade200, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment_turned_in, color: job.status == 'Resolved' ? Colors.green : Colors.purple),
                            const SizedBox(width: 8),
                            Text("Work Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: job.status == 'Resolved' ? Colors.green : Colors.purple)),
                          ],
                        ),
                        const Divider(height: 20),
                        _detailRow("Findings", job.findings.isNotEmpty ? job.findings : "N/A"),
                        _detailRow("Action Taken", job.actionTaken.isNotEmpty ? job.actionTaken : "N/A"),
                        _detailRow("Final Result", job.inspectionResult.isNotEmpty ? job.inspectionResult : "N/A"),
                        
                        const SizedBox(height: 20),

                        // --- VERIFICATION ACTIONS (If Pending Verification) ---
                        if (job.status == 'Pending Verification')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showRejectDialog(context, job.id),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text("Reject Work", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await ComplaintService().verifyComplaint(job.id);
                                    if (mounted) Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text("Verify & Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),

                        // --- UNDO VERIFICATION (If Resolved) ---
                        if (job.status == 'Resolved') ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green),
                              SizedBox(width: 6),
                              Text("Verified by Management", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.undo, color: Colors.orange),
                              label: const Text("Undo Verification", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.orange, width: 1.5), // Visible Border
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Undo Verification?"),
                                    content: const Text("This will move the job back to the 'Verify' tab."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Undo")),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ComplaintService().undoVerification(job.id);
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 7: ACTION REQUIRED (Only if Pending) ---
                if (job.status == 'Pending') ...[
                  _buildSectionTitle("Action Required"),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Assign to Maintainer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        const SizedBox(height: 15),
                        StreamBuilder<List<UserModel>>(
                          stream: DatabaseService().maintainers,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator();
                            var maintainers = snapshot.data!;
                            
                            return DropdownButtonFormField<String>(
                              value: selectedMaintainerId,
                              hint: const Text("Select Staff Member"),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: maintainers.map((m) {
                                return DropdownMenuItem(
                                  value: m.uid,
                                  child: Text("${m.fullName} (${m.specialization ?? 'General'})", overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => selectedMaintainerId = val),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (selectedMaintainerId != null) {
                                await ComplaintService().assignComplaint(job.id, selectedMaintainerId!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Assigned Successfully!")));
                                  Navigator.pop(context);
                                }
                              }
                            },
                            child: const Text("Confirm Assignment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- SECTION 8: RESIDENT FEEDBACK ---
                if (job.rating > 0) ...[
                  _buildSectionTitle("Resident Feedback"),
                  _buildFeedbackBox(job),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.imageUrls.isNotEmpty)
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
          if (job.videoUrl != null && job.videoUrl!.isNotEmpty) ...[
            if (job.imageUrls.isNotEmpty) const SizedBox(height: 15),
            const Text("Video", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: SimpleVideoPlayer(videoUrl: job.videoUrl!),
              ),
            ),
          ]
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
            children: List.generate(5, (index) => Icon(
              index < job.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 36,
            )),
          ),
          const SizedBox(height: 10),
          Text(
            job.review.isNotEmpty ? "\"${job.review}\"" : "No written comment provided.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic, 
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w500
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, String complaintId) async {
    String reason = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Reject Work Report", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: TextField(
          onChanged: (val) => reason = val,
          decoration: const InputDecoration(hintText: "Why is the work rejected?", border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reason.isNotEmpty) {
                await ComplaintService().rejectComplaint(complaintId, reason);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                }
              }
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}