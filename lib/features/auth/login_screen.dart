import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/theme/app_colors.dart';
import 'auth_providers.dart';
import '../../core/utils/error_utils.dart';
import '../../core/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw const AuthException("Please enter email and password");
      }
      await ref.read(authRepositoryProvider).signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
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
        if (e.toString() == 'account-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Account not found. Please sign up first."),
            backgroundColor: AppColors.warning,
          ));
          context.go('/register');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AuthErrorUtils.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ));
        }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Glow Icon & Brand
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceNavyBlue.withValues(alpha: 0.6),
                    border: Border.all(
                      color: AppColors.primaryCyan.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 42,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "EWUmate",
                  style: GoogleFonts.sora(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sign in to continue your academic journey",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 28),

                // Main Glass Form Container
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Student / Google Email",
                            labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.primaryCyan,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primaryCyan,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          autofillHints: const [AutofillHints.password],
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primaryCyan,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.primaryNavy.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primaryCyan,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: AppColors.secondaryText,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => context.push('/forgot-password'),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                "Forgot Password?",
                                style: GoogleFonts.sora(
                                  color: AppColors.primaryCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Primary Gradient Login Button
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryCyan, Color(0xFF0891B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _loading ? null : _login,
                              borderRadius: BorderRadius.circular(14),
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
                                        "Sign In",
                                        style: GoogleFonts.sora(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryNavy,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider Row
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.08),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                "or continue with",
                                style: GoogleFonts.sora(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.08),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign In Glass Container
                        GlassContainer(
                          onTap: _loading ? null : _googleLogin,
                          color: AppColors.surfaceNavyBlue.withValues(alpha: 0.3),
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          borderColor: Colors.white.withValues(alpha: 0.08),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
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
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Sign in with Google",
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
                const SizedBox(height: 24),

                // Sign Up Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: GoogleFonts.sora(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        "Sign Up",
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
