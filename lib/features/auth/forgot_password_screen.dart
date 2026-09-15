import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _codeSent = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Recovery code sent! Check your student email.",
            style: GoogleFonts.sora(),
          ),
          backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.8),
        ));
        setState(() => _codeSent = true);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verifyAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.recovery,
      );

      if (response.session != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Password reset successfully!", style: GoogleFonts.sora()),
            backgroundColor: AppColors.success,
          ));
          context.go('/dashboard'); 
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorUtils.getFriendlyMessage(e), style: GoogleFonts.sora()),
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
                // Animated Icon with Cyan Aura
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
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _codeSent
                            ? Icons.lock_reset_rounded
                            : Icons.mark_email_read_rounded,
                        key: ValueKey<bool>(_codeSent),
                        size: 42,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  _codeSent ? "Reset Password" : "Forgot Password",
                  style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _codeSent
                      ? "Enter the 6-digit recovery code and new password"
                      : "We'll send a 6-digit recovery code to your email",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Glass Container
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(22.0),
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_codeSent)
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "Student Email Address",
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
                            validator: (v) => (v == null || v.isEmpty || !v.contains('@'))
                                ? "Valid email required"
                                : null,
                          ),
                        if (_codeSent) ...[
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              letterSpacing: 10,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: "6-Digit Code",
                              labelStyle: GoogleFonts.sora(
                                color: AppColors.secondaryText,
                                letterSpacing: 0,
                                fontSize: 13,
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
                            validator: (v) =>
                                (v == null || v.length < 6) ? "Code must be 6 digits" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "New Password",
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
                                onPressed: () =>
                                    setState(() => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6) ? "Min 6 characters required" : null,
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Gradient Submit Button
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
                              onTap: _loading
                                  ? null
                                  : (_codeSent ? _verifyAndResetPassword : _sendResetCode),
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
                                        _codeSent
                                            ? "Verify & Reset Password"
                                            : "Send Recovery Code",
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
                        const SizedBox(height: 16),

                        // Back / Switch action
                        TextButton(
                          onPressed: () {
                            if (_codeSent) {
                              setState(() => _codeSent = false);
                            } else {
                              context.pop();
                            }
                          },
                          child: Text(
                            _codeSent ? "Use a different email" : "Back to Login",
                            style: GoogleFonts.sora(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
