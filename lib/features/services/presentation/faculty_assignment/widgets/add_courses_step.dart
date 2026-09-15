import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';
import '../../../../../core/utils/course_utils.dart';
import '../../../repositories/faculty_assignment_repository.dart';
import 'faculty_search_modal.dart';

class AddCoursesStep extends StatelessWidget {
  final String selectedSemester;
  final List<String> availableSemesters;
  final ValueChanged<String> onSemesterChanged;

  // Enrolled quick fills
  final List<Map<String, dynamic>> enrolledCourses;
  final void Function(String code, String section) onQuickFillEnrolled;

  // Builder state
  final String? selectedCourseCode;
  final String selectedSessionType; // 'Theory' or 'Lab'
  final ValueChanged<String> onSessionTypeChanged;
  final String selectedSectionNumber;
  final List<String> availableSections;
  final ValueChanged<String> onSectionChanged;
  final Map<String, dynamic>? selectedFaculty;
  final ValueChanged<Map<String, dynamic>?> onFacultySelected;
  final List<Map<String, dynamic>> facultyMaster;

  final VoidCallback onSearchCourse;
  final VoidCallback onAddAssignment;

  // Staged assignments
  final List<FacultyAssignmentItem> addedAssignments;
  final ValueChanged<int> onRemoveAssignment;

  // Navigation
  final VoidCallback onNextStep;
  final EwuColors colors;

