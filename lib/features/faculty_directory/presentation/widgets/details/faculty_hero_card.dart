import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/faculty.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class FacultyHeroCard extends StatelessWidget {
  final Faculty faculty;
  final EwuColors colors;
  final bool isLiveUrl;
  final String? photoUrl;
  final ValueChanged<String> onSendEmail;
  final ValueChanged<String> onCopyEmail;

  const FacultyHeroCard({
    super.key,
    required this.faculty,
    required this.colors,
    required this.isLiveUrl,
    required this.photoUrl,
    required this.onSendEmail,
    required this.onCopyEmail,
  });

  Widget _buildAvatarInitials(Faculty faculty) {
    return Center(
      child: Text(
        faculty.avatarInitials,
        style: GoogleFonts.sora(
          color: AppColors.primaryCyan,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryCyan.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Centered Avatar
          Hero(
            tag: 'faculty_${faculty.id}',
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF102A4A), Color(0xFF08192E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primaryCyan,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: isLiveUrl
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('⚠️ Image.network error for ${faculty.shortName} ($photoUrl): $error');
                        return _buildAvatarInitials(faculty);
                      },
                    )
                  : _buildAvatarInitials(faculty),
            ),
          ),
          const SizedBox(height: 14),

          // Faculty Name & Short Name Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  faculty.fullName,
                  style: GoogleFonts.sora(
                    color: colors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              if (faculty.shortName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryCyan.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    faculty.shortName,
                    style: GoogleFonts.sora(
                      color: AppColors.primaryCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Designation
          if (faculty.designation != null && faculty.designation!.isNotEmpty) ...[
            Text(
              faculty.designation!,
              style: GoogleFonts.sora(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],

          // Department
          Text(
            'Department of ${faculty.department}',
            style: GoogleFonts.sora(
              color: AppColors.secondarySoftBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Email Pill Row with Direct Actions
          if (faculty.email != null && faculty.email!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF071426),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, color: AppColors.primaryCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      faculty.email!,
                      style: GoogleFonts.sora(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primaryCyan, size: 16),
                    onPressed: () => onSendEmail(faculty.email!),
                    tooltip: 'Send Email',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                    onPressed: () => onCopyEmail(faculty.email!),
                    tooltip: 'Copy Email',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
