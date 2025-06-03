import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'ai_feedback_page.dart';

class SelfEvaluationForm extends StatefulWidget {
  final String employeeName;

  const SelfEvaluationForm({super.key, required this.employeeName});

  @override
  State<SelfEvaluationForm> createState() => _SelfEvaluationFormState();
}

class _SelfEvaluationFormState extends State<SelfEvaluationForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final Map<String, double> _scores = {};
  final Map<String, String> _comments = {};
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

  final _strengthsController = TextEditingController();
  final _weaknessesController = TextEditingController();
  final _opportunitiesController = TextEditingController();
  final _threatsController = TextEditingController();

  final _whatWentWellController = TextEditingController();
  final _powerUpController = TextEditingController();
  final _nextStepsController = TextEditingController();

  final List<TextEditingController> _achievementsControllers =
      List.generate(3, (_) => TextEditingController());

  final List<TextEditingController> _bmcControllers =
      List.generate(9, (_) => TextEditingController());

  String? feedbackText;
  bool isSubmitting = false;

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  Future<void> submitEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final timestamp = Timestamp.now();

    final roleSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final employeeRole = roleSnapshot.data()?['role'] ?? 'Not specified';

    final data = {
      'role': employeeRole,
      'name': widget.employeeName,
      'scores': _scores,
      'comments': _comments,
      'swot': {
        'strengths': _strengthsController.text,
        'weaknesses': _weaknessesController.text,
        'opportunities': _opportunitiesController.text,
        'threats': _threatsController.text,
      },
      'achievements': _achievementsControllers.map((e) => e.text).toList(),
      'bmc': _bmcControllers.map((e) => e.text).toList(),
      'summary': {
        'whatWentWell': _whatWentWellController.text,
        'powerUp': _powerUpController.text,
        'nextSteps': _nextStepsController.text,
      },
      'timestamp': timestamp,
    };

    setState(() => isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('evaluations')
          .add(data);

      final jsonSafeData = {
        ...data,
        'timestamp': timestamp.toDate().toIso8601String(),
      };

      final feedbackRes = await http.post(
        Uri.parse('http://localhost:8000/generate-feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonSafeData),
      );

      if (feedbackRes.statusCode == 200) {
        final json = jsonDecode(feedbackRes.body);
        final feedback = json['feedback'];
        print("✅ Feedback received");

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AiFeedbackPage(feedbackText: feedback),
          ),
        );
      } else {
        print("❌ Feedback failed with status ${feedbackRes.statusCode}");
        showSnack("⚠️ Failed to get AI feedback.");
      }
    } catch (e) {
      showSnack('❌ Error: $e');
    }

    setState(() => isSubmitting = false);
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildScorecardStep();
      case 1:
        return _buildSwotStep();
      case 2:
        return _buildAchievementsStep();
      case 3:
        return _buildBmcStep();
      case 4:
        return _buildSummaryStep();
      default:
        return Container();
    }
  }

  Widget _buildScorecardStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('🔹 Step 1: Personal Info + Performance Scorecard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (var crit in _criteria)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crit, style: TextStyle(fontWeight: FontWeight.w600)),
                  RatingBar.builder(
                    initialRating: _scores[crit] ?? 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() => _scores[crit] = rating);
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Comment'),
                    onChanged: (val) => _comments[crit] = val,
                  )
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child:
                ElevatedButton(onPressed: _nextStep, child: Text("Continue")),
          )
        ],
      ),
    );
  }

  Widget _buildSwotStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('🔹 Step 2: SWOT Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTextField('Strengths', _strengthsController),
          _buildTextField('Weaknesses', _weaknessesController),
          _buildTextField('Opportunities', _opportunitiesController),
          _buildTextField('Threats', _threatsController),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(onPressed: _prevStep, child: Text("Back")),
              ElevatedButton(onPressed: _nextStep, child: Text("Continue")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAchievementsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('🔹 Step 3: Achievements & Challenges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTextField(
              "Key accomplishments this quarter", _achievementsControllers[0]),
          _buildTextField("Major challenges and how you overcame them",
              _achievementsControllers[1]),
          _buildTextField("What you’re most proud of",
              _achievementsControllers[2]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(onPressed: _prevStep, child: Text("Back")),
              ElevatedButton(onPressed: _nextStep, child: Text("Continue")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBmcStep() {
    final labels = [
      "Customer Segments (Who do you help the most?)",
      "Value Proposition (What value do you deliver?)",
      "Channels (How do you reach your customers?)",
      "Customer Relationships (How do you build trust?)",
      "Revenue Streams (How do you help grow revenue?)",
      "Key Resources (What tools or skills do you use?)",
      "Key Activities (Your main tasks)",
      "Key Partnerships (Who do you work with?)",
      "Cost Structure (How do you save money or boost efficiency?)",
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '🔹 Step 4: Business Model Canvas - Your Gameboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < labels.length; i++)
            _buildTextField(labels[i], _bmcControllers[i]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(onPressed: _prevStep, child: Text("Back")),
              ElevatedButton(onPressed: _nextStep, child: Text("Continue")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('🔹 Step 5: Summary & Next Steps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTextField(
              "What Went Well (2 strengths)", _whatWentWellController),
          _buildTextField("What To Power Up (2 areas to improve)",
              _powerUpController),
          _buildTextField(
              "Next Steps & Support Needed", _nextStepsController),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(onPressed: _prevStep, child: Text("Back")),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : submitEvaluation,
                icon: Icon(Icons.send),
                label: Text(isSubmitting ? "Submitting..." : "Submit"),
              ),
            ],
          ),
          if (feedbackText != null) ...[
            const SizedBox(height: 20),
            Text("AI Feedback:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(feedbackText!),
          ]
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  void dispose() {
    _strengthsController.dispose();
    _weaknessesController.dispose();
    _opportunitiesController.dispose();
    _threatsController.dispose();
    _whatWentWellController.dispose();
    _powerUpController.dispose();
    _nextStepsController.dispose();
    for (var c in _achievementsControllers) c.dispose();
    for (var c in _bmcControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Self Evaluation Form")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }
}
