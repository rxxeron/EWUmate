import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/azure_functions_service.dart';
import '../models/advising_guide_models.dart';

class AdvisingGuideState {
  final bool isLoading;
  final String? errorMessage;
  final AdvisingGuideData? data;
  final int selectedTab; // 0: Eligible, 1: Locked, 2: History (Done/Enrolled), 3: All Curriculum
  final String selectedArea;
  final String searchQuery;

  const AdvisingGuideState({
    this.isLoading = true,
    this.errorMessage,
    this.data,
    this.selectedTab = 0,
    this.selectedArea = 'All',
    this.searchQuery = '',
  });

  AdvisingGuideState copyWith({
    bool? isLoading,
    String? errorMessage,
    AdvisingGuideData? data,
    int? selectedTab,
    String? selectedArea,
    String? searchQuery,
  }) {
    return AdvisingGuideState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedArea: selectedArea ?? this.selectedArea,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<AdvisingCourseItem> get displayedCourses {
    if (data == null) return [];

    List<AdvisingCourseItem> baseList;
    switch (selectedTab) {
      case 0:
        baseList = data!.eligibleCourses;
        break;
      case 1:
        baseList = data!.lockedCourses;
        break;
      case 2:
        baseList = [...data!.enrolledCourses, ...data!.completedCourses];
        break;
      case 3:
      default:
        baseList = [
          ...data!.eligibleCourses,
          ...data!.lockedCourses,
          ...data!.enrolledCourses,
          ...data!.completedCourses,
        ];
        break;
    }

    // Filter by area
    if (selectedArea != 'All') {
      baseList = baseList.where((c) => c.areaName.toLowerCase() == selectedArea.toLowerCase()).toList();
    }

    // Filter by search query
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      baseList = baseList.where((c) {
        return c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q);
      }).toList();
    }

    return baseList;
  }

  List<String> get availableAreas {
    if (data == null) return ['All'];
    final set = <String>{'All'};
    for (final a in data!.areas) {
      if (a.areaName.isNotEmpty) {
        set.add(a.areaName);
      }
    }
    return set.toList();
  }
}

class AdvisingGuideNotifier extends StateNotifier<AdvisingGuideState> {
  final Ref _ref;

  AdvisingGuideNotifier(this._ref) : super(const AdvisingGuideState()) {
    loadAdvisingData();
  }

