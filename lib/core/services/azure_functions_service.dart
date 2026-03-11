import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service that calls Azure Functions for server-side computation.
/// Handles: CGPA recalculation, semester progress, schedule generation.
class AzureFunctionsService {
  // ⚠️ Replace with your actual Azure Function URL after deployment
  // Local dev: http://localhost:7071/api
  // Production: https://<your-function-app>.azurewebsites.net/api
  static const String _baseUrl = 'https://ewumate-parser.azurewebsites.net/api';

  // Azure Function key (provided via .env)
  static final String _functionKey = dotenv.env['AZURE_FUNCTION_KEY'] ?? '';

  static final AzureFunctionsService _instance = AzureFunctionsService._();
  AzureFunctionsService._();
  factory AzureFunctionsService() => _instance;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  static const String _notLoggedIn = 'Not logged in';

  Future<Map<String, dynamic>> _post(
      String action, Map<String, dynamic> body) async {
    final url = Uri.parse(
        '$_baseUrl/$action${_functionKey.isNotEmpty ? "?code=$_functionKey" : ""}');
    
    // Get the current session to extract the JWT
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null) {
       debugPrint('[AzureFunc] No auth token available');
       throw Exception('Not authenticated');
    }

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
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
    if (uid == null) {
      throw Exception(_notLoggedIn);
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'recalculate-stats',
        body: {'user_id': uid},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[EdgeFunc] recalculate-stats failed: $e');
      rethrow;
    }
  }

  /// Updates live semester progress (mark tracking → predicted SGPA).
  /// Call this when a student updates their quiz/exam marks.
  Future<Map<String, dynamic>> updateProgress(String semesterCode) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception(_notLoggedIn);
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'update-progress',
        body: {
          'user_id': uid,
          'semester_code': semesterCode,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[EdgeFunc] update-progress failed: $e');
      rethrow;
    }
  }

  /// Generates schedule combinations via backtracking algorithm.
  /// Returns a generation ID that can be used to stream results.
  Future<Map<String, dynamic>> generateSchedules({
    required String semester,
    required List<String> courses,
    Map<String, dynamic>? filters,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw Exception(_notLoggedIn);
    }

    return _post('generate_schedules', {
      'user_id': uid,
      'semester': semester,
      'courses': courses,
      'filters': filters ?? {},
    });
  }

  /// Calls the general purpose app-logic Edge Function for remote-controlled logic.
  Future<Map<String, dynamic>> invokeAppLogic(String action, Map<String, dynamic> data) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'app-logic',
        body: {
          'action': action,
          'data': data,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[EdgeFunc] app-logic failed for $action: $e');
      rethrow;
    }
  }
}
