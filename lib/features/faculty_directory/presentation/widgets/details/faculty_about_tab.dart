import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/faculty.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';

class FacultyAboutTab extends StatelessWidget {
  final Faculty faculty;
  final EwuColors colors;
  final ValueChanged<String> onOpenUrl;

  const FacultyAboutTab({
    super.key,
    required this.faculty,
    required this.colors,
    required this.onOpenUrl,
  });

  Widget _buildInfoRow(String label, String value, EwuColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.sora(
              color: colors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.sora(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Bio summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceNavyBlue,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biography',
                style: GoogleFonts.sora(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${faculty.fullName} is a ${faculty.designation ?? 'Faculty Member'} in the Department of ${faculty.department} at East West University.',
                style: GoogleFonts.sora(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Key Information Grid
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceNavyBlue,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Faculty Information',
                style: GoogleFonts.sora(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildInfoRow('Initials', faculty.shortName, colors),
              const Divider(color: Colors.white10, height: 20),
              _buildInfoRow('Email', faculty.email ?? 'Not available', colors),
              const Divider(color: Colors.white10, height: 20),
              _buildInfoRow('Office Room', faculty.officeRoom ?? 'Not specified', colors),
              const Divider(color: Colors.white10, height: 20),
              _buildInfoRow('Department', 'Department of ${faculty.department}', colors),
              const Divider(color: Colors.white10, height: 20),
              _buildInfoRow('Designation', faculty.designation ?? 'Faculty Member', colors),
            ],
          ),
        ),

        if (faculty.profileUrl != null && faculty.profileUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () => onOpenUrl(faculty.profileUrl!),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, color: AppColors.primaryCyan, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Official University Web Profile',
                      style: GoogleFonts.sora(
                        color: AppColors.primaryCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, color: AppColors.primaryCyan, size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
