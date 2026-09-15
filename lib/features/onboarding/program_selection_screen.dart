import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_repository.dart';
import '../auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/onboarding_overlay.dart';

class ProgramSelectionScreen extends ConsumerStatefulWidget {
  const ProgramSelectionScreen({super.key});

  @override
  ConsumerState<ProgramSelectionScreen> createState() => _ProgramSelectionScreenState();
}

class _ProgramSelectionScreenState extends ConsumerState<ProgramSelectionScreen> {
  static bool _welcomeShown = false;
  List<Map<String, dynamic>> _departments = [];
  String? _selectedProgramId;
  String? _selectedDeptName;
  String? _selectedAdmittedSemester;
  bool _loading = true;
  bool _saving = false;

  List<String> _semesters = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _showWelcomeOnboarding();
  }

  void _showWelcomeOnboarding() {
    if (_welcomeShown) return;
    _welcomeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingOverlay.show(
        context: context,
        featureKey: 'welcome_flow',
        steps: [
          const OnboardingStep(
            title: "Welcome to EWUmate!",
            description: "Your all-in-one assistant for academic success at East West University. Let's get you set up!",
            icon: Icons.auto_awesome,
          ),
          const OnboardingStep(
            title: "Personalized Profile",
            description: "First, we need to know your program and batch to provide you with the correct course catalogs and schedules.",
            icon: Icons.school,
          ),
          const OnboardingStep(
            title: "Course History",
            description: "Next, you can import your completed courses to get better advising suggestions and CGPA projections.",
            icon: Icons.history_edu,
          ),
        ],
      );
    });
  }

  Future<void> _loadDepartments() async {
    final repo = ref.read(onboardingRepositoryProvider);
    final results = await Future.wait([
      repo.fetchDepartments(),
      repo.fetchSemesters(),
      repo.fetchUserProfile(),
      repo.getActiveSemesterConfig(),
    ]);

    if (mounted) {
      setState(() {
        _departments = results[0] as List<Map<String, dynamic>>;
        _semesters = results[1] as List<String>;
        
        final profile = results[2] as Map<String, dynamic>;
        final config = results[3] as Map<String, dynamic>;
        final runningSem = config['current_semester_code']?.toString();

        _selectedAdmittedSemester = profile['admitted_semester']?.toString();
        _selectedDeptName = profile['department_name']?.toString();
        _selectedProgramId = profile['program_code']?.toString();

        // Safety: Ensure _selectedAdmittedSemester exists in _semesters to avoid Dropdown crash
        if (_selectedAdmittedSemester != null && !_semesters.contains(_selectedAdmittedSemester)) {
          _semesters.insert(0, _selectedAdmittedSemester!);
        }
        
        // Also ensure running semester is available
        if (runningSem != null && !_semesters.contains(runningSem)) {
          _semesters.insert(0, runningSem);
        }

        _loading = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_selectedProgramId == null ||
        _selectedAdmittedSemester == null ||
        _selectedDeptName == null) {
      return;
    }

    setState(() => _saving = true);

    try {
      final dept = _departments.where((d) => d['name'] == _selectedDeptName).firstOrNull;
      if (dept == null) throw Exception("Selected department not found");
      
      final programList = dept['programs'] as List<dynamic>? ?? [];
      final program = programList.where((p) => p['id'] == _selectedProgramId).firstOrNull;
      final programName = program?['name'] ?? _selectedProgramId!;
      
      final semType = dept['track'] ?? 'tri_semester';

      await ref.read(onboardingRepositoryProvider).saveProgram(
          _selectedProgramId!, programName, _selectedDeptName!, _selectedAdmittedSemester!, semType);
      if (mounted) {
        setState(() => _saving = false);
        context.push('/onboarding/course-history', extra: {
          'isEditMode': false,
          'admittedSemester': _selectedAdmittedSemester,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.school_rounded, color: AppColors.primaryCyan, size: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer(
                    builder: (context, ref, child) {
                      final profile = ref.watch(profileProvider).value;
                      final user = Supabase.instance.client.auth.currentUser;
                      final metadata = user?.userMetadata;
                      final name = profile?.nickname ?? 
                                   metadata?['full_name']?.toString().split(' ').first ?? 
                                   metadata?['name']?.toString().split(' ').first ?? 
                                   metadata?['displayName']?.toString().split(' ').first ?? 
                                   profile?.fullName?.split(' ').first ??
                                   'Student';
                      return Text(
                        "$name, welcome to EWUmate!",
                        style: GoogleFonts.sora(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose how you would like to set up your profile:",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(fontSize: 14, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 28),

                  // Option A: Fast-track Portal Sync
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceNavyBlue,
                          const Color(0xFF0C2B54).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryCyan, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Option 1: Sync with Portal",
                                    style: GoogleFonts.sora(
                                      color: AppColors.primaryCyan,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Recommended • 1-Click Instant Setup",
                                    style: GoogleFonts.sora(color: AppColors.secondarySoftBlue, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Instantly import your Department, Program, Admitted Semester, Active Routine, Faculty & Degree Progress in 5 seconds.",
                          style: GoogleFonts.sora(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/portal-sync');
                            },
                            icon: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF04101E)),
                            label: Text(
                              "Connect EWU Portal",
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF04101E),
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceNavyBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            "OR OPTION 2: MANUAL SETUP",
                            style: GoogleFonts.sora(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dept Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedDeptName),
                        decoration: InputDecoration(
                          labelText: "Department",
                          labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.business_rounded, color: AppColors.primaryCyan, size: 20),
                        ),
                        dropdownColor: const Color(0xFF0D2342),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan),
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                        initialValue: _selectedDeptName,
                        items: _departments.map((dept) {
                          final name = dept['name'] as String;
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name, style: GoogleFonts.sora(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDeptName = val;
                            _selectedProgramId = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Program Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey("$_selectedDeptName-$_selectedProgramId"),
                        decoration: InputDecoration(
                          labelText: "Degree Program",
                          labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.school_rounded, color: AppColors.primaryCyan, size: 20),
                        ),
                        dropdownColor: const Color(0xFF0D2342),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan),
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                        initialValue: _selectedProgramId,
                        disabledHint: Text(
                          "Select Department First",
                          style: GoogleFonts.sora(color: Colors.white38, fontSize: 13),
                        ),
                        items: _selectedDeptName == null
                            ? []
                            : List<Map<String, dynamic>>.from(
                                    (_departments.where((d) =>
                                            d['name'] ==
                                            _selectedDeptName).firstOrNull?['programs'] as List?) ??
                                        [])
                                .map((prog) => DropdownMenuItem(
                                    value: prog['id'] as String,
                                    child: Text(
                                      prog['title'] as String,
                                      style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                    )))
                                .toList(),
                        onChanged: _selectedDeptName == null
                            ? null
                            : (val) {
                                setState(() => _selectedProgramId = val);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Semester Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedAdmittedSemester),
                        decoration: InputDecoration(
                          labelText: "Admitted Semester",
                          labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryCyan, size: 20),
                        ),
                        dropdownColor: const Color(0xFF0D2342),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan),
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                        initialValue: _selectedAdmittedSemester,
                        items: _semesters.where((sem) {
                          if (_selectedDeptName == null) return true;
                          final dept = _departments.where((d) => d['name'] == _selectedDeptName).firstOrNull;
                          if (dept != null && dept['track'] == 'bi_semester') {
                            return !sem.contains("Summer");
                          }
                          return true;
                        }).map((sem) {
                          return DropdownMenuItem(
                            value: sem,
                            child: Text(sem, style: GoogleFonts.sora(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedAdmittedSemester = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: (_selectedProgramId == null ||
                              _selectedAdmittedSemester == null ||
                              _saving)
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                            ),
                      color: (_selectedProgramId == null ||
                              _selectedAdmittedSemester == null ||
                              _saving)
                          ? AppColors.surfaceNavyBlue.withValues(alpha: 0.5)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: (_selectedProgramId != null &&
                              _selectedAdmittedSemester != null &&
                              !_saving)
                          ? [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: (_selectedProgramId == null ||
                              _selectedAdmittedSemester == null ||
                              _saving)
                          ? null
                          : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF04101E),
                              ),
                            )
                          else ...[
                            Text(
                              "Continue to Course History",
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w800,
                                color: (_selectedProgramId == null || _selectedAdmittedSemester == null)
                                    ? Colors.white38
                                    : const Color(0xFF04101E),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: (_selectedProgramId == null || _selectedAdmittedSemester == null)
                                  ? Colors.white38
                                  : const Color(0xFF04101E),
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
