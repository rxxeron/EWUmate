import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/course_utils.dart';

Future<Map<String, String>?> showCourseSearchModal({
  required BuildContext context,
  required List<String> availableCourseCodes,
  required Map<String, List<String>> courseSectionsMap,
}) {
  HapticFeedback.selectionClick();
  String query = '';

  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF071426),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = availableCourseCodes.where((c) {
            if (query.isEmpty) return true;
            return c.toLowerCase().contains(query);
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: AppColors.primaryCyan, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Select Course Code',
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filtered.length} courses',
                          style: GoogleFonts.sora(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2342),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        autofocus: true,
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                        onChanged: (v) => setModalState(() => query = v.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search course code (e.g. CSE103, ACT101)...',
                          hintStyle: GoogleFonts.sora(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryCyan),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final code = filtered[i];
                          final sections = courseSectionsMap[code] ?? [];
                          final title = CourseUtils.getCourseTitle(code);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2342),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  code,
                                  style: GoogleFonts.sora(
                                    color: AppColors.primaryCyan,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                title.isNotEmpty ? title : code,
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${sections.length} sections available',
                                style: GoogleFonts.sora(color: Colors.white38, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                              onTap: () {
                                Navigator.pop(context, {
                                  'code': code,
                                  'section': sections.isNotEmpty ? sections.first : '1',
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
