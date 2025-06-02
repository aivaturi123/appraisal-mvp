import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'comparison_view.dart';

class EvaluateEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic> evaluation;

  const EvaluateEmployeeScreen({super.key, required this.evaluation});

  @override
  State<EvaluateEmployeeScreen> createState() => _EvaluateEmployeeScreenState();
}

class _EvaluateEmployeeScreenState extends State<EvaluateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, double> _managerScores = {};
  final Map<String, String> _managerComments = {};
  bool isSubmitting = false;

  final List<String> _criteria = [
    'Quality of Deliverables',
    'Timeliness & Responsiveness',
    'Client Relationship',
    'Knowledge Sharing & IP',
    'Team Collaboration & Culture',
    'Skill Development',
    'Ownership & Accountability',
    'Adaptability & Learning'
  ];

  Future<void> submitManagerEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('evaluations')
          .doc(widget.evaluation['id']);

      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update({
          'managerReview': {
            'scores': _managerScores,
            'comments': _managerComments,
            'timestamp': Timestamp.now(),
          }
        });
      } else {
        await docRef.set({
          'name': widget.evaluation['name'],
          'scores': {},
          'comments': {},
          'managerReview': {
            'scores': _managerScores,
            'comments': _managerComments,
            'timestamp': Timestamp.now(),
          }
        });
      }

      final fullDoc = await docRef.get();
      final data = fullDoc.data();

      final employeeData = {
        'name': data?['name'],
        'scores': Map<String, dynamic>.from(data?['scores'] ?? {}),
        'comments': Map<String, dynamic>.from(data?['comments'] ?? {}),
      };

      final managerData = Map<String, dynamic>.from(data?['managerReview'] ?? {});

      if ((employeeData['scores'] as Map).isNotEmpty && (managerData['scores'] as Map).isNotEmpty)
 {
        final aiFeedbackText = '✅ AI Summary: Employee and Manager evaluations aligned with minor gaps in adaptability.';

        Future.microtask(() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ComparisonView(
        employeeEval: employeeData,
        managerReview: managerData,
        aiFeedback: aiFeedbackText,
      ),
    ),
  );
});
;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Submitted successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Submit error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Submission failed")));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final selfEval = widget.evaluation;

    return Scaffold(
      appBar: AppBar(
        title: Text("Evaluate ${selfEval['name']}"),
        backgroundColor: Color(0xFF0047BB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📝 Self-Evaluation by ${selfEval['name']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._criteria.map((crit) {
                        final score = (selfEval['scores'] ?? {})[crit]?.toString() ?? 'N/A';
                        final comment = (selfEval['comments'] ?? {})[crit] ?? '';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("$crit - ⭐ $score", style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(comment),
                        );
                      }),
                      Divider(height: 32, thickness: 1),
                      Text("✅ Your Evaluation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._criteria.map((crit) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(crit, style: TextStyle(fontWeight: FontWeight.w600)),
                            RatingBar.builder(
                              initialRating: _managerScores[crit] ?? 3,
                              minRating: 1,
                              allowHalfRating: false,
                              direction: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                              onRatingUpdate: (rating) => setState(() => _managerScores[crit] = rating),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: "Comment",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => _managerComments[crit] = val,
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submitManagerEvaluation,
                          icon: Icon(Icons.send),
                          label: Text(isSubmitting ? "Submitting..." : "Submit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0047BB),
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
