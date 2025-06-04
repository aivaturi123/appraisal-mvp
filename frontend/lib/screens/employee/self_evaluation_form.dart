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

  // Brand colors
  static const Color brandBlue = Color(0xFF0047BB);
  static const Color lightBlue = Color(0xFF3366CC);
  static const Color accentBlue = Color(0xFF66B2FF);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color textGray = Color(0xFF2C3E50);

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
      // Validate star ratings are filled
      if (_currentStep == 0) {
        bool allRated = _criteria.every((crit) => _scores[crit] != null && _scores[crit]! > 0);
        if (!allRated) {
          _showSnackBar('Please rate all criteria before continuing', isError: true);
          return;
        }
      }
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
          .doc(uid)
          .set({...data, 'id': uid});

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
        _showSnackBar("⚠️ Failed to get AI feedback.", isError: true);
      }
    } catch (e) {
      _showSnackBar('❌ Error: $e', isError: true);
    }

    setState(() => isSubmitting = false);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red[600] : brandBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Row(
        children: List.generate(5, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: isActive 
                  ? LinearGradient(colors: [brandBlue, lightBlue])
                  : null,
                color: isActive ? null : Colors.grey[300],
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: brandBlue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ] : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGradientHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandBlue, lightBlue, accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
          _buildGradientHeader('🎯 Step 1: Performance Scorecard'),
          _buildRatingLegend(),
          const SizedBox(height: 24),
          for (var crit in _criteria)
            _buildCriteriaCard(crit),
          const SizedBox(height: 24),
          _buildGradientButton(
            text: "Continue",
            onPressed: _nextStep,
            isNext: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingLegend() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange[300], size: 20),
                    Icon(Icons.star_border, color: Colors.grey[400], size: 20),
                    SizedBox(width: 8),
                    Text('1-2 Stars', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange[700])),
                  ],
                ),
                SizedBox(height: 4),
                Text('Needs Extra Power Up', style: TextStyle(fontSize: 12, color: textGray)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (i) => Icon(Icons.star, color: Colors.amber, size: 20)),
                    SizedBox(width: 8),
                    Text('4-5 Stars', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber[700])),
                  ],
                ),
                SizedBox(height: 4),
                Text('MVP Status', style: TextStyle(fontSize: 12, color: textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaCard(String criterion) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            criterion,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: textGray,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: RatingBar.builder(
              initialRating: _scores[criterion] ?? 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              unratedColor: Colors.grey[300],
              itemPadding: EdgeInsets.symmetric(horizontal: 6.0),
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(Icons.star, color: Colors.amber),
              ),
              onRatingUpdate: (rating) {
                setState(() => _scores[criterion] = rating);
              },
            ),
          ),
          SizedBox(height: 16),
          _buildModernTextField(
            'Comment *',
            null,
            onChanged: (val) => _comments[criterion] = val,
            validator: (val) => val == null || val.isEmpty ? 'Comment is required' : null,
          ),
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
          _buildGradientHeader('🎯 Step 2: SWOT Analysis'),
          _buildModernTextField('Strengths *', _strengthsController, isRequired: true),
          _buildModernTextField('Weaknesses *', _weaknessesController, isRequired: true),
          _buildModernTextField('Opportunities *', _opportunitiesController, isRequired: true),
          _buildModernTextField('Threats *', _threatsController, isRequired: true),
          SizedBox(height: 24),
          _buildNavigationButtons(),
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
          _buildGradientHeader('🏆 Step 3: Achievements & Challenges'),
          _buildModernTextField(
              "Key accomplishments this quarter *", _achievementsControllers[0], isRequired: true),
          _buildModernTextField("Major challenges and how you overcame them *",
              _achievementsControllers[1], isRequired: true),
          _buildModernTextField("What you're most proud of *",
              _achievementsControllers[2], isRequired: true),
          SizedBox(height: 24),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildBmcStep() {
    final labels = [
      "Customer Segments (Who do you help the most?) *",
      "Value Proposition (What value do you deliver?) *",
      "Channels (How do you reach your customers?) *",
      "Customer Relationships (How do you build trust?) *",
      "Revenue Streams (How do you help grow revenue?) *",
      "Key Resources (What tools or skills do you use?) *",
      "Key Activities (Your main tasks) *",
      "Key Partnerships (Who do you work with?) *",
      "Cost Structure (How do you save money or boost efficiency?) *",
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildGradientHeader('🎲 Step 4: Business Model Canvas'),
          for (int i = 0; i < labels.length; i++)
            _buildModernTextField(labels[i], _bmcControllers[i], isRequired: true),
          SizedBox(height: 24),
          _buildNavigationButtons(),
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
          _buildGradientHeader('📋 Step 5: Summary & Next Steps'),
          _buildModernTextField(
              "What Went Well (2 strengths) *", _whatWentWellController, isRequired: true),
          _buildModernTextField("What To Power Up (2 areas to improve) *",
              _powerUpController, isRequired: true),
          _buildModernTextField(
              "Next Steps & Support Needed *", _nextStepsController, isRequired: true),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGradientButton(
                text: "Back",
                onPressed: _prevStep,
                isNext: false,
              ),
              _buildGradientButton(
                text: isSubmitting ? "Submitting..." : "Submit",
                onPressed: isSubmitting ? null : submitEvaluation,
                isNext: true,
                icon: Icons.send,
              ),
            ],
          ),
          if (feedbackText != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.blue[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brandBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🤖 AI Feedback:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: brandBlue,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    feedbackText!,
                    style: TextStyle(color: textGray, height: 1.5),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildModernTextField(
    String labelText,
    TextEditingController? controller, {
    Function(String)? onChanged,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 3,
        style: TextStyle(color: textGray),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: brandBlue.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: brandBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator ?? (isRequired 
          ? (val) => val == null || val.isEmpty ? 'This field is required' : null 
          : null),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGradientButton(
          text: "Back",
          onPressed: _prevStep,
          isNext: false,
        ),
        _buildGradientButton(
          text: "Continue",
          onPressed: _nextStep,
          isNext: true,
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isNext,
    IconData? icon,
  }) {
    final colors = isNext 
      ? [brandBlue, lightBlue] 
      : [Colors.grey[600]!, Colors.grey[700]!];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: (isNext ? brandBlue : Colors.grey[600]!).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: Text(
          "Self Evaluation Form",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: brandBlue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [brandBlue, lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                _buildStepIndicator(),
                _buildStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}