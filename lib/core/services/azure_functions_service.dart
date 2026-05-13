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

  String get functionKey => _functionKey;

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

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _getRequest(
      String endpoint, Map<String, String> queryParams) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: {
      ...queryParams,
      'code': _functionKey,
    });

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
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
      'filters': filters,
    });
    
    // The Python function returns 'generationId' (camelCase)
    final genId = response['generationId'] ?? response['generation_id'];
    if (genId != null) {
        return genId.toString();
    }
    return '';
  }

  /// Triggers the portal scraper for a specific semester
  Future<List<Map<String, dynamic>>> triggerScraper({
    required String semester,
    bool preview = true,
  }) async {
    final response = await _getRequest('/api/scraper/portal_sync', {
      'semester': semester,
      'preview': preview.toString(),
    });
    
    if (response['status'] == 'success' && response['data'] != null) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    return [];
  }
}

final azureFunctionsServiceProvider = Provider<AzureFunctionsService>((ref) {
  return AzureFunctionsService();
});
