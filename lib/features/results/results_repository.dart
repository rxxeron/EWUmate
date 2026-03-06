import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/result_models.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/schedule_cache_service.dart';
import '../../core/services/azure_functions_service.dart';
import '../calendar/academic_repository.dart';
import 'package:flutter/foundation.dart';

class ResultsRepository {
  final _supabase = Supabase.instance.client;

  // Cache for metadata
  static final Map<String, double> _courseCreditsCache = {};
  static final Map<String, double> gradeScaleCache = {};
  static bool _metadataLoaded = false;

  static const _programMap = {
    'cse': 'B.Sc. in Computer Science & Engineering',
    'ice': 'B.Sc. in Information & Communications Engineering',
    'ete': 'B.Sc. in Electronic & Telecommunication Engineering',
    'eee': 'B.Sc. in Electrical & Electronic Engineering',
    'ce': 'B.Sc. in Civil Engineering',
    'pharm': 'Bachelor of Pharmacy (B.Pharm) Professional',
    'geb': 'B.Sc. in Genetic Engineering & Biotechnology',
    'dsa': 'B.Sc. in Data Science & Analytics',
    'math': 'B.Sc. (Hons) in Mathematics',
    'bba': 'Bachelor of Business Administration',
    'eco': 'B.S.S. (Hons) in Economics',
    'eng': 'B.A. (Hons) in English',
    'soc': 'B.S.S. (Hons) in Sociology',
    'islm': 'B.S.S. in Info. Studies & Library Management',
    'law': 'LL.B. (Hons)',
  };

  Future<AcademicProfile> fetchAcademicProfile() async {
    final cachedData = OfflineCacheService().getCachedAcademicProfile();
    AcademicProfile? cachedProfile;
    if (cachedData != null) {
      cachedProfile = AcademicProfile.fromMap(cachedData);
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return cachedProfile ?? AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
    }

    await ensureMetadataLoaded();

    try {
      final profileData = await _supabase.from('profiles').select().eq('id', user.id).single();
      final academicData = await _supabase.from('academic_data').select().eq('user_id', user.id).maybeSingle();

      if (academicData != null) {
        final semesters = await _injectOngoingSemester(
          _parseCloudSemesters(academicData['semesters']),
          user.id,
        );
        
        final profile = _mapToAcademicProfile(profileData, academicData, semesters);

        // 2. Cache the fresh profile
        final profileMap = profile.toMap();
        await OfflineCacheService().cacheAcademicProfile(profileMap);
        await ScheduleCacheService().cacheStats(profileMap);

        return profile;
      }
    } catch (e) {
      debugPrint("Error fetching academic profile: $e");
    }

    return cachedProfile ?? AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
  }

  AcademicProfile _mapToAcademicProfile(
    Map<String, dynamic> profileData,
    Map<String, dynamic> academicData,
    List<SemesterResult> semesters,
  ) {
    int ongoing = 0;
    int completed = 0;
    for (var s in semesters) {
      for (var c in s.courses) {
        if (c.grade == 'Ongoing' || c.grade.isEmpty) {
          ongoing++;
        } else if (!['W', 'I', 'F', 'F*', 'S', 'U', 'R-'].contains(c.grade)) {
          completed++;
        }
      }
    }

    final cgpa = _readDouble(academicData['cgpa']);
    double totalCreditsEarned = _readDouble(academicData['total_credits_earned']);
    final remainedCredits = _readDouble(academicData['remained_credits']);

    if (totalCreditsEarned == 0 && semesters.isNotEmpty) {
      totalCreditsEarned = _calculateTotalCreditsEarned(semesters);
      try {
        AzureFunctionsService().recalculateStats().ignore();
      } catch (_) {}
    }

    final enrolledCount = (profileData['enrolled_sections'] as List?)?.length ?? 0;
    final cloudOngoing = (academicData['ongoing_courses'] as num?)?.toInt() ?? 0;
    int resolvedOngoing = cloudOngoing;
    if (enrolledCount > 0) {
      resolvedOngoing = enrolledCount;
    } else if (ongoing > 0) {
      resolvedOngoing = ongoing;
    }

    return AcademicProfile(
      semesters: semesters,
      cgpa: cgpa,
      ongoingCourses: resolvedOngoing,
      totalCoursesCompleted: completed,
      totalCreditsEarned: totalCreditsEarned,
      studentName: (profileData['full_name'] ?? 'Student').toString(),
      studentId: (profileData['student_id'] ?? 'N/A').toString(),
      programId: (profileData['program_id'] ?? '').toString().toLowerCase(),
      program: _getProgramName((profileData['program_id'] ?? 'N/A').toString()),
      department: (profileData['department'] ?? 'N/A').toString(),
      nickname: (profileData['nickname'] ?? '').toString(),
      photoUrl: (profileData['photo_url'] ?? profileData['avatar_url'] ?? '').toString(),
      remainedCredits: remainedCredits,
      scholarshipStatus: _calculateScholarship(
        (profileData['student_id'] ?? 'N/A').toString(),
        (profileData['program_id'] ?? 'N/A').toString(),
        cgpa,
        semesters,
      ),
    );
  }

