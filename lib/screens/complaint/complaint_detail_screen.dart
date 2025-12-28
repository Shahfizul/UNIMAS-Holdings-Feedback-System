import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
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
    return StreamProvider<List<UserModel>>.value(
      value: DatabaseService().maintainers, // Listen to list of workers
      initialData: const [],
      child: Scaffold(
        appBar: AppBar(title: const Text("Complaint Details")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image
              if (widget.complaint.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.complaint.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),

              // 2. Text Details
              Text(
                widget.complaint.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Priority: ${widget.complaint.priority}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const Divider(),
              Text(
                widget.complaint.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // 3. Assignment Section (Only if Pending)
              if (widget.complaint.status == 'Pending') ...[
                const Text(
                  "Assign to Maintainer:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Consumer<List<UserModel>>(
                  builder: (context, maintainers, child) {
                    if (maintainers.isEmpty)
                      return const Text("No maintainers found.");

                    return DropdownButtonFormField<String>(
                      items: maintainers.map((m) {
                        return DropdownMenuItem(
                          value: m.uid,
                          child: Text(m.email),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => selectedMaintainerId = val),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "Assign & Start Job",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: selectedMaintainerId == null
                        ? null
                        : () async {
                            await ComplaintService().assignMaintainer(
                              widget.complaint.id,
                              selectedMaintainerId!,
                            );
                            Navigator.pop(context);
                          },
                  ),
                ),
              ] else ...[
                // If already assigned
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.green[100],
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text("Job is already assigned/completed."),
                    ],
                  ),
                ),
              ],
              // 4. Show CCF Report & Admin Actions
              // Show this section if the job is finished (either waiting or verified)
              if (widget.complaint.status == 'Pending Verification' || widget.complaint.status == 'Resolved') ...[
                const SizedBox(height: 30),
                const Divider(thickness: 2),
                const Text(
                  "✅ Digital Completion Report",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),

                _buildReportRow("Sec 2 (Findings):", widget.complaint.findings ?? "N/A"),
                _buildReportRow("Sec 3 (Action):", widget.complaint.actionTaken ?? "N/A"),
                _buildReportRow("Sec 4 (Result):", widget.complaint.inspectionResult ?? "N/A"),

                const SizedBox(height: 20),

                // --- SECTION 5: ADMIN ACTIONS ---
                
                // CASE A: It is waiting for YOU (The Admin) to verify
                if (widget.complaint.status == 'Pending Verification')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Section 5: Verification", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // REJECT BUTTON
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Reject (Re-open)"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () async {
                                String reason = "";
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Reject Report"),
                                    content: TextField(
                                      onChanged: (val) => reason = val,
                                      decoration: const InputDecoration(hintText: "Why is it rejected?"),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          await ComplaintService().rejectComplaint(widget.complaint.id, reason);
                                          Navigator.pop(context); // Close Dialog
                                          Navigator.pop(context); // Close Screen
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
                          // APPROVE BUTTON
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Verify & Close"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () async {
                                await ComplaintService().verifyComplaint(widget.complaint.id);
                                Navigator.pop(context); // Go back
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Verified!")));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                
                // CASE B: It is ALREADY verified
                else if (widget.complaint.status == 'Resolved')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.green[100],
                    child: const Center(
                      child: Text(
                        "✅ Verified by Management", 
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                      )
                    ),
                  )
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
