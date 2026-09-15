import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/faculty.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ewu_theme_extension.dart';

class FacultyCard extends StatefulWidget {
  final Faculty faculty;

  const FacultyCard({super.key, required this.faculty});

  @override
  State<FacultyCard> createState() => _FacultyCardState();
}

class _FacultyCardState extends State<FacultyCard> {
  bool _isPressed = false;

  void _copyEmail(BuildContext context, String email) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primaryCyan, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email copied: $email',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D2342),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
        ),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final faculty = widget.faculty;
    final photoUrl = faculty.photoUrl;
    final isLiveUrl = photoUrl != null && photoUrl.startsWith('http');

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceNavyBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/services/faculty-directory/details', extra: faculty);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Initials / Photo Avatar
                  Hero(
                    tag: 'faculty_${faculty.id}',
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF102A4A), Color(0xFF08192E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.38),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(alpha: 0.10),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isLiveUrl
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitialsFallback(faculty),
                            )
                          : _buildInitialsFallback(faculty),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Middle Information Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name and Code Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                faculty.fullName,
                                style: GoogleFonts.sora(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (faculty.shortName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryCyan.withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  faculty.shortName,
                                  style: GoogleFonts.sora(
                                    color: AppColors.primaryCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Department / Designation Label
                        Text(
                          'Department of ${faculty.department}',
                          style: GoogleFonts.sora(
                            color: AppColors.secondarySoftBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Email Pill Row
                        if (faculty.email != null && faculty.email!.isNotEmpty)
                          InkWell(
                            onTap: () => _launchEmail(faculty.email!),
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.primaryCyan,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    faculty.email!,
                                    style: GoogleFonts.sora(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right Quick Action Pill (Email / Copy)
                  if (faculty.email != null && faculty.email!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Copy Email',
                      child: InkWell(
                        onTap: () => _copyEmail(context, faculty.email!),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryCyan.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsFallback(Faculty faculty) {
    return Center(
      child: Text(
        faculty.avatarInitials,
        style: GoogleFonts.sora(
          color: AppColors.primaryCyan,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
