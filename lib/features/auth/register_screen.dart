import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_kit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/error_utils.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _studentIdController = TextEditingController();

  bool _loading = false;
  bool _passwordVisible = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'ewumate://login-callback',
        data: {
          'displayName': _nicknameController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'studentId': _studentIdController.text.trim(),
        },
      );

      if (res.user == null) {
        throw const AuthException("Registration failed");
      }

      if (res.session == null) {
        // Email verification is required and pending
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surfaceNavyBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: AppColors.primaryCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Verify Email",
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                "A verification link has been sent to your student email. Please check your inbox and verify your email before logging in.",
                style: GoogleFonts.sora(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  child: Text(
                    "Back to Login",
                    style: GoogleFonts.sora(
                      color: AppColors.primaryCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        // Verification was bypassed (e.g. email verified by provider like Google)
        final String uid = res.user!.id;
        await Supabase.instance.client.from('profiles').upsert({
          'id': uid,
          'full_name': _fullNameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'onboarding_status': 'registered',
        });

        if (mounted) {
          context.go('/onboarding/program');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorUtils.getFriendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.invalidate(profileProvider);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorUtils.getFriendlyMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fullNameController.dispose();
    _nicknameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryCyan,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 13),
      labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
      prefixIcon: Icon(icon, size: 19, color: AppColors.primaryCyan),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      filled: true,
      fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  "Create Account",
                  style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Join the EWU student community today",
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),

                // Glass Form Container
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(22.0),
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section 1: Personal Info
                        _buildSectionHeader("Personal Info"),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fullNameController,
                                textCapitalization: TextCapitalization.words,
                                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                decoration: _inputDecoration(
                                  label: "Full Name",
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _nicknameController,
                                textCapitalization: TextCapitalization.words,
                                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                decoration: _inputDecoration(
                                  label: "Nickname",
                                  icon: Icons.face_rounded,
                                ),
                                validator: (v) => v!.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _studentIdController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                          inputFormatters: [StudentIdFormatter()],
                          decoration: _inputDecoration(
                            label: "Student ID",
                            hint: "2025-2-50-009",
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Student ID required";
                            if (v.length < 13) return "Incomplete Student ID";
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Section 2: Account Details
                        _buildSectionHeader("Account Details"),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration(
                            label: "Student Email",
                            hint: "id@std.ewubd.edu",
                            icon: Icons.mail_outline_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Email required";
                            if (!value.trim().endsWith('@std.ewubd.edu')) {
                              return "Only @std.ewubd.edu allowed";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          autofillHints: const [AutofillHints.newPassword],
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration(
                            label: "Password",
                            icon: Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 18,
                                color: AppColors.secondaryText,
                              ),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                          validator: (value) => (value == null || value.length < 6)
                              ? "Min 6 characters required"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _confirmController,
                          obscureText: !_passwordVisible,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                          decoration: _inputDecoration(
                            label: "Confirm Password",
                            icon: Icons.lock_outline_rounded,
                          ),
                          validator: (value) =>
                              value != _passwordController.text ? "Passwords do not match" : null,
                        ),
                        const SizedBox(height: 22),

                        // Submit Button
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryCyan, Color(0xFF0891B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _loading ? null : _register,
                              borderRadius: BorderRadius.circular(13),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryNavy,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        "Create Account",
                                        style: GoogleFonts.sora(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Google Sign Up
                        GlassContainer(
                          onTap: _loading ? null : _googleLogin,
                          color: AppColors.surfaceNavyBlue.withValues(alpha: 0.3),
                          borderRadius: 13,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          borderColor: Colors.white.withValues(alpha: 0.08),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    "G",
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Sign up with Google",
                                style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: GoogleFonts.sora(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        "Login",
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryCyan,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
