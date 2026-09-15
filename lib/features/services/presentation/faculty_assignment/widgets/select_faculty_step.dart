import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';
import '../../../../../core/widgets/primitives/ewu_empty_state.dart';

class SelectFacultyStep extends StatelessWidget {
  final List<Map<String, dynamic>> facultyMaster;
  final Map<String, dynamic>? selectedFaculty;
  final ValueChanged<Map<String, dynamic>?> onFacultySelected;
  final VoidCallback onNextStep;
  final TextEditingController searchController;
  final String searchQuery;
  final EwuColors colors;

  const SelectFacultyStep({
    super.key,
    required this.facultyMaster,
    required this.selectedFaculty,
    required this.onFacultySelected,
    required this.onNextStep,
    required this.searchController,
    required this.searchQuery,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = facultyMaster.where((f) {
      if (searchQuery.isEmpty) return true;
      final initial = (f['short_name'] ?? '').toString().toLowerCase();
      final name = (f['full_name'] ?? '').toString().toLowerCase();
      final desig = (f['designation_name'] ?? '').toString().toLowerCase();
      return initial.contains(searchQuery) ||
          name.contains(searchQuery) ||
          desig.contains(searchQuery);
    }).toList();

    return Column(
      key: const ValueKey('step_1'),
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Select Faculty Member',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Search by name or initials to find your faculty member.',
                style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: searchQuery.isNotEmpty
                        ? AppColors.primaryCyan.withValues(alpha: 0.8)
                        : colors.borderSubtle,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  style: GoogleFonts.sora(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, initials, or designation...',
                    hintStyle: GoogleFonts.sora(color: colors.textTertiary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryCyan),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                            onPressed: () => searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Faculty Results List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: EwuEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No Faculty Found',
                    subtitle: 'No faculty matches "$searchQuery". Try another query.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final f = filtered[index];
                    final initial = (f['short_name'] ?? '').toString();
                    final fullName = (f['full_name'] ?? '').toString();
                    final desig = (f['designation_name'] ?? 'Faculty Member').toString();
                    final isSelected = selectedFaculty != null && selectedFaculty!['short_name'] == initial;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: colors.surfaceNavyBlue,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryCyan
                              : colors.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF102A4A), Color(0xFF08192E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryCyan : AppColors.primaryCyan.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial.length >= 2 ? initial.substring(0, 2) : initial,
                              style: GoogleFonts.sora(
                                color: AppColors.primaryCyan,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: GoogleFonts.sora(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              '$initial • $desig',
                              style: GoogleFonts.sora(
                                color: AppColors.secondarySoftBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onFacultySelected(isSelected ? null : f);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primaryCyan
                                  : AppColors.primaryCyan.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.primaryCyan.withValues(alpha: isSelected ? 1.0 : 0.25),
                              ),
                            ),
                            child: Icon(
                              isSelected ? Icons.check_rounded : Icons.add_rounded,
                              size: 16,
                              color: isSelected ? AppColors.primaryNavy : AppColors.primaryCyan,
                            ),
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onFacultySelected(f);
                        },
                      ),
                    );
                  },
                ),
        ),

        // Bottom Selected Preview + "Next Step" Button
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedFaculty != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2342),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF102A4A),
                          ),
                          child: Center(
                            child: Text(
                              (selectedFaculty!['short_name'] ?? 'F').toString().substring(0, 1),
                              style: GoogleFonts.sora(
                                color: AppColors.primaryCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Faculty',
                                style: GoogleFonts.sora(color: colors.textTertiary, fontSize: 10),
                              ),
                              Text(
                                '${selectedFaculty!['full_name']} (${selectedFaculty!['short_name']})',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => onFacultySelected(null),
                          child: Text(
                            'Change',
                            style: GoogleFonts.sora(
                              color: AppColors.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: selectedFaculty == null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onNextStep();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      disabledBackgroundColor: colors.surfaceNavyBlue,
                      disabledForegroundColor: Colors.white24,
                      foregroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next Step',
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
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
