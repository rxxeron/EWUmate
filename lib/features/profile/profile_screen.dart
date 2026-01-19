import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/schedule_cache_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/widgets/glass_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _nicknameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  final ScheduleCacheService _cacheService = ScheduleCacheService();

  bool _loading = false;
  String? _photoUrl;
  bool _morningAlarmEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService();
    final enabled = await settings.getMorningAlarmEnabled();
    if (mounted) {
      setState(() => _morningAlarmEnabled = enabled);
    }
  }

  Future<void> _toggleMorningAlarm(bool value) async {
    setState(() => _morningAlarmEnabled = value);
    final settings = SettingsService();
    await settings.setMorningAlarmEnabled(value);
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    _emailCtrl.text = user!.email ?? '';

    // Try cache first
    final cached = await _cacheService.getCachedStats();
    if (cached != null) {
      _populateFields(cached);
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        await _cacheService.cacheStats(data);
        _populateFields(data);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = data['fullName'] ?? '';
      _nicknameCtrl.text = data['nickname'] ?? '';
      _idCtrl.text = data['studentId'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _photoUrl = data['profilePicture'];
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _loading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user!.uid}.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final bytes = await image.readAsBytes();

      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profilePicture': url});

      await user!.updatePhotoURL(url);

      setState(() => _photoUrl = url);
      if (mounted) _showSnack("Photo updated!");
    } catch (e) {
      if (mounted) _showSnack("Upload failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'fullName': _nameCtrl.text.trim(),
        'nickname': _nicknameCtrl.text.trim(),
        'studentId': _idCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) _showSnack("Profile saved!");
    } catch (e) {
      if (mounted) _showSnack("Save failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField("Current Password", currentPassCtrl),
            const SizedBox(height: 12),
            _dialogField("New Password", newPassCtrl),
            const SizedBox(height: 12),
            _dialogField("Confirm New Password", confirmPassCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                _showSnack("Passwords don't match!", isError: true);
                return;
              }
              if (newPassCtrl.text.length < 6) {
                _showSnack(
                  "Password must be at least 6 characters!",
                  isError: true,
                );
                return;
              }

              try {
                final credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPassCtrl.text,
                );
                await user!.reauthenticateWithCredential(credential);
                await user!.updatePassword(newPassCtrl.text);

                if (!mounted) return;
                Navigator.of(context).pop();
                _showSnack("Password changed successfully!");
              } on FirebaseAuthException catch (e) {
                _showSnack("Error: ${e.message}", isError: true);
              }
            },
            child: const Text("Change", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.cyanAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show save button if not loading
    final saveButton = _loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.cyanAccent,
            ),
          )
        : IconButton(
            icon: const Icon(Icons.check, color: Colors.cyanAccent),
            onPressed: _saveProfile,
            tooltip: 'Save Changes',
          );

    return FullGradientScaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: saveButton),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white10,
                      backgroundImage:
                          _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white30,
                            )
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: _loading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Student",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _emailCtrl.text,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Form Fields
            _buildSectionHeader("Personal Info"),
            const SizedBox(height: 15),
            _buildGlassField("Full Name", _nameCtrl, Icons.person_outline),
            const SizedBox(height: 15),
            _buildGlassField("Nickname", _nicknameCtrl, Icons.badge_outlined),
            const SizedBox(height: 15),
            _buildGlassField("Student ID", _idCtrl, Icons.card_membership),
            const SizedBox(height: 15),
            _buildGlassField("Mobile Number", _phoneCtrl, Icons.phone_outlined),

            const SizedBox(height: 40),
            _buildSectionHeader("App Settings"),
            const SizedBox(height: 15),

            GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              color: Colors.white.withValues(alpha: 0.05),
              child: Column(
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, theme, _) {
                      return SwitchListTile(
                        title: const Text(
                          "Dark Mode",
                          style: TextStyle(color: Colors.white),
                        ),
                        secondary: Icon(
                          theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.cyanAccent,
                        ),
                        activeThumbColor: Colors.cyanAccent,
                        value: theme.isDarkMode,
                        onChanged: (val) => theme.toggleTheme(val),
                      );
                    },
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.1), height: 1),
                  SwitchListTile(
                    title: const Text(
                      "Morning Alarm",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "Wake up for 08:30 AM classes",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    secondary: const Icon(
                      Icons.alarm,
                      color: Colors.cyanAccent,
                    ),
                    activeThumbColor: Colors.cyanAccent,
                    value: _morningAlarmEnabled,
                    onChanged: _toggleMorningAlarm,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 5),
              borderRadius: 16,
              color: Colors.white.withValues(alpha: 0.05),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.lock_reset,
                      color: Colors.orangeAccent,
                    ),
                    title: const Text(
                      "Change Password",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: _showChangePasswordDialog,
                  ),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.1), height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      "Log Out",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGlassField(
    String label,
    TextEditingController ctrl,
    IconData icon,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      color: Colors.white.withValues(alpha: 0.05),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white60, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
