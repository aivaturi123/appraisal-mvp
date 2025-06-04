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

class _EmployeeDashboardState extends State<EmployeeDashboard> with TickerProviderStateMixin {
  final TextEditingController _roleController = TextEditingController();
  String? _savedRole;
  bool _hasManagerReview = false;
  bool _hasAISummary = false;
  bool _hasSubmittedEvaluation = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadExistingRole();
    _checkEvaluationStatus();
    
    // Animation for manager review notification
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
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

  Future<void> _checkEvaluationStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      // Check using document ID first (if evaluations are stored with UID as doc ID)
      final docById = await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(uid)
          .get();

      if (docById.exists) {
        print("✅ Found evaluation by document ID");
        final data = docById.data()!;
        setState(() {
          _hasSubmittedEvaluation = true;
          _hasManagerReview = data.containsKey('managerReview') && 
                            data['managerReview'] != null &&
                            data['managerReview'].toString().trim().isNotEmpty;
          _hasAISummary = data.containsKey('aiSummary') && 
                         data['aiSummary'] != null &&
                         data['aiSummary'].toString().trim().isNotEmpty;
        });
        return;
      }

      // If not found by doc ID, check using employeeId field
      final queryByField = await FirebaseFirestore.instance
          .collection('evaluations')
          .where('employeeId', isEqualTo: uid)
          .get();

