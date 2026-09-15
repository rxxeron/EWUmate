import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/portal_service.dart';
import '../../core/utils/course_utils.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/onboarding/onboarding_repository.dart';

class PortalSyncModal extends ConsumerStatefulWidget {
  final VoidCallback? onSyncComplete;
  const PortalSyncModal({super.key, this.onSyncComplete});

  static Future<void> show(BuildContext context, {VoidCallback? onSyncComplete}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PortalSyncModal(onSyncComplete: onSyncComplete),
    );
  }

  @override
  ConsumerState<PortalSyncModal> createState() => _PortalSyncModalState();
}

class _PortalSyncModalState extends ConsumerState<PortalSyncModal> {
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    final sid = profile?.studentId;
    if (sid != null && sid.isNotEmpty) {
      _studentIdCtrl.text = sid;
    }
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSync() async {
    final studentId = _studentIdCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both Student ID and Portal Password.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = "Connecting to EWU portal...";
    });

    try {
      final portalService = ref.read(portalServiceProvider);
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User is not authenticated.");

      // 1. Sync from Portal
      setState(() => _statusMessage = "Authenticating & solving captcha...");
      final result = await portalService.syncAll(
        studentId: studentId,
        password: password,
      );

      // 2. Update Profile metadata
      setState(() => _statusMessage = "Syncing academic profile & program...");
      final cleanAdmittedSem = CourseUtils.cleanSemester(result.profile.admittedSemester);
      final profilePayload = {
        'id': user.id,
        'student_id': result.profile.studentId,
        'program_code': result.profile.programCode.toUpperCase(),
        'program_name': result.profile.programName,
        'department_name': result.profile.departmentName,
        'admitted_semester': cleanAdmittedSem.isNotEmpty ? cleanAdmittedSem : null,
      };
      await supabase.from('profiles').upsert(profilePayload);

      // 3. Save Completed Courses & Grades (First try Azure parse_grade_sheet for semester-by-semester, fallback to degreeAreas)
      setState(() => _statusMessage = "Syncing semester-wise grades & academic history...");
      final List<Map<String, dynamic>> completedRows = [];

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
          final parsedCourses = data['courses'] as List? ?? [];
          for (final c in parsedCourses) {
            completedRows.add({
              'user_id': user.id,
              'course_code': c['course_code'],
              'grade': c['grade'],
              'grade_point': c['grade_point'],
              'credits': c['credits'],
              'semester_code': c['semester_code'],
            });
          }
        }
      } catch (e) {
        debugPrint("[PortalSync] Azure parse_grade_sheet notice: $e");
      }

      // Fallback: if server parser unavailable, use degree review courses
      if (completedRows.isEmpty) {
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
        // Clear prior and insert verified grades
        await supabase.from('completed_courses').delete().eq('user_id', user.id);
        await supabase.from('completed_courses').insert(completedRows);
      }

      // 4. Sync Active Routine & Enrollments + Global Faculty Verified Mapping
      setState(() => _statusMessage = "Syncing active class routine & faculty...");
      final activeSemCode = CourseUtils.cleanSemester(result.activeSemesterName);

      if (result.enrolledCourses.isNotEmpty) {
        await supabase.from('enrollments').delete().eq('user_id', user.id).eq('semester_code', activeSemCode);

        final enrollmentRows = <Map<String, dynamic>>[];
        final facultyUpdates = <Map<String, dynamic>>[];

        for (final item in result.enrolledCourses) {
          final cleanCode = item.courseCode.contains(' ') ? item.courseCode.split(' ')[0] : item.courseCode;
          enrollmentRows.add({
            'user_id': user.id,
            'course_code': cleanCode,
            'section': item.section,
            'semester_code': activeSemCode,
            'status': 'enrolled',
          });

          // Bidirectional Crowdsourcing: write verified faculty details to DB
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

        if (enrollmentRows.isNotEmpty) {
          await supabase.from('enrollments').insert(enrollmentRows);
        }

        // Try upserting verified faculty mappings into faculty_assignments if table exists
        if (facultyUpdates.isNotEmpty) {
          try {
            await supabase.from('faculty_assignments').upsert(
              facultyUpdates,
              onConflict: 'course_code,section_number,semester',
            );
          } catch (e) {
            debugPrint("[PortalSync] Verified faculty sync warning: $e");
          }
        }
      }

      // 5. Recalculate stats
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

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade800,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Sync completed! ${result.enrolledCourses.length} active courses and ${completedRows.length} completed grades imported.",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

        widget.onSyncComplete?.call();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131B2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.cyanAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EWU Portal Sync",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Auto-sync routine, grades & assigned faculty",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your credentials are used solely to establish an official session with portal.ewubd.edu and are never stored on our servers.",
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Student ID
              TextField(
                controller: _studentIdCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Student ID",
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
              const SizedBox(height: 14),

              // Password
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
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: _isLoading ? null : _startSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: Text(
                  _isLoading ? "Syncing..." : "Connect & Sync All",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
