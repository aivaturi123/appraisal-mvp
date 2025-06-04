import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  // Helper function to safely convert Firestore data
  Map<String, dynamic> _convertFirestoreData(dynamic data) {
    if (data == null) return <String, dynamic>{};
    
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(
        data.map((key, value) => MapEntry(key.toString(), _convertValue(value)))
      );
    }
    return <String, dynamic>{};
  }

  // Helper function to recursively convert nested values
  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, val) => MapEntry(key.toString(), _convertValue(val)))
      );
    } else if (value is List) {
      return value.map((item) => _convertValue(item)).toList();
    } else if (value is Timestamp) {
      return value; // Keep Timestamp as is, convert when needed
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        backgroundColor: const Color(0xFF0047BB),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/manager-login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('evaluations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No employee evaluations submitted yet."));
          }
          
          final docs = snapshot.data!.docs;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Submitted Self-Evaluations",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      
                      // 🔐 Safe conversion from Firestore data
                      final rawData = doc.data();
                      final data = _convertFirestoreData(rawData);
                      data['id'] = doc.id; // Add document ID
                      
                      // Extract employee name safely
                      final name = data['name'] ??
                          data['employee']?['name'] ??
                          data['employeeName'] ??
                          'Unnamed Employee';
                      
                      // Get submission timestamp for display
                      final timestamp = data['timestamp'] as Timestamp?;
                      final dateString = timestamp != null 
                          ? timestamp.toDate().toString().split(' ')[0]
                          : 'No date';
                      
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 10
                          ),
                          leading: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                            child: Icon(Icons.person, color: Color(0xFF0047BB)),
                          ),
                          title: Text(
                            name, 
                            style: const TextStyle(fontWeight: FontWeight.w600)
                          ),
                          subtitle: Text(
                            'Submitted: $dateString',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate with properly converted data
                            Navigator.pushNamed(
                              context,
                              '/evaluate-employee',
                              arguments: data, // Now properly typed as Map<String, dynamic>
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