  double _calculateTotalCreditsEarned(List<SemesterResult> semesters) {
    double total = 0;
    for (var sem in semesters) {
      for (var c in sem.courses) {
        if (c.grade != 'Ongoing' && c.grade.isNotEmpty && 
            !['W', 'I', 'F', 'F*'].contains(c.grade)) {
          total += c.credits;
        }
      }
    }
    return total;
  }

  String _getProgramName(String id) {
    return _programMap[id.toLowerCase()] ?? id.toUpperCase();
  }

  Future<List<SemesterResult>> _injectOngoingSemester(
      List<SemesterResult> currentHistory, String userId) async {
    try {
      final res = await _supabase
          .from('active_semester')
          .select('current_semester_code')
          .eq('is_active', true)
          .maybeSingle();
      final currentCode = res?['current_semester_code']?.toString();
      if (currentCode == null) return currentHistory;

      // If already in history, we still want to merge/refresh to ensure latest details from progress table
      final existingIndex = currentHistory.indexWhere((s) =>
          s.semesterName.replaceAll(" ", "").toLowerCase() ==
          currentCode.toLowerCase());
      
      // ... continue to fetch and merge ...

      // Fetch from semester_progress
      final progress = await _supabase
          .from('semester_progress')
          .select('summary')
          .eq('user_id', userId)
          .eq('semester_code', currentCode)
          .maybeSingle();

      if (progress != null && progress['summary'] != null) {
        final summary = Map<String, dynamic>.from(progress['summary']);
        final coursesData = summary['courses'] as Map? ?? {};

        final courses = coursesData.values.map((c) {
          final cMap = Map<String, dynamic>.from(c as Map);
          final rawCode = cMap['courseCode']?.toString() ?? '';
          // Handle cases like "MAT102_Sec4" by taking the base code
          final baseCode = rawCode.split('_')[0].toLowerCase().trim();
          final cachedCredits = _courseCreditsCache[baseCode];
          
          final res = CourseResult(
            courseCode: rawCode,
            courseTitle: cMap['courseName'] ?? cMap['courseCode'] ?? '',
            credits: cachedCredits ?? _readDouble(cMap['credits']),
            grade: 'Ongoing',
            gradePoint: 0.0,
          );
          return res;
        }).toList();

        // ═══════════════════════════════════════════════════════════════════
        // Deduplicate ongoing courses (some users have both "MAT102" and "MAT102_Sec4")
        // ═══════════════════════════════════════════════════════════════════
        final Map<String, CourseResult> uniqueCourses = {};
        for (var c in courses) {
          final baseCode = c.courseCode.split('_')[0].toUpperCase().trim();
          // Prefer the one with shorter code (usually the base code) or prioritize if already exists
          if (!uniqueCourses.containsKey(baseCode)) {
            uniqueCourses[baseCode] = c;
          } else {
             // If we have a long code (with _Sec) and a short code, prefer the short one for UI
             if (c.courseCode.length < uniqueCourses[baseCode]!.courseCode.length) {
               uniqueCourses[baseCode] = c;
             }
          }
        }
        final deduplicatedCourses = uniqueCourses.values.toList();

        if (deduplicatedCourses.isNotEmpty) {
          final ongoing = SemesterResult(
            semesterName: currentCode,
            courses: deduplicatedCourses,
          );
          // Only local calculation allowed for "In Memory" ongoing semester
          ongoing.calculateTermGPA();
          if (existingIndex != -1) {
            currentHistory[existingIndex] = ongoing;
          } else {
            currentHistory.insert(0, ongoing);
          }
          return currentHistory;
        }
      }
    } catch (e) {
      debugPrint("Error injecting ongoing semester: $e");
    }
    return currentHistory;
  }

