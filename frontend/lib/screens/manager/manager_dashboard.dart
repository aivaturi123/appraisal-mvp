import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  Future<List<Map<String, dynamic>>> fetchEvaluatedEmployees() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('evaluations') 
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text("Manager Dashboard"),
        backgroundColor: Color(0xFF0047BB),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/manager-login');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchEvaluatedEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No employee evaluations submitted yet."));
          }

          final evaluations = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Submitted Self-Evaluations",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: evaluations.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final eval = evaluations[index];
                      final name = eval['name'] ??
             eval['employee']?['name'] ??
             eval['employeeName'] ??
             'Unnamed';

                      final timestamp = eval['timestamp'] as Timestamp?;
                      final scoreCount = (eval['scores'] as Map?)?.length ?? 0;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                            child: Icon(Icons.person, color: Color(0xFF0047BB)),
                          ),
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/evaluate-employee',
                              arguments: {
                                'employeeId': eval['id'],
                                'employeeName': name,
                                'selfEvaluation': eval,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}