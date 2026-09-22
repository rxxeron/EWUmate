import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/faculty_review.dart';
import '../../../../core/repositories/faculty_reviews_repository.dart';

class SubmitFacultyReviewSheet extends ConsumerStatefulWidget {
  final String facultyInitials;
  final String? facultyName;
  final String currentSemester;
  final FacultyReview? existingReview;

  const SubmitFacultyReviewSheet({
    super.key,
    required this.facultyInitials,
    this.facultyName,
    required this.currentSemester,
    this.existingReview,
  });

  @override
  ConsumerState<SubmitFacultyReviewSheet> createState() => _SubmitFacultyReviewSheetState();
}

class _SubmitFacultyReviewSheetState extends ConsumerState<SubmitFacultyReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _examTipsController;
  late TextEditingController _reviewNoteController;

  String? _selectedCourseCode;
  String? _selectedCourseName;
  late String _selectedSemesterTitle;
  String? _selectedSemesterCode;
  String? _courseValidationError;

  late String _deliveryType;
  late String? _gradeReceived;
  late double _clarityRating;
  late double _gradingFairness;
  late double _examAlignment;
  late double _officeHoursAccessibility;
  late double _attendanceStrictness;
  late String _workloadLevel;
  late String _slideReliance;
  late String _quizFrequency;
  late String _quizCount;
  late String _quizGradingStyle;
  late String _textbookNeed;
  late bool _wouldTakeAgain;
  late Set<String> _selectedTraits;

  bool _isSubmitting = false;

  final List<String> _availableTraits = [
    'Clear Explanations',
    'Engaging Lectures',
    'Helpful in Office Hours',
    'Fair Grader',
    'Tough Grader',
    'Heavy Homework',
    'Project Heavy',
    'Surprise Quizzes',
    'Slide Heavy',
    'Board & Discussion',
    'Coding Focused',
    'Inspiring Mentor',
    'Strict Deadlines',
    'Exam Matches Class',
  ];

  final List<String> _grades = [
    'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existingReview;
    _selectedCourseCode = r?.courseCode;
    _selectedSemesterTitle = r?.semester ?? (widget.currentSemester.isNotEmpty ? widget.currentSemester : 'Summer 2026');
    _selectedSemesterCode = r?.semesterCode;

    _examTipsController = TextEditingController(text: r?.examPrepTips ?? '');
    _reviewNoteController = TextEditingController(text: r?.reviewNote ?? '');

    _deliveryType = r?.deliveryType ?? 'theory';
    _gradeReceived = r?.gradeReceived;
    _clarityRating = r?.clarityRating ?? 4.0;
    _gradingFairness = r?.gradingFairness ?? 4.0;
    _examAlignment = r?.examAlignment ?? 4.0;
    _officeHoursAccessibility = r?.officeHoursAccessibility ?? 4.0;
    _attendanceStrictness = r?.attendanceStrictness ?? 3.0;
    _workloadLevel = r?.workloadLevel ?? 'manageable';
    _slideReliance = r?.slideReliance ?? 'slides_with_whiteboard';
    _quizFrequency = r?.quizFrequency ?? 'bi_weekly';

    // Parse existing quiz structure or set standard EWU defaults (4 quizzes, Best N-1)
    final existingQuiz = r?.quizFrequency ?? '';
    if (existingQuiz.contains('best_1') || existingQuiz.contains('Best 1')) {
      _quizGradingStyle = 'best_1';
    } else if (existingQuiz.contains('average_all') || existingQuiz.contains('Average of All')) {
      _quizGradingStyle = 'average_all';
    } else if (existingQuiz.contains('sum_all') || existingQuiz.contains('Sum of All')) {
      _quizGradingStyle = 'sum_all';
    } else {
      _quizGradingStyle = 'best_n_minus_1';
    }

    if (existingQuiz.startsWith('0') || existingQuiz.toLowerCase() == 'none' || existingQuiz.toLowerCase() == 'no quizzes') {
      _quizCount = '0';
    } else if (existingQuiz.startsWith('1')) {
      _quizCount = '1';
    } else if (existingQuiz.startsWith('2')) {
      _quizCount = '2';
    } else if (existingQuiz.startsWith('3')) {
      _quizCount = '3';
    } else if (existingQuiz.startsWith('5')) {
      _quizCount = '5';
    } else if (existingQuiz.startsWith('6')) {
      _quizCount = '6+';
    } else {
      _quizCount = '4';
    }

    if (r?.quizFrequency != null && r!.quizFrequency.isNotEmpty && !r.quizFrequency.startsWith('bi_weekly')) {
      _quizFrequency = r.quizFrequency;
    } else {
      _syncQuizFrequency();
    }

    _textbookNeed = r?.textbookNeed ?? 'supplementary';
    _wouldTakeAgain = r?.wouldTakeAgain ?? true;
    _selectedTraits = Set<String>.from(r?.traits ?? []);
  }

  @override
  void dispose() {
    _examTipsController.dispose();
    _reviewNoteController.dispose();
    super.dispose();
  }

  void _openCoursePicker(BuildContext context, List<Map<String, String>> courses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _CourseSearchModal(
          courses: courses,
          selectedCourseCode: _selectedCourseCode,
          onSelected: (code, name) {
            setState(() {
              _selectedCourseCode = code;
              _selectedCourseName = name;
              _courseValidationError = null;
            });
          },
        );
      },
    );
  }

  void _openSemesterPicker(BuildContext context, List<Map<String, dynamic>> semesters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _SemesterSearchModal(
          semesters: semesters,
          selectedSemesterTitle: _selectedSemesterTitle,
          onSelected: (code, title) {
            setState(() {
              _selectedSemesterTitle = title;
              _selectedSemesterCode = code;
            });
          },
        );
      },
    );
  }

  String _getBestNMinusOneLabel(String count) {
    if (count == '2') return 'Best 1 of 2 (Best N-1)';
    if (count == '3') return 'Best 2 of 3 (Best N-1)';
    if (count == '4') return 'Best 3 of 4 (Best N-1)';
    if (count == '5') return 'Best 4 of 5 (Best N-1)';
    return 'Average of Best (N-1) of N';
  }

  void _syncQuizFrequency() {
    if (_quizCount == '0') {
      _quizFrequency = 'No Quizzes';
      return;
    }
    if (_quizCount == '1') {
      _quizFrequency = '1 Quiz • Counted Directly';
      return;
    }

    String styleText;
    switch (_quizGradingStyle) {
      case 'best_n_minus_1':
        styleText = _getBestNMinusOneLabel(_quizCount);
        break;
      case 'best_1':
        styleText = 'Best 1 of $_quizCount';
        break;
      case 'average_all':
        styleText = 'Average of All';
        break;
      case 'sum_all':
        styleText = 'Sum of All';
        break;
      default:
        styleText = 'Average of Best (N-1) of N';
    }

    _quizFrequency = '$_quizCount Quizzes • $styleText';
  }

  Future<void> _submit() async {
    if (_selectedCourseCode == null || _selectedCourseCode!.trim().isEmpty) {
      setState(() {
        _courseValidationError = 'Please select a course from the dropdown catalog';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a course from the catalog.', style: GoogleFonts.sora(color: Colors.white)),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(facultyReviewsRepositoryProvider);
      final review = FacultyReview(
        id: widget.existingReview?.id ?? '',
        userId: '',
        facultyInitials: widget.facultyInitials.toUpperCase(),
        facultyName: widget.facultyName,
        courseCode: _selectedCourseCode!.trim().toUpperCase(),
        semester: _selectedSemesterTitle,
        semesterCode: _selectedSemesterCode,
        status: 'pending',
        deliveryType: _deliveryType,
        gradeReceived: _gradeReceived == 'Prefer not to say' ? null : _gradeReceived,
        clarityRating: _clarityRating,
        gradingFairness: _gradingFairness,
        examAlignment: _examAlignment,
        officeHoursAccessibility: _officeHoursAccessibility,
        attendanceStrictness: _attendanceStrictness,
        workloadLevel: _workloadLevel,
        slideReliance: _slideReliance,
        quizFrequency: _quizFrequency,
        textbookNeed: _textbookNeed,
        traits: _selectedTraits.toList(),
        examPrepTips: _examTipsController.text.trim().isEmpty ? null : _examTipsController.text.trim(),
        reviewNote: _reviewNoteController.text.trim().isEmpty ? null : _reviewNoteController.text.trim(),
        wouldTakeAgain: _wouldTakeAgain,
        createdAt: widget.existingReview?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingReview != null) {
        await repo.resubmitReview(review);
      } else {
        await repo.submitReview(review);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.existingReview != null
                        ? (widget.existingReview!.status == 'rejected'
                            ? 'Revised evaluation resubmitted for moderation!'
                            : 'Evaluation updated & resubmitted for review!')
                        : 'Evaluation submitted for moderation!',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D2342),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission error: $e', style: GoogleFonts.sora(color: Colors.white)),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSliderField({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.sora(fontSize: 11, color: Colors.white54)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup<T>({
    required String label,
    required List<Map<String, dynamic>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final val = opt['value'] as T;
              final isSelected = val == selectedValue;
              return InkWell(
                onTap: () => onSelected(val),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt['label'] as String,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.cyanAccent : Colors.white70,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesCatalogProvider);
    final semestersAsync = ref.watch(allSemestersListProvider);

    // Auto-resolve course title if not set yet
    if (_selectedCourseCode != null && _selectedCourseName == null && coursesAsync.hasValue) {
      final courses = coursesAsync.value;
      if (courses != null) {
        for (final c in courses) {
          if (c['code'] == _selectedCourseCode) {
            final courseName = c['name'];
            if (courseName != null && courseName.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedCourseName == null) {
                  setState(() => _selectedCourseName = courseName);
                }
              });
            }
            break;
          }
        }
      }
    }

    // Auto-resolve semesterCode if not set yet
    if (_selectedSemesterCode == null && semestersAsync.hasValue) {
      final semesters = semestersAsync.value;
      if (semesters != null) {
        final targetTitle = _selectedSemesterTitle.trim().toLowerCase();
        final targetNoSpace = _selectedSemesterTitle.replaceAll(' ', '').toLowerCase();
        for (final s in semesters) {
          final title = (s['title'] ?? '').toString().trim().toLowerCase();
          final code = (s['code'] ?? '').toString().trim().toLowerCase();
          if (title == targetTitle || code == targetNoSpace) {
            final codeVal = s['code']?.toString();
            if (codeVal != null && codeVal.isNotEmpty) {
              _selectedSemesterCode = codeVal;
            }
            break;
          }
        }
      }
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: screenHeight * 0.90,
        decoration: const BoxDecoration(
          color: Color(0xFF08192E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 10),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existingReview != null
                            ? (widget.existingReview!.status == 'rejected'
                                ? 'Edit & Resubmit Evaluation'
                                : 'Edit Evaluation')
                            : 'Rigorous Faculty Review',
                        style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'For ${widget.facultyInitials}',
                            style: GoogleFonts.sora(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 11, color: Colors.greenAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '100% Anonymous',
                                  style: GoogleFonts.sora(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.white10),

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Anonymity & Moderation Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Colors.cyanAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '100% Anonymous: Your name and student ID are strictly hidden from peers & faculty. Reviews are moderated to prevent harassment and ensure honest academic guidance.',
                                style: GoogleFonts.sora(fontSize: 11, color: Colors.white70, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // If editing a rejected review, show moderator rejection reason
                      if (widget.existingReview?.status == 'rejected') ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PREVIOUS REJECTION REASON',
                                    style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.redAccent, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.existingReview?.adminRejectionNote?.isNotEmpty == true
                                    ? widget.existingReview!.adminRejectionNote!
                                    : 'Your review was rejected by moderator guidelines. Please make necessary revisions and resubmit.',
                                style: GoogleFonts.sora(fontSize: 12, color: Colors.white, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],

                    // Course Selector Card (Searchable Dropdown)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'COURSE CODE & TITLE *',
                                style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.8),
                              ),
                              if (coursesAsync.isLoading)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              final courses = coursesAsync.value ?? [];
                              _openCoursePicker(context, courses);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _courseValidationError != null
                                      ? Colors.redAccent
                                      : (_selectedCourseCode != null ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1)),
                                  width: _selectedCourseCode != null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.school_rounded, color: Colors.cyanAccent, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_selectedCourseCode != null && _selectedCourseCode!.isNotEmpty) ...[
                                          Text(
                                            _selectedCourseCode!,
                                            style: GoogleFonts.sora(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.cyanAccent,
                                            ),
                                          ),
                                          if (_selectedCourseName != null && _selectedCourseName!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              _selectedCourseName!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.sora(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ] else ...[
                                          Text(
                                            'Tap to search & select course (e.g. CSE106)',
                                            style: GoogleFonts.sora(
                                              fontSize: 13,
                                              color: Colors.white38,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.search_rounded,
                                    color: _selectedCourseCode != null ? Colors.cyanAccent : Colors.white38,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_courseValidationError != null) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                _courseValidationError!,
                                style: GoogleFonts.sora(fontSize: 11, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Semester Selector Card (Searchable Dropdown)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SEMESTER *',
                                style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.8),
                              ),
                              if (semestersAsync.isLoading)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              final semesters = semestersAsync.value ?? [];
                              _openSemesterPicker(context, semesters);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_today_rounded, color: Colors.amberAccent, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedSemesterTitle,
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Type & Grade
                    _buildRadioGroup<String>(
                      label: 'Course Delivery Type',
                      options: const [
                        {'label': 'Theory', 'value': 'theory'},
                        {'label': 'Lab', 'value': 'lab'},
                        {'label': 'Both (Integrated)', 'value': 'both'},
                      ],
                      selectedValue: _deliveryType,
                      onSelected: (v) => setState(() => _deliveryType = v),
                    ),

                    // Optional Grade Received
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GRADE RECEIVED (ANONYMOUS OPTIONAL)',
                            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _gradeReceived,
                            dropdownColor: const Color(0xFF0F2642),
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                            hint: Text('Select grade or leave empty', style: GoogleFonts.sora(color: Colors.white38, fontSize: 12)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                            ),
                            items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (v) => setState(() => _gradeReceived = v),
                          ),
                        ],
                      ),
                    ),

                    // 5 Academic Sliders
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'ACADEMIC RATINGS (1.0 TO 5.0)',
                        style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.cyanAccent, letterSpacing: 1.0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildSliderField(
                      title: 'Teaching Clarity',
                      subtitle: 'How effectively does the faculty explain concepts?',
                      value: _clarityRating,
                      onChanged: (v) => setState(() => _clarityRating = v),
                    ),

                    _buildSliderField(
                      title: 'Grading Fairness & Transparency',
                      subtitle: 'Is grading objective and aligned with rubrics?',
                      value: _gradingFairness,
                      onChanged: (v) => setState(() => _gradingFairness = v),
                    ),

                    _buildSliderField(
                      title: 'Exam Alignment with Lectures',
                      subtitle: 'Did midterm and final exams reflect taught material?',
                      value: _examAlignment,
                      onChanged: (v) => setState(() => _examAlignment = v),
                    ),

                    _buildSliderField(
                      title: 'Office Hours Accessibility',
                      subtitle: 'How welcoming and available are they for doubts?',
                      value: _officeHoursAccessibility,
                      onChanged: (v) => setState(() => _officeHoursAccessibility = v),
                    ),

                    _buildSliderField(
                      title: 'Attendance Strictness',
                      subtitle: '1 = Relaxed, 5 = Very strict on timings & presence',
                      value: _attendanceStrictness,
                      onChanged: (v) => setState(() => _attendanceStrictness = v),
                    ),

                    const SizedBox(height: 10),

                    // Practical Dynamics
                    _buildRadioGroup<String>(
                      label: 'Workload Level',
                      options: const [
                        {'label': 'Light', 'value': 'light'},
                        {'label': 'Manageable', 'value': 'manageable'},
                        {'label': 'Heavy', 'value': 'heavy'},
                        {'label': 'Overwhelming', 'value': 'overwhelming'},
                      ],
                      selectedValue: _workloadLevel,
                      onSelected: (v) => setState(() => _workloadLevel = v),
                    ),

                    _buildRadioGroup<String>(
                      label: 'Teaching Style / Slide Reliance',
                      options: const [
                        {'label': 'Pure Slides', 'value': 'pure_slides'},
                        {'label': 'Slides + Whiteboard', 'value': 'slides_with_whiteboard'},
                        {'label': 'Board & Discussion', 'value': 'whiteboard_discussion_heavy'},
                        {'label': 'Hands-on Coding', 'value': 'hands_on_coding'},
                      ],
                      selectedValue: _slideReliance,
                      onSelected: (v) => setState(() => _slideReliance = v),
                    ),

                    // Quiz Assessment Policy Card (Number of Quizzes + Grading Style)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.quiz_rounded, color: Colors.cyanAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'QUIZ ASSESSMENT POLICY',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.cyanAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 1. Number of Quizzes (N)
                          Text(
                            'NUMBER OF QUIZZES (N)',
                            style: GoogleFonts.sora(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white54,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              {'label': '0 (None)', 'value': '0'},
                              {'label': '1', 'value': '1'},
                              {'label': '2', 'value': '2'},
                              {'label': '3', 'value': '3'},
                              {'label': '4', 'value': '4'},
                              {'label': '5', 'value': '5'},
                              {'label': '6+', 'value': '6+'},
                            ].map((opt) {
                              final isSelected = _quizCount == opt['value'];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _quizCount = opt['value']!;
                                    _syncQuizFrequency();
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.08),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    opt['label']!,
                                    style: GoogleFonts.sora(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.cyanAccent : Colors.white70,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // 2. Grading Style (Only if N >= 2)
                          if (_quizCount != '0' && _quizCount != '1') ...[
                            const SizedBox(height: 14),
                            Text(
                              'GRADING STYLE / CRITERIA',
                              style: GoogleFonts.sora(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                {
                                  'label': _getBestNMinusOneLabel(_quizCount),
                                  'value': 'best_n_minus_1',
                                },
                                {
                                  'label': 'Best 1 (Highest Score)',
                                  'value': 'best_1',
                                },
                                {
                                  'label': 'Average of All',
                                  'value': 'average_all',
                                },
                                {
                                  'label': 'Sum of All (Cumulative)',
                                  'value': 'sum_all',
                                },
                              ].map((opt) {
                                final isSelected = _quizGradingStyle == opt['value'];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _quizGradingStyle = opt['value']!;
                                      _syncQuizFrequency();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.cyanAccent.withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.08),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      opt['label']!,
                                      style: GoogleFonts.sora(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.cyanAccent : Colors.white70,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 12),
                          // Summary badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 13),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Selected: $_quizFrequency',
                                    style: GoogleFonts.sora(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.cyanAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildRadioGroup<String>(
                      label: 'Textbook Requirement',
                      options: const [
                        {'label': 'Mandatory', 'value': 'mandatory'},
                        {'label': 'Supplementary', 'value': 'supplementary'},
                        {'label': 'Not Required', 'value': 'not_required'},
                      ],
                      selectedValue: _textbookNeed,
                      onSelected: (v) => setState(() => _textbookNeed = v),
                    ),

                    // Would take again toggle
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Would you take this faculty again?',
                                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _wouldTakeAgain ? 'Yes, recommended' : 'No, would avoid',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: _wouldTakeAgain ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _wouldTakeAgain,
                            activeTrackColor: Colors.cyanAccent,
                            onChanged: (v) => setState(() => _wouldTakeAgain = v),
                          ),
                        ],
                      ),
                    ),

                    // Traits multi-select
                    Text(
                      'TAGS & TRAITS (SELECT APPLICABLE)',
                      style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTraits.map((t) {
                        final isSelected = _selectedTraits.contains(t);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            '#$t',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.cyanAccent : Colors.white70,
                            ),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          selectedColor: Colors.cyanAccent.withValues(alpha: 0.18),
                          checkmarkColor: Colors.cyanAccent,
                          side: BorderSide(
                            color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTraits.add(t);
                              } else {
                                _selectedTraits.remove(t);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Exam Prep Tips
                    TextFormField(
                      controller: _examTipsController,
                      maxLines: 3,
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Exam Preparation & Survival Advice',
                        labelStyle: GoogleFonts.sora(color: Colors.amberAccent, fontSize: 12),
                        hintText: 'e.g. Focus on class slides for midterms, practice previous year question banks, do chapter 4 and 6 thoroughly...',
                        hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.amberAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student Review Note
                    TextFormField(
                      controller: _reviewNoteController,
                      maxLines: 4,
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'General Review & Feedback Note',
                        labelStyle: GoogleFonts.sora(color: Colors.cyanAccent, fontSize: 12),
                        hintText: 'Share your genuine experience with this faculty to help junior peers choose wisely...',
                        hintStyle: GoogleFonts.sora(color: Colors.white24, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.cyanAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: const Color(0xFF071426),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                          shadowColor: Colors.cyanAccent.withValues(alpha: 0.4),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF071426)),
                              )
                            : Text(
                                widget.existingReview != null
                                    ? (widget.existingReview!.status == 'rejected'
                                        ? 'Resubmit Evaluation'
                                        : 'Update Evaluation')
                                    : 'Submit Evaluation for Approval',
                                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _CourseSearchModal extends StatefulWidget {
  final List<Map<String, String>> courses;
  final String? selectedCourseCode;
  final Function(String code, String name) onSelected;

  const _CourseSearchModal({
    required this.courses,
    required this.selectedCourseCode,
    required this.onSelected,
  });

  @override
  State<_CourseSearchModal> createState() => _CourseSearchModalState();
}

class _CourseSearchModalState extends State<_CourseSearchModal> {
  late TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.courses
        : widget.courses.where((c) {
            final code = (c['code'] ?? '').toLowerCase();
            final name = (c['name'] ?? '').toLowerCase();
            return code.contains(_query) || name.contains(_query);
          }).toList();

    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: screenHeight * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF08192E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 25, spreadRadius: 5),
          ],
        ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Course',
                      style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EWU Course Catalog (${widget.courses.length} courses)',
                      style: GoogleFonts.sora(fontSize: 12, color: Colors.cyanAccent),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by course code or title (e.g. CSE106)...',
                hintStyle: GoogleFonts.sora(color: Colors.white30, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white10),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, color: Colors.white24, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            'No courses found matching "$_query"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(fontSize: 13, color: Colors.white60),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for CSE106 or ACT101',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(fontSize: 11, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      final code = c['code'] ?? '';
                      final name = c['name'] ?? '';
                      final isSelected = widget.selectedCourseCode == code;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.cyanAccent.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.cyanAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () {
                            widget.onSelected(code, name);
                            Navigator.of(context).pop();
                          },
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.cyanAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              code,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF071426) : Colors.cyanAccent,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
  }
}

class _SemesterSearchModal extends StatefulWidget {
  final List<Map<String, dynamic>> semesters;
  final String selectedSemesterTitle;
  final Function(String code, String title) onSelected;

  const _SemesterSearchModal({
    required this.semesters,
    required this.selectedSemesterTitle,
    required this.onSelected,
  });

  @override
  State<_SemesterSearchModal> createState() => _SemesterSearchModalState();
}

class _SemesterSearchModalState extends State<_SemesterSearchModal> {
  late TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.semesters
        : widget.semesters.where((s) {
            final title = (s['title'] ?? '').toString().toLowerCase();
            final code = (s['code'] ?? '').toString().toLowerCase();
            return title.contains(_query) || code.contains(_query);
          }).toList();

    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: screenHeight * 0.70,
        decoration: const BoxDecoration(
          color: Color(0xFF08192E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 25, spreadRadius: 5),
          ],
        ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Semester',
                      style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose semester when you completed the course',
                      style: GoogleFonts.sora(fontSize: 12, color: Colors.amberAccent),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Filter semester (e.g. Summer 2026)...',
                hintStyle: GoogleFonts.sora(color: Colors.white30, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.amberAccent, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.amberAccent),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white10),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No semesters found matching "$_query"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(fontSize: 13, color: Colors.white60),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      final code = (s['code'] ?? '').toString();
                      final title = (s['title'] ?? '').toString();
                      final isActive = s['is_active'] == true;
                      final isSelected = widget.selectedSemesterTitle.toLowerCase() == title.toLowerCase();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amberAccent.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amberAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () {
                            widget.onSelected(code, title);
                            Navigator.of(context).pop();
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amberAccent
                                  : Colors.amberAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: isSelected ? const Color(0xFF071426) : Colors.amberAccent,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: GoogleFonts.sora(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Colors.amberAccent, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
  }
}
