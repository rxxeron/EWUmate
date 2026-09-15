import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';
import '../../../repositories/faculty_assignment_repository.dart';

class UploadProofStep extends StatelessWidget {
  final List<FacultyAssignmentItem> assignments;
  final Uint8List? proofBytes;
  final String? proofFileName;
  final int proofFileSize;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;
  final VoidCallback onPreviewFile;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final EwuColors colors;

  const UploadProofStep({
    super.key,
    required this.assignments,
    required this.proofBytes,
    required this.proofFileName,
    required this.proofFileSize,
    required this.onPickFile,
    required this.onClearFile,
    required this.onPreviewFile,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
    required this.colors,
  });

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primaryCyan, fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.sora(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProof = proofBytes != null;
    final isPdf = proofFileName != null && proofFileName!.toLowerCase().endsWith('.pdf');

    return Column(
      key: const ValueKey('step_2_proof'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              Text(
                '2. Upload Schedule Proof',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Upload a screenshot or PDF of your portal routine verifying these assignments.',
                style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // 1. Assignments Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Submission Summary',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${assignments.length} assignments',
                            style: GoogleFonts.sora(
                              color: AppColors.primaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assignments.map((item) {
                        final isLab = item.sessionType.toLowerCase() == 'lab';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF071426),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.courseCode} Sec ${item.sectionNumber}',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLab
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                      : AppColors.primaryCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isLab ? 'LAB' : 'THEORY',
                                  style: GoogleFonts.sora(
                                    color: isLab ? const Color(0xFFF59E0B) : AppColors.primaryCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '→ ${item.facultyInitial ?? "TBA"}',
                                style: GoogleFonts.sora(
                                  color: AppColors.primaryCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Upload Dropzone or File Selected Card
              if (!hasProof)
                InkWell(
                  onTap: onPickFile,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: colors.surfaceNavyBlue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryCyan.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 38,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to upload routine screenshot or PDF',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Supports JPG, PNG, PDF (Max 10MB)',
                          style: GoogleFonts.sora(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // File Selected Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceNavyBlue,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                              color: AppColors.primaryCyan,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proofFileName ?? 'proof_file',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(proofFileSize / 1024).toStringAsFixed(1)} KB',
                                  style: GoogleFonts.sora(
                                    color: colors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60),
                            onPressed: onClearFile,
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onPreviewFile,
                              icon: const Icon(Icons.visibility_rounded, size: 16),
                              label: const Text('Preview'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryCyan,
                                side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onPickFile,
                              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                              label: const Text('Change'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Guidelines Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF071426),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: AppColors.primaryCyan, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Submission Guidelines',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildGuidelineItem('Upload your advising/portal routine showing the courses & faculties.'),
                    _buildGuidelineItem('Ensure the course codes, section numbers, and faculty names are legible.'),
                    _buildGuidelineItem('Submissions with clear proof are verified swiftly by admins.'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom CTA: Back + Submit
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF071426).withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.15)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: Text(
                    '← Back',
                    style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (!hasProof || isSubmitting || assignments.isEmpty) ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        disabledBackgroundColor: colors.surfaceNavyBlue,
                        disabledForegroundColor: Colors.white24,
                        foregroundColor: AppColors.primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryNavy,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Submit for Verification',
                                  style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
