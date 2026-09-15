import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/services/storage_service.dart';
import '../onboarding_repository.dart';
import '../../../core/theme/app_colors.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryCyan.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: CircleAvatar(
                            backgroundColor: AppColors.primaryNavy,
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : null,
                            child: _imageBytes == null && _imageFile == null
                                ? const Icon(Icons.person,
                                    size: 52, color: AppColors.secondaryText)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 18, color: Color(0xFF04101E)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Complete Your Profile",
                  style: GoogleFonts.sora(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "We need a few more details to personalize your EWUmate experience.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(fontSize: 14, color: AppColors.secondaryText),
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
                        "Skip manual form filling! Log in with your EWU student portal to auto-fill your profile, active routine, and academic record in 1 click.",
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
                
                _buildTextField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                  hint: "John Doe",
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _nickController,
                  label: "Nickname",
                  icon: Icons.badge_outlined,
                  hint: "John",
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _idController,
                  label: "Student ID",
                  icon: Icons.perm_identity_rounded,
                  hint: "2023-1-10-001",
                  keyboardType: TextInputType.text,
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 36),
                
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
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF04101E),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF04101E), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Save and Continue",
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF04101E),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
          hintText: hint,
          hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 13),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.primaryCyan, size: 20),
        ),
      ),
    );
  }
}
