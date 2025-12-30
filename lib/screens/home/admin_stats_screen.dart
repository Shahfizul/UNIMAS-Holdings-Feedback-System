import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart'; 
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart'; 
import '../../models/complaint_model.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // --- FILTER STATE ---
  String _timeFilter = 'This Month'; 
  String _buildingFilter = 'All';
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final allComplaints = Provider.of<List<ComplaintModel>>(context);

    if (allComplaints.isEmpty) {
      return const Center(child: Text("Waiting for data..."));
    }

    // --- 1. PREPARE DYNAMIC FILTER LISTS ---
    final Set<String> buildings = {'All', ...allComplaints.map((e) => e.building ?? 'Unknown').toSet()};
    final Set<String> categories = {
      'All', 
      'Furniture', 'Mechanical', 'Electrical', 'Plumbing/Sink', 
      'Waste Water', 'Wi-Fi', 'Other'
    };

    Set<String> timeOptions = {'This Month', 'Last Month', 'This Year', 'All Time'};
    for (var c in allComplaints) {
      timeOptions.add(DateFormat('MMMM yyyy').format(c.timestamp));
    }

    // --- 2. FILTER LOGIC ---
    List<ComplaintModel> filteredList = allComplaints.where((c) {
      bool timeMatch = true;
      final now = DateTime.now();
      
      if (_timeFilter == 'This Month') {
        timeMatch = c.timestamp.month == now.month && c.timestamp.year == now.year;
      } else if (_timeFilter == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        timeMatch = c.timestamp.month == lastMonth.month && c.timestamp.year == lastMonth.year;
      } else if (_timeFilter == 'This Year') {
        timeMatch = c.timestamp.year == now.year;
      } else if (_timeFilter == 'All Time') {
        timeMatch = true;
      } else {
        String cDate = DateFormat('MMMM yyyy').format(c.timestamp);
        timeMatch = cDate == _timeFilter;
      }

      bool buildingMatch = _buildingFilter == 'All' || (c.building ?? 'Unknown') == _buildingFilter;

      bool categoryMatch = true;
      if (_categoryFilter != 'All') {
        if (_categoryFilter == 'Other') {
          final standard = ['Furniture', 'Mechanical', 'Electrical', 'Plumbing/Sink', 'Waste Water', 'Wi-Fi'];
          categoryMatch = !standard.contains(c.category);
        } else {
          categoryMatch = c.category == _categoryFilter;
        }
      }

      return timeMatch && buildingMatch && categoryMatch;
    }).toList();

    // --- 3. CALCULATE KPIs ---
    int total = filteredList.length;
    int resolved = filteredList.where((c) => c.status == 'Resolved').length;
    int pending = filteredList.where((c) => c.status == 'Pending').length;
    int inProgress = filteredList.where((c) => c.status == 'In Progress').length;
    double completionRate = total == 0 ? 0 : (resolved / total) * 100;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Analytics Dashboard",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.blueGrey),
                  tooltip: "Download PDF Report",
                  onPressed: () => _generatePdf(filteredList, total, resolved, pending, inProgress, completionRate),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- FILTER BAR ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: SingleChildScrollView( 
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: "TIME PERIOD",
                      value: _timeFilter,
                      items: timeOptions.toList(),
                      onChanged: (val) => setState(() => _timeFilter = val!),
                    ),
                    const SizedBox(width: 15),
                    _buildFilterChip(
                      label: "PROPERTY",
                      value: _buildingFilter,
                      items: buildings.toList(),
                      onChanged: (val) => setState(() => _buildingFilter = val!),
                    ),
                    const SizedBox(width: 15),
                    _buildFilterChip(
                      label: "CATEGORY",
                      value: _categoryFilter,
                      items: categories.toList(),
                      onChanged: (val) => setState(() => _categoryFilter = val!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KPI ROW ---
            Row(
              children: [
                Expanded(child: _buildKPICard("Total Issues", "$total", Icons.folder_open, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard("Completion", "${completionRate.toStringAsFixed(0)}%", Icons.pie_chart, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildKPICard("Pending", "$pending", Icons.assignment_late_outlined, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard("In Progress", "$inProgress", Icons.engineering_outlined, Colors.purple)),
              ],
            ),

            const SizedBox(height: 30),

            // --- CHARTS ---
            _buildSectionTitle("Issues by Category"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: _buildCategoryBarChart(filteredList),
            ),

            const SizedBox(height: 30),

            _buildSectionTitle("Property Hotspots"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: _buildPropertyHotspots(filteredList),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 4. PDF GENERATOR FUNCTION (FIXED) ---
  Future<void> _generatePdf(
    List<ComplaintModel> data, 
    int total, int resolved, int pending, int inProgress, double rate
  ) async {
    final pdf = pw.Document();
    
    // Group Data
    Map<String, int> catCounts = {};
    for (var c in data) { catCounts[c.category] = (catCounts[c.category] ?? 0) + 1; }
    
    Map<String, int> bldCounts = {};
    for (var c in data) { 
      String b = c.building ?? "Unknown";
      bldCounts[b] = (bldCounts[b] ?? 0) + 1; 
    }

    // --- FIX: USE MULTIPAGE FOR PAGINATION ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32), // Cleaner margins
        
        // --- HEADER (Appears on first page, or every page if repeated) ---
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Maintenance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text("Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              
              // --- FIX: CLEAR FILTER LABELS ---
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  children: [
                    pw.Text("Report Scope:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 10),
                    pw.Text("Time: $_timeFilter"),
                    pw.SizedBox(width: 15),
                    pw.Text("Property: $_buildingFilter"),
                    pw.SizedBox(width: 15),
                    pw.Text("Category: $_categoryFilter"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },

        // --- BODY (Automatically flows to next page) ---
        build: (pw.Context context) => [
          
          // KPI Summary
          pw.Text("Performance Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Issues', '$total'],
              ['Completion Rate', '${rate.toStringAsFixed(1)}%'],
              ['Pending Action', '$pending'],
              ['In Progress', '$inProgress'],
              ['Resolved', '$resolved'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          
          pw.SizedBox(height: 30),

          // Category Table
          pw.Text("Breakdown by Category", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Category', 'Count'],
            data: catCounts.entries.map((e) => [e.key, '${e.value}']).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
            cellPadding: const pw.EdgeInsets.all(8),
          ),

          pw.SizedBox(height: 30),

          // Property Table
          pw.Text("Breakdown by Property", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Property', 'Count'],
            data: bldCounts.entries.map((e) => [e.key, '${e.value}']).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          
          // Footer / End of Report
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300),
          pw.Center(
            child: pw.Text("Generated by Suggestify Admin System", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildFilterChip({
    required String label, 
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: Colors.blueGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.blueGrey),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 3))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: Colors.blue[800]),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryBarChart(List<ComplaintModel> data) {
    if (data.isEmpty) return const Center(child: Text("No data matching filters."));

    Map<String, int> counts = {};
    for (var c in data) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }
    
    var sortedKeys = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    int max = counts.values.isEmpty ? 1 : counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: sortedKeys.map((key) {
        int count = counts[key]!;
        double pct = count / max;
        
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("$key: $count issues found"),
              duration: const Duration(seconds: 1),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 10, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5))),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 30, child: Text("$count", textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPropertyHotspots(List<ComplaintModel> data) {
    if (data.isEmpty) return const Center(child: Text("No data matching filters."));

    Map<String, int> counts = {};
    for (var c in data) {
      String buildingName = c.building ?? "Unknown"; 
      counts[buildingName] = (counts[buildingName] ?? 0) + 1;
    }

    var sortedKeys = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    int max = counts.values.isEmpty ? 1 : counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: sortedKeys.map((key) {
        int count = counts[key]!;
        double pct = count / max;

        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("$key has $count issues"),
              duration: const Duration(seconds: 1),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    Text("$count issues", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      count > 5 ? Colors.redAccent : Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}