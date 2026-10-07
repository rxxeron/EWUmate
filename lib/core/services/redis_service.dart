import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class RedisService {
  final String _url;
  final String _token;
  final http.Client _client;

  RedisService({
    String? url,
    String? token,
    http.Client? client,
  })  : _url = url ?? dotenv.env['UPSTASH_REDIS_REST_URL'] ?? '',
        _token = token ?? dotenv.env['UPSTASH_REDIS_REST_TOKEN'] ?? '',
        _client = client ?? http.Client();

  bool get isConfigured => _url.isNotEmpty && _token.isNotEmpty;

  /// Retrieves a value by key. Returns decoded JSON, raw String, or null on cache miss/error.
  Future<dynamic> get(String key) async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse(_url);
      final body = jsonEncode(['GET', key]);
      
      final res = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final result = decoded['result'];
        if (result == null) return null;
        if (result is String) {
          try {
            return jsonDecode(result);
          } catch (_) {
            return result;
          }
        }
        return result;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[RedisService] GET $key fallback: $e');
    }
    return null;
  }

  /// Sets a key-value pair in Redis with optional TTL (Time To Live).
  Future<bool> set(String key, dynamic value, {Duration? ttl}) async {
    if (!isConfigured) return false;
    try {
      final uri = Uri.parse(_url);
      final encodedValue = value is String ? value : jsonEncode(value);
      
      final List<dynamic> command = ['SET', key, encodedValue];
      if (ttl != null && ttl.inSeconds > 0) {
        command.addAll(['EX', ttl.inSeconds]);
      }

      final body = jsonEncode(command);
      final res = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 3));

      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[RedisService] SET $key failed: $e');
      return false;
    }
  }

  /// Convenience method to retrieve a JSON Map directly.
  Future<Map<String, dynamic>?> getMap(String key) async {
    final data = await get(key);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Convenience method to retrieve a JSON List directly.
  Future<List<dynamic>?> getList(String key) async {
    final data = await get(key);
    if (data is List) return data;
    return null;
  }

  /// Closes the HTTP client to release underlying network sockets.
  void dispose() {
    _client.close();
  }
}

final redisServiceProvider = Provider<RedisService>((ref) {
  final service = RedisService();
  ref.onDispose(() => service.dispose());
  return service;
});
