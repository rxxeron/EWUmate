import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/profile_repository.dart';
import '../../../core/repositories/progress_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/models/profile.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/refresh_utils.dart';

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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
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
        backgroundColor: const Color(0xFF1E2836),
        title: Text('Edit $title', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new $title',
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Save'),
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
          setState(() {}); // Force UI refresh
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AuthErrorUtils.getFriendlyMessage(e)),
              backgroundColor: Colors.redAccent,
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
          backgroundColor: const Color(0xFF1E2836),
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only show current password field if user has an email identity
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
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.cyan),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrent
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
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
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: hasPassword ? 'New Password' : 'Set Password',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.cyan),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
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
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.cyan),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
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
                    }
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;
                  
                  if (user?.email == null) return;

                  // 1. Check if we need to re-authenticate (only if they have a password already)
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
                          const SnackBar(
                            content: Text('Current password incorrect.'),
                            backgroundColor: Colors.redAccent,
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
                        const SnackBar(
                          content: Text('Password updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AuthErrorUtils.getFriendlyMessage(e)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.cyan),
              child: const Text('Save'),
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
        imageQuality: 60, // Slightly lower quality to ensure small file size
        maxWidth: 800,    // Limit dimensions to avoid massive files
      );
      
      if (xFile == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updating profile picture...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final file = File(xFile.path);
      // Fixed filename to prevent storage bloat (one avatar per user)
      final fileExt = xFile.path.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar.$fileExt';

      // 1. Upload to Storage
      await Supabase.instance.client.storage
          .from('profile_images')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '0', upsert: true),
          );

      // 2. Get Public URL
      final imageUrl = Supabase.instance.client.storage
          .from('profile_images')
          .getPublicUrl(fileName);

      // 3. Add timestamp to URL to bypass image caching in the app
      final timestampedUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // 4. Update Profile Table
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(profile.copyWith(photoUrl: timestampedUrl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
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
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rely strictly on synchronous cached state, avoiding stream delay edge effects.
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF16202A),
        body: Center(
          child: Text('User not found.', style: TextStyle(color: Colors.white)),
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

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          RefreshUtils.refreshAcademicData(ref);
          // Wait a bit for the stream to emit
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: Colors.cyan,
        backgroundColor: const Color(0xFF1E2836),
        child: StreamBuilder<Profile?>(
          stream: profileStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: Center(
                    child: Text(
                      'Profile not found.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(profile, user?.email),
                const SizedBox(height: 32),
                _buildStatsGrid(profile, coursesDone),
                const SizedBox(height: 32),
                _buildSectionTitle('Personal Info'),
                const SizedBox(height: 16),
                _buildInfoCard(
                  Icons.person_outline,
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
                const SizedBox(height: 12),
                _buildInfoCard(
                  Icons.badge_outlined,
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
                const SizedBox(height: 12),
                _buildInfoCard(
                  Icons.train_outlined,
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
                const SizedBox(height: 32),
                const SizedBox(height: 32),
                _buildSectionTitle('Security'),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  Icons.lock_outline,
                  'Change Password',
                  onTap: _editPassword,
                ),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  Icons.logout,
                  'Sign Out',
                  onTap: _logout,
                  isDestructive: true,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2A364B),
                backgroundImage: profile.photoUrl != null
                    ? CachedNetworkImageProvider(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 14,
                ),
                onPressed: () => _uploadProfileImage(profile),
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName ?? 'Not set',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email ?? 'No email',
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          'Started: ${_formatSemester(profile.admittedSemester)} • ${(profile.track ?? 'tri_semester').replaceAll('_', ' ').toUpperCase()}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      children: [
        _buildStatCard(
          Icons.star_border,
          profile.cgpa?.toStringAsFixed(2) ?? '0.00',
          'CGPA',
        ),
        _buildStatCard(
          Icons.school_outlined,
          profile.totalCreditsEarned?.toStringAsFixed(1) ?? '0.0',
          'Earned Credits',
        ),
        _buildStatCard(
          Icons.check_circle_outline,
          coursesDone.toString(),
          'Courses Done',
        ),
        _buildStatCard(
          Icons.phone_android,
          profile.enrolledCredits.toStringAsFixed(1),
          'Doing Now',
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.cyan, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: onTap != null
                ? const Color(0xFF1E2836).withOpacity(0.8)
                : const Color(0xFF1E2836),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[400]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.edit, color: Colors.grey[600], size: 18),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2836),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.redAccent : Colors.grey[400],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.redAccent : Colors.white,
                ),
              ),
            ),
            trailing ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
