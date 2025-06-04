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

  // Criteria for performance scorecard
  final List<String> _criteria = const [
    'Quality of Deliverables',
    'Timeliness & Responsiveness',
    'Client Relationship',
    'Knowledge Sharing & IP',
    'Team Collaboration & Culture',
    'Skill Development',
    'Ownership & Accountability',
    'Adaptability & Learning',
  ];

  final List<String> _bmcLabels = const [
    "Customer Segments", "Value Proposition", "Channels",
    "Customer Relationships", "Revenue Streams", "Key Resources",
    "Key Activities", "Key Partnerships", "Cost Structure"
  ];

  final List<String> _achievementQuestions = const [
    "📝 Key accomplishments this quarter:",
    "🎯 Major challenges and how you overcame them:",
    "🌟 What you're most proud of:"
  ];

  // Helper function to safely get values
  dynamic _getSafeValue(Map<String, dynamic> data, String key, [dynamic defaultValue = 'Not provided']) {
    return data[key] ?? defaultValue;
  }

  Widget _sectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0047BB), const Color(0xFF0066FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0047BB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _comparisonCard({
    required String title,
    required String employeeContent,
    required String managerContent,
    String? employeeScore,
    String? managerScore,
  }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0047BB),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Employee",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            if (employeeScore != null) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      employeeScore,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          employeeContent,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Manager Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business_center, color: Color(0xFF0047BB), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Manager",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0047BB),
                              ),
                            ),
                            if (managerScore != null) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      managerScore,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          managerContent,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiSummaryCard() {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "🧠 AI Feedback Summary",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                aiFeedback,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scores = employeeEval['scores'] ?? {};
    final comments = employeeEval['comments'] ?? {};
    final mgrScores = managerReview['scores'] ?? {};
    final mgrComments = managerReview['comments'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "📊 Evaluation Comparison & AI Analysis",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0047BB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Performance Scorecard
            _sectionHeader("⭐ Step 1: Performance Scorecard"),
            ..._criteria.map((criterion) {
              final empScore = scores[criterion]?.toString() ?? '0';
              final empComment = comments[criterion]?.toString() ?? 'No comment provided';
              final mgrScore = mgrScores[criterion]?.toString() ?? '0';
              final mgrComment = mgrComments[criterion]?.toString() ?? 'No comment provided';

              return _comparisonCard(
                title: "📊 $criterion",
                employeeContent: empComment,
                managerContent: mgrComment,
                employeeScore: empScore,
                managerScore: mgrScore,
              );
            }),

            // Step 2: SWOT Analysis
            _sectionHeader("🎯 Step 2: SWOT Analysis"),
            _comparisonCard(
              title: "💪 Strengths",
              employeeContent: _getSafeValue(employeeEval, 'swot')['strengths']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'swot')['strengths']?.toString() ?? 'Not provided',
            ),
            _comparisonCard(
              title: "⚠️ Areas for Improvement",
              employeeContent: _getSafeValue(employeeEval, 'swot')['weaknesses']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'swot')['weaknesses']?.toString() ?? 'Not provided',
            ),
            _comparisonCard(
              title: "🚀 Growth Opportunities",
              employeeContent: _getSafeValue(employeeEval, 'swot')['opportunities']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'swot')['opportunities']?.toString() ?? 'Not provided',
            ),
            _comparisonCard(
              title: "⚡ Potential Challenges",
              employeeContent: _getSafeValue(employeeEval, 'swot')['threats']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'swot')['threats']?.toString() ?? 'Not provided',
            ),

            // Step 3: Achievements & Challenges
            _sectionHeader("🏆 Step 3: Achievements & Challenges"),
            for (int i = 0; i < _achievementQuestions.length; i++) ...[
              _comparisonCard(
                title: _achievementQuestions[i],
                employeeContent: () {
                  final achievements = employeeEval['achievements'];
                  if (achievements is List && i < achievements.length) {
                    return achievements[i]?.toString() ?? 'Not provided';
                  }
                  return 'Not provided';
                }(),
                managerContent: () {
                  final managerAchievements = managerReview['achievements'];
                  if (managerAchievements is List && i < managerAchievements.length) {
                    return managerAchievements[i]?.toString() ?? 'Not provided';
                  }
                  return 'Not provided';
                }(),
              ),
            ],

            // Step 4: Business Model Canvas
            _sectionHeader("📋 Step 4: Business Model Canvas"),
            for (int i = 0; i < _bmcLabels.length; i++) ...[
              _comparisonCard(
                title: "🎯 ${_bmcLabels[i]}",
                employeeContent: () {
                  final bmc = employeeEval['bmc'];
                  if (bmc is List && i < bmc.length) {
                    return bmc[i]?.toString() ?? 'Not provided';
                  }
                  return 'Not provided';
                }(),
                managerContent: () {
                  final managerBmc = managerReview['bmc'];
                  if (managerBmc is List && i < managerBmc.length) {
                    return managerBmc[i]?.toString() ?? 'Not provided';
                  }
                  return 'Not provided';
                }(),
              ),
            ],

            // Step 5: Summary & Next Steps
            _sectionHeader("📝 Step 5: Summary & Next Steps"),
            _comparisonCard(
              title: "✅ What Went Well",
              employeeContent: _getSafeValue(employeeEval, 'summary')['whatWentWell']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'summary')['whatWentWell']?.toString() ?? 'Not provided',
            ),
            _comparisonCard(
              title: "⚡ Power Up / Areas to Improve",
              employeeContent: _getSafeValue(employeeEval, 'summary')['powerUp']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'summary')['powerUp']?.toString() ?? 'Not provided',
            ),
            _comparisonCard(
              title: "🎯 Next Steps",
              employeeContent: _getSafeValue(employeeEval, 'summary')['nextSteps']?.toString() ?? 'Not provided',
              managerContent: _getSafeValue(managerReview, 'summary')['nextSteps']?.toString() ?? 'Not provided',
            ),

            // AI Summary
            _aiSummaryCard(),
          ],
        ),
      ),
    );
  }
}