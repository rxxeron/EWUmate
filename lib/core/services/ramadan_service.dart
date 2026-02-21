import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'offline_cache_service.dart';

class RamadanDay {
  final int day;
  final DateTime date;
  final String sehri;
  final String iftar;

  RamadanDay({
    required this.day,
    required this.date,
    required this.sehri,
    required this.iftar,
  });

  factory RamadanDay.fromMap(Map<String, dynamic> map) {
    return RamadanDay(
      day: map['day_number'] as int? ?? map['day'] as int,
      date: DateTime.parse((map['fasting_date'] ?? map['date']) as String),
      sehri: (map['sehri_time'] ?? map['sehri']) as String,
      iftar: (map['iftar_time'] ?? map['iftar']) as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'date': date.toIso8601String(),
      'sehri': sehri,
      'iftar': iftar,
    };
  }

  static String _formatTime(String rawTime) {
    // rawTime is likely "HH:mm:ss"
    final parts = rawTime.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    
    final period = hour >= 12 ? "PM" : "AM";
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
  }
}

class RamadanService {
  static final _supabase = Supabase.instance.client;
  static List<RamadanDay>? _cache;
  static DateTime? _lastFetch;

  static Future<List<RamadanDay>> getFullTimetable() async {
    // 1. Initial cached value from Hive
    final cachedTimetable = OfflineCacheService().getCachedRamadanTimetable();
    if (_cache == null && cachedTimetable.isNotEmpty) {
      _cache = cachedTimetable.map((m) => RamadanDay.fromMap(m)).toList();
    }

    // Use memory cache if it's less than 1 hour old
    if (_cache != null && _lastFetch != null && 
        DateTime.now().difference(_lastFetch!).inHours < 1) {
      return _cache!;
    }

    try {
      final response = await _supabase
          .from('ramadan_timetable')
          .select()
          .order('day_number', ascending: true);
      
      final data = (response as List).map((m) {
        // Need to format times from Supabase format (HH:mm:ss) to user-friendly format
        return RamadanDay(
          day: m['day_number'] as int,
          date: DateTime.parse(m['fasting_date'] as String),
          sehri: RamadanDay._formatTime(m['sehri_time'] as String),
          iftar: RamadanDay._formatTime(m['iftar_time'] as String),
        );
      }).toList();

      _cache = data;
      _lastFetch = DateTime.now();

      // 2. Persist to Hive (Disabled per request)
      // await OfflineCacheService().cacheRamadanTimetable(data.map((d) => d.toMap()).toList());

      return data;
    } catch (e) {
      debugPrint("Error fetching Ramadan timetable: $e");
      return _cache ?? [];
    }
  }

  static Future<bool> isRamadanSeason() async {
    final timetable = await getFullTimetable();
    if (timetable.isEmpty) return false;
    
    final now = DateTime.now();
    final firstDay = timetable.first.date;
    final lastDay = timetable.last.date;
    
    // Show from 2 days before Ramadan starts until exactly the last fasting day
    final showStart = firstDay.subtract(const Duration(days: 2));
    final showEnd = lastDay.add(const Duration(days: 1)); // Covers the final day
    
    return now.isAfter(showStart) && now.isBefore(showEnd);
  }

  static Future<RamadanDay?> getTodayTimings() async {
    final now = DateTime.now();
    final timetable = await getFullTimetable();
    try {
      return timetable.firstWhere(
        (day) => day.date.year == now.year && day.date.month == now.month && day.date.day == now.day,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<RamadanDay?> getDayByDate(DateTime date) async {
    final timetable = await getFullTimetable();
    try {
      return timetable.firstWhere(
        (day) => day.date.year == date.year && day.date.month == date.month && day.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }
}
