import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/progress_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/models/profile.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/refresh_utils.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          ref.invalidate(profileRepositoryProvider);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.profileKey,
          steps: OnboardingSteps.profile,
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavyBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out from EWUmate?',
          style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.sora(color: AppColors.secondaryText)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sign Out', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(cacheServiceProvider).clearAll();
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  String _formatSemester(String? semester) {
    if (semester == null || semester.isEmpty) return "Unknown";
    return semester
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _editField(
    String title,
    String currentValue,
    Future<void> Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavyBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Edit $title',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter new $title',
            hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.sora(color: AppColors.secondaryText)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newValue != null &&
        newValue.isNotEmpty &&
        newValue != currentValue &&
        mounted) {
      try {
        await onSave(newValue);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title updated successfully!', style: GoogleFonts.sora()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editPassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceNavyBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Change Password',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<UserIdentity>>(
                    future: Supabase.instance.client.auth.getUserIdentities(),
                    builder: (context, snapshot) {
                      final hasPassword = snapshot.data?.any((id) => id.provider == 'email') ?? true;
                      
                      return Column(
                        children: [
                          if (hasPassword) ...[
                            TextFormField(
                              controller: currentController,
                              obscureText: obscureCurrent,
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                                filled: true,
                                fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primaryCyan),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.secondaryText,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setState(() => obscureCurrent = !obscureCurrent),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: newController,
                            obscureText: obscureNew,
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: hasPassword ? 'New Password' : 'Set Password',
                              labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryCyan),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.secondaryText,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => obscureNew = !obscureNew),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.length < 6 ? 'Min 6 chars' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmController,
                            obscureText: obscureConfirm,
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryCyan),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.secondaryText,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => obscureConfirm = !obscureConfirm),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (val != newController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.sora(color: AppColors.secondaryText)),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;
                  
                  if (user?.email == null) return;

                  final identities = await supabase.auth.getUserIdentities();
                  final hasPassword = identities.any((id) => id.provider == 'email');

                  if (hasPassword) {
                    try {
                      await supabase.auth.signInWithPassword(
                        email: user!.email!,
                        password: currentController.text,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Current password incorrect.', style: GoogleFonts.sora()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                      return;
                    }
                  }

                  try {
                    await Supabase.instance.client.auth.updateUser(
                      UserAttributes(password: newController.text),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password updated successfully!', style: GoogleFonts.sora()),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: AppColors.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(Profile profile) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 800,
      );
      
      if (xFile == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updating profile picture...', style: GoogleFonts.sora()),
            backgroundColor: AppColors.secondarySoftBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final file = File(xFile.path);
      final fileExt = xFile.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar.$fileExt';

      await Supabase.instance.client.storage
          .from('profile_images')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '0', upsert: true),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('profile_images')
          .getPublicUrl(fileName);

      final timestampedUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await ref
          .read(profileRepositoryProvider)
          .updateProfile(profile.copyWith(photoUrl: timestampedUrl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated!', style: GoogleFonts.sora()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProfileImage] Upload Error: $e');
      if (mounted) {
        String errorMsg = AuthErrorUtils.getFriendlyMessage(e);
        if (errorMsg.contains('403') || errorMsg.contains('Permission denied')) {
          errorMsg = 'Permission denied. Please contact admin to check Storage RLS.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: GoogleFonts.sora()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    if (userId == null) {
      return FullGradientScaffold(
        body: Center(
          child: Text('User not found.', style: GoogleFonts.sora(color: Colors.white)),
        ),
      );
    }

    final profileStream = ref
        .watch(profileRepositoryProvider)
        .streamProfile(userId);
    final semesterSummariesAsync = ref.watch(allSemesterSummariesProvider);

    int coursesDone = 0;
    if (semesterSummariesAsync is AsyncData) {
      for (final summary in semesterSummariesAsync.value ?? []) {
        coursesDone += (summary.courses.length as int);
      }
    }

    return FullGradientScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            RefreshUtils.refreshAcademicData(ref);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primaryCyan,
          backgroundColor: AppColors.surfaceNavyBlue,
          child: StreamBuilder<Profile?>(
            stream: profileStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryCyan),
                );
              }

              final profile = snapshot.data;
              if (profile == null) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 500,
                    child: Center(
                      child: Text(
                        'Profile not found.',
                        style: GoogleFonts.sora(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Profile',
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Header Avatar & Identity
                    _buildHeader(profile, user?.email),
                    const SizedBox(height: 24),

                    // 4-Stats Grid
                    _buildStatsGrid(profile, coursesDone),
                    const SizedBox(height: 28),

                    // Section: Personal Info
                    _buildSectionTitle('Personal Info'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.person_outline_rounded,
                      'Full Name',
                      profile.fullName ?? 'Not Set',
                      onTap: () => _editField(
                        'Full Name',
                        profile.fullName ?? '',
                        (val) => ref
                            .read(profileRepositoryProvider)
                            .updateProfile(profile.copyWith(fullName: val)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      Icons.face_rounded,
                      'Nickname',
                      profile.nickname ?? 'Not Set',
                      onTap: () => _editField(
                        'Nickname',
                        profile.nickname ?? '',
                        (val) => ref
                            .read(profileRepositoryProvider)
                            .updateProfile(profile.copyWith(nickname: val)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      Icons.badge_outlined,
                      'Student ID',
                      profile.studentId ?? 'Not Set',
                      onTap: () => _editField(
                        'Student ID',
                        profile.studentId ?? '',
                        (val) => ref
                            .read(profileRepositoryProvider)
                            .updateProfile(profile.copyWith(studentId: val)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section: Preferences
                    _buildSectionTitle('Preferences'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      Icons.notifications_active_outlined,
                      'Class Reminder Settings',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondaryText,
                      ),
                      onTap: () => context.push('/notifications/settings'),
                    ),
                    const SizedBox(height: 28),

                    // Section: Security
                    _buildSectionTitle('Security'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      Icons.lock_outline_rounded,
                      'Change Password',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondaryText,
                      ),
                      onTap: _editPassword,
                    ),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      Icons.logout_rounded,
                      'Sign Out',
                      onTap: _logout,
                      isDestructive: true,
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Profile profile, String? email) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Glowing Avatar Ring
            Container(
              width: 106,
              height: 106,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceNavyBlue,
                ),
                clipBehavior: Clip.antiAlias,
                child: profile.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: profile.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: AppColors.secondaryText,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: AppColors.secondaryText,
                      ),
              ),
            ),
            // Camera Edit Button
            GestureDetector(
              onTap: () => _uploadProfileImage(profile),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryNavy, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primaryNavy,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.fullName ?? 'Not set',
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email ?? 'No email',
          style: GoogleFonts.sora(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.primaryCyan.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            'Started: ${_formatSemester(profile.admittedSemester)} • ${(profile.track ?? 'tri_semester').replaceAll('_', ' ').toUpperCase()}',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryCyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Profile profile, int coursesDone) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 96,
      ),
      children: [
        _buildStatCard(
          Icons.star_rounded,
          profile.cgpa?.toStringAsFixed(2) ?? '0.00',
          'CGPA',
          color: AppColors.warning,
        ),
        _buildStatCard(
          Icons.school_rounded,
          profile.totalCreditsEarned?.toStringAsFixed(1) ?? '0.0',
          'Credits',
          color: AppColors.primaryCyan,
        ),
        _buildStatCard(
          Icons.check_circle_rounded,
          coursesDone.toString(),
          'Completed',
          color: AppColors.success,
        ),
        _buildStatCard(
          Icons.menu_book_rounded,
          profile.enrolledCredits.toStringAsFixed(1),
          'Now',
          color: AppColors.secondarySoftBlue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label, {
    Color color = AppColors.primaryCyan,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 10,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryCyan,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceNavyBlue.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: AppColors.primaryCyan, size: 19),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit_rounded,
                  color: AppColors.secondaryText.withValues(alpha: 0.6),
                  size: 17,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.surfaceNavyBlue.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primaryCyan,
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : Colors.white,
                  ),
                ),
              ),
              trailing ?? const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}