      if (queryByField.docs.isNotEmpty) {
        print("✅ Found evaluation by employeeId field");
        // Sort by timestamp to get the most recent
        final sortedDocs = queryByField.docs;
        sortedDocs.sort((a, b) {
          final timestampA = a.data()['timestamp'] as Timestamp?;
          final timestampB = b.data()['timestamp'] as Timestamp?;
          
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          
          return timestampB.compareTo(timestampA);
        });
        
        final data = sortedDocs.first.data();
        setState(() {
          _hasSubmittedEvaluation = true;
          _hasManagerReview = data.containsKey('managerReview') && 
                            data['managerReview'] != null &&
                            data['managerReview'].toString().trim().isNotEmpty;
          _hasAISummary = data.containsKey('aiSummary') && 
                         data['aiSummary'] != null &&
                         data['aiSummary'].toString().trim().isNotEmpty;
        });
      }
    } catch (e) {
      print("Error checking evaluation status: $e");
    }
  }

  Future<void> _saveRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final role = _roleController.text.trim();
    if (role.isNotEmpty) {
      await FirebaseFirestore.instance.collection('roles').doc(uid).set({'role': role});
      setState(() => _savedRole = role);
      
      // Show beautiful success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text("Role saved successfully!", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    String? badge,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Text(badge, style: const TextStyle(fontSize: 16)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _roleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFB),
              Color(0xFFE8F2FF),
              Color(0xFFF0F8FF),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Stunning Gradient AppBar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0047BB),
                      Color(0xFF0056D6),
                      Color(0xFF0066FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x330047BB),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: FlexibleSpaceBar(
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      "Welcome, ${widget.employeeName}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/employee-login');
                    },
                  ),
                ),
              ],
            ),
            
            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Welcome Section with animated icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFF8FAFB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0047BB).withOpacity(0.1),
                                  const Color(0xFF0066FF).withOpacity(0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0047BB).withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.dashboard_rounded,
                              size: 48,
                              color: Color(0xFF0047BB),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Hello, ${widget.employeeName} 👋",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ready to make your voice heard?",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Role Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFF8FAFB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF0047BB).withOpacity(0.1),
                                      const Color(0xFF0066FF).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.work_rounded,
                                  color: Color(0xFF0047BB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Your Role",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0047BB).withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _roleController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Software Engineer, Product Manager...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0047BB), Color(0xFF0066FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                                    onPressed: _saveRole,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Notifications Section
                    if (_hasManagerReview || _hasAISummary) ...[
                      // Manager Review Notification
                      if (_hasManagerReview)
                        _buildNotificationCard(
                          title: "Manager Review Available!",
                          subtitle: "Your manager has completed their review",
                          icon: Icons.new_releases_rounded,
                          gradientColors: [Colors.green.shade400, Colors.teal.shade400],
                          badge: "🎉",
                        ),
                      
                      // AI Summary Notification
                      if (_hasAISummary)
                        _buildNotificationCard(
                          title: "AI Summary Ready!",
                          subtitle: "Smart insights from your evaluation are available",
                          icon: Icons.auto_awesome_rounded,
                          gradientColors: [Colors.purple.shade400, Colors.indigo.shade400],
                          badge: "🤖",
                        ),
                    ],
                    
                    // Action Buttons
                    const SizedBox(height: 20),
                    
                    // Start Evaluation Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0047BB), Color(0xFF0066FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0047BB).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.assignment_rounded, color: Colors.white),
                        label: const Text(
                          "Start New Evaluation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // View Previous Evaluation Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0047BB).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            print("⏳ Querying evaluations...");
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            
                            // First, try to find evaluation by document ID
                            final docById = await FirebaseFirestore.instance
                                .collection('evaluations')
                                .doc(uid)
                                .get();

                            if (docById.exists) {
                              print("✅ Found evaluation by document ID: ${docById.id}");
                              final data = docById.data()!;
                              final hasManagerReview = data.containsKey('managerReview') && 
                                                     data['managerReview'] != null &&
                                                     data['managerReview'].toString().trim().isNotEmpty;
                              final hasAISummary = data.containsKey('aiSummary') && 
                                                  data['aiSummary'] != null &&
                                                  data['aiSummary'].toString().trim().isNotEmpty;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewSelfEvaluationScreen(
                                    employeeId: docById.id,
                                    showManagerReview: hasManagerReview,
                                  ),
                                ),
                              );
                              return;
                            }

                            // If not found by doc ID, query by employeeId field
                            final queryByField = await FirebaseFirestore.instance
                                .collection('evaluations')
                                .where('employeeId', isEqualTo: uid)
                                .get();

                            print("📄 Found ${queryByField.docs.length} docs via employeeId field");
                            
                            if (queryByField.docs.isNotEmpty) {
                              // Sort by timestamp to get the most recent
                              final sortedDocs = queryByField.docs;
                              sortedDocs.sort((a, b) {
                                final timestampA = a.data()['timestamp'] as Timestamp?;
                                final timestampB = b.data()['timestamp'] as Timestamp?;
                                
                                if (timestampA == null && timestampB == null) return 0;
                                if (timestampA == null) return 1;
                                if (timestampB == null) return -1;
                                
                                return timestampB.compareTo(timestampA); // Descending order
                              });
                              
                              final doc = sortedDocs.first; // Most recent document
                              final data = doc.data();
                              final hasManagerReview = data.containsKey('managerReview') && 
                                                     data['managerReview'] != null &&
                                                     data['managerReview'].toString().trim().isNotEmpty;
                              final hasAISummary = data.containsKey('aiSummary') && 
                                                  data['aiSummary'] != null &&
                                                  data['aiSummary'].toString().trim().isNotEmpty;

                              print("🔍 Navigating with doc ID: ${doc.id}");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewSelfEvaluationScreen(
                                    employeeId: doc.id,
                                    showManagerReview: hasManagerReview,
                                  ),
                                ),
                              );
                            } else {
                              print("❌ No evaluations found.");
                              _showSnackBar(
                                "No evaluations found. Start your first one!",
                                Colors.orange.shade600,
                                Icons.info_outline,
                              );
                            }
                          } catch (e, stack) {
                            print("❌ Firestore query error: $e");
                            print(stack);
                            _showSnackBar(
                              "Failed to load evaluation. Please try again.",
                              Colors.red.shade600,
                              Icons.error_outline,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Stack(
                          children: [
                            const Icon(Icons.visibility_rounded, color: Color(0xFF0047BB)),
                            if (_hasManagerReview || _hasAISummary)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _hasManagerReview ? Colors.green : Colors.purple,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_hasManagerReview ? Colors.green : Colors.purple).withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: Text(
                          _getViewButtonText(),
                          style: const TextStyle(
                            color: Color(0xFF0047BB),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Motivational Message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0047BB).withOpacity(0.1),
                            const Color(0xFF0066FF).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0047BB).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFF0047BB),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "💡 Pro Tip",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Take your time with self-evaluation. Reflect on your achievements, challenges, and growth opportunities. Your insights matter!",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getViewButtonText() {
    if (_hasManagerReview && _hasAISummary) {
      return "View Evaluation, Manager Review & AI Summary";
    } else if (_hasManagerReview) {
      return "View Evaluation & Manager Review";
    } else if (_hasAISummary) {
      return "View Evaluation & AI Summary";
    } else {
      return "View Submitted Evaluation";
    }
  }

  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}