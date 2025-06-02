import 'package:flutter/material.dart';
import 'view_self_evaluation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDashboard extends StatelessWidget {
  final String employeeName;

  const EmployeeDashboard({
    Key? key,
    required this.employeeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome, $employeeName")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, size: 80, color: Color(0xFF0047BB)),
              SizedBox(height: 20),
              Text("Hello, $employeeName 👋", style: TextStyle(fontSize: 20)),
              SizedBox(height: 30),
              Text(
                "Start your self-evaluation when you're ready!",
                style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/self-evaluation',
                    arguments: {'employeeName': employeeName},
                  );
                },
                icon: Icon(Icons.assignment),
                label: Text("Start Evaluation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  final doc = await FirebaseFirestore.instance
                      .collection('evaluations')
                      .doc(uid)
                      .get();

                  if (doc.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewSelfEvaluationScreen(employeeId: uid),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("⚠️ You haven't submitted an evaluation yet.")),
                    );
                  }
                },
                icon: Icon(Icons.visibility),
                label: Text("View Submitted Evaluation"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
