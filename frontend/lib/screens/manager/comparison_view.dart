import 'package:flutter/material.dart';

class ComparisonView extends StatelessWidget {
  final Map<String, dynamic> employeeEval;
  final Map<String, dynamic> managerReview;
  final String aiFeedback;

  const ComparisonView({
    Key? key,
    required this.employeeEval,
    required this.managerReview,
    required this.aiFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scores = employeeEval['scores'] ?? {};
    final comments = employeeEval['comments'] ?? {};
    final mgrScores = managerReview['scores'] ?? {};
    final mgrComments = managerReview['comments'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text("Comparison & AI Summary"),
        backgroundColor: Color(0xFF0047BB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Performance Comparison Title + Side-by-side comparison UI
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📊 Performance Comparison",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                ...scores.keys.map((crit) {
                  final empScore = scores[crit]?.toString() ?? '-';
                  final empComment = comments[crit] ?? '';
                  final mgrScore = mgrScores[crit]?.toString() ?? '-';
                  final mgrComment = mgrComments[crit] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crit,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                color: Colors.blue[50],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Employee:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("$empScore ⭐"),
                                    if (empComment.isNotEmpty) Text(empComment),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                color: Colors.green[50],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Manager:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("$mgrScore ⭐"),
                                    if (mgrComment.isNotEmpty) Text(mgrComment),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

            SizedBox(height: 24),

            // AI Feedback Summary section
            Text(
              "🧠 AI Feedback Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(aiFeedback),
            ),
          ],
        ),
      ),
    );
  }
}
