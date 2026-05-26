import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tutorial_model.dart';

final tutorialsRepositoryProvider = Provider<TutorialsRepository>(
  (ref) => TutorialsRepository(),
);

class TutorialsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Tutorial>> fetchAll() async {
    final data = await _supabase
        .from('tutorials')
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);
    return (data as List<dynamic>)
        .map((e) => Tutorial.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
