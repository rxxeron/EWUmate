import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/models/faculty.dart';
import '../../../../../core/models/faculty_review.dart';
import '../../../../../core/providers/supabase_provider.dart';
import '../../../../../core/repositories/faculty_reviews_repository.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/ewu_theme_extension.dart';
import '../submit_faculty_review_sheet.dart';

// Riverpod provider for approved reviews of this faculty
final facultyApprovedReviewsProvider =
    FutureProvider.family<List<FacultyReview>, String>((ref, initials) async {
  return ref.watch(facultyReviewsRepositoryProvider).getApprovedReviews(initials);
});

// Riverpod provider for current user's reviews for this faculty
final facultyMyReviewsProvider =
    FutureProvider.family<List<FacultyReview>, String>((ref, initials) async {
  return ref.watch(facultyReviewsRepositoryProvider).getUserReviewsForFaculty(initials);
});

class FacultyReviewsTab extends ConsumerStatefulWidget {
  final Faculty faculty;
  final EwuColors colors;
  final String currentSemester;

  const FacultyReviewsTab({
    super.key,
    required this.faculty,
    required this.colors,
    required this.currentSemester,
  });

  @override
  ConsumerState<FacultyReviewsTab> createState() => _FacultyReviewsTabState();
}

class _FacultyReviewsTabState extends ConsumerState<FacultyReviewsTab> {
  String _selectedCourseFilter = 'ALL';

