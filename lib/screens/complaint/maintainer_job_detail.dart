import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';

class MaintainerJobDetail extends StatelessWidget {
  final ComplaintModel job;
  const MaintainerJobDetail({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Work Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.adminRemarks != null && job.adminRemarks!.isNotEmpty && job.status == 'In Progress')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⚠️ Job Rejected / Re-opened", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Admin Reason: \"${job.adminRemarks}\"", style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),

            // 1. Photo of the Issue
            if (job.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  job.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 20),

            // 2. Info
            Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Chip(
              label: Text(job.priority, style: const TextStyle(color: Colors.white)),
              backgroundColor: job.priority == 'High' ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 10),
            Text("Category: ${job.category}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const Divider(),
            const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(job.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 40),

            // 3. Action Button
            if (job.status == 'In Progress')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Mark as Resolved", style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    // --- FIX: Pre-fill with existing data if it exists ---
                    final findingsController = TextEditingController(text: job.findings ?? '');
                    final actionController = TextEditingController(text: job.actionTaken ?? '');
                    final resultController = TextEditingController(text: job.inspectionResult ?? '');

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Digital Completion Report (DCR)"),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Section 2: Validation", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                controller: findingsController,
                                decoration: const InputDecoration(
                                  hintText: "Investigation / Findings",
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 15),
                              
                              const Text("Section 3: Action Plan", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                controller: actionController,
                                decoration: const InputDecoration(
                                  hintText: "Corrective Plan / Action Taken",
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 15),

                              const Text("Section 4: Work Inspection", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                controller: resultController,
                                decoration: const InputDecoration(
                                  hintText: "Result / Status (e.g., Fixed, Needs Parts)",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            child: const Text("Submit Report"),
                            onPressed: () async {
                              if (findingsController.text.isEmpty) return; 

                              await ComplaintService().resolveComplaint(
                                complaintId: job.id,
                                findings: findingsController.text,
                                actionTaken: actionController.text,
                                inspectionResult: resultController.text,
                              );
                              
                              if (context.mounted) {
                                Navigator.pop(context); // Close Dialog
                                Navigator.pop(context); // Close Screen
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
               // --- READ ONLY VIEW ---
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // Color depends on status
                    color: job.status == 'Pending Verification' ? Colors.orange[50] : Colors.green[50],
                    border: Border.all(
                      color: job.status == 'Pending Verification' ? Colors.orange : Colors.green
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Title
                      Row(
                        children: [
                          Icon(
                            job.status == 'Pending Verification' ? Icons.hourglass_bottom : Icons.check_circle,
                            color: job.status == 'Pending Verification' ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            job.status == 'Pending Verification' ? "Pending Verification" : "Job Verified & Closed", 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18, 
                              color: job.status == 'Pending Verification' ? Colors.orange[800] : Colors.green[800]
                            )
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildRow("Findings:", job.findings),
                      _buildRow("Action:", job.actionTaken),
                      _buildRow("Result:", job.inspectionResult),
                      
                      // Show Rejection Note if it happened
                      if (job.status == 'In Progress') // This handles if it was rejected
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text("⚠️ Admin Note: Please fix this!", style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
               )
          ],
        ),
      ),
    );
  }
  // Helper for text rows
  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value ?? "N/A")),
        ],
      ),
    );
  }
}