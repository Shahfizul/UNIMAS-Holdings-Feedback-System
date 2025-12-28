import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
// import '../../services/complaint_service.dart'; // Uncomment when we implement rating logic later

class ResidentComplaintDetail extends StatelessWidget {
  final ComplaintModel job;

  const ResidentComplaintDetail({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    // Helper for Status Colors
    Color statusColor = Colors.grey;
    if (job.status == 'In Progress') statusColor = Colors.orange;
    if (job.status == 'Resolved') statusColor = Colors.green;
    if (job.status == 'Pending Verification') statusColor = Colors.blue;

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
            // 1. STATUS HEADER (FR-08)
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    job.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. MAIN DETAILS
            Text(
              job.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Category: ${job.category} • Priority: ${job.priority}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(job.description, style: const TextStyle(fontSize: 16)),

            const Divider(height: 40),

            // 3. WORK DETAILS (If available)
            if (job.findings.isNotEmpty) ...[
              const Text("Maintainer Findings:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(job.findings),
              const SizedBox(height: 10),
            ],
            if (job.actionTaken.isNotEmpty) ...[
              const Text("Action Taken:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(job.actionTaken),
              const SizedBox(height: 10),
            ],

            const Divider(height: 40),

            // 4. RATING SECTION (FR-09)
            // Only show this if status is Resolved
            if (job.status == 'Resolved') 
              Center(
                child: Column(
                  children: [
                    const Text(
                      "How was the service?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text("Rate Service"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        // TODO: Open Rating Dialog Here
                        _showRatingDialog(context);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Placeholder for Rating Dialog
  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rate Service"),
        content: const Text("Star rating functionality coming next!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }
}