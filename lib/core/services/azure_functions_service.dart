import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that calls Azure Functions for server-side computation.
/// Handles: CGPA recalculation, semester progress, schedule generation.
class AzureFunctionsService {
  // ⚠️ Replace with your actual Azure Function URL after deployment
  // Local dev: http://localhost:7071/api
  // Production: https://<your-function-app>.azurewebsites.net/api
  static const String _baseUrl = 'https://ewumate-parser.azurewebsites.net/api';

  // Azure Function key (set after deployment)
  static const String _functionKey = '';

  static final AzureFunctionsService _instance = AzureFunctionsService._();
  AzureFunctionsService._();
  factory AzureFunctionsService() => _instance;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<Map<String, dynamic>> _post(
      String action, Map<String, dynamic> body) async {
    final url = Uri.parse(
        '$_baseUrl/$action${_functionKey.isNotEmpty ? "?code=$_functionKey" : ""}');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
            '[AzureFunc] Error ${response.statusCode}: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AzureFunc] Request failed for $action: $e');
      rethrow;
    }
  }

  /// Recalculates CGPA, builds structured semester list with credits/grade points.
  /// Call this after onboarding or whenever course history is updated.
  Future<Map<String, dynamic>> recalculateStats() async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Not logged in');

    return _post('recalculate_stats', {'user_id': uid});
  }

  /// Updates live semester progress (mark tracking → predicted SGPA).
  /// Call this when a student updates their quiz/exam marks.
  Future<Map<String, dynamic>> updateProgress(String semesterCode) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Not logged in');

    return _post('update_progress', {
      'user_id': uid,
      'semester_code': semesterCode,
    });
  }

  /// Generates schedule combinations via backtracking algorithm.
  /// Returns a generation ID that can be used to stream results.
  Future<Map<String, dynamic>> generateSchedules({
    required String semester,
    required List<String> courses,
    Map<String, dynamic>? filters,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Not logged in');

    return _post('generate_schedules', {
      'user_id': uid,
      'semester': semester,
      'courses': courses,
      'filters': filters ?? {},
    });
  }
}