  void setSelectedTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  void setSelectedArea(String area) {
    state = state.copyWith(selectedArea: area);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> loadAdvisingData({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = _ref.read(currentUserProvider) ?? Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User is not authenticated. Please sign in.',
        );
        return;
      }

      final nextSem = await _ref.read(nextSemesterCodeProvider.future) ??
          await _ref.read(currentSemesterCodeProvider.future);

      // 1. First Attempt: Backend Azure Function
      try {
        final azureService = _ref.read(azureFunctionsServiceProvider);
        final res = await azureService.getAdvisingCourses(
          userId: user.id,
          semester: nextSem,
        );

        if (res.isNotEmpty && res['program_code'] != null) {
          final data = AdvisingGuideData.fromJson(res);
          state = state.copyWith(isLoading: false, data: data);
          return;
        }
      } catch (azureErr) {
        if (kDebugMode) {
          debugPrint('[AdvisingGuide] Azure function fallback to direct Supabase: $azureErr');
        }
      }

      // 2. Direct Supabase Querying Fallback
      final data = await _fetchFromSupabaseDirect(user.id, nextSem);
      state = state.copyWith(isLoading: false, data: data);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AdvisingGuide] Error loading advising: $e\n$st');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load advising recommendations: $e',
      );
    }
  }

  Future<AdvisingGuideData> _fetchFromSupabaseDirect(String userId, String? nextSem) async {
    final supabase = _ref.read(supabaseClientProvider);

    // Profile
    final profRes = await supabase
        .from('profiles')
        .select('id, program_code, full_name, student_id, total_credits_earned')
        .eq('id', userId)
        .maybeSingle();

    final progCode = (profRes?['program_code']?.toString() ?? 'ICE').trim();

    // Program info
    final progRes = await supabase
        .from('programs')
        .select('program_code, name, department_name, total_degree_credits')
        .eq('program_code', progCode)
        .maybeSingle();

    final progName = progRes?['name']?.toString() ?? progCode;
    final deptName = progRes?['department_name']?.toString();
    final totalDegreeCr = (progRes?['total_degree_credits'] as num?)?.toDouble() ?? 130.0;

    // Completed courses
    final completedRes = await supabase
        .from('completed_courses')
        .select('course_code, semester_code, grade, credits')
        .eq('user_id', userId);

    final Map<String, Map<String, dynamic>> passedMap = {};
    double totalEarnedCr = 0.0;
    const failingGrades = {'F', 'W', 'I', 'X'};
    const retakeGrades = {'D', 'D+', 'C-'};

    for (final r in (completedRes as List)) {
      final code = _normalizeCode(r['course_code']?.toString() ?? '');
      final grade = (r['grade']?.toString() ?? '').trim().toUpperCase();
      final cr = (r['credits'] as num?)?.toDouble() ?? 3.0;

      if (!failingGrades.contains(grade)) {
        passedMap[code] = {
          'code': r['course_code'],
          'grade': grade,
          'credits': cr,
          'semester': r['semester_code'],
          'is_retake': retakeGrades.contains(grade),
        };
        totalEarnedCr += cr;
      }
    }

    // Current enrollments
    final enrRes = await supabase
        .from('enrollments')
        .select('course_code, semester_code, section, status')
        .eq('user_id', userId);

    final Map<String, Map<String, dynamic>> enrolledMap = {};
    for (final r in (enrRes as List)) {
      final code = _normalizeCode(r['course_code']?.toString() ?? '');
      enrolledMap[code] = {
        'code': r['course_code'],
        'semester_code': r['semester_code'],
        'section': r['section'],
      };
    }

    final satisfiedPrereqs = {...passedMap.keys, ...enrolledMap.keys};

    // Program curriculum courses
    final currRes = await supabase
        .from('program_curriculum_courses')
        .select('course_code, area_name, is_compulsory, course_metadata(name, credit_val, required_credits)')
        .eq('program_code', progCode)
        .order('area_name', ascending: true);

    // Relational prerequisites
    final prereqRes = await supabase
        .from('course_prerequisites')
        .select('course_code, prerequisite_course_code, required_credits');

    final Map<String, List<Map<String, dynamic>>> prereqMap = {};
    for (final p in (prereqRes as List)) {
      final cNorm = _normalizeCode(p['course_code']?.toString() ?? '');
      prereqMap.putIfAbsent(cNorm, () => []);
      final pNorm = p['prerequisite_course_code'] != null
          ? _normalizeCode(p['prerequisite_course_code'].toString())
          : null;
      final reqCr = (p['required_credits'] as num?)?.toDouble();
      prereqMap[cNorm]!.add({'prereq': pNorm, 'required_credits': reqCr});
    }

    final List<AdvisingCourseItem> eligibleList = [];
    final List<AdvisingCourseItem> lockedList = [];
    final List<AdvisingCourseItem> completedList = [];
    final List<AdvisingCourseItem> enrolledList = [];
    final Map<String, AdvisingAreaSummary> areaMap = {};

    for (final row in (currRes as List)) {
      final rawCode = row['course_code']?.toString() ?? '';
      final normCode = _normalizeCode(rawCode);
      final meta = row['course_metadata'] as Map<String, dynamic>? ?? {};
      final name = meta['name']?.toString() ?? rawCode;
      final cr = (meta['credit_val'] as num?)?.toDouble() ?? 3.0;
      final areaName = row['area_name']?.toString() ?? 'General';
      final isCompulsory = row['is_compulsory'] == true;
      final metaReqCr = (meta['required_credits'] as num?)?.toDouble();

      final pData = prereqMap[normCode] ?? [];
      final prereqCodes = pData.map((e) => e['prereq']?.toString()).whereType<String>().toList();
      double? creditThresh = metaReqCr;
      for (final p in pData) {
        final r = (p['required_credits'] as num?)?.toDouble();
        if (r != null) {
          if (creditThresh == null || r > creditThresh) creditThresh = r;
        }
      }

      if (passedMap.containsKey(normCode)) {
        final pInfo = passedMap[normCode]!;
        completedList.add(AdvisingCourseItem(
          code: rawCode,
          name: name,
          credits: cr,
          areaName: areaName,
          isCompulsory: isCompulsory,
          status: 'COMPLETED',
          grade: pInfo['grade']?.toString(),
          semester: pInfo['semester']?.toString(),
          prerequisites: prereqCodes,
          isRetakeEligible: pInfo['is_retake'] == true,
        ));
        continue;
      }

      if (enrolledMap.containsKey(normCode)) {
        final eInfo = enrolledMap[normCode]!;
        enrolledList.add(AdvisingCourseItem(
          code: rawCode,
          name: name,
          credits: cr,
          areaName: areaName,
          isCompulsory: isCompulsory,
          status: 'CURRENTLY_ENROLLED',
          semester: eInfo['semester_code']?.toString(),
          section: eInfo['section']?.toString(),
          prerequisites: prereqCodes,
        ));
        continue;
      }

      // Check prereqs
      final missingPrereqs = <String>[];
      final fulfilledPrereqs = <String>[];
      for (final pCode in prereqCodes) {
        if (satisfiedPrereqs.contains(pCode)) {
          fulfilledPrereqs.add(pCode);
        } else {
          missingPrereqs.add(pCode);
        }
      }

      final reasons = <String>[];
      if (missingPrereqs.isNotEmpty) {
        reasons.add('Missing prerequisite: ${missingPrereqs.join(", ")}');
      }
      if (creditThresh != null && totalEarnedCr < creditThresh) {
        final deficit = creditThresh - totalEarnedCr;
        reasons.add('Requires ${creditThresh.toStringAsFixed(0)} completed credits (you have ${totalEarnedCr.toStringAsFixed(0)}, need ${deficit.toStringAsFixed(0)} more)');
      }

      final isEligible = missingPrereqs.isEmpty && (creditThresh == null || totalEarnedCr >= creditThresh);

      final item = AdvisingCourseItem(
        code: rawCode,
        name: name,
        credits: cr,
        areaName: areaName,
        isCompulsory: isCompulsory,
        status: isEligible ? 'ELIGIBLE' : 'LOCKED',
        prerequisites: prereqCodes,
        fulfilledPrerequisites: fulfilledPrereqs,
        missingPrerequisites: missingPrereqs,
        requiredCredits: creditThresh,
        lockReasons: reasons,
      );

      if (isEligible) {
        eligibleList.add(item);
      } else {
        lockedList.add(item);
      }
    }

    return AdvisingGuideData(
      programCode: progCode,
      programName: progName,
      departmentName: deptName,
      totalDegreeCredits: totalDegreeCr,
      completedCredits: totalEarnedCr,
      totalCurriculumCourses: eligibleList.length + lockedList.length + completedList.length + enrolledList.length,
      completedCount: completedList.length,
      enrolledCount: enrolledList.length,
      eligibleCount: eligibleList.length,
      lockedCount: lockedList.length,
      areas: areaMap.values.toList(),
      eligibleCourses: eligibleList,
      lockedCourses: lockedList,
      completedCourses: completedList,
      enrolledCourses: enrolledList,
    );
  }

  static String _normalizeCode(String code) {
    final c = code.trim().toUpperCase().replaceAll(' ', '');
    if (c.startsWith('CE7') || c.startsWith('PHRM7')) return c;
    final m = RegExp(r'^([A-Z]+)[79](\d{3}[A-Z]?)$').firstMatch(c);
    if (m != null) {
      return '${m.group(1)}${m.group(2)}';
    }
    return c;
  }
}

final advisingGuideNotifierProvider =
    StateNotifierProvider<AdvisingGuideNotifier, AdvisingGuideState>((ref) {
  return AdvisingGuideNotifier(ref);
});