  static Future<void> ensureMetadataLoaded() async {
    if (_metadataLoaded) return;
    try {
      final supabase = Supabase.instance.client;
      // 1. Fetch Credits Cache — prefer credit_val (total w/ lab) over credits (theory only)
      final res = await supabase.from('course_metadata').select('code, credits, credit_val');
      for (var row in res) {
        final code = row['code'].toString().toLowerCase();
        final creditVal = row['credit_val'];
        final credits = row['credits'];
        final resolved = _readDouble(creditVal ?? credits);
        _courseCreditsCache[code] = resolved;
      }

      // 2. Fetch Universal Grade Scale
      final scaleRes = await supabase.from('grade_scale').select('grade, point').order('point', ascending: false);
      for (var row in scaleRes) {
        gradeScaleCache[row['grade'].toString().toUpperCase()] =
            _readDouble(row['point']);
      }

      _metadataLoaded = true;
    } catch (e) {
      debugPrint("Error loading course metadata: $e");
    }
  }

  Stream<AcademicProfile> streamAcademicProfile() {
    final user = _supabase.auth.currentUser;
    final controller = StreamController<AcademicProfile>();

    // 1. Initial cached value
    final cachedData = OfflineCacheService().getCachedAcademicProfile();
    if (cachedData != null) {
      controller.add(AcademicProfile.fromMap(cachedData));
    }

    if (user == null) {
      if (cachedData == null) {
        controller.add(AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0));
      }
      controller.close();
      return controller.stream;
    }

