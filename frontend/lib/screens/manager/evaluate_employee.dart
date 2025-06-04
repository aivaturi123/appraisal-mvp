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

  final _achievementQuestions = [
    "📝 Key accomplishments this quarter:",
    "🎯 Major challenges and how you overcame them:",
    "🌟 What you're most proud of:"
  ];

  final _achievementManagerFields = [
    "Manager's Comment on Key Accomplishments",
    "Manager's Comment on Challenges Overcome", 
    "Manager's Comment on What Employee is Proud Of"
  ];

  // Helper function to safely get nested values
  dynamic _getSafeValue(Map<String, dynamic> data, List<String> path, [dynamic defaultValue]) {
    dynamic current = data;
    for (String key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }
    return current ?? defaultValue;
  }

  // Helper function to safely convert Map data
  Map<String, dynamic> _convertToStringMap(dynamic data) {
    if (data == null) return <String, dynamic>{};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(
        data.map((key, value) => MapEntry(key.toString(), value))
      );
    }
    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize comment controllers
    for (var crit in _criteria) {
      _managerCommentControllers[crit] = TextEditingController();
    }

    final eval = widget.evaluation;

    // Safely initialize manager scores and comments
    for (var crit in _criteria) {
      // Get existing manager scores if they exist
      final managerReview = _convertToStringMap(eval['managerReview']);
      final scores = _convertToStringMap(managerReview['scores']);
      final comments = _convertToStringMap(managerReview['comments']);
      
      _managerScores[crit] = (scores[crit] as num?)?.toDouble() ?? 3.0;
      _managerCommentControllers[crit]!.text = comments[crit]?.toString() ?? '';
    }

    // Initialize SWOT analysis
    final managerReview = _convertToStringMap(eval['managerReview']);
    final swot = _convertToStringMap(managerReview['swot']);
    
    _strengthsController.text = swot['strengths']?.toString() ?? '';
    _weaknessesController.text = swot['weaknesses']?.toString() ?? '';
    _opportunitiesController.text = swot['opportunities']?.toString() ?? '';
    _threatsController.text = swot['threats']?.toString() ?? '';

    // Initialize summary fields
    final summary = _convertToStringMap(managerReview['summary']);
    _wentWellController.text = summary['whatWentWell']?.toString() ?? '';
    _powerUpController.text = summary['powerUp']?.toString() ?? '';
    _nextStepsController.text = summary['nextSteps']?.toString() ?? '';
  }

  Future<void> submitManagerEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('evaluations').doc(widget.evaluation['id']);

      final commentsMap = <String, String>{};
      for (var crit in _criteria) {
        commentsMap[crit] = _managerCommentControllers[crit]!.text.trim();
      }

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

      // Get updated document
      final updatedData = await docRef.get();
      final data = updatedData.data();
      
      if (data == null) {
        throw Exception('Failed to retrieve updated evaluation data');
      }

      // Clean data for AI processing
      dynamic clean(dynamic d) {
        if (d is Timestamp) return d.toDate().toIso8601String();
        if (d is Map) {
          return Map<String, dynamic>.from(
            d.map((k, v) => MapEntry(k.toString(), clean(v)))
          );
        }
        if (d is List) return d.map(clean).toList();
        return d;
      }

      final cleanedManager = clean(data['managerReview'] ?? {});
      final cleanedEmployee = clean({
        'name': data['name'],
        'scores': data['scores'],
        'comments': data['comments'],
        'swot': data['swot'],
        'achievements': data['achievements'],
        'bmc': data['bmc'],
        'summary': data['summary'],
      });

      // Call AI service
      try {
        final aiResponse = await http.post(
          Uri.parse('http://localhost:8000/generate-ai-summary'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'employee': cleanedEmployee, 'manager': cleanedManager}),
        );

        String aiSummary = '';
        if (aiResponse.statusCode == 200) {
          final responseData = json.decode(aiResponse.body);
          aiSummary = responseData['summary']?.toString() ?? 'AI summary not available';
        } else {
          aiSummary = 'AI summary service unavailable';
        }

        // Update document with AI summary
        await docRef.update({'aiSummary': aiSummary});

        // Navigate to comparison view
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComparisonView(
              employeeEval: cleanedEmployee as Map<String, dynamic>,
              managerReview: cleanedManager as Map<String, dynamic>,
              aiFeedback: aiSummary,
            ),
          ),
        );
      } catch (aiError) {
        print('AI service error: $aiError');
        // Continue without AI summary
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ComparisonView(
              employeeEval: cleanedEmployee as Map<String, dynamic>,
              managerReview: cleanedManager as Map<String, dynamic>,
              aiFeedback: 'AI feedback unavailable',
            ),
          ),
        );
      }
    } catch (e) {
      print('Submission error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Widget _sectionTitle(String title) => Container(
    margin: const EdgeInsets.symmetric(vertical: 20.0),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFF0047BB), const Color(0xFF0066FF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0047BB).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      title, 
      style: const TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      )
    ),
  );

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: const Color(0xFF0047BB).withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0047BB), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: isRequired ? (val) => val == null || val.trim().isEmpty ? 'This field is required' : null : null,
        maxLines: null,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildEmployeeResponseCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0047BB),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.isEmpty ? 'No response provided' : content,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eval = widget.evaluation;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Evaluate ${eval['name'] ?? 'Employee'}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0047BB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle("⭐ Step 1: Performance Scorecard"),
            ..._criteria.map((crit) {
              final scores = _convertToStringMap(eval['scores']);
              final comments = _convertToStringMap(eval['comments']);
              
              final empScore = (scores[crit] as num?)?.toDouble() ?? 0.0;
              final empComment = comments[crit]?.toString() ?? 'No comment provided';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📊 $crit", 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: Color(0xFF0047BB),
                          )
                        ),
                        const SizedBox(height: 16),
                        
                        // Employee Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "👤 Employee Self-Assessment:",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          empScore.toStringAsFixed(1),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                empComment,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Manager Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "👔 Manager Assessment:",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              RatingBar.builder(
                                initialRating: _managerScores[crit] ?? 3.0,
                                minRating: 1,
                                itemCount: 5,
                                allowHalfRating: false,
                                itemSize: 32,
                                itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                                onRatingUpdate: (val) => setState(() => _managerScores[crit] = val),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _managerCommentControllers[crit]!, 
                                "Your detailed feedback for $crit"
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            _sectionTitle("🎯 Step 2: SWOT Analysis"),
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ["💪 Strengths", "⚠️ Weaknesses", "🚀 Opportunities", "⚡ Threats"][i],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0047BB),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEmployeeResponseCard(
                  "Employee Response:",
                  _getSafeValue(eval, ['swot', ['strengths', 'weaknesses', 'opportunities', 'threats'][i]], 'Not provided').toString(),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  [_strengthsController, _weaknessesController, _opportunitiesController, _threatsController][i],
                  "Manager's Input: ${["Strengths", "Areas for Improvement", "Growth Opportunities", "Potential Challenges"][i]}",
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
),


            _sectionTitle("🏆 Step 3: Achievements & Challenges"),
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _achievementQuestions.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🎯 ${_achievementQuestions[i]}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0047BB),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // Employee Response per question
                _buildEmployeeResponseCard(
                  "Employee Response:",
                  () {
                    final list = eval['achievements'];
                    if (list is List && i < list.length) {
                      return list[i]?.toString() ?? 'Not provided';
                    }
                    return 'Not provided';
                  }()
                ),

                const SizedBox(height: 12),

                // Manager's input field
                _buildTextField(
                  _managerAchievements[i],
                  _achievementManagerFields[i],
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
),



            _sectionTitle("📋 Step 4: Business Model Canvas"),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _bmcLabels.length; i++) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🎯 ${_bmcLabels[i]}:",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0047BB),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildEmployeeResponseCard(
                              "Employee Input:",
                              () {
                                final bmcList = eval['bmc'];
                                if (bmcList is List && i < bmcList.length) {
                                  return bmcList[i]?.toString() ?? 'Not provided';
                                }
                                return 'Not provided';
                              }()
                            ),
                            _buildTextField(
                              _managerBMC[i], 
                              "Manager's Input: ${_bmcLabels[i]}"
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            _sectionTitle("📝 Step 5: Summary & Next Steps"),
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ["✅ What Went Well", "⚡ Power Up", "🎯 Next Steps"][i],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0047BB),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEmployeeResponseCard(
                  "Employee Response:",
                  _getSafeValue(eval, ['summary', ['whatWentWell', 'powerUp', 'nextSteps'][i]], 'Not provided').toString(),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  [_wentWellController, _powerUpController, _nextStepsController][i],
                  "Manager's Input: ${["What Went Well", "Areas to Power Up", "Recommended Next Steps"][i]}",
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
),


            const SizedBox(height: 30),
            Center(
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0047BB), const Color(0xFF0066FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0047BB).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  label: Text(
                    isSubmitting ? "Submitting Evaluation..." : "Submit Manager Review",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: isSubmitting ? null : submitManagerEvaluation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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