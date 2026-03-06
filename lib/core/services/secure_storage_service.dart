import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Writes a [value] for the given [key].
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads the value associated with [key]. Returns null if not present.
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes the entry for [key].
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clears all stored keys.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
