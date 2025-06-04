import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'comparison_view.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EvaluateEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic> evaluation;

  const EvaluateEmployeeScreen({Key? key, required this.evaluation}) : super(key: key);

  @override
  State<EvaluateEmployeeScreen> createState() => _EvaluateEmployeeScreenState();
}

class _EvaluateEmployeeScreenState extends State<EvaluateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  final Map<String, double> _managerScores = {};
  final Map<String, TextEditingController> _managerCommentControllers = {};

  // Manager input controllers: start empty, manager fills fresh
  final List<TextEditingController> _managerAchievements = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _managerBMC = List.generate(9, (_) => TextEditingController());

  final _strengthsController = TextEditingController();
  final _weaknessesController = TextEditingController();
  final _opportunitiesController = TextEditingController();
  final _threatsController = TextEditingController();

  final _wentWellController = TextEditingController();
  final _powerUpController = TextEditingController();
  final _nextStepsController = TextEditingController();

  final _criteria = [
    'Quality of Deliverables',
    'Timeliness & Responsiveness',
    'Client Relationship',
    'Knowledge Sharing & IP',
    'Team Collaboration & Culture',
    'Skill Development',
    'Ownership & Accountability',
    'Adaptability & Learning',
  ];

  final _bmcLabels = [
    "Customer Segments", "Value Proposition", "Channels",
    "Customer Relationships", "Revenue Streams", "Key Resources",
    "Key Activities", "Key Partnerships", "Cost Structure"
  ];

  @override
  void initState() {
    super.initState();

    for (var crit in _criteria) {
      _managerCommentControllers[crit] = TextEditingController();
    }

    final eval = widget.evaluation;

    // Initialize manager scores if available, else default to 3.0
    if (eval['managerReview']?['scores'] != null) {
      Map<String, dynamic> mgrScores = eval['managerReview']['scores'];
      mgrScores.forEach((key, value) {
        _managerScores[key] = (value is num) ? value.toDouble() : 3.0;
      });
    } else {
      for (var crit in _criteria) {
        _managerScores[crit] = 3.0;
      }
    }

    // Initialize manager comment controllers with any existing comments
    if (eval['managerReview']?['comments'] != null) {
      Map<String, dynamic> mgrComments = eval['managerReview']['comments'];
      mgrComments.forEach((key, value) {
        if (_managerCommentControllers.containsKey(key)) {
          _managerCommentControllers[key]!.text = value.toString();
        }
      });
    }

    // Preload SWOT fields from managerReview if available (manager inputs)
    final swot = eval['managerReview']?['swot'] ?? {};
    _strengthsController.text = swot['strengths'] ?? '';
    _weaknessesController.text = swot['weaknesses'] ?? '';
    _opportunitiesController.text = swot['opportunities'] ?? '';
    _threatsController.text = swot['threats'] ?? '';

    // *** REMOVE loading employee self-eval into manager controllers ***
    // We ONLY show employee self-eval as Text in build()

    // So, do NOT assign employeeAchievements, employeeBmc, or employeeSummary
    // to manager controllers here.
  }

  Future<void> submitManagerEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('evaluations')
          .doc(widget.evaluation['id']);

      final commentsMap = <String, String>{};
      _managerCommentControllers.forEach((key, controller) {
        commentsMap[key] = controller.text.trim();
      });

      await docRef.set({
        'managerReview': {
          'scores': _managerScores,
          'comments': commentsMap,
          'swot': {
            'strengths': _strengthsController.text.trim(),
            'weaknesses': _weaknessesController.text.trim(),
            'opportunities': _opportunitiesController.text.trim(),
            'threats': _threatsController.text.trim(),
          },
          'achievements': _managerAchievements.map((c) => c.text.trim()).toList(),
          'bmc': _managerBMC.map((c) => c.text.trim()).toList(),
          'summary': {
            'whatWentWell': _wentWellController.text.trim(),
            'powerUp': _powerUpController.text.trim(),
            'nextSteps': _nextStepsController.text.trim(),
          },
          'timestamp': Timestamp.now(),
        }
      }, SetOptions(merge: true));

      // Fetch updated doc after write
      final updatedData = await docRef.get();
      final data = updatedData.data();

      dynamic cleanFirestoreData(dynamic data) {
        if (data is Timestamp) {
          return data.toDate().toIso8601String();
        } else if (data is Map) {
          return data.map((key, value) => MapEntry(key, cleanFirestoreData(value)));
        } else if (data is List) {
          return data.map((item) => cleanFirestoreData(item)).toList();
        }
        return data;
      }

      final cleanedEmployee = cleanFirestoreData({
        'scores': data?['scores'],
        'comments': data?['comments'],
        'swot': data?['swot'],
        'achievements': data?['achievements'],
        'bmc': data?['bmc'],
        'summary': data?['summary'],
      });

      final cleanedManager = cleanFirestoreData(data?['managerReview'] ?? {});

      // Call AI summary endpoint
      final aiResponse = await http.post(
        Uri.parse('http://localhost:8000/generate-ai-summary'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employee': cleanedEmployee,
          'manager': cleanedManager,
        }),
      );

      String aiSummary = '';
      if (aiResponse.statusCode == 200) {
        final jsonResp = json.decode(aiResponse.body);
        aiSummary = jsonResp['summary'] ?? '';
      } else {
        throw Exception('Failed to fetch AI summary');
      }

      // Save AI summary back to doc
      await docRef.update({'aiSummary': aiSummary});

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ComparisonView(
            employeeEval: {
              'name': data?['name'],
              'scores': data?['scores'] ?? {},
              'comments': data?['comments'] ?? {},
              'swot': data?['swot'] ?? {},
              'achievements': data?['achievements'] ?? [],
              'bmc': data?['bmc'] ?? [],
              'summary': data?['summary'] ?? {},
              'timestamp': data?['timestamp']?.toDate().toIso8601String(),
            },
            managerReview: data?['managerReview'] ?? {},
            aiFeedback: aiSummary,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Submission failed: $e")),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
        maxLines: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eval = widget.evaluation;

    return Scaffold(
      appBar: AppBar(
        title: Text("Evaluate ${eval['name'] ?? 'Employee'}"),
        backgroundColor: const Color(0xFF0047BB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle("🔹 Step 1: Scorecard"),
            ..._criteria.map((crit) {
              final empScore = (eval['scores'] ?? {})[crit]?.toDouble() ?? 0;
              final empComment = (eval['comments'] ?? {})[crit] ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$crit - Employee ⭐ $empScore\nComment: $empComment"),
                  RatingBar.builder(
                    initialRating: _managerScores[crit] ?? 3,
                    minRating: 1,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (val) => setState(() => _managerScores[crit] = val),
                  ),
                  _buildTextField(_managerCommentControllers[crit]!, "Manager's comment"),
                ],
              );
            }),

            _sectionTitle("🔹 Step 2: SWOT Analysis"),
            Text("Strengths: ${eval['swot']?['strengths'] ?? ''}"),
            Text("Weaknesses: ${eval['swot']?['weaknesses'] ?? ''}"),
            Text("Opportunities: ${eval['swot']?['opportunities'] ?? ''}"),
            Text("Threats: ${eval['swot']?['threats'] ?? ''}"),
            _buildTextField(_strengthsController, "Strengths"),
            _buildTextField(_weaknessesController, "Weaknesses"),
            _buildTextField(_opportunitiesController, "Opportunities"),
            _buildTextField(_threatsController, "Threats"),

            _sectionTitle("🔹 Step 3: Achievements & Challenges"),
            // Display employee achievements as text only:
            Text("Key Accomplishments: ${eval['achievements']?[0] ?? ''}"),
            _buildTextField(_managerAchievements[0], "Manager’s Comment on Key Accomplishments"),
            const SizedBox(height: 12),
            Text("Major Challenges Overcome: ${eval['achievements']?[1] ?? ''}"),
            _buildTextField(_managerAchievements[1], "Manager’s Comment on Challenges Overcome"),
            const SizedBox(height: 12),
            Text("What They're Most Proud Of: ${eval['achievements']?[2] ?? ''}"),
            _buildTextField(_managerAchievements[2], "Manager’s Comment on Pride Point"),

            _sectionTitle("🔹 Step 4: Business Model Canvas - Your Gameboard"),
            // Display employee BMC as text only + manager input fields:
            for (int i = 0; i < _bmcLabels.length; i++) ...[
              Text(
                "${_bmcLabels[i]}\nEmployee: ${eval['bmc']?[i] ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              _buildTextField(_managerBMC[i], "Manager’s Input: ${_bmcLabels[i]}"),
              const SizedBox(height: 12),
            ],

            _sectionTitle("🔹 Step 5: Summary & Next Steps"),
            // Display employee summary as text only + manager input fields
            Text("What Went Well: ${eval['summary']?['whatWentWell'] ?? ''}"),
            _buildTextField(_wentWellController, "‘What Went Well’"),
            Text("Power Up: ${eval['summary']?['powerUp'] ?? ''}"),
            _buildTextField(_powerUpController, "‘Power Up’"),
            Text("Next Steps: ${eval['summary']?['nextSteps'] ?? ''}"),
            _buildTextField(_nextStepsController, "Next Steps"),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(isSubmitting ? "Submitting..." : "Submit", style: const TextStyle(color: Colors.white)),
                onPressed: isSubmitting ? null : submitManagerEvaluation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047BB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _managerCommentControllers.forEach((_, c) => c.dispose());
    _managerAchievements.forEach((c) => c.dispose());
    _managerBMC.forEach((c) => c.dispose());
    _strengthsController.dispose();
    _weaknessesController.dispose();
    _opportunitiesController.dispose();
    _threatsController.dispose();
    _wentWellController.dispose();
    _powerUpController.dispose();
    _nextStepsController.dispose();
    super.dispose();
  }
}
