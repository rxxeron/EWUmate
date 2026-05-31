import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/services/storage_service.dart';
import '../onboarding_repository.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/utils/error_utils.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nickController = TextEditingController();
  final _idController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      // Attempt online fetch since handle_new_user trigger already created the profile row
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null && mounted) {
        setState(() {
          _nameController.text = profileData['full_name'] ?? user.userMetadata?['full_name'] ?? '';
          _nickController.text = profileData['nickname'] ?? user.userMetadata?['nickname'] ?? '';
          _idController.text = profileData['student_id'] ?? user.userMetadata?['studentId'] ?? '';
        });
      } else {
        // Fallback to metadata
        _nameController.text = user.userMetadata?['full_name'] ?? '';
        _nickController.text = user.userMetadata?['nickname'] ?? '';
        _idController.text = user.userMetadata?['studentId'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nickController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Session expired");

      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _storageService.uploadProfileImage(_imageFile!, user.id);
      }

      await ref.read(onboardingRepositoryProvider).saveProfileDetails(
            fullName: _nameController.text.trim(),
            nickname: _nickController.text.trim(),
            studentId: _idController.text.trim(),
            photoUrl: photoUrl,
          );
      
      if (mounted) {
        context.go('/onboarding/program');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorUtils.getFriendlyMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white10,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : null,
                        child: _imageFile == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white70)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.cyanAccent,
                          radius: 18,
                          child: IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.black),
                            onPressed: _pickImage,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Complete Your Profile",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "We need a few more details to personalize your EWUmate experience.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                
                _buildTextField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                  hint: "John Doe",
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: _nickController,
                  label: "Nickname",
                  icon: Icons.badge_outlined,
                  hint: "John",
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: _idController,
                  label: "Student ID",
                  icon: Icons.perm_identity_rounded,
                  hint: "2023-1-10-001",
                  keyboardType: TextInputType.text,
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 48),
                
                GlassContainer(
                  onTap: _isSaving ? null : _saveAndContinue,
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  borderColor: Colors.cyanAccent,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.cyanAccent,
                          ),
                        )
                      else
                        const Icon(Icons.check_circle_outline, color: Colors.cyanAccent),
                      const SizedBox(width: 12),
                      const Text(
                        "Save and Continue",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 12,
      color: Colors.white.withValues(alpha: 0.05),
      borderColor: Colors.white.withValues(alpha: 0.2),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
