import 'package:flutter/material.dart';
import 'view_self_evaluation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDashboard extends StatefulWidget {
  final String employeeName;

  const EmployeeDashboard({
    Key? key,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final TextEditingController _roleController = TextEditingController();
  String? _savedRole;

  @override
  void initState() {
    super.initState();
    _loadExistingRole();
  }

  Future<void> _loadExistingRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('roles').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _savedRole = doc['role'];
        _roleController.text = _savedRole!;
      });
    }
  }

  Future<void> _saveRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final role = _roleController.text.trim();
    if (role.isNotEmpty) {
      await FirebaseFirestore.instance.collection('roles').doc(uid).set({'role': role});
      setState(() => _savedRole = role);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Role saved")));
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text("Welcome, ${widget.employeeName}"),
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/employee-login');
          },
        ),
      ],
    ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, size: 80, color: Color(0xFF0047BB)),
              SizedBox(height: 20),
              Text("Hello, ${widget.employeeName} 👋", style: TextStyle(fontSize: 20)),
              SizedBox(height: 30),

              Text("Your Role", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              
              ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 400), // adjust width as needed
  child: TextField(
    controller: _roleController,
    decoration: InputDecoration(
      hintText: 'e.g., Software Engineer',
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // tighter padding
      suffixIcon: IconButton(
        icon: Icon(Icons.save),
        onPressed: _saveRole,
      ),
    ),
    style: TextStyle(fontSize: 14), // optional: smaller font
  ),
),
SizedBox(height: 30),
              SizedBox(height: 30),

              Text(
                "Start your self-evaluation when you're ready!",
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/self-evaluation',
                    arguments: {
                      'employeeName': widget.employeeName,
                      'role': _roleController.text,
                    },
                  );
                },
                icon: Icon(Icons.assignment),
                label: Text("Start Evaluation"),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
  onPressed: () async {
  try {
    final query = await FirebaseFirestore.instance
        .collection('evaluations')
        .orderBy('timestamp', descending: true) // 🔁 newest first
        .limit(1) // ✅ only the latest
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final hasManagerReview = doc['managerReview'] != null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewSelfEvaluationScreen(
            employeeId: doc.id, // ✅ pass the doc ID
            showManagerReview: hasManagerReview,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ No evaluations found.")),
      );
    }
  } catch (e) {
    print("Error fetching most recent evaluation: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Failed to load evaluation.")),
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