    // Stream 1: Academic Data
    final academicStream = _supabase
        .from('academic_data')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id)
        .map((data) => data.isNotEmpty ? data.first : null);

    // Stream 2: Profile (Identity)
    final profileStream = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) => data.isNotEmpty ? data.first : null);

    Map<String, dynamic>? lastAcademic;
    Map<String, dynamic>? lastProfile;

    Future<void> update() async {
      if (lastAcademic != null && lastProfile != null) {
        try {
          await ensureMetadataLoaded();
          final profile =
              await _fetchCombinedData(lastAcademic!, lastProfile!, user.id);
          
          // 2. Cache updated profile
          final profileMap = profile.toMap();
          await OfflineCacheService().cacheAcademicProfile(profileMap);
          await ScheduleCacheService().cacheStats(profileMap);
          
          controller.add(profile);
        } catch (e) {
          debugPrint("Error in combined profile stream (sync might have failed): $e");
        }
      }
    }

    final subA = academicStream.listen((data) {
      lastAcademic = data;
      update();
    }, onError: (e) {
      debugPrint("Academic data stream error: $e");
    });

    final subP = profileStream.listen((data) {
      lastProfile = data;
      update();
    }, onError: (e) {
      debugPrint("Profile stream error: $e");
    });

    controller.onCancel = () {
      subA.cancel();
      subP.cancel();
    };

    return controller.stream;
  }

  Future<AcademicProfile> _fetchCombinedData(Map<String, dynamic> academicData,
      Map<String, dynamic> profileData, String userId) async {
    final semesters = await _injectOngoingSemester(
      _parseCloudSemesters(academicData['semesters']),
      userId,
    );

    int ongoing = 0;
    int completed = 0;
    for (var s in semesters) {
      for (var c in s.courses) {
        if (c.grade == 'Ongoing' || c.grade.isEmpty) {
          ongoing++;
        } else if (!['W', 'I', 'S', 'U', 'R-'].contains(c.grade)) {
          completed++;
        }
      }
    }

    final enrolledCount = (profileData['enrolled_sections'] as List?)?.length ?? 0;
    final cloudOngoing = (academicData['ongoing_courses'] as num?)?.toInt() ?? 0;

    final cgpa = _readDouble(academicData['cgpa']);
    int resolvedOngoing = cloudOngoing;
    if (enrolledCount > 0) {
      resolvedOngoing = enrolledCount;
    } else if (ongoing > 0) {
      resolvedOngoing = ongoing;
    }

    return AcademicProfile(
      semesters: semesters,
      cgpa: cgpa,
      ongoingCourses: resolvedOngoing,
      totalCoursesCompleted: completed,
      totalCreditsEarned: _readDouble(academicData['total_credits_earned']),
      studentName: (profileData['full_name'] ?? 'Student').toString(),
      studentId: (profileData['student_id'] ?? 'N/A').toString(),
      program: _getProgramName((profileData['program_id'] ?? 'N/A').toString()),
      department: (profileData['department'] ?? 'N/A').toString(),
      nickname: (profileData['nickname'] ?? '').toString(),
      photoUrl: (profileData['photo_url'] ?? profileData['avatar_url'] ?? '')
          .toString(),
      remainedCredits: _readDouble(academicData['remained_credits']),
      scholarshipStatus: _calculateScholarship(
        (profileData['student_id'] ?? 'N/A').toString(),
        (profileData['program_id'] ?? 'N/A').toString(),
        cgpa,
        semesters,
      ),
    );
  }

  List<SemesterResult> _parseCloudSemesters(dynamic list) {
    if (list == null) return [];
    
    // Handle Map format (raw history from onboarding)
    if (list is Map) {
      try {
        final sems = <SemesterResult>[];
        list.forEach((key, value) {
          final courses = (value as Map).entries.map((e) {
            final code = e.key.toString();
            final grade = e.value.toString();
            final cachedCredits = _courseCreditsCache[code.toLowerCase()];
            return CourseResult(
              courseCode: code,
              courseTitle: code,
              credits: cachedCredits ?? 3.0,
              grade: grade,
              gradePoint: _getGradePoint(grade),
            );
          }).toList();
          
          final sem = SemesterResult(
            semesterName: key.toString(), 
            courses: courses,
          );
          sem.calculateTermGPA();
          sems.add(sem);
        });
        sems.sort((a, b) => _compareSemesterName(a.semesterName, b.semesterName));
        return sems.reversed.toList();
      } catch (e) {
        debugPrint("Error parsing Map semesters: $e");
        return [];
      }
    }

    if (list is! List) return [];
    try {
      final results = <SemesterResult>[];
      for (var item in list) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item);
        final semesterName = data['semesterName'] ?? '';
        final List<CourseResult> courseResults = [];

        final rawCourses = data['courses'] as List? ?? [];
        for (var c in rawCourses) {
          final course = Map<String, dynamic>.from(c as Map);
          final code = course['code'] ?? course['courseCode'] ?? '';
          final cleanCode = code.toString().toUpperCase();
          
          final rawCredits = _readDouble(course['credits']);
          final cachedCredits = _courseCreditsCache[cleanCode.toLowerCase()];
          final credits = cachedCredits ?? (rawCredits > 0 ? rawCredits : 3.0);
          
          courseResults.add(CourseResult(
            courseCode: cleanCode,
            courseTitle: course['title'] ?? course['name'] ?? cleanCode,
            credits: credits,
            grade: course['grade'] ?? '',
            gradePoint: _readDouble(course['gradePoint'] ?? course['point']),
          ));
        }

        // Deduplicate by base code
        final Map<String, CourseResult> uniqueCourses = {};
        for (var c in courseResults) {
          final base = c.courseCode.split('_')[0].toUpperCase();
          if (!uniqueCourses.containsKey(base) || c.courseCode.length < uniqueCourses[base]!.courseCode.length) {
            uniqueCourses[base] = c;
          }
        }

        results.add(SemesterResult(
          semesterName: semesterName,
          courses: uniqueCourses.values.toList(),
          termGPA: _readDouble(data['termGPA']),
          cumulativeGPA: _readDouble(data['cumulativeGPA']),
          totalCredits: _readDouble(data['totalCredits']),
          totalPoints: _readDouble(data['totalPoints']),
        ));
      }
      results.sort((a, b) => _compareSemesterName(a.semesterName, b.semesterName));
      return results.reversed.toList();
    } catch (e) {
      debugPrint("Error parsing List semesters: $e");
      return [];
    }
  }



  static double getGradePoint(String grade) {
    if (grade.isEmpty) return 0.0;
    return gradeScaleCache[grade.toUpperCase()] ?? 0.0;
  }

  double _getGradePoint(String grade) {
    return ResultsRepository.getGradePoint(grade);
  }

  static double _readDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  /// Fetches enrolled courses for the current active semester and resolves their credits.
  Future<List<CourseResult>> fetchCurrentEnrolledResults() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final academicRepo = AcademicRepository();
    await ensureMetadataLoaded();

    try {
      final semesterCode = await academicRepo.getCurrentSemesterCode();
      final enrolled = await academicRepo.fetchEnrolledCourses(semesterCode);

      final results = enrolled.map((c) {
        final baseCode = c.code.split('_')[0].toLowerCase().trim();
        final credits = _courseCreditsCache[baseCode] ?? _readDouble(c.credits);
        
        return CourseResult(
          courseCode: c.code,
          courseTitle: c.courseName,
          credits: credits,
          grade: 'Ongoing',
          gradePoint: 0.0,
        );
      }).toList();

      return results;
    } catch (e) {
      debugPrint("Error fetching current enrolled results: $e");
      return [];
    }
  }

  Future<List<String>> fetchCourseCodes() async {
    try {
      final data = await _supabase.from('course_metadata').select('code');
      return data.map((e) => e['code'].toString().toUpperCase()).toList();
    } catch (e) {
      debugPrint("Error fetching course codes: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchRawCourseHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};
    try {
      final data = await _supabase
          .from('academic_data')
          .select('semesters, course_history')
          .eq('user_id', user.id)
          .maybeSingle();
          
      if (data == null) return {};

      // 1. Try course_history first
      final ch = data['course_history'];
      if (ch != null && ch is Map && ch.isNotEmpty) {
        return Map<String, dynamic>.from(ch);
      }

      // 2. Fallback to semesters
      final sems = data['semesters'];
      if (sems != null) {
        if (sems is Map) {
          return Map<String, dynamic>.from(sems);
        } else if (sems is List) {
          final map = <String, dynamic>{};
          for (var s in sems) {
            final sData = Map<String, dynamic>.from(s as Map);
            final semName = sData['semesterName'] ?? 'Unknown';
            final courses = sData['courses'] as List? ?? [];
            final cMap = <String, dynamic>{};
            for (var c in courses) {
              final cData = Map<String, dynamic>.from(c as Map);
              final code = cData['code'] ?? cData['courseCode'] ?? '';
              final grade = cData['grade'] ?? '';
              if (code.isNotEmpty) cMap[code] = grade;
            }
            map[semName] = cMap;
          }
          return map;
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
    return {};
  }

  Future<void> updateCourseHistory(Map<String, dynamic> history) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    await _supabase.from('academic_data').upsert({
      'user_id': user.id,
      'course_history': history,
      'last_updated': DateTime.now().toIso8601String(),
    });
    
    // Trigger recalculation in background
    try {
      AzureFunctionsService().recalculateStats().ignore();
    } catch (_) {}
  }

  static int _compareSemesterName(String a, String b) {
    final pa = _parseSemesterName(a);
    final pb = _parseSemesterName(b);
    final yearCmp = pa.$2.compareTo(pb.$2);
    if (yearCmp != 0) return yearCmp;
    return pa.$1.compareTo(pb.$1);
  }

  static (int, int) _parseSemesterName(String name) {
    final lower = name.toLowerCase().trim();
    int term = 99;
    if (lower.contains('spring')) term = 1;
    if (lower.contains('summer')) term = 2;
    if (lower.contains('fall')) term = 3;
    final yearMatch = RegExp(r'(20\d{2})').firstMatch(lower);
    final year = int.tryParse(yearMatch?.group(1) ?? '') ?? 0;
    return (term, year);
  }

  String _calculateScholarship(String studentId, String programId, double cgpa, List<SemesterResult> semesters) {
    if (cgpa < 3.50) {
      return "";
    }
    
    final (term, year) = _parseAdmissionFromId(studentId);
    if (year == 0) {
      return "";
    }

    final potential = _getPotentialTier(cgpa, year, term);
    if (potential.isEmpty) {
      return "";
    }

    final double lastYearCredits = _calculateLastYearCredits(semesters);
    final double requiredCredits = _getRequiredCredits(programId, year, term);
    
    return lastYearCredits >= requiredCredits ? potential : "";
  }

  String _getPotentialTier(double cgpa, int admitYear, int admitTerm) {
    // PDF states "Admitted in Spring 2026 and onward" for new thresholds.
    final bool isNewRules = admitYear > 2026 || (admitYear == 2026 && admitTerm >= 1);
    
    if (isNewRules) {
      if (cgpa >= 3.95) return "100% Merit Scholarship";
      if (cgpa >= 3.85) return "Dean’s List Scholarship";
      if (cgpa >= 3.75) return "Medha Lalon Scholarship";
    } else {
      if (cgpa >= 3.90) return "100% Merit Scholarship";
      if (cgpa >= 3.75) return "Dean’s List Scholarship";
      if (cgpa >= 3.50) return "Medha Lalon Scholarship";
    }
    return "";
  }

  double _calculateLastYearCredits(List<SemesterResult> semesters) {
    // "Last one year" means the last 3 consecutive completed semesters
    final completed = semesters
        .where((s) => s.courses.any((c) => c.grade != 'Ongoing' && c.grade != 'I' && c.grade != 'W'))
        .toList();
    completed.sort((a, b) => _compareSemesterName(b.semesterName, a.semesterName));

    double credits = 0;
    for (var i = 0; i < completed.length && i < 3; i++) {
      credits += completed[i].totalCredits;
    }
    return credits;
  }

  double _getRequiredCredits(String program, int year, int term) {
    final p = program.toUpperCase();
    
    bool isUpto(int targetYear, int targetTerm) {
      if (year < targetYear) return true;
      if (year == targetYear && term <= targetTerm) return true;
      return false;
    }

    if (p.contains('CSE') || p.contains('ICE') || p.contains('EEE')) return 35.0;
    if (p.contains('PHARM')) return 39.0;
    if (p.contains('MATHEMATICS') || p.contains('DSA')) return 33.0;
    if (p.contains('INFORMATION STUDIES') || p.contains('ISLM')) return 30.0;
    
    if (p.contains('ECONOMICS') || p.contains('ENGLISH') || p.contains('PPHS')) {
      return isUpto(2024, 1) ? 30.0 : 33.0;
    }
    if (p.contains('LL.B') || p.contains('LAW')) return 33.0;
    if (p.contains('CE') || p.contains('CIVIL')) {
      return isUpto(2024, 1) ? 37.0 : 35.0;
    }
    if (p.contains('BBA') || p.contains('BUSINESS') || p.contains('SOC')) {
      return isUpto(2024, 3) ? 30.0 : 33.0;
    }
    if (p.contains('GEB') || p.contains('GENETIC')) {
      return isUpto(2025, 3) ? 33.0 : 35.0;
    }

    return 30.0;
  }

  (int, int) _parseAdmissionFromId(String id) {
    final parts = id.split('-');
    if (parts.length >= 2) {
      return (int.tryParse(parts[1]) ?? 0, int.tryParse(parts[0]) ?? 0);
    }
    return (0, 0);
  }
}
