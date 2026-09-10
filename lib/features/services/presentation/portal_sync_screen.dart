import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/portal_service.dart';
import '../../../core/utils/course_utils.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/services/cache_service.dart';
import '../../auth/auth_providers.dart';
import '../../onboarding/onboarding_repository.dart';

class PortalSyncScreen extends ConsumerStatefulWidget {
  const PortalSyncScreen({super.key});

  @override
  ConsumerState<PortalSyncScreen> createState() => _PortalSyncScreenState();
}

class _PortalSyncScreenState extends ConsumerState<PortalSyncScreen> {
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // Flow State: 0 = Input form, 1 = Preview & Selection
  int _step = 0;
  bool _isLoading = false;
  String? _statusMessage;
  String? _errorMessage;

  // Fetched Data from Portal
  PortalSyncResult? _portalData;
  List<Map<String, dynamic>> _azureParsedGrades = [];

  // User Selection Checkboxes
  bool _syncActiveSchedule = true;
  bool _syncAcademicHistory = false; // Opt-in: Only if user wants
  bool _syncProfileMetadata = false; // Default false for completed users
  bool _syncCrowdsourcedFaculty = true;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    final sid = profile?.studentId;
    if (sid != null && sid.isNotEmpty) {
      _studentIdCtrl.text = sid;
    }
    // If onboarding is not completed, default profile metadata to true
    if (profile?.onboardingStatus != 'completed') {
      _syncProfileMetadata = true;
    }
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Step 1: Connect to Portal and fetch data for preview
  Future<void> _fetchPortalData() async {
    final studentId = _studentIdCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both Student ID and Portal Password.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = "Logging into EWU Portal & solving arithmetic captcha...";
    });

    try {
      final portalService = ref.read(portalServiceProvider);

      // 1. Fetch complete portal data
      final result = await portalService.syncAll(
        studentId: studentId,
        password: password,
      );

      // 2. Concurrently fetch Azure Function PDF grade sheet if available
      setState(() => _statusMessage = "Fetching official grade sheet records...");
      List<Map<String, dynamic>> parsedCourses = [];
      try {
        final gradeSheetRes = await http.post(
          Uri.parse('https://ewumate-parser.azurewebsites.net/api/parse_grade_sheet'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'password': password,
          }),
        ).timeout(const Duration(seconds: 15));

        if (gradeSheetRes.statusCode == 200) {
          final data = jsonDecode(gradeSheetRes.body) as Map<String, dynamic>;
          parsedCourses = List<Map<String, dynamic>>.from(data['courses'] ?? []);
        }
      } catch (e) {
        debugPrint("[PortalSyncScreen] Azure grade-sheet notice: $e");
      }

      // 3. Enrich enrolled courses with verified faculty directory & assignments data
      setState(() => _statusMessage = "Matching verified faculty directory details...");
      List<PortalEnrolledCourse> enrichedCourses = [];
      try {
        final supabase = Supabase.instance.client;
        final semCode = CourseUtils.cleanSemester(result.activeSemesterName);

        final facultyDirRes = await supabase
            .from('faculty_directory')
            .select('short_name, full_name, email');
        
        final Map<String, Map<String, String>> facultyByInitial = {};
        for (final row in facultyDirRes as List) {
          final init = (row['short_name'] ?? '').toString().trim().toUpperCase();
          if (init.isNotEmpty) {
            facultyByInitial[init] = {
              'fullName': (row['full_name'] ?? '').toString().trim(),
              'email': (row['email'] ?? '').toString().trim(),
            };
          }
        }

        final assignmentsRes = await supabase
            .from('faculty_assignments')
            .select('course_code, section_number, faculty_initial, faculty_name')
            .eq('semester', semCode);

        final Map<String, Map<String, String>> assignmentsByKey = {};
        for (final row in assignmentsRes as List) {
          final code = (row['course_code'] ?? '').toString().trim().toUpperCase();
          final sec = (row['section_number'] ?? '').toString().trim();
          final init = (row['faculty_initial'] ?? '').toString().trim();
          final name = (row['faculty_name'] ?? '').toString().trim();
          if (code.isNotEmpty && init.isNotEmpty && init != 'TBA') {
            assignmentsByKey['$code:$sec'] = {
              'initial': init,
              'name': name,
            };
          }
        }

        for (final c in result.enrolledCourses) {
          final cleanCode = c.courseCode.contains(' ') ? c.courseCode.split(' ')[0].toUpperCase() : c.courseCode.toUpperCase();
          final secKey = '$cleanCode:${c.section.trim()}';

          String resolvedInitial = c.facultyInitial.trim();
          String resolvedName = c.facultyName.trim();
          String resolvedEmail = c.facultyEmail.trim();

          // 1. If portal gave a valid initial, prioritize it!
          // If portal returned TBA or empty, fallback to community verified faculty_assignments
          if (resolvedInitial.isEmpty || resolvedInitial.toUpperCase() == 'TBA') {
            if (assignmentsByKey.containsKey(secKey)) {
              resolvedInitial = assignmentsByKey[secKey]!['initial']!;
              if (assignmentsByKey[secKey]!['name']!.isNotEmpty) {
                resolvedName = assignmentsByKey[secKey]!['name']!;
              }
            }
          }

          // 2. Canonical faculty_directory matching initial -> fills full name and official email
          final normInit = resolvedInitial.trim().toUpperCase();
          if (facultyByInitial.containsKey(normInit)) {
            final dir = facultyByInitial[normInit]!;
            if (dir['fullName']!.isNotEmpty) {
              resolvedName = dir['fullName']!;
            }
            if (dir['email']!.isNotEmpty && (resolvedEmail.isEmpty || !resolvedEmail.contains('@'))) {
              resolvedEmail = dir['email']!;
            }
          }

          enrichedCourses.add(c.copyWith(
            facultyInitial: resolvedInitial,
            facultyName: resolvedName,
            facultyEmail: resolvedEmail,
          ));
        }
      } catch (e) {
        debugPrint("[PortalSyncScreen] Faculty directory enrichment note: $e");
        enrichedCourses = result.enrolledCourses;
      }

      final finalResult = PortalSyncResult(
        profile: result.profile,
        activeSemesterName: result.activeSemesterName,
        activeSemesterId: result.activeSemesterId,
        enrolledCourses: enrichedCourses,
        degreeAreas: result.degreeAreas,
      );

      if (mounted) {
        setState(() {
          _portalData = finalResult;
          _azureParsedGrades = parsedCourses;
          _step = 1; // Move to Preview & Selection
          _isLoading = false;
          _statusMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  /// Formats the raw TimeSlotName (e.g. "ST 08:30 AM-10:00 AM" or "T 04:50 PM-06:50 PM") into weekly_grid_cache
  Map<String, List<Map<String, dynamic>>> _buildWeeklyGridCache(
    List<PortalEnrolledCourse> courses,
    Map<String, String> courseNamesByCode,
  ) {
    final Map<String, List<Map<String, dynamic>>> grid = {
      'Saturday': [],
      'Sunday': [],
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
    };

    const dayMap = {
      'S': 'Sunday',
      'M': 'Monday',
      'T': 'Tuesday',
      'W': 'Wednesday',
      'R': 'Thursday',
      'F': 'Friday',
      'A': 'Saturday',
    };

    for (final item in courses) {
      final timing = item.timing.trim();
      if (timing.isEmpty || timing.toUpperCase() == 'TBA') continue;

      // Extract Day codes and Time range
      final parts = timing.split(' ');
      if (parts.isEmpty) continue;

      final dayCodes = parts[0].trim();
      final timeRange = parts.sublist(1).join(' ').trim();
      final timeSplit = timeRange.split('-');
      if (timeSplit.length < 2) continue;

      final startStr = timeSplit[0].trim();
      final endStr = timeSplit[1].trim();

      final cleanCode = item.courseCode.contains(' ') ? item.courseCode.split(' ')[0] : item.courseCode;
      final courseName = courseNamesByCode[cleanCode] ?? item.courseCode;
      final isLab = CourseUtils.isLab(startStr, endStr, cleanCode);

      final classEntry = {
        'courseCode': cleanCode,
        'courseName': courseName,
        'section': item.section,
        'startTime': startStr,
        'endTime': endStr,
        'room': item.room.isNotEmpty ? item.room : 'TBA',
        'faculty': item.facultyInitial.isNotEmpty ? item.facultyInitial : (item.facultyName.isNotEmpty ? item.facultyName : 'TBA'),
        'facultyName': item.facultyName,
        'facultyEmail': item.facultyEmail,
        'type': isLab ? 'Lab' : 'Theory',
      };

      // Handle dual-day codes
      if (dayCodes.toUpperCase() == 'ST') {
        grid['Sunday']?.add(Map.from(classEntry));
        grid['Tuesday']?.add(Map.from(classEntry));
      } else if (dayCodes.toUpperCase() == 'SR') {
        grid['Sunday']?.add(Map.from(classEntry));
        grid['Thursday']?.add(Map.from(classEntry));
      } else if (dayCodes.toUpperCase() == 'MW') {
        grid['Monday']?.add(Map.from(classEntry));
        grid['Wednesday']?.add(Map.from(classEntry));
      } else if (dayCodes.toUpperCase() == 'TR') {
        grid['Tuesday']?.add(Map.from(classEntry));
        grid['Thursday']?.add(Map.from(classEntry));
      } else if (dayCodes.toUpperCase() == 'RA') {
        grid['Thursday']?.add(Map.from(classEntry));
        grid['Saturday']?.add(Map.from(classEntry));
      } else {
        for (int i = 0; i < dayCodes.length; i++) {
          final char = dayCodes[i].toUpperCase();
          final fullDay = dayMap[char];
          if (fullDay != null && grid.containsKey(fullDay)) {
            grid[fullDay]?.add(Map.from(classEntry));
          }
        }
      }
    }

    grid.forEach((day, classes) {
      classes.sort((a, b) {
        final tA = CourseUtils.parseTimeToDouble(a['startTime'].toString());
        final tB = CourseUtils.parseTimeToDouble(b['startTime'].toString());
        return tA.compareTo(tB);
      });
    });

    return grid;
  }

  /// Step 2: Confirm and Apply Selected Sync Options to Database
  Future<void> _applySync() async {
    final result = _portalData;
    if (result == null) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _errorMessage = "User is not authenticated.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = "Applying your selections...";
    });

    try {
      final activeSemCode = CourseUtils.cleanSemester(result.activeSemesterName);

      // 1. Fetch official course names from courses_<activeSemCode> or course_metadata
      final Map<String, String> courseNames = {};
      try {
        final catalogRes = await supabase
            .from('courses_$activeSemCode')
            .select('course_code, course_name');
        for (final row in catalogRes as List) {
          final code = (row['course_code'] ?? '').toString();
          final name = (row['course_name'] ?? '').toString();
          if (code.isNotEmpty && name.isNotEmpty) {
            courseNames[code] = name;
          }
        }
      } catch (_) {
        try {
          final metaRes = await supabase.from('course_metadata').select('code, name');
          for (final row in metaRes as List) {
            final code = (row['code'] ?? '').toString();
            final name = (row['name'] ?? '').toString();
            if (code.isNotEmpty && name.isNotEmpty) {
              courseNames[code] = name;
            }
          }
        } catch (_) {}
      }

      // 2. Profile Metadata Update
      if (_syncProfileMetadata) {
        setState(() => _statusMessage = "Updating profile metadata...");
        final cleanAdmittedSem = CourseUtils.cleanSemester(result.profile.admittedSemester);
        final isBi = result.profile.departmentName.toLowerCase().contains('pharm') ||
            result.profile.departmentName.toLowerCase().contains('law') ||
            result.profile.programCode.toUpperCase().contains('PHRM') ||
            result.profile.programCode.toUpperCase().contains('LLB');
        final track = isBi ? 'bi_semester' : 'tri_semester';

        final profilePayload = <String, dynamic>{
          'id': user.id,
          'student_id': result.profile.studentId,
          'program_code': result.profile.programCode.toUpperCase(),
          'program_name': result.profile.programName,
          'department_name': result.profile.departmentName,
          'semester_type': track,
          'track': track,
          'onboarding_status': 'completed',
        };
        if (cleanAdmittedSem.isNotEmpty) {
          profilePayload['admitted_semester'] = cleanAdmittedSem;
        }
        await supabase.from('profiles').upsert(profilePayload);
      } else {
        // Even if metadata fields are kept as-is, ensure onboarding is marked completed
        await supabase.from('profiles').update({
          'onboarding_status': 'completed',
        }).eq('id', user.id);
      }

      // 3. Academic History & Grades
      int importedGradesCount = 0;
      if (_syncAcademicHistory) {
        setState(() => _statusMessage = "Saving verified academic history...");
        final List<Map<String, dynamic>> completedRows = [];

        if (_azureParsedGrades.isNotEmpty) {
          for (final c in _azureParsedGrades) {
            completedRows.add({
              'user_id': user.id,
              'course_code': c['course_code'],
              'grade': c['grade'],
              'grade_point': c['grade_point'],
              'credits': c['credits'],
              'semester_code': CourseUtils.cleanSemester(c['semester_code'] ?? ''),
            });
          }
        } else {
          for (final area in result.degreeAreas) {
            for (final c in area.courses) {
              if (c.grade.isNotEmpty) {
                completedRows.add({
                  'user_id': user.id,
                  'course_code': c.courseCode,
                  'grade': c.grade,
                  'grade_point': c.gradePoint,
                  'credits': c.credits,
                  'semester_code': 'portal_verified',
                });
              }
            }
          }
        }

        if (completedRows.isNotEmpty) {
          await supabase.from('completed_courses').delete().eq('user_id', user.id);
          await supabase.from('completed_courses').insert(completedRows);
          importedGradesCount = completedRows.length;
        }
      }

      // 4. Active Semester Schedule & Enrollments
      int enrolledCount = 0;
      if (_syncActiveSchedule && result.enrolledCourses.isNotEmpty) {
        setState(() => _statusMessage = "Saving routine and weekly schedule grid...");

        await supabase.from('enrollments').delete().eq('user_id', user.id).eq('semester_code', activeSemCode);

        final enrollmentRows = <Map<String, dynamic>>[];
        final progressRows = <Map<String, dynamic>>[];

        for (final item in result.enrolledCourses) {
          final cleanCode = item.courseCode.contains(' ') ? item.courseCode.split(' ')[0] : item.courseCode;
          enrollmentRows.add({
            'user_id': user.id,
            'course_code': cleanCode,
            'section': item.section,
            'semester_code': activeSemCode,
            'status': 'enrolled',
          });

          progressRows.add({
            'user_id': user.id,
            'course_code': cleanCode,
            'course_name': courseNames[cleanCode] ?? cleanCode,
            'section': item.section,
            'semester_code': activeSemCode,
          });
        }

        if (enrollmentRows.isNotEmpty) {
          await supabase.from('enrollments').insert(enrollmentRows);
          enrolledCount = enrollmentRows.length;
        }

        if (progressRows.isNotEmpty) {
          try {
            await supabase.from('semester_course_marks').upsert(
              progressRows,
              onConflict: 'user_id,course_code,semester_code',
            );
          } catch (e) {
            debugPrint("[PortalSyncScreen] semester_course_marks note: $e");
          }
        }

        // 4a. First Crowdsource verified faculty assignments so DB has latest truth
        if (_syncCrowdsourcedFaculty && result.enrolledCourses.isNotEmpty) {
          setState(() => _statusMessage = "Crowdsourcing verified faculty assignments...");
          final facultyUpdates = <Map<String, dynamic>>[];
          for (final item in result.enrolledCourses) {
            final cleanCode = item.courseCode.contains(' ') ? item.courseCode.split(' ')[0] : item.courseCode;
            if (item.facultyInitial.isNotEmpty && item.facultyInitial != 'TBA') {
              facultyUpdates.add({
                'course_code': cleanCode,
                'section_number': item.section,
                'semester': activeSemCode,
                'faculty_initial': item.facultyInitial,
                'faculty_name': item.facultyName,
                'is_verified': true,
              });
            }
          }

          if (facultyUpdates.isNotEmpty) {
            try {
              await supabase.from('faculty_assignments').upsert(
                facultyUpdates,
                onConflict: 'course_code,section_number,semester',
              );
            } catch (e) {
              debugPrint("[PortalSyncScreen] faculty_assignments note: $e");
            }
          }
        }

        // 4b. Build and save the formatted weekly_grid_cache into user_semester_states
        final weeklyGrid = _buildWeeklyGridCache(result.enrolledCourses, courseNames);
        try {
          await supabase.from('user_semester_states').upsert({
            'user_id': user.id,
            'semester_code': activeSemCode,
            'weekly_grid_cache': weeklyGrid,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,semester_code');
          debugPrint("[PortalSyncScreen] weekly_grid_cache preserved successfully!");
        } catch (e) {
          debugPrint("[PortalSyncScreen] user_semester_states weekly_grid error: $e");
        }

        try {
          final cache = ref.read(cacheServiceProvider);
          await cache.invalidateDashboardSchedule(user.id, activeSemCode);
        } catch (_) {}
      }

      // 6. Recalculate stats & sync server functions
      setState(() => _statusMessage = "Finalizing calculations...");
      try {
        await ref.read(onboardingRepositoryProvider).recalculateStats(activeSemCode);
      } catch (_) {}

      ref.invalidate(profileProvider);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade800,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Sync applied! Routine ($enrolledCount courses) and Grades ($importedGradesCount records) preserved successfully.",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );

        // Mark onboarding complete and navigate to dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: const EWUmateAppBar(
        title: "EWU Portal Sync",
        showBack: true,
      ),
      body: SafeArea(
        child: _step == 0 ? _buildCredentialsForm() : _buildPreviewAndOptions(),
      ),
    );
  }

  Widget _buildCredentialsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.cloud_sync_rounded, color: Colors.cyanAccent, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Connect Your EWU Portal",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Instantly fetch your active semester routine, assigned faculty, room numbers, and academic history.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.cyanAccent, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your portal credentials are used in real-time solely to establish a secure session with portal.ewubd.edu and are NEVER stored on our servers.",
                    style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _studentIdCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Student ID (e.g. 2025-2-50-009)",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.badge_outlined, color: Colors.cyanAccent),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Portal Password",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.cyanAccent),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          if (_isLoading && _statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: Colors.cyanAccent),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          ElevatedButton(
            onPressed: _isLoading ? null : _fetchPortalData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: Text(
              _isLoading ? "Connecting to Portal..." : "Fetch & Preview Data",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewAndOptions() {
    final res = _portalData;
    if (res == null) return const Center(child: Text("No data fetched."));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E293B), Colors.cyanAccent.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        res.profile.fullName.isNotEmpty ? res.profile.fullName : res.profile.studentId,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        res.activeSemesterName,
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "ID: ${res.profile.studentId} • ${res.profile.programName.isNotEmpty ? res.profile.programName : res.profile.programCode}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (res.profile.admittedSemester.isNotEmpty)
                  Text(
                    "Admitted: ${CourseUtils.prettifySemesterCode(CourseUtils.cleanSemester(res.profile.admittedSemester))}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Enrolled Routine (${res.enrolledCourses.length} Courses)",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Verified Live",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (res.enrolledCourses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text("No enrolled courses found for this semester on portal.", style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ...res.enrolledCourses.map((c) => _buildEnrolledCourseCard(c)),

          const SizedBox(height: 20),

          const Text(
            "Choose What to Update",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          _buildCheckboxOption(
            title: "Active Schedule & Routine",
            subtitle: "Preserve ${res.enrolledCourses.length} courses, section timings, room & day schedule",
            value: _syncActiveSchedule,
            onChanged: (v) => setState(() => _syncActiveSchedule = v ?? true),
          ),
          _buildCheckboxOption(
            title: "Academic History & Grades (Optional)",
            subtitle: _azureParsedGrades.isNotEmpty
                ? "Optional: Import ${_azureParsedGrades.length} completed courses & grade sheet"
                : "Optional: Import completed degree courses & letter grades",
            value: _syncAcademicHistory,
            onChanged: (v) => setState(() => _syncAcademicHistory = v ?? false),
          ),
          _buildCheckboxOption(
            title: "Crowdsource Faculty Assignments",
            subtitle: "Share verified faculty initials with your classmates",
            value: _syncCrowdsourcedFaculty,
            onChanged: (v) => setState(() => _syncCrowdsourcedFaculty = v ?? true),
          ),
          _buildCheckboxOption(
            title: "Update Program & Profile Metadata",
            subtitle: "Update Department, Program and Admitted Semester",
            value: _syncProfileMetadata,
            onChanged: (v) => setState(() => _syncProfileMetadata = v ?? false),
          ),

          const SizedBox(height: 16),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          if (_isLoading && _statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: Colors.cyanAccent),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Re-enter"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _applySync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: Text(
                    _isLoading ? "Applying..." : "Confirm & Save Schedule",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEnrolledCourseCard(PortalEnrolledCourse c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.courseCode,
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Sec: ${c.section}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              if (c.credits > 0)
                Text(
                  "${c.credits} Cr",
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: Colors.tealAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.facultyName.isNotEmpty
                      ? "${c.facultyName} (${c.facultyInitial})"
                      : (c.facultyInitial.isNotEmpty ? c.facultyInitial : "TBA"),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Text(
                c.timing.isNotEmpty ? c.timing : "Timing: TBA",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.meeting_room_outlined, size: 16, color: Colors.purpleAccent),
              const SizedBox(width: 4),
              Text(
                c.room.isNotEmpty ? "Room: ${c.room}" : "Room: TBA",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? Colors.cyanAccent.withValues(alpha: 0.05) : const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.cyanAccent.withValues(alpha: 0.3) : const Color(0xFF334155),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00E5FF),
        checkColor: Colors.black,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }
}
