import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'comparison_view.dart'; 

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  Map<String, dynamic> _convertFirestoreData(dynamic data) {
    if (data == null) return <String, dynamic>{};
    
    if (data is Map) {
      final Map<String, dynamic> converted = {};
      data.forEach((key, value) {
        converted[key.toString()] = _convertValue(value);
      });
      return converted;
    }
    
    return <String, dynamic>{};
  }

  dynamic _convertValue(dynamic value) {
    if (value == null) return null;
    
    if (value is Map) {
      final Map<String, dynamic> converted = {};
      value.forEach((key, val) {
        converted[key.toString()] = _convertValue(val);
      });
      return converted;
    } else if (value is List) {
      return value.map((item) => _convertValue(item)).toList();
    } else if (value is Timestamp) {
      return value; 
    }
    
    return value;
  }

  int _safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    
    // Handle direct integer
    if (value is int) return value;
    
    // Handle double (round to nearest int)
    if (value is double) return value.round();
    
    // Handle string conversion
    if (value is String) {
      // Remove any whitespace
      final trimmed = value.trim();
      if (trimmed.isEmpty) return defaultValue;
      
      // Try to parse as int first
      final intParsed = int.tryParse(trimmed);
      if (intParsed != null) return intParsed;
      
      // Try to parse as double then convert to int
      final doubleParsed = double.tryParse(trimmed);
      if (doubleParsed != null) return doubleParsed.round();
    }
    
    // Handle boolean (true = 1, false = 0)
    if (value is bool) return value ? 1 : 0;
    
    print('⚠️ Could not parse value to int: $value (type: ${value.runtimeType})');
    return defaultValue;
  }

  String _safeParseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    

    if (value is String) return value;
    
   
    return value.toString();
  }

  Map<String, dynamic> _prepareEvaluationData(Map<String, dynamic> rawData) {
    final prepared = <String, dynamic>{};
    
    // Performance scorecard criteria
    final List<String> criteria = [
      'Quality of Deliverables',
      'Timeliness & Responsiveness',
      'Client Relationship',
      'Knowledge Sharing & IP',
      'Team Collaboration & Culture',
      'Skill Development',
      'Ownership & Accountability',
      'Adaptability & Learning',
    ];
    
    // Initialize scores and comments maps
    final scores = <String, dynamic>{};
    final comments = <String, dynamic>{};
    
    // Extract scores and comments for each criterion
    for (final criterion in criteria) {
      // Try different possible field names for scores
      final scoreKey = criterion.toLowerCase().replaceAll(' ', '').replaceAll('&', '');
      final score = rawData[criterion] ?? 
                   rawData['${criterion}Score'] ?? 
                   rawData['${criterion}_score'] ?? 
                   rawData[scoreKey] ?? 
                   rawData['${scoreKey}rating'] ?? 
                   rawData['${scoreKey}Rating'] ?? 0;
      
      scores[criterion] = _safeParseInt(score);
      
      // Try different possible field names for comments
      final comment = rawData['${criterion}Comment'] ?? 
                     rawData['${criterion}_comment'] ?? 
                     rawData['${criterion}Text'] ?? 
                     rawData['${criterion}_text'] ?? 
                     rawData['${scoreKey}comment'] ?? 
                     rawData['${scoreKey}Comment'] ?? 
                     rawData['${scoreKey}text'] ?? 
                     rawData['${scoreKey}Text'] ?? 
                     'No comment provided';
      
      comments[criterion] = _safeParseString(comment, defaultValue: 'No comment provided');
    }
    
    prepared['scores'] = scores;
    prepared['comments'] = comments;
    
    // Handle SWOT analysis
    final swot = <String, dynamic>{};
    final rawSwot = rawData['swot'] ?? <String, dynamic>{};
    if (rawSwot is Map) {
      swot['strengths'] = _safeParseString(rawSwot['strengths'], defaultValue: 'Not provided');
      swot['weaknesses'] = _safeParseString(rawSwot['weaknesses'], defaultValue: 'Not provided');
      swot['opportunities'] = _safeParseString(rawSwot['opportunities'], defaultValue: 'Not provided');
      swot['threats'] = _safeParseString(rawSwot['threats'], defaultValue: 'Not provided');
    } else {
      swot['strengths'] = _safeParseString(rawData['strengths'], defaultValue: 'Not provided');
      swot['weaknesses'] = _safeParseString(rawData['weaknesses'] ?? rawData['improvements'], defaultValue: 'Not provided');
      swot['opportunities'] = _safeParseString(rawData['opportunities'], defaultValue: 'Not provided');
      swot['threats'] = _safeParseString(rawData['threats'], defaultValue: 'Not provided');
    }
    prepared['swot'] = swot;
    
    // Handle achievements
    final achievements = <String>[];
    final rawAchievements = rawData['achievements'];
    if (rawAchievements is List) {
      for (int i = 0; i < 3; i++) {
        if (i < rawAchievements.length) {
          achievements.add(_safeParseString(rawAchievements[i], defaultValue: 'Not provided'));
        } else {
          achievements.add('Not provided');
        }
      }
    } else {
      // Try individual achievement fields
      achievements.add(_safeParseString(rawData['achievement1'] ?? rawData['accomplishments'], defaultValue: 'Not provided'));
      achievements.add(_safeParseString(rawData['achievement2'] ?? rawData['challenges'], defaultValue: 'Not provided'));
      achievements.add(_safeParseString(rawData['achievement3'] ?? rawData['proud'], defaultValue: 'Not provided'));
    }
    prepared['achievements'] = achievements;
    
    // Handle Business Model Canvas
    final bmc = <String>[];
    final rawBmc = rawData['bmc'];
    if (rawBmc is List) {
      for (int i = 0; i < 9; i++) {
        if (i < rawBmc.length) {
          bmc.add(_safeParseString(rawBmc[i], defaultValue: 'Not provided'));
        } else {
          bmc.add('Not provided');
        }
      }
    } else {
      // Try individual BMC fields
      final bmcLabels = [
        'customerSegments', 'valueProposition', 'channels',
        'customerRelationships', 'revenueStreams', 'keyResources',
        'keyActivities', 'keyPartnerships', 'costStructure'
      ];
      for (final label in bmcLabels) {
        bmc.add(_safeParseString(rawData[label], defaultValue: 'Not provided'));
      }
    }
    prepared['bmc'] = bmc;
    
    // Handle summary
    final summary = <String, dynamic>{};
    final rawSummary = rawData['summary'];
    if (rawSummary is Map) {
      summary['whatWentWell'] = _safeParseString(rawSummary['whatWentWell'], defaultValue: 'Not provided');
      summary['powerUp'] = _safeParseString(rawSummary['powerUp'], defaultValue: 'Not provided');
      summary['nextSteps'] = _safeParseString(rawSummary['nextSteps'], defaultValue: 'Not provided');
    } else {
      summary['whatWentWell'] = _safeParseString(rawData['whatWentWell'], defaultValue: 'Not provided');
      summary['powerUp'] = _safeParseString(rawData['powerUp'] ?? rawData['improvements'], defaultValue: 'Not provided');
      summary['nextSteps'] = _safeParseString(rawData['nextSteps'], defaultValue: 'Not provided');
    }
    prepared['summary'] = summary;
    
    return prepared;
  }

  Map<String, dynamic> _cleanEvaluationData(Map<String, dynamic> rawData) {
    final cleaned = <String, dynamic>{};
    
    rawData.forEach((key, value) {
      switch (key.toLowerCase()) {
        // Numeric fields that should be integers (ratings, scores, counts)
        case 'strengths':
        case 'improvements':
        case 'overallrating':
        case 'overall_rating':
        case 'communicationrating':
        case 'communication_rating':
        case 'technicalrating':
        case 'technical_rating':
        case 'leadershiprating':
        case 'leadership_rating':
        case 'teamworkrating':
        case 'teamwork_rating':
        case 'problemsolvingrating':
        case 'problem_solving_rating':
        case 'rating':
        case 'score':
        case 'total':
        case 'average':
          cleaned[key] = _safeParseInt(value);
          break;
        
       
        case 'strengthstext':
        case 'strengths_text':
        case 'improvementstext':
        case 'improvements_text':
        case 'comments':
        case 'feedback':
        case 'goals':
        case 'achievements':
        case 'concerns':
        case 'notes':
        case 'description':
        case 'summary':
        case 'recommendation':
        case 'action_plan':
        case 'actionplan':
          cleaned[key] = _safeParseString(value);
          break;
        
    
        case 'employee_name':
        case 'employeename':
        case 'name':
          cleaned[key] = _safeParseString(value);
          break;
          
        case 'date':
        case 'review_date':
        case 'reviewdate':
        case 'timestamp':
          cleaned[key] = value;
          break;
          
        case 'completed':
        case 'is_completed':
        case 'iscompleted':
          // Keep booleans as-is
          cleaned[key] = value is bool ? value : (value.toString().toLowerCase() == 'true');
          break;
        
        // Default: Try to intelligently convert based on value type
        default:
          // If the key contains 'rating', 'score', or 'count', treat as int
          if (key.toLowerCase().contains('rating') || 
              key.toLowerCase().contains('score') || 
              key.toLowerCase().contains('count')) {
            cleaned[key] = _safeParseInt(value);
          } 
          // If the key contains 'text', 'comment', 'feedback', treat as string
          else if (key.toLowerCase().contains('text') || 
                   key.toLowerCase().contains('comment') || 
                   key.toLowerCase().contains('feedback') ||
                   key.toLowerCase().contains('note')) {
            cleaned[key] = _safeParseString(value);
          }
          // Otherwise, convert safely based on the value type
          else {
            cleaned[key] = _convertValue(value);
          }
          break;
      }
    });
    
    // Debug logging to help track conversion issues
    print('🔄 Data cleaning for evaluation:');
    rawData.forEach((key, value) {
      if (cleaned[key] != value) {
        print('  $key: ${value.runtimeType}($value) -> ${cleaned[key].runtimeType}(${cleaned[key]})');
      }
    });
    
    return cleaned;
  }


  Map<String, dynamic>? _safeGetMap(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return _convertFirestoreData(value);
    }
    
    return null;
  }


  bool _isEvaluatedByManager(Map<String, dynamic> data) {
    print('🔍 Checking evaluation: ${data['name']} - hasManagerReview: ${data['hasManagerReview']} - status: ${data['status']}');
    

    if (data['hasManagerReview'] == true) {
      return true;
    }
    
   
    final status = data['status']?.toString().toLowerCase();
    if (status == 'completed' || status == 'manager_completed' || status == 'reviewed') {
      return true;
    }
    

    final managerReview = _safeGetMap(data, 'managerReview');
    if (managerReview != null) {
      final isCompleted = managerReview['isCompleted'] == true ||
                         managerReview['completed'] == true ||
                         managerReview['status']?.toString().toLowerCase() == 'completed' ||
                         managerReview['reviewDate'] != null;
      if (isCompleted) return true;
    }
    
    // Additional legacy checks with null safety
    return data['managerEvaluated'] == true ||
           data['isEvaluatedByManager'] == true ||
           data['managerStatus']?.toString().toLowerCase() == 'completed' ||
           data['evaluationStatus']?.toString().toLowerCase() == 'manager_completed' ||
           data['status']?.toString().toLowerCase() == 'manager_reviewed' ||
           data['managerReviewDate'] != null;
  }

 
  DateTime? _getManagerReviewDate(Map<String, dynamic> data) {

    Timestamp? timestamp = data['lastUpdated'] as Timestamp? ??
                          data['managerReviewDate'] as Timestamp?;
    

    if (timestamp == null) {
      final managerReview = _safeGetMap(data, 'managerReview');
      if (managerReview != null) {
        timestamp = managerReview['reviewDate'] as Timestamp? ??
                   managerReview['completedDate'] as Timestamp?;
      }
    }
    
    timestamp ??= data['evaluatedDate'] as Timestamp?;
    
    return timestamp?.toDate();
  }


  String _getEmployeeName(Map<String, dynamic> data) {
    // Try direct name field first
    if (data['name'] != null) {
      return data['name'].toString();
    }
    
    // Try nested employee object with safe access
    final employee = _safeGetMap(data, 'employee');
    if (employee?['name'] != null) {
      return employee!['name'].toString();
    }
    
    // Try employeeName field
    if (data['employeeName'] != null) {
      return data['employeeName'].toString();
    }
    
    return 'Unnamed Employee';
  }

  // Build evaluation card widget
  Widget _buildEvaluationCard(Map<String, dynamic> data, BuildContext context, bool isEvaluated) {
    final name = _getEmployeeName(data);
    
    final timestamp = data['timestamp'] as Timestamp?;
    final dateString = timestamp != null 
        ? timestamp.toDate().toString().split(' ')[0]
        : 'No date';

    // Get manager review date if available
    final managerReviewDate = _getManagerReviewDate(data);
    final reviewDateString = managerReviewDate != null 
        ? managerReviewDate.toString().split(' ')[0]
        : '';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FAFB),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (isEvaluated) {
              try {
                
                final rawEmployeeEval = _safeGetMap(data, 'employeeEvaluation') ?? 
                                       _safeGetMap(data, 'evaluation') ?? 
                                       _safeGetMap(data, 'selfEvaluation') ??
                                       <String, dynamic>{};
                
                final rawManagerReview = _safeGetMap(data, 'managerReview') ?? 
                                        _safeGetMap(data, 'managerEvaluation') ??
                                        <String, dynamic>{};
 
                final employeeEval = _prepareEvaluationData(rawEmployeeEval);
                final managerReview = _prepareEvaluationData(rawManagerReview);
                
                final aiFeedback = _safeParseString(data['aiFeedback'], defaultValue: 'No AI feedback available');
                
                print('🔧 Prepared employee eval: $employeeEval');
                print('🔧 Prepared manager review: $managerReview');
                
                // Navigate to comparison view for completed evaluations
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComparisonView(
                      employeeEval: employeeEval,
                      managerReview: managerReview,
                      aiFeedback: aiFeedback,
                    ),
                  ),
                );
              } catch (e) {
                print('❌ Error navigating to ComparisonView: $e');
                print('❌ Stack trace: ${StackTrace.current}');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading comparison view: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            } else {
              // Navigate to evaluate employee for pending evaluations
              final result = await Navigator.pushNamed(
                context,
                '/evaluate-employee',
                arguments: data,
              );
              
              // Refresh the dashboard if evaluation was completed
              if (result == 'completed') {
                // The StreamBuilder will automatically refresh
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Evaluation completed successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEvaluated 
                        ? [
                            Colors.green.withOpacity(0.1),
                            Colors.teal.withOpacity(0.05),
                          ]
                        : [
                            const Color(0xFF0047BB).withOpacity(0.1),
                            const Color(0xFF0066FF).withOpacity(0.05),
                          ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEvaluated 
                        ? Colors.green.withOpacity(0.2)
                        : const Color(0xFF0047BB).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isEvaluated ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: isEvaluated ? Colors.green[700] : const Color(0xFF0047BB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Employee ID or Department if available
                      if (data['employeeId'] != null || data['department'] != null) ...[
                        Text(
                          'ID: ${data['employeeId']?.toString() ?? 'N/A'} • Dept: ${data['department']?.toString() ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Submission date
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.1),
                                  Colors.indigo.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              'Submitted: $dateString',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Status tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isEvaluated 
                                  ? [
                                      Colors.green.withOpacity(0.1),
                                      Colors.teal.withOpacity(0.05),
                                    ]
                                  : [
                                      Colors.orange.withOpacity(0.1),
                                      Colors.amber.withOpacity(0.05),
                                    ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isEvaluated 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              isEvaluated 
                                ? 'Manager Reviewed${reviewDateString.isNotEmpty ? ' ($reviewDateString)' : ''}'
                                : 'Pending Manager Review',
                              style: TextStyle(
                                color: isEvaluated ? Colors.green[700] : Colors.orange[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEvaluated 
                        ? [
                            Colors.green.withOpacity(0.1),
                            Colors.teal.withOpacity(0.05),
                          ]
                        : [
                            const Color(0xFF0047BB).withOpacity(0.1),
                            const Color(0xFF0066FF).withOpacity(0.05),
                          ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEvaluated ? Icons.visibility_rounded : Icons.edit_rounded,
                        size: 16,
                        color: isEvaluated ? Colors.green[700] : const Color(0xFF0047BB),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isEvaluated ? Colors.green[700] : const Color(0xFF0047BB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build section header
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.replaceAll('{count}', count.toString()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFB),
              Color(0xFFE8F2FF),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Stunning Gradient AppBar
            SliverAppBar(
              expandedHeight: 120,
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
                child: const FlexibleSpaceBar(
                  title: Text(
                    "Manager Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
                      Navigator.pushReplacementNamed(context, '/manager-login');
                    },
                  ),
                ),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('evaluations')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0047BB)),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Container(
                      margin: const EdgeInsets.all(24),
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
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Error Loading Data",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please check your connection and try again",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.all(24),
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
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: Color(0xFF0047BB),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No Evaluations Yet",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Employee evaluations will appear here once submitted",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final docs = snapshot.data!.docs;
   
                  final List<Map<String, dynamic>> pendingEvaluations = [];
                  final List<Map<String, dynamic>> completedEvaluations = [];
                  
                  for (final doc in docs) {
                    try {
                      final rawData = doc.data();
                      final data = _convertFirestoreData(rawData);
                      data['id'] = doc.id;
                      
                      if (_isEvaluatedByManager(data)) {
                        completedEvaluations.add(data);
                      } else {
                        pendingEvaluations.add(data);
                      }
                    } catch (e) {
                      print('❌ Error processing document ${doc.id}: $e');
                      print('❌ Document data: ${doc.data()}');
                      // Skip problematic documents instead of crashing
                      continue;
                    }
                  }
                  
                  
                  // Debug print to see the separation
                  print('📊 Dashboard Status: ${pendingEvaluations.length} pending, ${completedEvaluations.length} completed');
                  
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Stats
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0047BB), Color(0xFF0066FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${docs.length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Total Evaluations',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${pendingEvaluations.length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${completedEvaluations.length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                       
                        
                        // Pending Reviews Section
                        if (pendingEvaluations.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: "Pending Reviews",
                            subtitle: "{count} evaluation${pendingEvaluations.length != 1 ? 's' : ''} awaiting your review",
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFFF6B35),
                            count: pendingEvaluations.length,
                          ),
                          const SizedBox(height: 20),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingEvaluations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildEvaluationCard(
                                pendingEvaluations[index], 
                                context, 
                                false
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        // Completed Reviews Section
                        if (completedEvaluations.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: "Completed Reviews",
                            subtitle: "{count} evaluation${completedEvaluations.length != 1 ? 's' : ''} reviewed - Tap to view comparison",
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                            count: completedEvaluations.length,
                          ),
                          const SizedBox(height: 20),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedEvaluations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildEvaluationCard(
                                completedEvaluations[index], 
                                context, 
                                true
                              );
                            },
                          ),
                        ],
                        
                        // Show message if no evaluations in a specific category
                        if (pendingEvaluations.isEmpty && completedEvaluations.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.green, Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.celebration_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "All caught up! No pending reviews.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
     );
  }
}