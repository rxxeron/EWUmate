import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

void showProofPreviewDialog({
  required BuildContext context,
  required Uint8List? proofBytes,
  required String? proofFileName,
}) {
  if (proofBytes == null) return;
  HapticFeedback.lightImpact();

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF071426),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    proofFileName ?? 'Schedule Proof',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                color: Colors.black,
                child: (proofFileName != null && proofFileName.toLowerCase().endsWith('.pdf'))
                    ? Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 54),
                            const SizedBox(height: 12),
                            Text(
                              'PDF Document Attached',
                              style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              proofFileName,
                              style: GoogleFonts.sora(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : Image.memory(
                        proofBytes,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
