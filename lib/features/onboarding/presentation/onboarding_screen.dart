import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/profile.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/utils/error_utils.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _studentIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();

  String? _selectedProgramCode;
  String? _selectedTrack;
  bool _isLoading = false;

  List<Map<String, dynamic>> _programOptions = [];

  final List<String> _tracks = ['bi_semester', 'tri_semester'];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final res = await Supabase.instance.client
          .from('programs')
          .select('program_code, name, track, department_name')
          .order('name');
      final list = List<Map<String, dynamic>>.from(res as List);
      if (mounted) {
        setState(() {
          _programOptions = list;
        });
      }
    } catch (e) {
      debugPrint('[OnboardingScreen] Error loading programs: $e');
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _fullNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (_selectedProgramCode == null ||
        _selectedTrack == null ||
        _studentIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newProfile = Profile(
        id: user.id,
        studentId: _studentIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        programCode: _selectedProgramCode,
        track: _selectedTrack,
        onboardingStatus: 'completed',
        updatedAt: DateTime.now(),
      );

      await ref.read(profileRepositoryProvider).updateProfile(newProfile);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
              Text(
                'Complete Your Profile',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Help us customize EWUmate for your degree & schedule',
                style: GoogleFonts.sora(fontSize: 14, color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Quick 1-Click Setup Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF19D9F5).withValues(alpha: 0.15),
                      const Color(0xFF0F325E).withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF19D9F5).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Color(0xFF19D9F5), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "⚡ Fast Setup with Portal Sync",
                                style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Import routine, courses & grades instantly",
                                style: GoogleFonts.sora(
                                  fontSize: 11.5,
                                  color: const Color(0xFF19D9F5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Skip manual form filling! Connect directly to your EWU student portal to auto-fill your profile, active schedule, and completed courses in seconds.",
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/portal-sync'),
                        icon: const Icon(Icons.sync_rounded, color: Color(0xFF04101E), size: 18),
                        label: Text(
                          "Auto-Setup from Portal",
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF04101E),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF19D9F5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR FILL MANUALLY",
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 20),

              _buildInputField(
                controller: _studentIdController,
                label: 'Student ID',
                hint: 'e.g. 2021-1-00-000',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'e.g. Md. Hasan',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _nicknameController,
                label: 'Nickname (Optional)',
                hint: 'e.g. Hasan',
                icon: Icons.face_outlined,
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Program',
                icon: Icons.menu_book_rounded,
                value: _selectedProgramCode,
                items: _programOptions.isNotEmpty
                    ? _programOptions.map((p) => p['program_code'].toString()).toList()
                    : ['CSE', 'PHRM', 'LLB', 'BBA'],
                itemLabel: (code) {
                  final match = _programOptions.firstWhere(
                    (p) => p['program_code'] == code,
                    orElse: () => {'name': code},
                  );
                  return match['name'] ?? code;
                },
                onChanged: (val) {
                  setState(() {
                    _selectedProgramCode = val;
                    if (val != null && _programOptions.isNotEmpty) {
                      final match = _programOptions.firstWhere(
                        (p) => p['program_code'] == val,
                        orElse: () => {},
                      );
                      if (match.isNotEmpty && match['track'] != null) {
                        _selectedTrack = match['track'].toString();
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Academic Track',
                icon: Icons.timeline_rounded,
                value: _selectedTrack,
                items: _tracks,
                itemLabel: (t) => t == 'bi_semester' ? 'Bi-Semester (Pharmacy/Law)' : 'Tri-Semester (Standard)',
                onChanged: (val) => setState(() => _selectedTrack = val),
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF04101E)),
                        )
                      : Text(
                          'Finish Setup',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF04101E),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
          hintText: hint,
          hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.primaryCyan, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String Function(String) itemLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0D2342),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryCyan),
          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primaryCyan, size: 20),
            border: InputBorder.none,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(itemLabel(item), style: GoogleFonts.sora(color: Colors.white, fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

