import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'comparison_view.dart';

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
  final Map<String, String> _managerComments = {};
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
    'Adaptability & Learning'
  ];

  final _bmcLabels = [
    "Customer Segments", "Value Proposition", "Channels",
    "Customer Relationships", "Revenue Streams", "Key Resources",
    "Key Activities", "Key Partnerships", "Cost Structure"
  ];

  Future<void> submitManagerEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('evaluations').doc(widget.evaluation['id']);
      await docRef.set({
  'managerReview': {
    'scores': _managerScores,
    'comments': _managerComments,
    'swot': {
      'strengths': _strengthsController.text,
      'weaknesses': _weaknessesController.text,
      'opportunities': _opportunitiesController.text,
      'threats': _threatsController.text,
    },
    'achievements': _managerAchievements.map((c) => c.text).toList(),
    'bmc': _managerBMC.map((c) => c.text).toList(),
    'summary': {
      'whatWentWell': _wentWellController.text,
      'powerUp': _powerUpController.text,
      'nextSteps': _nextStepsController.text,
    },
    'timestamp': Timestamp.now(),
  }
}, SetOptions(merge: true)); // ✅ merged here


      final updatedData = await docRef.get();
      final data = updatedData.data();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Submission failed: $e")));
    }

    setState(() => isSubmitting = false);
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eval = widget.evaluation;
    


    return Scaffold(
      appBar: AppBar(title: Text("Evaluate ${eval['name']}"), backgroundColor: Color(0xFF0047BB)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
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
                    itemBuilder: (_, __) => Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (val) => setState(() => _managerScores[crit] = val),
                  ),
                  _buildTextField(TextEditingController(text: _managerComments[crit]), "Manager's comment"),
                ],
              );
            }),

            _sectionTitle("🔹 Step 2: SWOT Analysis"),
            Text("Strengths: ${eval['swot']?['strengths'] ?? ''}"),
            Text("Weaknesses: ${eval['swot']?['weaknesses'] ?? ''}"),
            Text("Opportunities: ${eval['swot']?['opportunities'] ?? ''}"),
            Text("Threats: ${eval['swot']?['threats'] ?? ''}"),
            _buildTextField(_strengthsController, " Strengths"),
            _buildTextField(_weaknessesController, " Weaknesses"),
            _buildTextField(_opportunitiesController, " Opportunities"),
            _buildTextField(_threatsController, " Threats"),



_sectionTitle("🔹 Step 3: Achievements & Challenges"),

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("Key Accomplishments: ${eval['achievements']?[0] ?? ''}"),
    _buildTextField(_managerAchievements[0], "Manager’s Comment on Key Accomplishments"),

    SizedBox(height: 12),
    Text("Major Challenges Overcome: ${eval['achievements']?[1] ?? ''}"),
    _buildTextField(_managerAchievements[1], "Manager’s Comment on Challenges Overcome"),

    SizedBox(height: 12),
    Text("What They're Most Proud Of: ${eval['achievements']?[2] ?? ''}"),
    _buildTextField(_managerAchievements[2], "Manager’s Comment on Pride Point"),
  ],
),

_sectionTitle("🔹 Step 4: Business Model Canvas - Your Gameboard"),

Text(
  "Customer Segments (Who do you help the most?)\nEmployee: ${eval['bmc']?[0] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[0], "Manager’s Input: Customer Segments"),
SizedBox(height: 12),

Text(
  "Value Proposition (What value do you deliver?)\nEmployee: ${eval['bmc']?[1] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[1], "Manager’s Input: Value Proposition"),
SizedBox(height: 12),

Text(
  "Channels (How do you reach your customers?)\nEmployee: ${eval['bmc']?[2] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[2], "Manager’s Input: Channels"),
SizedBox(height: 12),

Text(
  "Customer Relationships (How do you build trust?)\nEmployee: ${eval['bmc']?[3] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[3], "Manager’s Input: Customer Relationships"),
SizedBox(height: 12),

Text(
  "Revenue Streams (How do you help grow revenue?)\nEmployee: ${eval['bmc']?[4] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[4], "Manager’s Input: Revenue Streams"),
SizedBox(height: 12),

Text(
  "Key Resources (What tools or skills do you use?)\nEmployee: ${eval['bmc']?[5] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[5], "Manager’s Input: Key Resources"),
SizedBox(height: 12),

Text(
  "Key Activities (Your main tasks)\nEmployee: ${eval['bmc']?[6] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[6], "Manager’s Input: Key Activities"),
SizedBox(height: 12),

Text(
  "Key Partnerships (Who do you work with?)\nEmployee: ${eval['bmc']?[7] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[7], "Manager’s Input: Key Partnerships"),
SizedBox(height: 12),

Text(
  "Cost Structure (How do you save money or boost efficiency?)\nEmployee: ${eval['bmc']?[8] ?? ''}",
  style: TextStyle(fontWeight: FontWeight.w500),
),
_buildTextField(_managerBMC[8], "Manager’s Input: Cost Structure"),
SizedBox(height: 12),




            _sectionTitle("🔹 Step 5: Summary & Next Steps"),
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
    icon: Icon(Icons.send, color: Colors.white), 
    label: Text(
      isSubmitting ? "Submitting..." : "Submit",
      style: TextStyle(color: Colors.white),
    ),
    onPressed: isSubmitting ? null : submitManagerEvaluation,
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF0047BB),
      foregroundColor: Colors.white, 
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
)

          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
