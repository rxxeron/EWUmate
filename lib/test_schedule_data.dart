
import 'dart:io';
import 'package:supabase/supabase.dart';
void main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? 'http://127.0.0.1:54321';
  final key = Platform.environment['SUPABASE_ANON_KEY'] ?? 'ey...';
  final db = SupabaseClient(url, key);
  final data = await db.from('courses_spring2026').select().limit(1);
  print(data);
}