  const AddCoursesStep({
    super.key,
    required this.selectedSemester,
    required this.availableSemesters,
    required this.onSemesterChanged,
    required this.enrolledCourses,
    required this.onQuickFillEnrolled,
    required this.selectedCourseCode,
    required this.selectedSessionType,
    required this.onSessionTypeChanged,
    required this.selectedSectionNumber,
    required this.availableSections,
    required this.onSectionChanged,
    required this.selectedFaculty,
    required this.onFacultySelected,
    required this.facultyMaster,
    required this.onSearchCourse,
    required this.onAddAssignment,
    required this.addedAssignments,
    required this.onRemoveAssignment,
    required this.onNextStep,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = selectedCourseCode != null &&
        selectedSectionNumber.isNotEmpty &&
        selectedFaculty != null;

    return Column(
      key: const ValueKey('step_1_assign'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              Text(
                '1. Assign Course Faculties',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Configure course, type (Theory or Lab), section, and faculty. Add as many as you want in one submission.',
                style: GoogleFonts.sora(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // 1. Target Semester Selector Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primaryCyan, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Semester',
                          style: GoogleFonts.sora(color: colors.textTertiary, fontSize: 10),
                        ),
                        Text(
                          CourseUtils.prettifySemesterCode(selectedSemester),
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSemester,
                        dropdownColor: const Color(0xFF0D2342),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryCyan),
                        items: availableSemesters.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              CourseUtils.prettifySemesterCode(s),
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != selectedSemester) {
                            onSemesterChanged(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Quick Fill Enrolled Courses Chips
              if (enrolledCourses.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.primaryCyan, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Quick Fill Enrolled Courses',
                            style: GoogleFonts.sora(
                              color: AppColors.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any enrolled course below to auto-fill its code & section:',
                        style: GoogleFonts.sora(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: enrolledCourses.map((c) {
                          final code = c['course_code']?.toString() ?? '';
                          final sec = c['section']?.toString() ?? '1';
                          final isSelected = selectedCourseCode == code && selectedSectionNumber == sec;

                          return InkWell(
                            onTap: () => onQuickFillEnrolled(code, sec),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryCyan.withValues(alpha: 0.25)
                                    : const Color(0xFF0D2342),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryCyan : Colors.white12,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$code Sec $sec',
                                    style: GoogleFonts.sora(
                                      color: isSelected ? AppColors.primaryCyan : Colors.white,
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                    color: isSelected ? AppColors.primaryCyan : Colors.white54,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 3. Assignment Builder Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure Course & Faculty',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // A. Course Code & Section Row
                    Row(
                      children: [
                        // Course Code Selector Pill
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: onSearchCourse,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF071426),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedCourseCode != null
                                      ? AppColors.primaryCyan.withValues(alpha: 0.4)
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: AppColors.primaryCyan, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selectedCourseCode ?? 'Search Code...',
                                      style: GoogleFonts.sora(
                                        color: selectedCourseCode != null ? Colors.white : colors.textTertiary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Section Dropdown
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF071426),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: availableSections.contains(selectedSectionNumber)
                                    ? selectedSectionNumber
                                    : (availableSections.isNotEmpty ? availableSections.first : '1'),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF0D2342),
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryCyan),
                                items: availableSections.map((sec) {
                                  return DropdownMenuItem(
                                    value: sec,
                                    child: Text(
                                      'Sec $sec',
                                      style: GoogleFonts.sora(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    onSectionChanged(val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // B. Course Type Toggle (Theory vs Lab)
                    Text(
                      'Session Type',
                      style: GoogleFonts.sora(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onSessionTypeChanged('Theory'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: selectedSessionType == 'Theory'
                                    ? AppColors.primaryCyan.withValues(alpha: 0.20)
                                    : const Color(0xFF071426),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedSessionType == 'Theory'
                                      ? AppColors.primaryCyan
                                      : Colors.white12,
                                  width: selectedSessionType == 'Theory' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 15,
                                    color: selectedSessionType == 'Theory' ? AppColors.primaryCyan : Colors.white54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Theory',
                                    style: GoogleFonts.sora(
                                      color: selectedSessionType == 'Theory' ? AppColors.primaryCyan : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: selectedSessionType == 'Theory' ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => onSessionTypeChanged('Lab'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: selectedSessionType == 'Lab'
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                                    : const Color(0xFF071426),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedSessionType == 'Lab'
                                      ? const Color(0xFFF59E0B)
                                      : Colors.white12,
                                  width: selectedSessionType == 'Lab' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.biotech_rounded,
                                    size: 16,
                                    color: selectedSessionType == 'Lab' ? const Color(0xFFF59E0B) : Colors.white54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lab',
                                    style: GoogleFonts.sora(
                                      color: selectedSessionType == 'Lab' ? const Color(0xFFF59E0B) : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: selectedSessionType == 'Lab' ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // C. Faculty Selector Button
                    Text(
                      'Assigned Faculty',
                      style: GoogleFonts.sora(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final fac = await showFacultySearchModal(
                          context: context,
                          facultyMaster: facultyMaster,
                          currentInitial: selectedFaculty?['short_name'],
                        );
                        if (fac != null) {
                          onFacultySelected(fac);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071426),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedFaculty != null
                                ? AppColors.primaryCyan.withValues(alpha: 0.5)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: selectedFaculty != null
                                  ? AppColors.primaryCyan
                                  : const Color(0xFF1E3A5F),
                              child: Text(
                                selectedFaculty != null
                                    ? (selectedFaculty!['short_name'] ?? '?').toString().toUpperCase()
                                    : '?',
                                style: GoogleFonts.sora(
                                  color: selectedFaculty != null ? AppColors.primaryNavy : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFaculty != null
                                        ? '${selectedFaculty!['full_name']} (${selectedFaculty!['short_name']})'
                                        : 'Tap to choose faculty...',
                                    style: GoogleFonts.sora(
                                      color: selectedFaculty != null ? Colors.white : colors.textTertiary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (selectedFaculty?['designation_name'] != null)
                                    Text(
                                      selectedFaculty!['designation_name'],
                                      style: GoogleFonts.sora(color: Colors.white54, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryCyan, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // D. Add to List Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: canAdd ? onAddAssignment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          disabledBackgroundColor: const Color(0xFF071426),
                          disabledForegroundColor: Colors.white24,
                          foregroundColor: AppColors.primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Add to Assignment List',
                              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Staged Assignments List
              if (addedAssignments.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Staged Assignments (${addedAssignments.length})',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Will be verified via proof',
                      style: GoogleFonts.sora(color: AppColors.primaryCyan, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...addedAssignments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLab = item.sessionType.toLowerCase() == 'lab';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surfaceNavyBlue,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        // Course Code Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            item.courseCode,
                            style: GoogleFonts.sora(
                              color: AppColors.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Section Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF071426),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'Sec ${item.sectionNumber}',
                            style: GoogleFonts.sora(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Type Badge (Theory vs Lab)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLab
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : AppColors.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLab
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                  : AppColors.primaryCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            isLab ? 'LAB' : 'THEORY',
                            style: GoogleFonts.sora(
                              color: isLab ? const Color(0xFFF59E0B) : AppColors.primaryCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Faculty Initial & Full Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '→ ${item.facultyInitial ?? "TBA"}',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (item.facultyFullName != null)
                                Text(
                                  item.facultyFullName!,
                                  style: GoogleFonts.sora(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onRemoveAssignment(index);
                          },
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2342),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No assignments added yet. Use the card above to configure and add your course faculties.',
                          style: GoogleFonts.sora(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom CTA Button: Proceed to Upload Proof
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
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: addedAssignments.isEmpty ? null : onNextStep,
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
                      addedAssignments.isEmpty
                          ? 'Add Assignments to Proceed'
                          : 'Continue to Upload Proof (${addedAssignments.length})',
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
