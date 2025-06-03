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
  bool isSubmitting = false;

  final Map<String, double> _managerScores = {};
  final Map<String, String> _managerComments = {};

  final _managerStrengthsController = TextEditingController();
  final _managerWeaknessesController = TextEditingController();
  final _managerOpportunitiesController = TextEditingController();
  final _managerThreatsController = TextEditingController();

  final _managerAchievements = List.generate(3, (_) => TextEditingController());
  final _managerBMC = List.generate(9, (_) => TextEditingController());

  final _managerWentWell = TextEditingController();
  final _managerPowerUp = TextEditingController();
  final _managerNextSteps = TextEditingController();

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

  final List<String> _bmcLabels = [
    "Customer Segments", "Value Proposition", "Channels",
    "Customer Relationships", "Revenue Streams", "Key Resources",
    "Key Activities", "Key Partnerships", "Cost Structure"
  ];

  Future<void> submitManagerEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('evaluations')
          .doc(widget.evaluation['id']);

      await docRef.update({
        'managerReview': {
          'scores': _managerScores,
          'comments': _managerComments,
          'swot': {
            'strengths': _managerStrengthsController.text,
            'weaknesses': _managerWeaknessesController.text,
            'opportunities': _managerOpportunitiesController.text,
            'threats': _managerThreatsController.text,
          },
          'achievements': _managerAchievements.map((e) => e.text).toList(),
          'bmc': _managerBMC.map((e) => e.text).toList(),
          'summary': {
            'whatWentWell': _managerWentWell.text,
            'powerUp': _managerPowerUp.text,
            'nextSteps': _managerNextSteps.text,
          },
          'timestamp': Timestamp.now(),
        }
      });

      final fullDoc = await docRef.get();
      final data = fullDoc.data();

      final employeeData = {
        'name': data?['name'],
        'scores': data?['scores'] ?? {},
        'comments': data?['comments'] ?? {},
      };

      final managerData = data?['managerReview'] ?? {};

      if ((employeeData['scores'] as Map).isNotEmpty &&
          (managerData['scores'] as Map).isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComparisonView(
              employeeEval: employeeData,
              managerReview: managerData,
              aiFeedback: "✅ AI summary will go here",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Submitted successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Submission failed: $e")));
    }

    setState(() => isSubmitting = false);
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final eval = widget.evaluation;

    return Scaffold(
      appBar: AppBar(
        title: Text("Evaluate ${eval['name']}"),
        backgroundColor: Color(0xFF0047BB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("🔹 Step 1: Scorecard"),
              ..._criteria.map((crit) {
                final score = (eval['scores'] ?? {})[crit]?.toDouble() ?? 0;
                final comment = (eval['comments'] ?? {})[crit] ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$crit - Employee ⭐ $score"),
                    Text("Comment: $comment"),
                    const SizedBox(height: 6),
                    RatingBar.builder(
                      initialRating: _managerScores[crit] ?? 3,
                      minRating: 1,
                      itemCount: 5,
                      itemBuilder: (_, __) => Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (val) =>
                          setState(() => _managerScores[crit] = val),
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Your comment"),
                      onChanged: (val) => _managerComments[crit] = val,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              _buildSectionTitle("🔹 Step 2: SWOT Analysis"),
              Text("Employee:\nStrengths: ${eval['swot']?['strengths'] ?? ''}"),
              Text("Weaknesses: ${eval['swot']?['weaknesses'] ?? ''}"),
              Text("Opportunities: ${eval['swot']?['opportunities'] ?? ''}"),
              Text("Threats: ${eval['swot']?['threats'] ?? ''}"),
              TextFormField(controller: _managerStrengthsController, decoration: InputDecoration(labelText: "Your Strengths"), validator: _required),
              TextFormField(controller: _managerWeaknessesController, decoration: InputDecoration(labelText: "Your Weaknesses"), validator: _required),
              TextFormField(controller: _managerOpportunitiesController, decoration: InputDecoration(labelText: "Your Opportunities"), validator: _required),
              TextFormField(controller: _managerThreatsController, decoration: InputDecoration(labelText: "Your Threats"), validator: _required),

              _buildSectionTitle("🔹 Step 3: Achievements"),
              ...(eval['bmc'] ?? []).asMap().entries.map((entry) {
                final index = entry.key;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Employee: ${entry.value}"),
                    TextFormField(
                      controller: _managerAchievements[index],
                      decoration: InputDecoration(labelText: "Manager's View"),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

              _buildSectionTitle("🔹 Step 4: BMC Gameboard"),
              ...(eval['bmc'] ?? []).asMap().entries.map((entry) {
                final i = entry.key;
                final label = _bmcLabels[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$label\nEmployee: ${entry.value}"),
                    TextFormField(
                      controller: _managerBMC[i],
                      decoration: InputDecoration(labelText: "Manager’s Input"),
                      validator: _required,
                    ),
                  ],
                );
              }),

              _buildSectionTitle("🔹 Step 5: Summary"),
              Text("What Went Well: ${eval['summary']?['whatWentWell'] ?? ''}"),
              TextFormField(controller: _managerWentWell, decoration: InputDecoration(labelText: "Your ‘What Went Well’"), validator: _required),
              Text("Power Up: ${eval['summary']?['powerUp'] ?? ''}"),
              TextFormField(controller: _managerPowerUp, decoration: InputDecoration(labelText: "Your ‘Power Up’"), validator: _required),
              Text("Next Steps: ${eval['summary']?['nextSteps'] ?? ''}"),
              TextFormField(controller: _managerNextSteps, decoration: InputDecoration(labelText: "Your Next Steps"), validator: _required),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text(isSubmitting ? "Submitting..." : "Submit"),
                  onPressed: isSubmitting ? null : submitManagerEvaluation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0047BB),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? val) => val == null || val.isEmpty ? 'Required' : null;

  @override
  void dispose() {
    for (final c in _managerAchievements) c.dispose();
    for (final c in _managerBMC) c.dispose();
    _managerStrengthsController.dispose();
    _managerWeaknessesController.dispose();
    _managerOpportunitiesController.dispose();
    _managerThreatsController.dispose();
    _managerWentWell.dispose();
    _managerPowerUp.dispose();
    _managerNextSteps.dispose();
    super.dispose();
  }
}
