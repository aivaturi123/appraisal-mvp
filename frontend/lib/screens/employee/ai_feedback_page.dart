import 'package:flutter/material.dart';

class AiFeedbackPage extends StatelessWidget {
  final String feedbackText;

  const AiFeedbackPage({super.key, required this.feedbackText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Performance Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Here’s your personalized feedback:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0047BB)),
                  ),
                  child: Text(
                    feedbackText,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
