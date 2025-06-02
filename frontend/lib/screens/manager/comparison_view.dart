import 'package:flutter/material.dart';

class ComparisonView extends StatelessWidget {
  final Map<String, dynamic> employeeEval;
  final Map<String, dynamic> managerReview;
  final String aiFeedback;

  const ComparisonView({
    super.key,
    required this.employeeEval,
    required this.managerReview,
    required this.aiFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final criteria = employeeEval['scores'].keys.toList();

    return Scaffold(
      appBar: AppBar(title: Text("Comparison & AI Insight")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("📝 Performance Comparison",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            DataTable(
              columns: [
                DataColumn(label: Text("Criteria")),
                DataColumn(label: Text("Employee Score")),
                DataColumn(label: Text("Manager Score")),
              ],
              rows: criteria.map((crit) {
                final empScore = employeeEval['scores'][crit]?.toString() ?? '-';
                final mgrScore = managerReview['scores']?[crit]?.toString() ?? '-';
                return DataRow(cells: [
                  DataCell(Text(crit)),
                  DataCell(Text(empScore)),
                  DataCell(Text(mgrScore)),
                ]);
              }).toList(),
            ),
            SizedBox(height: 30),
            Text("💡 AI-Generated Summary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                aiFeedback,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
