import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/faculty.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class FacultyContactTab extends StatelessWidget {
  final Faculty faculty;
  final EwuColors colors;
  final ValueChanged<String> onSendEmail;
  final ValueChanged<String> onOpenUrl;

  const FacultyContactTab({
    super.key,
    required this.faculty,
    required this.colors,
    required this.onSendEmail,
    required this.onOpenUrl,
  });

  Widget _buildContactCard({
    required String title,
    required String value,
    required IconData icon,
    required String? actionLabel,
    required VoidCallback? onAction,
    required EwuColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryCyan, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.sora(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: GoogleFonts.sora(
                  color: AppColors.primaryCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (faculty.email != null && faculty.email!.isNotEmpty)
          _buildContactCard(
            title: 'Official Email',
            value: faculty.email!,
            icon: Icons.email_rounded,
            actionLabel: 'Send Email',
            onAction: () => onSendEmail(faculty.email!),
            colors: colors,
          ),
        const SizedBox(height: 12),
        _buildContactCard(
          title: 'Office Location',
          value: faculty.officeRoom != null && faculty.officeRoom!.isNotEmpty
              ? 'Room ${faculty.officeRoom}'
              : 'Not specified in university records',
          icon: Icons.meeting_room_rounded,
          actionLabel: null,
          onAction: null,
          colors: colors,
        ),
        if (faculty.profileUrl != null && faculty.profileUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildContactCard(
            title: 'University Profile',
            value: 'East West University Faculty Directory',
            icon: Icons.public_rounded,
            actionLabel: 'Open Profile',
            onAction: () => onOpenUrl(faculty.profileUrl!),
            colors: colors,
          ),
        ],
      ],
    );
  }
}
