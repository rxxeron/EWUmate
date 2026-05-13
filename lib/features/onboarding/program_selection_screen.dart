import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_repository.dart';
import '../auth/auth_providers.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/onboarding_overlay.dart';
import '../../core/utils/error_utils.dart';

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
      // removing appBar title, making it custom header in body
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.school_rounded,
                      size: 80, color: Colors.cyanAccent),
                  const SizedBox(height: 24),
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
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Let's get your profile set up.\nPlease select your department and program to personalize your experience.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Dept Dropdown
                  GlassContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 12,
                    color: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                            _selectedDeptName), // Ensure rebuild on change
                        decoration: const InputDecoration(
                          labelText: "Department",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.business_rounded,
                              color: Colors.cyanAccent),
                        ),
                        dropdownColor: const Color(0xFF1e1e1e),
                        style: const TextStyle(color: Colors.white),
                        // value: deprecated, using initialValue
                        value: _selectedDeptName,
                        items: _departments.map((dept) {
                          final name = dept['name'] as String;
                          return DropdownMenuItem(
                              value: name, child: Text(name));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDeptName = val;
                            _selectedProgramId = null; // Reset program
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Program Dropdown
                  GlassContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 12,
                    color: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                            "$_selectedDeptName-$_selectedProgramId"), // Ensure rebuild
                        decoration: const InputDecoration(
                          labelText: "Degree Program",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.school_rounded,
                              color: Colors.cyanAccent),
                        ),
                        dropdownColor: const Color(0xFF1e1e1e),
                        style: const TextStyle(color: Colors.white),
                        value: _selectedProgramId,
                        disabledHint: const Text("Select Department First",
                            style: TextStyle(color: Colors.white38)),
                        items: _selectedDeptName == null
                            ? []
                            : List<Map<String, dynamic>>.from(
                                    (_departments.where((d) =>
                                            d['name'] ==
                                            _selectedDeptName).firstOrNull?['programs'] as List?) ??
                                        [])
                                .map((prog) => DropdownMenuItem(
                                    value: prog['id'] as String,
                                      child: Text(prog['title'] as String)))
                                .toList(),
                        onChanged: _selectedDeptName == null
                            ? null
                            : (val) {
                                setState(() => _selectedProgramId = val);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Semester Dropdown
                  GlassContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 12,
                    color: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedAdmittedSemester),
                        decoration: const InputDecoration(
                          labelText: "Admitted Semester",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.calendar_today_rounded,
                              color: Colors.cyanAccent),
                        ),
                        dropdownColor: const Color(0xFF1e1e1e),
                        style: const TextStyle(color: Colors.white),
                        value: _selectedAdmittedSemester,
                        items: _semesters.where((sem) {
                          if (_selectedDeptName == null) return true;
                          final dept = _departments.where((d) => d['name'] == _selectedDeptName).firstOrNull;
                          if (dept != null && dept['track'] == 'bi_semester') {
                            return !sem.contains("Summer");
                          }
                          return true;
                        }).map((sem) {
                          return DropdownMenuItem(value: sem, child: Text(sem));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedAdmittedSemester = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  GlassContainer(
                    onTap: (_selectedProgramId == null ||
                            _selectedAdmittedSemester == null ||
                            _saving)
                        ? null
                        : _saveAndContinue,
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    borderColor: Colors.cyanAccent,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saving)
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.cyanAccent))
                        else
                          const Icon(Icons.arrow_forward,
                              color: Colors.cyanAccent),
                        const SizedBox(width: 8),
                        const Text("Continue to Course History",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