  void _openSubmitSheet(BuildContext context, [FacultyReview? existing]) {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in to submit a review.',
            style: GoogleFonts.sora(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0D2342),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Auto-detect existing review if not explicitly provided to enforce one evaluation per student
    FacultyReview? targetReview = existing;
    if (targetReview == null) {
      final myReviews = ref.read(facultyMyReviewsProvider(widget.faculty.shortName)).value;
      if (myReviews != null && myReviews.isNotEmpty) {
        targetReview = myReviews.first;
      }
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitFacultyReviewSheet(
        facultyInitials: widget.faculty.shortName,
        facultyName: widget.faculty.fullName,
        currentSemester: widget.currentSemester,
        existingReview: targetReview,
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(facultyApprovedReviewsProvider(widget.faculty.shortName));
        ref.invalidate(facultyMyReviewsProvider(widget.faculty.shortName));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final approvedAsync = ref.watch(facultyApprovedReviewsProvider(widget.faculty.shortName));
    final myReviewsAsync = ref.watch(facultyMyReviewsProvider(widget.faculty.shortName));

    return RefreshIndicator(
      color: AppColors.primaryCyan,
      backgroundColor: const Color(0xFF0A1E38),
      onRefresh: () async {
        ref.invalidate(facultyApprovedReviewsProvider(widget.faculty.shortName));
        ref.invalidate(facultyMyReviewsProvider(widget.faculty.shortName));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User's own review cards (Pending, Rejected, or Approved)
            myReviewsAsync.when(
              data: (myReviews) {
                if (myReviews.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR SUBMISSIONS',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.cyanAccent,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...myReviews.map((r) => _buildMyReviewCard(context, r)),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Approved Reviews Section
            approvedAsync.when(
              data: (reviews) {
                final myReviews = myReviewsAsync.value ?? [];
                final myReview = myReviews.isNotEmpty ? myReviews.first : null;

                if (reviews.isEmpty) {
                  return _buildEmptyState(context, myReview);
                }

                final distinctCourses = [
                  'ALL',
                  ...reviews.map((r) => r.courseCode.toUpperCase()).toSet().toList()..sort()
                ];

                final displayedReviews = _selectedCourseFilter == 'ALL'
                    ? reviews
                    : reviews.where((r) => r.courseCode.toUpperCase() == _selectedCourseFilter).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aggregate Scorecard (Overall or Course-specific)
                    _buildAggregateScorecard(displayedReviews, _selectedCourseFilter),
                    const SizedBox(height: 16),

                    // Course Filter Pills (if multiple courses available)
                    if (distinctCourses.length > 2) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: distinctCourses.map((c) {
                            final isSelected = _selectedCourseFilter == c;
                            final count = c == 'ALL'
                                ? reviews.length
                                : reviews.where((r) => r.courseCode.toUpperCase() == c).length;
                            final label = c == 'ALL' ? 'All Courses ($count)' : '$c ($count)';

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _selectedCourseFilter = c),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.cyanAccent.withValues(alpha: 0.18)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.cyanAccent
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(Icons.check_rounded, color: Colors.cyanAccent, size: 14),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        label,
                                        style: GoogleFonts.sora(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.cyanAccent : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // "Write Review" / "Edit Review" bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STUDENT EVALUATIONS (${displayedReviews.length})',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openSubmitSheet(context, myReview),
                          icon: Icon(
                            myReview != null
                                ? (myReview.status == 'rejected' ? Icons.replay_rounded : Icons.edit_note_rounded)
                                : Icons.rate_review_rounded,
                            size: 16,
                            color: myReview != null && myReview.status == 'rejected'
                                ? Colors.redAccent
                                : Colors.cyanAccent,
                          ),
                          label: Text(
                            myReview != null
                                ? (myReview.status == 'rejected' ? 'Edit & Resubmit' : 'Edit Your Evaluation')
                                : 'Add Evaluation',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: myReview != null && myReview.status == 'rejected'
                                  ? Colors.redAccent
                                  : Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List of approved individual reviews
                    ...displayedReviews.map((r) => _buildReviewCard(r)),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppColors.primaryCyan),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Failed to load evaluations.',
                    style: GoogleFonts.sora(color: Colors.white60),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Aggregate scorecard card (Overall or Course-specific)
  Widget _buildAggregateScorecard(List<FacultyReview> reviews, String filterCourse) {
    final count = reviews.length;
    if (count == 0) return const SizedBox.shrink();

    final avgRating = reviews.map((r) => r.averageRating).reduce((a, b) => a + b) / count;
    final avgClarity = reviews.map((r) => r.clarityRating).reduce((a, b) => a + b) / count;
    final avgFairness = reviews.map((r) => r.gradingFairness).reduce((a, b) => a + b) / count;
    final avgAlignment = reviews.map((r) => r.examAlignment).reduce((a, b) => a + b) / count;
    final avgOffice = reviews.map((r) => r.officeHoursAccessibility).reduce((a, b) => a + b) / count;
    final avgAttendance = reviews.map((r) => r.attendanceStrictness).reduce((a, b) => a + b) / count;

    final wouldTakeCount = reviews.where((r) => r.wouldTakeAgain).length;
    final retakePct = ((wouldTakeCount / count) * 100).round();

    // Collect top traits
    final traitFreq = <String, int>{};
    for (var r in reviews) {
      for (var t in r.traits) {
        traitFreq[t] = (traitFreq[t] ?? 0) + 1;
      }
    }
    final topTraits = traitFreq.keys.toList()
      ..sort((a, b) => traitFreq[b]!.compareTo(traitFreq[a]!));

    final title = filterCourse == 'ALL'
        ? 'OVERALL FACULTY SCORECARD'
        : '$filterCourse COURSE SCORECARD';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C223E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.cyanAccent,
                  letterSpacing: 1.0,
                ),
              ),
              if (filterCourse != 'ALL')
                InkWell(
                  onTap: () => setState(() => _selectedCourseFilter = 'ALL'),
                  child: Text(
                    'Reset Filter',
                    style: GoogleFonts.sora(fontSize: 10, color: Colors.white38, decoration: TextDecoration.underline),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Header summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: GoogleFonts.sora(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'out of 5.0',
                      style: GoogleFonts.sora(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$retakePct% Would Take Again',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: retakePct >= 60 ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Based on $count approved student course evaluation${count > 1 ? 's' : ''}.',
                      style: GoogleFonts.sora(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 14),

          // 5 Metrics Bar Breakdown
          _buildScoreBar('Teaching Clarity', avgClarity),
          _buildScoreBar('Grading Fairness', avgFairness),
          _buildScoreBar('Exam Alignment', avgAlignment),
          _buildScoreBar('Office Hours Helpfulness', avgOffice),
          _buildScoreBar('Attendance Strictness', avgAttendance),

          if (topTraits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topTraits.take(5).map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '#$t',
                    style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.cyanAccent),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: GoogleFonts.sora(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (score / 5.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 4.0
                      ? Colors.cyanAccent
                      : score >= 3.0
                          ? Colors.amberAccent
                          : Colors.redAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 26,
            child: Text(
              score.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, double val) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.sora(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 0.3),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val.toStringAsFixed(1),
              style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 1),
            const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 11),
          ],
        ),
      ],
    );
  }

  // User's own submission card (displays status + rejection note + edit button)
  Widget _buildMyReviewCard(BuildContext context, FacultyReview review) {
    final isPending = review.status == 'pending';
    final isRejected = review.status == 'rejected';

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (isPending) {
      statusColor = Colors.amberAccent;
      statusTitle = 'Submitted • Pending Moderation';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isRejected) {
      statusColor = Colors.redAccent;
      statusTitle = 'Action Required • Evaluation Rejected';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.greenAccent;
      statusTitle = 'Published & Live';
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusTitle,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  review.courseCode,
                  style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),

          // If rejected, show admin rejection reason prominently
          if (isRejected) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'REJECTION REASON',
                        style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.redAccent, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    review.adminRejectionNote?.isNotEmpty == true
                        ? review.adminRejectionNote!
                        : 'Your evaluation was rejected by moderator guidelines. Please click "Edit & Resubmit" below to revise and submit again.',
                    style: GoogleFonts.sora(fontSize: 12, color: Colors.white, height: 1.35),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted: ${review.semester}',
                style: GoogleFonts.sora(fontSize: 11, color: Colors.white54),
              ),
              TextButton.icon(
                onPressed: () => _openSubmitSheet(context, review),
                icon: Icon(
                  isRejected ? Icons.replay_rounded : Icons.edit_note_rounded,
                  size: 16,
                  color: isRejected ? Colors.redAccent : Colors.cyanAccent,
                ),
                label: Text(
                  isRejected ? 'Edit & Resubmit' : 'Edit Review',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isRejected ? Colors.redAccent : Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Public approved individual review card
  Widget _buildReviewCard(FacultyReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1E38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Course + Semester + Grade + Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      review.courseCode,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review.semester,
                    style: GoogleFonts.sora(fontSize: 11, color: Colors.white54),
                  ),
                  if (review.gradeReceived != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Grade: ${review.gradeReceived}',
                        style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 3),
                  Text(
                    review.averageRating.toStringAsFixed(1),
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                  ),
                  Text(
                    ' /5',
                    style: GoogleFonts.sora(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Individual 5-Dimension Ratings Breakdown Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniMetric('Clarity', review.clarityRating),
                _buildMiniMetric('Fairness', review.gradingFairness),
                _buildMiniMetric('Exam Match', review.examAlignment),
                _buildMiniMetric('Office Hours', review.officeHoursAccessibility),
                _buildMiniMetric('Strictness', review.attendanceStrictness),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Operational traits chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge(review.deliveryType.toUpperCase(), Colors.white60),
              _buildBadge('Workload: ${_formatAttr(review.workloadLevel)}', Colors.white60),
              _buildBadge('Style: ${_formatAttr(review.slideReliance)}', Colors.white60),
              _buildBadge(review.quizFrequency.contains('Quiz') ? review.quizFrequency : 'Quizzes: ${_formatAttr(review.quizFrequency)}', Colors.white60),
              if (review.wouldTakeAgain)
                _buildBadge('Would retake ✓', Colors.greenAccent)
              else
                _buildBadge("Wouldn't retake ✗", Colors.redAccent),
            ],
          ),

          // Tags
          if (review.traits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.traits.map((t) {
                return Text(
                  '#$t',
                  style: GoogleFonts.sora(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ],

          // Review Note
          if (review.reviewNote != null && review.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                '“${review.reviewNote}”',
                style: GoogleFonts.sora(fontSize: 12, color: Colors.white, height: 1.4, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          // Exam Preparation Advice
          if (review.examPrepTips != null && review.examPrepTips!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Exam Prep & Survival Advice',
                        style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.examPrepTips!,
                    style: GoogleFonts.sora(fontSize: 11, color: Colors.white, height: 1.35),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Verified Student Evaluation • Anonymous',
            style: GoogleFonts.sora(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatAttr(String s) {
    if (s.contains('•') || s.contains('Quizzes') || s.contains('Quiz')) {
      return s;
    }
    return s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Widget _buildEmptyState(BuildContext context, [FacultyReview? myReview]) {
    final hasMyReview = myReview != null;
    final isRejected = myReview?.status == 'rejected';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isRejected ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected ? Icons.warning_amber_rounded : Icons.rate_review_outlined,
                color: isRejected ? Colors.redAccent : Colors.cyanAccent,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasMyReview
                  ? (isRejected ? 'Action Required on Your Review' : 'Your Evaluation is Recorded')
                  : 'No Evaluations Yet',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              hasMyReview
                  ? (isRejected
                      ? 'Your evaluation for ${widget.faculty.shortName} was rejected. Please review the moderator feedback above and edit/resubmit.'
                      : 'You have submitted an evaluation for ${widget.faculty.shortName}. Once approved by moderators, it will be published here.')
                  : 'Be the first student to review ${widget.faculty.shortName}!\nHelp your fellow peers with exam advice & clarity insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(fontSize: 12, color: Colors.white54, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openSubmitSheet(context, myReview),
              icon: Icon(
                hasMyReview
                    ? (isRejected ? Icons.replay_rounded : Icons.edit_note_rounded)
                    : Icons.add_rounded,
                size: 18,
              ),
              label: Text(
                hasMyReview
                    ? (isRejected ? 'Edit & Resubmit' : 'Edit Your Evaluation')
                    : 'Write First Review',
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRejected ? Colors.redAccent : Colors.cyanAccent,
                foregroundColor: isRejected ? Colors.white : const Color(0xFF071426),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
