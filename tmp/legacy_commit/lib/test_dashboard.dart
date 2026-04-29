
import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:intl/intl.dart';

void main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? 'http://127.0.0.1:54321';
  final key = Platform.environment['SUPABASE_ANON_KEY'] ?? 'ey...';
  final db = SupabaseClient(url, key);
  // Get users
  final users = await db.from('profiles').select().order('created_at', ascending: false).limit(1);
  final user = users.first['id'];
  print('User: \');
  final row = await db.from('user_semester_states').select().eq('user_id', user).eq('semester_code', 'Spring2026').maybeSingle();
  print('Grid cache: \');
}

