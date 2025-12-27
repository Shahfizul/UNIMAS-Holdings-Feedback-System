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
                  child: Image.network(widget.complaint.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),

              // 2. Text Details
              Text(widget.complaint.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Priority: ${widget.complaint.priority}", style: const TextStyle(fontSize: 16, color: Colors.red)),
              const Divider(),
              Text(widget.complaint.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),

              // 3. Assignment Section (Only if Pending)
              if (widget.complaint.status == 'Pending') ...[
                const Text("Assign to Maintainer:", style: TextStyle(fontWeight: FontWeight.bold)),
                Consumer<List<UserModel>>(
                  builder: (context, maintainers, child) {
                    if (maintainers.isEmpty) return const Text("No maintainers found.");
                    
                    return DropdownButtonFormField<String>(
                      items: maintainers.map((m) {
                        return DropdownMenuItem(value: m.uid, child: Text(m.email));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedMaintainerId = val),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Assign & Start Job", style: TextStyle(color: Colors.white)),
                    onPressed: selectedMaintainerId == null ? null : () async {
                      await ComplaintService().assignMaintainer(widget.complaint.id, selectedMaintainerId!);
                      Navigator.pop(context);
                    },
                  ),
                )
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
                 )
              ]
            ],
          ),
        ),
      ),
    );
  }
}