import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart'; // Needed for Maintainer selection
import '../../services/complaint_service.dart';
import '../../services/database_service.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  String? selectedMaintainerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complaint Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- SECTION 1: COMPLAINANT INFO ---
            const Text("1. Complainant Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person, "Name", widget.complaint.fullName),
                  _buildDetailRow(Icons.badge, "ID / Matric", widget.complaint.matricNo),
                  _buildDetailRow(Icons.phone, "Contact", widget.complaint.contactNumber),
                  _buildDetailRow(Icons.assignment_ind, "User Type", widget.complaint.userType),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 2: PREMISE DETAILS ---
            const Text("2. Premise / Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildDetailRow(Icons.apartment, "Building", widget.complaint.building),
                  _buildDetailRow(Icons.room, "Room / Block", widget.complaint.roomNumber),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 3: DAMAGE DETAILS ---
            const Text("3. Damage Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            Text(widget.complaint.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              children: [
                Chip(
                  label: Text(widget.complaint.priority, style: const TextStyle(color: Colors.white)),
                  backgroundColor: widget.complaint.priority == 'High' ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 10),
                Chip(label: Text(widget.complaint.category)),
                const SizedBox(width: 10),
                Chip(label: Text(widget.complaint.status)),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
              child: Text(widget.complaint.description, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),

            // --- SECTION 4: EVIDENCE (IMAGES) ---
            if (widget.complaint.imageUrls.isNotEmpty) ...[
              const Text("4. Evidence Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 10),
              SizedBox(
                height: 300, // Taller to fit full image
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.complaint.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.complaint.imageUrls[index],
                          fit: BoxFit.contain, // FIX: Shows full image without cropping
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else 
              const Text("No images attached", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

            const SizedBox(height: 30),
            const Divider(thickness: 2),

            // --- SECTION 5: ADMIN ACTIONS ---
            // 1. Assign Job (If Pending)
            if (widget.complaint.status == 'Pending') ...[
              const Text("Assign to Maintainer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              StreamBuilder<List<UserModel>>(
                stream: DatabaseService().maintainers,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  var maintainers = snapshot.data!;
                  
                  return DropdownButtonFormField<String>(
                    value: selectedMaintainerId,
                    hint: const Text("Select Staff Member"),
                    items: maintainers.map((m) {
                      return DropdownMenuItem(
                        value: m.uid,
                        child: Text("${m.fullName} (${m.email})"), // Show Name
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedMaintainerId = val),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_ind, color: Colors.white),
                  label: const Text("Assign & Start Job", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], padding: const EdgeInsets.all(15)),
                  onPressed: () async {
                    if (selectedMaintainerId != null) {
                      await ComplaintService().assignComplaint(widget.complaint.id, selectedMaintainerId!);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Assigned Successfully!")));
                      }
                    }
                  },
                ),
              )
            ] else if (widget.complaint.status == 'In Progress') ...[
               Container(
                padding: const EdgeInsets.all(15),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    const Icon(Icons.build_circle, color: Colors.blue),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Job is currently In Progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        // We could show WHO it is assigned to here if we fetched the name
                        Text("Assigned to ID: ${widget.complaint.assignedTo ?? 'Unknown'}"),
                      ],
                    ),
                  ],
                ),
              )
            ],

            // 4. Show CCF Report & Admin Verification
            if (widget.complaint.status == 'Pending Verification' || widget.complaint.status == 'Resolved') ...[
                const SizedBox(height: 30),
                const Divider(thickness: 2),
                const Text("✅ Digital Completion Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 10),

                _buildReportRow("Sec 2 (Findings):", widget.complaint.findings ?? "N/A"),
                _buildReportRow("Sec 3 (Action):", widget.complaint.actionTaken ?? "N/A"),
                _buildReportRow("Sec 4 (Result):", widget.complaint.inspectionResult ?? "N/A"),

                const SizedBox(height: 20),

                // --- ADMIN VERIFICATION BUTTONS ---
                if (widget.complaint.status == 'Pending Verification')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Section 5: Verification", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Reject"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () async {
                                String reason = "";
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Reject Report"),
                                    content: TextField(
                                      onChanged: (val) => reason = val,
                                      decoration: const InputDecoration(hintText: "Reason for rejection"),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          await ComplaintService().rejectComplaint(widget.complaint.id, reason);
                                          Navigator.pop(context); Navigator.pop(context);
                                        },
                                        child: const Text("Send Back"),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Verify"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () async {
                                await ComplaintService().verifyComplaint(widget.complaint.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Verified!")));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (widget.complaint.status == 'Resolved')
                   Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text("✅ Verified by Management", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.undo, color: Colors.orange),
                        label: const Text("Mistake? Undo Verification"),
                        style: TextButton.styleFrom(foregroundColor: Colors.orange),
                        onPressed: () async {
                           bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Undo Verification?"),
                              content: const Text("This will move the job back to the 'To Verify' tab."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Undo")),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ComplaintService().undoVerification(widget.complaint.id);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      )
                    ],
                  )
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]))),
          Expanded(child: Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}