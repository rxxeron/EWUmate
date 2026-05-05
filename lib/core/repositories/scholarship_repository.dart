import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models/scholarship_rule_model.dart';
import '../providers/supabase_provider.dart';
import '../utils/grade_helper.dart';

part 'scholarship_repository.g.dart';

class ScholarshipRepository {
  final SupabaseClient _supabase;

  ScholarshipRepository(this._supabase);

  Future<ScholarshipRule?> getScholarshipPolicy(String programId, {String? admittedSemester}) async {
    try {
      final response = await _supabase
          .from('scholarship_policies')
          .select();
      
      final policies = (response as List).map((e) => ScholarshipRule.fromMap(e)).toList();
      
      // 0. Filter by Admission Cohort (if provided)
      List<ScholarshipRule> cohortMatches = policies;
      if (admittedSemester != null) {
        final userSemVal = GradeHelper.getSemesterValue(admittedSemester);
        cohortMatches = policies.where((p) {
          final fromVal = p.effectiveFrom != null ? GradeHelper.getSemesterValue(p.effectiveFrom!) : 0;
          final untilVal = p.effectiveUntil != null ? GradeHelper.getSemesterValue(p.effectiveUntil!) : 999999;
          
          return userSemVal >= fromVal && userSemVal <= untilVal;
        }).toList();
      }

      // 1. Exact match priority (check both ID and Name) within the cohort
      final exactMatch = cohortMatches.where((p) => 
          p.programId.toLowerCase().trim() == programId.toLowerCase().trim() ||
          p.programName.toLowerCase().trim() == programId.toLowerCase().trim()
      ).firstOrNull;

      if (exactMatch != null) return exactMatch;

      // 2. Robust Fuzzy Match for ICE and other common programs
      final pIdStr = programId.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
      
      final fuzzyMatch = cohortMatches.where((p) {
        final policyId = p.programId.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
        final policyName = p.programName.toLowerCase().replaceAll('.', '').replaceAll(' ', '');
        
        // Exact keyword hits
        if (pIdStr == 'ice' && (policyId.contains('ice') || policyName.contains('ice'))) return true;
        if (pIdStr.contains('ice') && policyId == 'ice') return true;

        if (policyId.contains(pIdStr) || policyName.contains(pIdStr)) return true;
        if (pIdStr.contains(policyId) || pIdStr.contains(policyName)) return true;
        
        return false;
      }).firstOrNull;

      return fuzzyMatch;
    } catch (e) {
      if (kDebugMode) print('Error fetching scholarship policy: $e');
      return null;
    }
  }

  Future<List<ScholarshipRule>> getAllPolicies() async {
    try {
      final response = await _supabase.from('scholarship_policies').select();
      return (response as List).map((e) => ScholarshipRule.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching scholarship policies: $e');
      return [];
    }
  }
}

@riverpod
ScholarshipRepository scholarshipRepository(ScholarshipRepositoryRef ref) {
  return ScholarshipRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<ScholarshipRule?> scholarshipPolicy(ScholarshipPolicyRef ref, String programId, {String? admittedSemester}) {
  return ref.watch(scholarshipRepositoryProvider).getScholarshipPolicy(programId, admittedSemester: admittedSemester);
}
