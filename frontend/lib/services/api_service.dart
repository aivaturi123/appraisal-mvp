import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<bool> submitSelfEvaluation(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/submit-evaluation');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data));
    return response.statusCode == 200;
  }

  static Future<String?> generateFeedback(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/generate-feedback');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data));

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      return res['feedback'];
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllEvaluations() async {
    final url = Uri.parse('$baseUrl/get-evaluations'); 
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      return rawList.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch evaluations");
    }
  }

  static Future<bool> submitManagerFeedback(String evalId, String feedback) async {
    final url = Uri.parse('$baseUrl/submit-manager-feedback'); 
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": evalId,
          "manager_feedback": feedback,
        }));

    return response.statusCode == 200;
  }
}
