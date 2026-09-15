import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primitives/ewu_empty_state.dart';

Future<Map<String, dynamic>?> showFacultySearchModal({
  required BuildContext context,
  required List<Map<String, dynamic>> facultyMaster,
  String? currentInitial,
}) {
  HapticFeedback.selectionClick();
  String query = '';

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF071426),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = facultyMaster.where((f) {
            if (query.isEmpty) return true;
            final initial = (f['short_name'] ?? '').toString().toLowerCase();
            final name = (f['full_name'] ?? '').toString().toLowerCase();
            final desig = (f['designation_name'] ?? '').toString().toLowerCase();
            return initial.contains(query) ||
                name.contains(query) ||
                desig.contains(query);
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
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
                        const Icon(Icons.person_search_rounded, color: AppColors.primaryCyan, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Select Faculty Member',
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ' found',
                          style: GoogleFonts.sora(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2342),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        autofocus: true,
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                        onChanged: (v) => setModalState(() => query = v.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search initials (e.g. ZMI) or name...',
                          hintStyle: GoogleFonts.sora(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryCyan),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                                  onPressed: () => setModalState(() => query = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const EwuEmptyState(
                              title: 'No faculty found',
                              subtitle: 'Try searching with different initials or name.',
                              icon: Icons.person_off_outlined,
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final fac = filtered[i];
                                final initial = fac['short_name']?.toString() ?? '';
                                final name = fac['full_name']?.toString() ?? '';
                                final desig = fac['designation_name']?.toString() ?? '';
                                final isSelected = currentInitial != null &&
                                    currentInitial.toUpperCase() == initial.toUpperCase();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryCyan.withValues(alpha: 0.12)
                                        : const Color(0xFF0D2342),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryCyan
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected
                                          ? AppColors.primaryCyan
                                          : const Color(0xFF1E3A5F),
                                      child: Text(
                                        initial.isNotEmpty
                                            ? initial.substring(0, initial.length.clamp(1, 3)).toUpperCase()
                                            : '?',
                                        style: GoogleFonts.sora(
                                          color: isSelected ? AppColors.primaryNavy : Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: GoogleFonts.sora(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: desig.isNotEmpty
                                        ? Text(
                                            desig,
                                            style: GoogleFonts.sora(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : null,
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryCyan
                                            : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.sora(
                                          color: isSelected ? AppColors.primaryNavy : AppColors.primaryCyan,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).pop(fac);
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
