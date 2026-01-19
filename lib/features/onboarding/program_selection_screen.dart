import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_repository.dart';
import '../../core/widgets/glass_kit.dart';

class ProgramSelectionScreen extends StatefulWidget {
  const ProgramSelectionScreen({super.key});

  @override
  State<ProgramSelectionScreen> createState() => _ProgramSelectionScreenState();
}

class _ProgramSelectionScreenState extends State<ProgramSelectionScreen> {
  final OnboardingRepository _repo = OnboardingRepository();
  List<Map<String, dynamic>> _departments = [];
  String? _selectedProgramId;
  String? _selectedDeptName;
  String? _selectedAdmittedSemester;
  bool _loading = true;
  bool _saving = false;

  final List<String> _semesters = [
    "Spring 2023",
    "Summer 2023",
    "Fall 2023",
    "Spring 2024",
    "Summer 2024",
    "Fall 2024",
    "Spring 2025",
    "Summer 2025",
    "Fall 2025",
    "Spring 2026",
    "Summer 2026",
    "Fall 2026"
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final depts = await _repo.fetchDepartments();
    if (mounted) {
      setState(() {
        _departments = depts;
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
      await _repo.saveProgram(
          _selectedProgramId!, _selectedDeptName!, _selectedAdmittedSemester!);
      if (mounted) context.push('/onboarding/course-history');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save selection")));
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
                  const Icon(Icons.account_balance_rounded,
                      size: 64, color: Colors.cyanAccent),
                  const SizedBox(height: 24),
                  const Text(
                    "Academic Profile",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please select your department and program to personalize your experience.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
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
                        decoration: const InputDecoration(
                          labelText: "Department",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.business_rounded,
                              color: Colors.cyanAccent),
                        ),
                        dropdownColor: const Color(0xFF1e1e1e),
                        style: const TextStyle(color: Colors.white),
                        initialValue: _selectedDeptName,
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
                        decoration: const InputDecoration(
                          labelText: "Degree Program",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.school_rounded,
                              color: Colors.cyanAccent),
                        ),
                        dropdownColor: const Color(0xFF1e1e1e),
                        style: const TextStyle(color: Colors.white),
                        initialValue: _selectedProgramId,
                        disabledHint: const Text("Select Department First",
                            style: TextStyle(color: Colors.white38)),
                        items: _selectedDeptName == null
                            ? []
                            : List<Map<String, dynamic>>.from(
                                    _departments.firstWhere((d) =>
                                            d['name'] ==
                                            _selectedDeptName)['programs'] ??
                                        [])
                                .map((prog) => DropdownMenuItem(
                                    value: prog['id'] as String,
                                    child: Text(prog['name'] as String)))
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
                        decoration: const InputDecoration(
                          labelText: "Admitted Semester",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.calendar_today_rounded,
                              color: Colors.cyanAccent),
                        ),
                        dropdownColor: const Color(0xFF1e1e1e),
                        style: const TextStyle(color: Colors.white),
                        initialValue: _selectedAdmittedSemester,
                        items: _semesters.map((sem) {
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
