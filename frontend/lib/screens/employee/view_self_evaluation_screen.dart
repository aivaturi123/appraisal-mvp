import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewSelfEvaluationScreen extends StatefulWidget {
  final String employeeId;
  final bool showManagerReview;

  const ViewSelfEvaluationScreen({
    Key? key,
    required this.employeeId,
    this.showManagerReview = false,
  }) : super(key: key);

  @override
  State<ViewSelfEvaluationScreen> createState() => _ViewSelfEvaluationScreenState();
}

class _ViewSelfEvaluationScreenState extends State<ViewSelfEvaluationScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? evalData;
  bool isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Brand colors
  static const Color primaryBlue = Color(0xFF0047BB);
  static const Color lightBlue = Color(0xFF4A90E2);
  static const Color darkBlue = Color(0xFF003A9B);
  static const Color accentGold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    loadEvaluation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadEvaluation() async {
    try {
      print("🔍 Loading evaluation for employeeId: ${widget.employeeId}");
      
      // Use the original working approach - direct document lookup
      final doc = await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(widget.employeeId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        print("📊 Found evaluation data: ${data?.keys.toList()}");
        
        setState(() {
          evalData = data;
          isLoading = false;
        });
        _fadeController.forward();
      } else {
        print("⚠️ No evaluation found for document ID: ${widget.employeeId}");
        setState(() {
          isLoading = false;
        });
        _showStyledSnackBar("⚠️ No evaluation found for employee ID: ${widget.employeeId}", Colors.orange);
      }
    } catch (e, stack) {
      print("🔥 Firestore load error: $e");
      print("📛 Stack trace:\n$stack");
      
      // Handle specific errors
      String errorMessage = "❌ Failed to load evaluation";
      if (e.toString().contains('permission-denied')) {
        errorMessage = "🔒 Permission denied. Check Firestore rules.";
      } else if (e.toString().contains('unavailable')) {
        errorMessage = "🌐 Network error. Check your connection.";
      }
      
      setState(() {
        isLoading = false;
      });
      _showStyledSnackBar(errorMessage, Colors.red);
    }
  }

  void _showStyledSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGradientContainer({
    required Widget child,
    required List<Color> gradientColors,
    double borderRadius = 16,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return _buildGradientContainer(
      gradientColors: [primaryBlue, lightBlue],
      borderRadius: 12,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledField(String label, dynamic value, {IconData? icon}) {
    // Handle different types of values safely
    String displayValue;
    if (value == null) {
      displayValue = 'Not provided';
    } else if (value is String) {
      displayValue = value.isEmpty ? 'Not provided' : value;
    } else if (value is Map || value is List) {
      displayValue = value.toString();
    } else {
      displayValue = value.toString();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Row(
              children: [
                Icon(icon, size: 18, color: primaryBlue),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkBlue,
                  ),
                ),
              ],
            )
          else
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lightBlue.withOpacity(0.3), width: 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              initialValue: displayValue,
              readOnly: true,
              maxLines: displayValue.length > 100 ? null : 1,
              style: TextStyle(
                fontSize: 16,
                color: displayValue != 'Not provided' ? Colors.black87 : Colors.grey.shade600,
                fontWeight: displayValue != 'Not provided' ? FontWeight.w500 : FontWeight.normal,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintText: displayValue == 'Not provided' ? 'No data available' : null,
                hintStyle: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String category, dynamic score, String? comment) {
    final scoreValue = score?.toString() ?? 'N/A';
    final scoreNum = int.tryParse(scoreValue) ?? 0;
    
    return Card(
      elevation: 8,
      shadowColor: primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: scoreNum >= 4
                          ? [Colors.green, Colors.green.shade300]
                          : scoreNum >= 3
                              ? [accentGold, Colors.yellow.shade300]
                              : [Colors.red, Colors.red.shade300],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scoreValue,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (comment != null && comment.isNotEmpty) 
              ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    comment,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildManagerReviewSection() {
    final managerReview = evalData?['managerReview'];
    if (managerReview == null) {
      return _buildGradientContainer(
        gradientColors: [Colors.orange.shade100, Colors.orange.shade200],
        child: Row(
          children: [
            Icon(Icons.pending, color: Colors.orange.shade700, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Manager review is pending submission",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("🧑‍💼 Manager's Review", Icons.supervisor_account),
        SizedBox(height: 20),
        
        // Manager scores and comments
        if (managerReview['scores'] != null && managerReview['scores'] is Map)
          for (var key in (managerReview['scores'] as Map).keys)
            _buildScoreCard(
              "Manager - $key",
              managerReview['scores'][key],
              managerReview['comments'] is Map ? managerReview['comments'][key] : null,
            ),
        
        SizedBox(height: 20),
        
        // Handle manager summary - check if it's a Map or String
        if (managerReview['summary'] != null) 
          ...[
            if (managerReview['summary'] is Map) 
              ...[
                // If summary is a Map, show its components
                () {
                  final summaryMap = managerReview['summary'] as Map<String, dynamic>;
                  return Column(
                    children: [
                      _buildStyledField("Manager Summary - What Went Well", summaryMap['whatWentWell'], icon: Icons.thumb_up),
                      _buildStyledField("Manager Summary - Areas to Power Up", summaryMap['powerUp'], icon: Icons.power_settings_new),
                      _buildStyledField("Manager Summary - Next Steps", summaryMap['nextSteps'], icon: Icons.arrow_forward),
                    ],
                  );
                }(),
              ] 
            else 
              ...[
                // If summary is a String, show it directly
                _buildStyledField("Manager Summary", managerReview['summary'], icon: Icons.summarize),
              ]
          ],
        
        // AI Summary if available - also handle both Map and String cases
        if (managerReview['aiSummary'] != null) 
          ...[
            SizedBox(height: 20),
            _buildGradientContainer(
              gradientColors: [Colors.purple.shade100, Colors.purple.shade200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple.shade700, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "🤖 AI Performance Insights",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    managerReview['aiSummary'] is String 
                      ? managerReview['aiSummary'] 
                      : managerReview['aiSummary'].toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.purple.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

        // Show global AI Summary if it exists at root level
        if (evalData?['aiSummary'] != null) 
          ...[
            SizedBox(height: 20),
            _buildGradientContainer(
              gradientColors: [Colors.green.shade100, Colors.green.shade200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "🤖 Overall AI Assessment",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    evalData!['aiSummary'] is String 
                      ? evalData!['aiSummary'] 
                      : evalData!['aiSummary'].toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, lightBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Loading your evaluation...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Your Performance Evaluation",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Debug info button
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Debug Info"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Employee ID: ${widget.employeeId}"),
                      Text("Show Manager Review: ${widget.showManagerReview}"),
                      Text("Collection: evaluations"),
                      Text("Document ID: ${widget.employeeId}"),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            isLoading = true;
                            evalData = null;
                          });
                          loadEvaluation(); // Retry loading
                        },
                        child: Text("Retry Load"),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, lightBlue],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? _buildLoadingState()
          : evalData == null
              ? Center(
                  child: _buildGradientContainer(
                    gradientColors: [Colors.red.shade100, Colors.red.shade200],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
                        SizedBox(height: 16),
                        Text(
                          "No evaluation found",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please complete your self-evaluation first",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Self-Evaluation Scores & Comments
                        _buildSectionHeader("📝 Your Self-Assessment", Icons.assessment),
                        SizedBox(height: 20),
                        
                        if (evalData!['scores'] != null)
                          for (var key in (evalData!['scores'] as Map).keys)
                            _buildScoreCard(
                              key,
                              evalData!['scores'][key],
                              evalData!['comments'] is Map ? evalData!['comments'][key] : null,
                            ),

                        SizedBox(height: 32),

                        // SWOT Analysis
                        _buildSectionHeader("🔍 SWOT Analysis", Icons.analytics),
                        SizedBox(height: 20),
                        _buildStyledField("💪 Strengths", evalData!['swot']?['strengths'], icon: Icons.trending_up),
                        _buildStyledField("⚠️ Weaknesses", evalData!['swot']?['weaknesses'], icon: Icons.trending_down),
                        _buildStyledField("🚀 Opportunities", evalData!['swot']?['opportunities'], icon: Icons.rocket_launch),
                        _buildStyledField("⚡ Threats", evalData!['swot']?['threats'], icon: Icons.warning),

                        SizedBox(height: 32),

                        // Achievements & Challenges
                        _buildSectionHeader("🏆 Achievements & Challenges", Icons.emoji_events),
                        SizedBox(height: 20),
                        _buildStyledField("🎯 Accomplishments", evalData!['achievements'] is List && (evalData!['achievements'] as List).isNotEmpty ? evalData!['achievements'][0] : null, icon: Icons.check_circle),
                        _buildStyledField("🔥 Challenges", evalData!['achievements'] is List && (evalData!['achievements'] as List).length > 1 ? evalData!['achievements'][1] : null, icon: Icons.bolt),
                        _buildStyledField("❤️ Most Proud Of", evalData!['achievements'] is List && (evalData!['achievements'] as List).length > 2 ? evalData!['achievements'][2] : null, icon: Icons.favorite),

                        SizedBox(height: 32),

                        // Business Model Canvas
                        _buildSectionHeader("📌 Business Model Canvas", Icons.dashboard),
                        SizedBox(height: 20),
                        if (evalData!['bmc'] is List) 
                          ...[
                            _buildStyledField("👥 Customer Segments", (evalData!['bmc'] as List).isNotEmpty ? evalData!['bmc'][0] : null),
                            _buildStyledField("💎 Value Proposition", (evalData!['bmc'] as List).length > 1 ? evalData!['bmc'][1] : null),
                            _buildStyledField("📺 Channels", (evalData!['bmc'] as List).length > 2 ? evalData!['bmc'][2] : null),
                            _buildStyledField("🤝 Customer Relationships", (evalData!['bmc'] as List).length > 3 ? evalData!['bmc'][3] : null),
                            _buildStyledField("💰 Revenue Streams", (evalData!['bmc'] as List).length > 4 ? evalData!['bmc'][4] : null),
                            _buildStyledField("🔧 Key Resources", (evalData!['bmc'] as List).length > 5 ? evalData!['bmc'][5] : null),
                            _buildStyledField("⚙️ Key Activities", (evalData!['bmc'] as List).length > 6 ? evalData!['bmc'][6] : null),
                            _buildStyledField("🤝 Key Partnerships", (evalData!['bmc'] as List).length > 7 ? evalData!['bmc'][7] : null),
                            _buildStyledField("💸 Cost Structure", (evalData!['bmc'] as List).length > 8 ? evalData!['bmc'][8] : null),
                          ],

                        SizedBox(height: 32),

                        // Summary & Next Steps
                        _buildSectionHeader("📋 Summary & Next Steps", Icons.playlist_add_check),
                        SizedBox(height: 20),
                        _buildStyledField("✅ What Went Well", evalData!['summary']?['whatWentWell'], icon: Icons.thumb_up),
                        _buildStyledField("⚡ Areas to Power Up", evalData!['summary']?['powerUp'], icon: Icons.power_settings_new),
                        _buildStyledField("🎯 Next Steps", evalData!['summary']?['nextSteps'], icon: Icons.arrow_forward),

                        SizedBox(height: 32),

                        // Manager Review Section
                        if (widget.showManagerReview) 
                          ...[
                            _buildManagerReviewSection(),
                            SizedBox(height: 32),
                          ],

                        // Footer
                        _buildGradientContainer(
                          gradientColors: [primaryBlue.withOpacity(0.1), lightBlue.withOpacity(0.1)],
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: primaryBlue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Keep growing and improving! Your journey matters.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}