class Evaluation {
  final String employeeName;
  final String selfReflection;
  final String goals;
  final String? skillsDeveloped;
  final String? managerComments;
  final String? evaluationDate;

  Evaluation({
    required this.employeeName,
    required this.selfReflection,
    required this.goals,
    this.skillsDeveloped,
    this.managerComments,
    this.evaluationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_name': employeeName,
      'self_reflection': selfReflection,
      'goals': goals,
      'skills_developed': skillsDeveloped,
      'manager_comments': managerComments,
      'evaluation_date': evaluationDate,
    };
  }

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      employeeName: json['employee_name'] ?? '',
      selfReflection: json['self_reflection'] ?? '',
      goals: json['goals'] ?? '',
      skillsDeveloped: json['skills_developed'],
      managerComments: json['manager_comments'],
      evaluationDate: json['evaluation_date'],
    );
  }
}
