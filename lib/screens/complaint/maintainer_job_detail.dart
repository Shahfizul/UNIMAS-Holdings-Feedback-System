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
            // --- REJECTION ALERT ---
            if (job.adminRemarks != null &&
                job.adminRemarks!.isNotEmpty &&
                job.status == 'In Progress')
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
                    const Text(
                      "⚠️ Job Rejected / Re-opened",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Admin Reason: \"${job.adminRemarks}\"",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),

            // --- 1. CONTACT & LOCATION INFO (NEW) ---
            const Text(
              "📍 Location & Contact",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildRow("Building:", job.building),
                  const Divider(),
                  _buildRow("Room No:", job.roomNumber),
                  const Divider(),
                  _buildRow("Resident:", job.fullName),
                  const Divider(),
                  _buildRow("Phone:", job.contactNumber),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. PHOTOS (Horizontal List) ---
            const Text(
              "📸 Evidence Photos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (job.imageUrls.isNotEmpty)
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: job.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          job.imageUrls[index],
                          fit: BoxFit.contain, // FIX: Full image visible
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Text(
                "No photos attached",
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 20),

            // 3. Info
            Text(
              job.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text(
                job.priority,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: job.priority == 'High'
                  ? Colors.red
                  : Colors.orange,
            ),
            const SizedBox(height: 10),
            Text(
              "Category: ${job.category}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(),
            const Text(
              "Description:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(job.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 40),

            // 4. Action Button (Submit Report)
            if (job.status == 'In Progress')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Mark as Resolved",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    // Pre-fill
                    final findingsController = TextEditingController(
                      text: job.findings,
                    );
                    final actionController = TextEditingController(
                      text: job.actionTaken,
                    );
                    final resultController = TextEditingController(
                      text: job.inspectionResult,
                    );

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Digital Completion Report (DCR)"),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Section 2: Validation",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextField(
                                controller: findingsController,
                                decoration: const InputDecoration(
                                  hintText: "Findings",
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 15),

                              const Text(
                                "Section 3: Action Plan",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextField(
                                controller: actionController,
                                decoration: const InputDecoration(
                                  hintText: "Action Taken",
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 15),

                              const Text(
                                "Section 4: Work Inspection",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextField(
                                controller: resultController,
                                decoration: const InputDecoration(
                                  hintText: "Result (e.g., Fixed)",
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
                                Navigator.pop(context);
                                Navigator.pop(context);
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
              // --- READ ONLY VIEW (Finished) ---
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: job.status == 'Pending Verification'
                      ? Colors.orange[50]
                      : Colors.green[50],
                  border: Border.all(
                    color: job.status == 'Pending Verification'
                        ? Colors.orange
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          job.status == 'Pending Verification'
                              ? Icons.hourglass_bottom
                              : Icons.check_circle,
                          color: job.status == 'Pending Verification'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          job.status == 'Pending Verification'
                              ? "Pending Verification"
                              : "Job Verified & Closed",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: job.status == 'Pending Verification'
                                ? Colors.orange[800]
                                : Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildRow("Findings:", job.findings),
                    _buildRow("Action:", job.actionTaken),
                    _buildRow("Result:", job.inspectionResult),
                  ],
                ),
              ),
            // --- 5. CUSTOMER FEEDBACK (NEW) ---
            if (job.rating > 0) ...[
              const SizedBox(height: 30),
              const Divider(thickness: 2),
              const Center(
                child: Text(
                  "⭐ Customer Feedback",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
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
                      job.review.isNotEmpty ? "\"${job.review}\"" : "No written comment.",
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  // Helper for text rows
  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
