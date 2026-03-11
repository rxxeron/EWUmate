import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/offline_cache_service.dart';

class AppConfigRepository {
  static final AppConfigRepository _instance = AppConfigRepository._internal();
  factory AppConfigRepository() => _instance;
  AppConfigRepository._internal();

  final Map<String, dynamic> _configs = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    // 1. Try to load from cache first for instant startup
    final cached = OfflineCacheService().getCachedAppConfigs();
    if (cached != null) {
      _configs.addAll(cached);
      _initialized = true;
      debugPrint('[AppConfig] Loaded from local cache: ${cached.keys.length} flags');
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('app_config').select().timeout(const Duration(seconds: 5));
      
      final Map<String, dynamic> freshConfigs = {};
      for (var item in response) {
        freshConfigs[item['key']] = {
          'is_enabled': item['is_enabled'],
          'config_value': item['config_value'],
        };
      }
      
      // Update memory and disk cache
      _configs.clear();
      _configs.addAll(freshConfigs);
      await OfflineCacheService().cacheAppConfigs(freshConfigs);
      
      _initialized = true;
      debugPrint('[AppConfig] Remote configurations synced: ${_configs.keys.length} flags');
    } catch (e) {
      debugPrint('[AppConfig] Error syncing remote configs: $e');
      // If we already loaded from cache, we keep _initialized = true
    }
  }

  bool isFeatureEnabled(String key, {bool defaultValue = true}) {
    if (!_configs.containsKey(key)) return defaultValue;
    return _configs[key]['is_enabled'] ?? defaultValue;
  }

  Map<String, dynamic> getConfigValue(String key) {
    if (!_configs.containsKey(key)) return {};
    return _configs[key]['config_value'] ?? {};
  }

  String getMaintenanceMessage() {
    final config = getConfigValue('maintenance_mode');
    return config['message'] ?? "System is under maintenance. Please try again later.";
  }

  Map<String, dynamic>? getEmergencyNotice() {
    if (!isFeatureEnabled('emergency_notice', defaultValue: false)) return null;
    return getConfigValue('emergency_notice');
  }
}
