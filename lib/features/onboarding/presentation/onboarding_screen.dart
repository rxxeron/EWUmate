import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/profile.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/error_utils.dart';

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

  final List<String> _programs = [
    'BSc in CSE',
    'BPharm',
    'LLB',
    'BBA',
  ]; // Dummy data
  final List<String> _tracks = ['bi_semester', 'tri_semester'];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID (e.g. 2021-1-00-000)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Program',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedProgramCode,
              items: _programs.map((program) {
                return DropdownMenuItem(value: program, child: Text(program));
              }).toList(),
              onChanged: (val) => setState(() => _selectedProgramCode = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Academic Track',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedTrack,
              items: _tracks.map((track) {
                return DropdownMenuItem(value: track, child: Text(track));
              }).toList(),
              onChanged: (val) => setState(() => _selectedTrack = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Finish Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
