import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/result_models.dart';
import 'package:flutter/foundation.dart';

class ResultsRepository {
  final _supabase = Supabase.instance.client;

  // Cache for metadata
  static final Map<String, double> _courseCreditsCache = {};
  static bool _metadataLoaded = false;

  Future<AcademicProfile> fetchAcademicProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
    }

    await _ensureMetadataLoaded();

    try {
      final profileData =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      final academicData = await _supabase
          .from('academic_data')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (academicData != null) {
        final semesters = _parseCloudSemesters(academicData['semesters']);
        final cgpa = _readDouble(academicData['cgpa']);

        return AcademicProfile(
          semesters: semesters,
          cgpa: cgpa,
          totalCreditsEarned: _readDouble(academicData['total_credits_earned']),
          studentName: (profileData['full_name'] ?? 'Student').toString(),
          studentId: (profileData['student_id'] ?? 'N/A').toString(),
          program: (profileData['program_id'] ?? 'N/A').toString(),
          department: (profileData['department'] ?? 'N/A').toString(),
          remainedCredits: _readDouble(academicData['remained_credits']),
          scholarshipStatus: _calculateScholarship(
            (profileData['student_id'] ?? 'N/A').toString(),
            (profileData['program_id'] ?? 'N/A').toString(),
            cgpa,
            semesters,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching academic profile: $e");
    }

    return AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
  }

  Future<void> _ensureMetadataLoaded() async {
    if (_metadataLoaded) return;
    try {
      final data = await _supabase.from('course_metadata').select();
      for (var item in data) {
        final code = item['code']?.toString().toUpperCase() ?? '';
        double val = 3.0;
        if (item['credit_val'] is num) {
          val = (item['credit_val'] as num).toDouble();
        } else if (item['credits'] != null) {
          val = double.tryParse(item['credits'].toString()) ?? 3.0;
        }
        if (code.isNotEmpty) _courseCreditsCache[code] = val;
      }
      _metadataLoaded = true;
    } catch (e) {
      debugPrint("Error loading course metadata: $e");
    }
  }

  Stream<AcademicProfile> streamAcademicProfile() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value(
          AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0));
    }

    return _supabase
        .from('academic_data')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id)
        .asyncMap((data) async {
          await _ensureMetadataLoaded();

          if (data.isEmpty) {
            return AcademicProfile(
                semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
          }

          final academicData = data.first;

          try {
            final profileData = await _supabase
                .from('profiles')
                .select()
                .eq('id', user.id)
                .single();

            final semesters = _parseCloudSemesters(academicData['semesters']);
            final cgpa = _readDouble(academicData['cgpa']);

            return AcademicProfile(
              semesters: semesters,
              cgpa: cgpa,
              totalCreditsEarned:
                  _readDouble(academicData['total_credits_earned']),
              studentName: (profileData['full_name'] ?? 'Student').toString(),
              studentId: (profileData['student_id'] ?? 'N/A').toString(),
              program: (profileData['program_id'] ?? 'N/A').toString(),
              department: (profileData['department'] ?? 'N/A').toString(),
              remainedCredits: _readDouble(academicData['remained_credits']),
              scholarshipStatus: _calculateScholarship(
                (profileData['student_id'] ?? 'N/A').toString(),
                (profileData['program_id'] ?? 'N/A').toString(),
                cgpa,
                semesters,
              ),
            );
          } catch (e) {
            debugPrint("Error in streamAcademicProfile: $e");
            return AcademicProfile(
                semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
          }
        });
  }

  List<SemesterResult> _parseCloudSemesters(dynamic list) {
    if (list is! List) return [];
    try {
      final sems = list
          .map((item) {
            if (item is! Map) return null;
            final data = Map<String, dynamic>.from(item);

            final courses = (data['courses'] as List? ?? []).map((c) {
              final cMap = Map<String, dynamic>.from(c as Map);
              return CourseResult(
                  courseCode: cMap['code'] ?? '',
                  courseTitle: cMap['title'] ?? cMap['code'] ?? '',
                  credits: _readDouble(cMap['credits']),
                  grade: cMap['grade'] ?? '',
                  gradePoint: _readDouble(cMap['point']));
            }).toList();

            final sem = SemesterResult(
                semesterName: data['semesterName'] ?? '', courses: courses);
            sem.calculateTermGPA();
            return sem;
          })
          .whereType<SemesterResult>()
          .toList();

      sems.sort((a, b) => _compareSemesterName(a.semesterName, b.semesterName));
      _calculateRunningCGPA(sems);
      return sems.reversed.toList();
    } catch (e) {
      debugPrint("Error parsing cloud semesters: $e");
      return [];
    }
  }

  void _calculateRunningCGPA(List<SemesterResult> sems) {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var sem in sems) {
      totalPoints += sem.totalPoints;
      totalCredits += sem.totalCredits;
      sem.cumulativeGPA = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
    }
  }

  double _readDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
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
          .select('semesters')
          .eq('user_id', user.id)
          .maybeSingle();
      if (data != null && data['semesters'] != null) {
        return Map<String, dynamic>.from(data['semesters']);
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
      'semesters': history,
      'updated_at': DateTime.now().toIso8601String(),
    });
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

  Future<String> _resolveProgramName(String programId) async {
    if (programId.isEmpty) return "N/A";
    final lowerId = programId.toLowerCase();
    try {
      final result = await _supabase
          .from('metadata')
          .select('data')
          .eq('id', 'departments')
          .single();
      final data = result['data'];
      if (data != null && data['programs'] is List) {
        for (var p in data['programs']) {
          if (p['id'].toString().toLowerCase() == lowerId) {
            return p['name'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint("Error resolving program name: $e");
    }

    // Fallback list
    const fallbacks = {
      'cse': 'Computer Science & Engineering',
      'eee': 'Electrical & Electronic Engineering',
      'pharma': 'Pharmacy',
      'eng': 'English',
      'bba': 'Business Administration',
    };
    return fallbacks[lowerId] ?? programId.toUpperCase();
  }

  String _calculateScholarship(String studentId, String programName,
      double cgpa, List<SemesterResult> semesters) {
    if (cgpa < 3.50) return "";
    final (term, year) = _parseAdmissionFromId(studentId);
    if (year == 0) return "";

    bool isNewRules = year > 2025 || (year == 2026 && term >= 1);
    String potential = "";
    if (isNewRules) {
      if (cgpa >= 3.95)
        potential = "100% Merit Scholarship";
      else if (cgpa >= 3.85)
        potential = "Dean’s List Scholarship";
      else if (cgpa >= 3.75) potential = "Medha Lalon Scholarship";
    } else {
      if (cgpa >= 3.90)
        potential = "100% Merit Scholarship";
      else if (cgpa >= 3.75)
        potential = "Dean’s List Scholarship";
      else if (cgpa >= 3.50) potential = "Medha Lalon Scholarship";
    }

    if (potential.isEmpty) return "";

    final completed = semesters
        .where((s) => s.courses.any(
            (c) => c.grade != 'Ongoing' && c.grade != 'I' && c.grade != 'W'))
        .toList();
    completed
        .sort((a, b) => _compareSemesterName(b.semesterName, a.semesterName));

    double lastYearCredits = 0;
    for (var i = 0; i < completed.length && i < 3; i++) {
      lastYearCredits += completed[i].totalCredits;
    }

    final required = _getRequiredCredits(programName, year, term);
    return lastYearCredits >= required ? potential : "";
  }

  (int, int) _parseAdmissionFromId(String id) {
    final parts = id.split('-');
    if (parts.length >= 2) {
      return (int.tryParse(parts[1]) ?? 0, int.tryParse(parts[0]) ?? 0);
    }
    return (0, 0);
  }

  double _getRequiredCredits(String program, int year, int term) {
    final isCSE = program.toUpperCase().contains('CSE') ||
        program.toUpperCase().contains('COMPUTER');
    final isPharma = program.toUpperCase().contains('PHARMA');

    if (isCSE) return 27.0; // Typical 9 credits per sem * 3 sems
    if (isPharma) return 33.0; // Higher requirement
    return 27.0; // Standard
  }
}
