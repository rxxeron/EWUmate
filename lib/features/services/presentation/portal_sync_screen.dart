import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/portal_service.dart';
import '../../../core/utils/course_utils.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/providers/academic_providers.dart';
import '../../auth/auth_providers.dart';
import '../../onboarding/onboarding_repository.dart';
import '../repositories/portal_sync_repository.dart';
import 'portal_sync/widgets/portal_sync_start_view.dart';
import 'portal_sync/widgets/portal_sync_connecting_view.dart';
import 'portal_sync/widgets/portal_sync_ready_view.dart';
import 'portal_sync/widgets/portal_sync_preview_view.dart';
import 'portal_sync/widgets/portal_sync_syncing_view.dart';
import 'portal_sync/widgets/portal_sync_complete_view.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

enum PortalSyncStep {
  startSync, // Step 1: User credentials
  connecting, // Step 2 & 3: Connection & Real-time status checklist
  syncReady, // Step 4: All data fetched, ready confirmation
  dataPreview, // Step 5: Routine & courses preview
  syncing, // Step 6: Saving data to database
  syncComplete, // Step 7: Final success summary
}

class PortalSyncScreen extends ConsumerStatefulWidget {
  const PortalSyncScreen({super.key});

  @override
  ConsumerState<PortalSyncScreen> createState() => _PortalSyncScreenState();
}

