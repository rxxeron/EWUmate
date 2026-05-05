import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AzureFunctionsService {
  final String _baseUrl;
  final String _functionKey;

  AzureFunctionsService()
      : _baseUrl = dotenv.env['AZURE_FUNCTION_URL'] ?? 'http://localhost:7071',
        _functionKey = dotenv.env['AZURE_FUNCTION_KEY'] ?? '';

  Future<Map<String, dynamic>> _postRequest(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'x-functions-key': _functionKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } else {
      throw Exception('Azure Function failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Triggers cloud schedule generation
  Future<String> generateSchedules({
    required String userId,
    required String semester,
    required List<String> courses,
    Map<String, dynamic>? filters,
  }) async {
    final response = await _postRequest('/api/generate_schedules', {
      'user_id': userId,
      'semester': semester,
      'courses': courses,
      'filters': ?filters,
    });
    
    // The Python function returns 'generationId' (camelCase)
    final genId = response['generationId'] ?? response['generation_id'];
    if (genId != null) {
        return genId.toString();
    }
    return '';
  }
}

final azureFunctionsServiceProvider = Provider<AzureFunctionsService>((ref) {
  return AzureFunctionsService();
});
