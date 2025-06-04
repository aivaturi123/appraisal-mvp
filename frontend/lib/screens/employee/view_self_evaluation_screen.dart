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

class _ViewSelfEvaluationScreenState extends State<ViewSelfEvaluationScreen> {
  Map<String, dynamic>? evalData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEvaluation();
  }

  Future<void> loadEvaluation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(widget.employeeId)
          .get();

      if (doc.exists) {
        setState(() {
          evalData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ No evaluation found")));
      }
    } catch (e, stack) {
       print("🔥 Firestore load error: $e");
      print("📛 Stack trace:\n$stack");
      print("Error loading evaluation: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to load evaluation")));
    }
  }

  Widget buildField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value ?? '',
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildManagerReviewSection() {
    final managerReview = evalData?['managerReview'];
    if (managerReview == null) return Text("Manager review not yet submitted.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("🧑‍💼 Manager's Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        for (var key in (managerReview['scores'] as Map).keys)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildField("Manager Score - $key", managerReview['scores'][key].toString()),
              buildField("Manager Comment - $key", managerReview['comments'][key]),
            ],
          ),
        Divider(height: 30),
        buildField("Manager Summary", managerReview['summary']),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Submitted Evaluation")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : evalData == null
              ? Center(child: Text("No evaluation found."))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📝 Scores & Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      for (var key in (evalData!['scores'] as Map).keys)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildField("Score - $key", evalData!['scores'][key].toString()),
                            buildField("Comment - $key", evalData!['comments'][key]),
                          ],
                        ),
                      Divider(height: 30),
                      Text("🔍 SWOT Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      buildField("Strengths", evalData!['swot']['strengths']),
                      buildField("Weaknesses", evalData!['swot']['weaknesses']),
                      buildField("Opportunities", evalData!['swot']['opportunities']),
                      buildField("Threats", evalData!['swot']['threats']),
                      Divider(height: 30),
                      Text("🏆 Achievements & Challenges", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      buildField("Accomplishments", evalData!['achievements'][0]),
                      buildField("Challenges", evalData!['achievements'][1]),
                      buildField("Proud Of", evalData!['achievements'][2]),
                      Divider(height: 30),
                      Text("📌 Business Model Canvas - Your Gameboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      buildField( "Customer Segments (Who do you help the most?)", evalData!['bmc'][0]),
                      buildField( "Value Proposition (What value do you deliver?)", evalData!['bmc'][1]),
                      buildField( "Channels (How do you reach your customers?)", evalData!['bmc'][2]),
                      buildField( "Customer Relationships (How do you engage with them?)", evalData!['bmc'][3]),
                      buildField( "Revenue Streams (How do you make money?)", evalData!['bmc'][4]),
                      buildField( "Key Resources (What do you need to deliver value?)", evalData!['bmc'][5]),
                      buildField( "Key Activities (What do you do to create value?)", evalData!['bmc'][6]),
                      buildField( "Key Partnerships (Who helps you succeed?)", evalData!['bmc'][7]),
                      buildField( "Cost Structure (What are your costs?)", evalData!['bmc'][8]),
                      Divider(height: 30),
                      Text("📌 Summary & Next Steps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      buildField("What Went Well", evalData!['summary']['whatWentWell']),
                      buildField("Areas to Power Up", evalData!['summary']['powerUp']),
                      buildField("Next Steps", evalData!['summary']['nextSteps']),
                      SizedBox(height: 30),
                      if (widget.showManagerReview) buildManagerReviewSection(),
                    ],
                  ),
                ),
    );
  }
}