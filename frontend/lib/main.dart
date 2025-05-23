import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(EmployeeEvalApp());
}

class EmployeeEvalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Evaluation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color.fromARGB(255, 3, 33, 64),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: EvaluationForm(),
    );
  }
}

class EvaluationForm extends StatefulWidget {
  @override
  _EvaluationFormState createState() => _EvaluationFormState();
}

class _EvaluationFormState extends State<EvaluationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skillsController = TextEditingController();
  final _goalsController = TextEditingController();
  int _workQuality = 3;
  int _collaboration = 3;

  String? feedbackText;

  Future<void> submitEvaluation() async {
    final submitUrl = Uri.parse('http://localhost:8000/submit-evaluation');
    final feedbackUrl = Uri.parse('http://localhost:8000/generate-feedback');

    final requestData = {
      'name': _nameController.text,
      'work_quality': _workQuality,
      'skill_dev': _skillsController.text,
      'collaboration': _collaboration,
      'goals': _goalsController.text,
    };

    try {
      final submitResponse = await http.post(
        submitUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (submitResponse.statusCode == 200) {
        final feedbackResponse = await http.post(
          feedbackUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        if (feedbackResponse.statusCode == 200) {
          final data = json.decode(feedbackResponse.body);
          print("Feedback from backend: ${data['feedback']}");
          setState(() {
            feedbackText = data['feedback'];
          });
          _formKey.currentState?.reset();
        } else {
          print("Error from feedback endpoint: ${feedbackResponse.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Failed to get AI feedback')),
          );
        }
      } else {
        print("Error from submit endpoint: ${submitResponse.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving evaluation')),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  Widget buildSectionCard({required String title, required Widget child}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          child
        ]),
      ),
    );
  }

  Widget buildSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$value',
          onChanged: (val) => onChanged(val.toInt()),
        ),
      ],
    );
  }

  Widget buildFeedbackCard(String feedback) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: Colors.indigo, size: 40),
            SizedBox(height: 10),
            Text(
              'AI Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(height: 20, thickness: 1),
            Text(
              feedback,
              style: TextStyle(fontSize: 15),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee Self Evaluation')),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: SingleChildScrollView(
            child: Column(children: [
              if (feedbackText != null)
                buildFeedbackCard(feedbackText!)
              else
                SizedBox.shrink(),
              Form(
                key: _formKey,
                child: Column(children: [
                  buildSectionCard(
                    title: 'Your Name',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: 'Enter your name'),
                    ),
                  ),
                  buildSectionCard(
                    title: 'Work Quality',
                    child: buildSlider('Rate your work quality', _workQuality,
                        (val) => setState(() => _workQuality = val)),
                  ),
                  buildSectionCard(
                    title: 'Collaboration',
                    child: buildSlider(
                        'Rate your collaboration',
                        _collaboration,
                        (val) => setState(() => _collaboration = val)),
                  ),
                  buildSectionCard(
                    title: 'Skills Developed',
                    child: TextFormField(
                      controller: _skillsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                          hintText: 'E.g. SQL, Python, teamwork...'),
                    ),
                  ),
                  buildSectionCard(
                    title: 'Future Goals',
                    child: TextFormField(
                      controller: _goalsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                          hintText: 'What do you want to improve next cycle?'),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: submitEvaluation,
                    icon: Icon(Icons.check),
                    label: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
