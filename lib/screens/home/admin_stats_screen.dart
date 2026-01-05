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
      backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: const BackButton(color: Color(0xFF003366)),
        title: const Text(
          "Analytics Dashboard",
          style: TextStyle(
            color: Color(0xFF003366),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Color(0xFF003366)),
            tooltip: "Download PDF Report",
            onPressed: allComplaints.isEmpty 
              ? null 
              : () => _generatePdf(filteredList, total, resolved, pending, inProgress, completionRate),
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: allComplaints.isEmpty 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FILTER BAR (Clean Horizontal Scroll) ---
              SingleChildScrollView( 
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDropdownChip(
                      icon: Icons.calendar_today,
                      label: "Time",
                      value: _timeFilter,
                      items: timeOptions.toList(),
                      onChanged: (val) => setState(() => _timeFilter = val!),
                    ),
                    const SizedBox(width: 12),
                    _buildDropdownChip(
                      icon: Icons.business,
                      label: "Property",
                      value: _buildingFilter,
                      items: buildings.toList(),
                      onChanged: (val) => setState(() => _buildingFilter = val!),
                    ),
                    const SizedBox(width: 12),
                    _buildDropdownChip(
                      icon: Icons.category_outlined,
                      label: "Category",
                      value: _categoryFilter,
                      items: categories.toList(),
                      onChanged: (val) => setState(() => _categoryFilter = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- KPI GRID ---
              Row(
                children: [
                  Expanded(child: _buildKPICard("Total Issues", "$total", Icons.folder_open, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKPICard("Completion", "${completionRate.toStringAsFixed(0)}%", Icons.pie_chart, Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildKPICard("Pending", "$pending", Icons.assignment_late_outlined, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKPICard("In Progress", "$inProgress", Icons.engineering_outlined, Colors.purple)),
                ],
              ),

              const SizedBox(height: 32),

              // --- CHARTS SECTION ---
              _buildChartSection(
                title: "Issues by Category",
                child: _buildCategoryBarChart(filteredList),
              ),

              const SizedBox(height: 24),

              _buildChartSection(
                title: "Property Hotspots",
                child: _buildPropertyHotspots(filteredList),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }

  // --- PDF GENERATOR (Kept Logic, unchanged) ---
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        
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

        build: (pw.Context context) => [
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

  // --- UI WIDGETS ---

  // Cleaner Dropdown Chip
  Widget _buildDropdownChip({
    required IconData icon,
    required String label, 
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w500)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF003366)),
          style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13),
          isDense: true,
          hint: Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  // Modern KPI Card
  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color.withOpacity(0.8), size: 24),
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  // Chart Container Wrapper
  Widget _buildChartSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF003366), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Color(0xFF003366))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
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
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700], fontFamily: 'Poppins'))),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 12, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 40, child: Text("$count", textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'))),
            ],
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Poppins')),
                  Text("$count issues", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Poppins')),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    count > 5 ? Colors.redAccent : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}