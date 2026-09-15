import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/faculty_office_hour.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primitives/ewu_empty_state.dart';

class FacultyOfficeHoursTab extends StatelessWidget {
  final AsyncValue<List<FacultyOfficeHour>> officeHoursAsync;
  final VoidCallback onAddOfficeHours;
  final ValueChanged<String> onOpenUrl;

  const FacultyOfficeHoursTab({
    super.key,
    required this.officeHoursAsync,
    required this.onAddOfficeHours,
    required this.onOpenUrl,
  });

  Widget _buildOfficeHourCard(BuildContext context, FacultyOfficeHour slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2342),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primaryCyan, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.day,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Verified',
                        style: GoogleFonts.sora(
                          color: const Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: GoogleFonts.sora(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // View Proof button
          ElevatedButton.icon(
            onPressed: () {
              final url = 'https://drive.google.com/file/d/${slot.driveFileId}/view';
              onOpenUrl(url);
            },
            icon: const Icon(Icons.verified_user_rounded, color: AppColors.primaryNavy, size: 13),
            label: Text(
              'Proof',
              style: GoogleFonts.sora(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return officeHoursAsync.when(
      data: (officeHours) {
        return Stack(
          children: [
            if (officeHours.isEmpty)
              const Center(
                child: EwuEmptyState(
                  icon: Icons.help_outline_rounded,
                  title: 'No Office Hours Reported',
                  subtitle: 'Help other students by contributing verified office hours with proof schedule!',
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: officeHours.length,
                itemBuilder: (context, index) {
                  final slot = officeHours[index];
                  return _buildOfficeHourCard(context, slot);
                },
              ),

            // Floating Submit Button
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: onAddOfficeHours,
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryNavy),
                label: Text(
                  'Add Office Hours',
                  style: GoogleFonts.sora(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: AppColors.primaryCyan,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryCyan),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error loading office hours: $err',
          style: GoogleFonts.sora(color: AppColors.error),
        ),
      ),
    );
  }
}
