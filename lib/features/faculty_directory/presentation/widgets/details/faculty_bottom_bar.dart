import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class FacultyBottomBar extends StatelessWidget {
  final VoidCallback onCopyEmail;

  const FacultyBottomBar({
    super.key,
    required this.onCopyEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF071426).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.primaryCyan.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onCopyEmail,
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryNavy),
            label: Text(
              'Copy Official Email',
              style: GoogleFonts.sora(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
              shadowColor: AppColors.primaryCyan.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