class _PortalSyncScreenState extends ConsumerState<PortalSyncScreen>
    with TickerProviderStateMixin {
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  PortalSyncStep _currentStep = PortalSyncStep.startSync;
  String? _errorMessage;

  // Local Credential & Semester state
  bool _rememberCredentials = false;
  List<Map<String, dynamic>> _availableSemesters = [];
  Map<String, dynamic>? _selectedSemester;
  bool _wasOnboarding = false;

  // Connecting animation checklist progress (0 to 5)
  int _fetchChecklistProgress = 0;
  // Syncing database checklist progress (0 to 5)
  int _syncChecklistProgress = 0;

  // Fetched Data from Portal
  PortalSyncResult? _portalData;
  List<Map<String, dynamic>> _azureParsedGrades = [];

  // User Selection Checkboxes
  bool _syncActiveSchedule = true;
  bool _syncAcademicHistory = true;
  bool _syncProfileMetadata = false;

  // Animation Controllers
  late AnimationController _rotationCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    final profile = ref.read(profileProvider).value;
    final sid = profile?.studentId;
    if (sid != null && sid.isNotEmpty) {
      _studentIdCtrl.text = sid;
    }
    if (profile?.onboardingStatus != 'completed') {
      _syncProfileMetadata = true;
      _wasOnboarding = true;
    }

    _loadSavedCredentials();
    _loadAvailableSemesters();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.portalSyncKey,
          steps: OnboardingSteps.portalSync,
        );
      }
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('portal_remember_credentials') ?? false;
      if (remember) {
        final savedId = prefs.getString('portal_local_saved_id') ?? '';
        final savedPass = prefs.getString('portal_local_saved_password') ?? '';
        if (mounted) {
          setState(() {
            _rememberCredentials = true;
            if (savedId.isNotEmpty && _studentIdCtrl.text.isEmpty) {
              _studentIdCtrl.text = savedId;
            }
            if (savedPass.isNotEmpty) {
              _passwordCtrl.text = savedPass;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[PortalSyncScreen] Error loading saved credentials: $e');
    }
  }

  Future<void> _loadAvailableSemesters() async {
    try {
      final res = await Supabase.instance.client
          .from('semesters')
          .select('code, title, is_active, portal_semester_id')
          .order('portal_semester_id', ascending: false);
      final list = List<Map<String, dynamic>>.from(res as List);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _availableSemesters = list;
          // Default to active semester, or top one
          _selectedSemester = list.firstWhere(
            (s) => s['is_active'] == true,
            orElse: () => list.first,
          );
        });
      }
    } catch (e) {
      debugPrint('[PortalSyncScreen] Error loading semesters: $e');
    }
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Triggered from Step 1: Start Sync
  Future<void> _handleStartSync() async {
    final studentId = _studentIdCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both Student ID and Portal Password.");
      return;
    }

    // Save/clear credentials locally on device according to _rememberCredentials (zero DB transmission)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberCredentials) {
        await prefs.setBool('portal_remember_credentials', true);
        await prefs.setString('portal_local_saved_id', studentId);
        await prefs.setString('portal_local_saved_password', password);
      } else {
        await prefs.setBool('portal_remember_credentials', false);
        await prefs.remove('portal_local_saved_id');
        await prefs.remove('portal_local_saved_password');
      }
    } catch (e) {
      debugPrint('[PortalSyncScreen] Error saving local credentials: $e');
    }

    setState(() {
      _errorMessage = null;
      _currentStep = PortalSyncStep.connecting;
      _fetchChecklistProgress = 1;
    });

    Timer? t1;
    Timer? t2;
    Timer? t3;

    t1 = Timer(const Duration(milliseconds: 900), () {
      if (mounted && _currentStep == PortalSyncStep.connecting) {
        setState(() => _fetchChecklistProgress = 2);
      }
    });

    t2 = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _currentStep == PortalSyncStep.connecting) {
        setState(() => _fetchChecklistProgress = 3);
      }
    });

    t3 = Timer(const Duration(milliseconds: 4000), () {
      if (mounted && _currentStep == PortalSyncStep.connecting) {
        setState(() => _fetchChecklistProgress = 4);
      }
    });

    try {
      final Map<String, dynamic> requestPayload = {
        'student_id': studentId,
        'password': password,
      };
      if (_selectedSemester != null) {
        if (_selectedSemester!['portal_semester_id'] != null) {
          requestPayload['semester_id'] = _selectedSemester!['portal_semester_id'];
        }
        if (_selectedSemester!['code'] != null) {
          requestPayload['semester_code'] = _selectedSemester!['code'];
        }
      }

      final azureRes = await http.post(
        Uri.parse('https://ewumate-parser.azurewebsites.net/api/portal_sync_student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      ).timeout(const Duration(seconds: 35));

      t1.cancel();
      t2.cancel();
      t3.cancel();

      if (azureRes.statusCode != 200) {
        final errBody = jsonDecode(azureRes.body);
        throw Exception(errBody['error'] ?? errBody['message'] ?? 'Failed to connect to EWU portal.');
      }

      final data = jsonDecode(azureRes.body) as Map<String, dynamic>;
      final profileMap = data['profile'] as Map<String, dynamic>? ?? {};
      final enrolledList = (data['enrolled_courses'] as List? ?? []).cast<Map<String, dynamic>>();
      final gradesList = (data['parsed_grades'] as List? ?? []).cast<Map<String, dynamic>>();

      final studentProfile = PortalStudentProfile(
        studentId: profileMap['studentId']?.toString() ?? profileMap['StudentId']?.toString() ?? studentId,
        fullName: profileMap['fullName']?.toString() ?? profileMap['FirstName']?.toString() ?? '',
        email: profileMap['email']?.toString() ?? profileMap['EmailAddress']?.toString() ?? '',
        programName: profileMap['programName']?.toString() ?? profileMap['ProgramName']?.toString() ?? '',
        programCode: profileMap['programCode']?.toString() ?? profileMap['ProgramShortName']?.toString() ?? '',
        departmentName: profileMap['departmentName']?.toString() ?? profileMap['AcademicDepartmentName']?.toString() ?? '',
        departmentCode: profileMap['departmentCode']?.toString() ?? profileMap['AcademicDepartmentShortName']?.toString() ?? '',
        admittedSemester: profileMap['admittedSemester']?.toString() ?? profileMap['StartedSemester']?.toString() ?? '',
        cgpa: (profileMap['cgpa'] as num?)?.toDouble() ?? (profileMap['CGPA'] as num?)?.toDouble() ?? 0.0,
        creditsEarned: (profileMap['creditsEarned'] as num?)?.toDouble() ?? (profileMap['CreditsCompleted'] as num?)?.toDouble() ?? 0.0,
        mentor: profileMap['mentor']?.toString() ?? '',
        mentorEmail: profileMap['mentorEmail']?.toString() ?? '',
      );

      final List<PortalEnrolledCourse> enrolledCourses = enrolledList.map((c) {
        return PortalEnrolledCourse.fromJson(c);
      }).toList();

      final semCode = data['semester_code']?.toString() ?? _selectedSemester?['code']?.toString() ?? 'fall2026';
      final semName = data['active_semester_name']?.toString() ?? _selectedSemester?['title']?.toString() ?? 'Fall 2026';
      final semId = (data['active_semester_id'] as num?)?.toInt() ?? (_selectedSemester?['portal_semester_id'] as num?)?.toInt() ?? 0;

      final finalResult = PortalSyncResult(
        profile: studentProfile,
        activeSemesterName: semName,
        activeSemesterId: semId,
        semesterCode: semCode,
        enrolledCourses: enrolledCourses,
        degreeAreas: [],
      );

      if (mounted) {
        setState(() {
          _portalData = finalResult;
          _azureParsedGrades = gradesList;
          _fetchChecklistProgress = 5;
          _currentStep = PortalSyncStep.syncReady;
        });
      }
    } catch (e) {
      t1.cancel();
      t2.cancel();
      t3.cancel();
      if (mounted) {
        setState(() {
          _currentStep = PortalSyncStep.startSync;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  /// Formats courses and sessions into weekly_grid_cache
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
      final cleanCode = (item.courseCode.contains(' ') ? item.courseCode.split(' ')[0] : item.courseCode).toUpperCase().trim();
      final courseName = courseNamesByCode[cleanCode] ?? item.courseCode;

      // 1. If parsed sessions are present from Azure scraper, use them directly for 100% precision!
      if (item.sessions.isNotEmpty) {
        for (final s in item.sessions) {
          final day = s.day.trim();
          if (!grid.containsKey(day)) continue;

          final sFacultyRaw = s.faculty.trim().toUpperCase();
          final itemFacultyRaw = item.facultyInitial.trim().toUpperCase();

          String resolvedFaculty = 'TBA';
          if (sFacultyRaw.isNotEmpty && sFacultyRaw != 'NONE' && sFacultyRaw != 'NULL' && sFacultyRaw != 'TBA') {
            resolvedFaculty = sFacultyRaw;
          } else if (itemFacultyRaw.isNotEmpty && itemFacultyRaw != 'NONE' && itemFacultyRaw != 'NULL' && itemFacultyRaw != 'TBA') {
            resolvedFaculty = itemFacultyRaw;
          }

          final sFacName = s.facultyName.isNotEmpty ? s.facultyName : item.facultyName;
          final sFacEmail = s.facultyEmail.isNotEmpty ? s.facultyEmail : item.facultyEmail;

          grid[day]?.add({
            'courseCode': cleanCode,
            'course_code': cleanCode,
            'courseName': courseName,
            'course_name': courseName,
            'section': item.section,
            'startTime': s.startTime,
            'endTime': s.endTime,
            'time': '${s.startTime}-${s.endTime}',
            'room': s.room.isNotEmpty ? s.room : (item.room.isNotEmpty ? item.room : 'TBA'),
            'faculty': resolvedFaculty,
            'facultyName': sFacName,
            'faculty_name': sFacName,
            'facultyEmail': sFacEmail,
            'faculty_email': sFacEmail,
            'type': s.type,
          });
        }
        continue;
      }

      // 2. Fallback if sessions array was empty: parse timing string
      final timing = item.timing.trim();
      if (timing.isEmpty || timing.toUpperCase() == 'TBA') continue;

      final parts = timing.split(' ');
      if (parts.isEmpty) continue;

      final dayCodes = parts[0].trim();
      final timeRange = parts.sublist(1).join(' ').trim();
      final timeSplit = timeRange.split('-');
      if (timeSplit.length < 2) continue;

      final startStr = timeSplit[0].trim();
      final endStr = timeSplit[1].trim();
      final isLab = CourseUtils.isLab(startStr, endStr, cleanCode);

      final itemFacultyRaw = item.facultyInitial.trim().toUpperCase();
      final resolvedFaculty = (itemFacultyRaw.isNotEmpty && itemFacultyRaw != 'NONE' && itemFacultyRaw != 'NULL' && itemFacultyRaw != 'TBA')
          ? itemFacultyRaw
          : 'TBA';

      final classEntry = {
        'courseCode': cleanCode,
        'course_code': cleanCode,
        'courseName': courseName,
        'course_name': courseName,
        'section': item.section,
        'startTime': startStr,
        'endTime': endStr,
        'time': '$startStr-$endStr',
        'room': item.room.isNotEmpty ? item.room : 'TBA',
        'faculty': resolvedFaculty,
        'facultyName': item.facultyName,
        'faculty_name': item.facultyName,
        'facultyEmail': item.facultyEmail,
        'faculty_email': item.facultyEmail,
        'type': isLab ? 'Lab' : 'Theory',
      };

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

  /// Triggered from Step 5: Confirm & Sync
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
      _currentStep = PortalSyncStep.syncing;
      _syncChecklistProgress = 1;
      _errorMessage = null;
    });

    try {
      final activeSemCode = result.semesterCode.isNotEmpty
          ? CourseUtils.cleanSemester(result.semesterCode)
          : CourseUtils.cleanSemester(result.activeSemesterName);

      // 1. Fetch course names
      final portalSyncRepo = ref.read(portalSyncRepositoryProvider);
      final courseNames = await portalSyncRepo.fetchCourseNames(activeSemCode);

      // Step 1: Saving course routine
      if (mounted) setState(() => _syncChecklistProgress = 1);
      await Future.delayed(const Duration(milliseconds: 350));

      // 2. Active Semester Schedule & Enrollments (Smart Diff to protect user attendance, marks, and exceptions)
      if (_syncActiveSchedule && result.enrolledCourses.isNotEmpty) {
        final activeCourses = result.enrolledCourses.where((c) => !c.isInactive).toList();
        final weeklyGrid = _buildWeeklyGridCache(activeCourses, courseNames);

        await portalSyncRepo.syncActiveSchedule(
          userId: user.id,
          activeSemCode: activeSemCode,
          activeCourses: activeCourses,
          courseNames: courseNames,
          weeklyGrid: weeklyGrid,
        );

        try {
          final cache = ref.read(cacheServiceProvider);
          await cache.invalidateDashboardSchedule(user.id, activeSemCode);
          ref.invalidate(academicStateProvider);
          ref.invalidate(currentSemesterCodeProvider);
        } catch (_) {}
      }

      // Step 2 & 3: Updating faculty info & room details
      if (mounted) setState(() => _syncChecklistProgress = 2);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) setState(() => _syncChecklistProgress = 3);
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Academic History & Grades
      if (_syncAcademicHistory && _azureParsedGrades.isNotEmpty) {
        await portalSyncRepo.syncAcademicHistory(
          userId: user.id,
          parsedGrades: _azureParsedGrades,
        );
      }

      // Step 4: Importing academic history
      if (mounted) setState(() => _syncChecklistProgress = 4);
      await Future.delayed(const Duration(milliseconds: 300));

      // 4. Profile Metadata Update with 4-Tier Program Resolution
      if (_syncProfileMetadata) {
        await portalSyncRepo.syncProfileMetadata(
          userId: user.id,
          profile: result.profile,
        );
      } else {
        await portalSyncRepo.markOnboardingCompleted(user.id);
      }

      // Step 5: Finalizing calculations
      if (mounted) setState(() => _syncChecklistProgress = 5);
      await Future.delayed(const Duration(milliseconds: 400));

      try {
        await ref.read(onboardingRepositoryProvider).recalculateStats(activeSemCode);
      } catch (_) {}

      ref.invalidate(profileProvider);

      if (mounted) {
        setState(() {
          _currentStep = PortalSyncStep.syncComplete;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStep = PortalSyncStep.dataPreview;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: EWUmateAppBar(
        title: _currentStep == PortalSyncStep.dataPreview
            ? "EWU Portal Preview"
            : (_currentStep == PortalSyncStep.syncComplete ? "Sync Complete" : "EWU Portal Sync"),
        showBack: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentStepWidget(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case PortalSyncStep.startSync:
        return PortalSyncStartView(
          studentIdController: _studentIdCtrl,
          passwordController: _passwordCtrl,
          obscurePassword: _obscurePassword,
          onToggleObscurePassword: () => setState(() => _obscurePassword = !_obscurePassword),
          errorMessage: _errorMessage,
          onStartSync: _handleStartSync,
          availableSemesters: _availableSemesters,
          selectedSemester: _selectedSemester,
          onSelectSemester: (sem) => setState(() => _selectedSemester = sem),
          rememberCredentials: _rememberCredentials,
          onToggleRememberCredentials: (val) => setState(() => _rememberCredentials = val),
        );

      case PortalSyncStep.connecting:
        return PortalSyncConnectingView(
          pulseController: _pulseCtrl,
          fetchChecklistProgress: _fetchChecklistProgress,
        );

      case PortalSyncStep.syncReady:
        return PortalSyncReadyView(
          onViewPreview: () => setState(() => _currentStep = PortalSyncStep.dataPreview),
        );

      case PortalSyncStep.dataPreview:
        final result = _portalData;
        if (result == null) return const SizedBox.shrink();
        return PortalSyncPreviewView(
          result: result,
          syncActiveSchedule: _syncActiveSchedule,
          onToggleSyncActiveSchedule: (val) => setState(() => _syncActiveSchedule = val),
          syncAcademicHistory: _syncAcademicHistory,
          onToggleSyncAcademicHistory: (val) => setState(() => _syncAcademicHistory = val),
          azureParsedGradesCount: _azureParsedGrades.length,
          onConfirmAndSync: _applySync,
          onBack: () => setState(() => _currentStep = PortalSyncStep.startSync),
        );

      case PortalSyncStep.syncing:
        return PortalSyncSyncingView(
          rotationAnimation: _rotationCtrl,
          syncChecklistProgress: _syncChecklistProgress,
        );

      case PortalSyncStep.syncComplete:
        return PortalSyncCompleteView(
          coursesCount: _portalData?.enrolledCourses.length ?? 0,
          onGoToDashboard: () => context.go('/dashboard'),
          onSyncAgain: () => setState(() => _currentStep = PortalSyncStep.startSync),
          wasOnboarding: _wasOnboarding,
        );
    }
  }
}
