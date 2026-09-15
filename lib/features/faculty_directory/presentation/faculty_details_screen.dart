import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/faculty.dart';
import '../../../core/models/faculty_office_hour.dart';
import '../../../core/repositories/office_hours_repository.dart';
import '../../../core/providers/academic_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import 'widgets/submit_office_hours_sheet.dart';
import 'widgets/details/faculty_hero_card.dart';
import 'widgets/details/faculty_about_tab.dart';
import 'widgets/details/faculty_courses_tab.dart';
import 'widgets/details/faculty_office_hours_tab.dart';
import 'widgets/details/faculty_contact_tab.dart';
import 'widgets/details/faculty_bottom_bar.dart';

// Riverpod Provider to fetch approved office hours for the active semester
final approvedOfficeHoursProvider = FutureProvider.family<List<FacultyOfficeHour>, String>((ref, initials) async {
  final activeSemester = ref.watch(academicStateProvider).value;
  final semesterCode = activeSemester?.currentSemesterCode ?? 'Summer 2026';
  return ref.watch(officeHoursRepositoryProvider).getApprovedOfficeHours(initials, semesterCode);
});

class FacultyDetailsScreen extends ConsumerStatefulWidget {
  final Faculty faculty;

  const FacultyDetailsScreen({
    super.key,
    required this.faculty,
  });

  @override
  ConsumerState<FacultyDetailsScreen> createState() => _FacultyDetailsScreenState();
}

class _FacultyDetailsScreenState extends ConsumerState<FacultyDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyEmail(BuildContext context, String email) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primaryCyan, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email copied: $email',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D2342),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
        ),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSubmitOfficeHoursSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SubmitOfficeHoursSheet(
          facultyInitials: widget.faculty.shortName,
        );
      },
    ).then((success) {
      if (success == true) {
        ref.invalidate(approvedOfficeHoursProvider(widget.faculty.shortName));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final photoUrl = widget.faculty.photoUrl;
    final isLiveUrl = photoUrl != null && photoUrl.startsWith('http');
    debugPrint('🔍 FACULTY PHOTO DEBUG: initials=${widget.faculty.shortName}, name=${widget.faculty.fullName}, photoUrl="$photoUrl", isLiveUrl=$isLiveUrl');
    final activeSemesterAsync = ref.watch(academicStateProvider);

    return FullGradientScaffold(
      appBar: EWUmateAppBar(
        title: 'Faculty Details',
        showBack: true,
        actions: [
          if (widget.faculty.profileUrl != null && widget.faculty.profileUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.public_rounded, color: AppColors.primaryCyan),
              onPressed: () => _launchUrl(widget.faculty.profileUrl!),
              tooltip: 'Official Web Profile',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: FacultyHeroCard(
                        faculty: widget.faculty,
                        colors: colors,
                        isLiveUrl: isLiveUrl,
                        photoUrl: photoUrl,
                        onSendEmail: _launchEmail,
                        onCopyEmail: (email) => _copyEmail(context, email),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primaryCyan,
                        indicatorWeight: 3.0,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: AppColors.primaryCyan,
                        unselectedLabelColor: colors.textTertiary,
                        labelStyle: GoogleFonts.sora(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: GoogleFonts.sora(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'About'),
                          Tab(text: 'Courses'),
                          Tab(text: 'Office Hours'),
                          Tab(text: 'Contact'),
                        ],
                      ),
                      backgroundColor: colors.surfaceNavyBlue,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: About
                  FacultyAboutTab(
                    faculty: widget.faculty,
                    colors: colors,
                    onOpenUrl: _launchUrl,
                  ),

                  // TAB 2: Class Schedule (Courses)
                  FacultyCoursesTab(
                    facultyShortName: widget.faculty.shortName,
                    activeSemesterAsync: activeSemesterAsync,
                  ),

                  // TAB 3: Office Hours
                  FacultyOfficeHoursTab(
                    officeHoursAsync: ref.watch(approvedOfficeHoursProvider(widget.faculty.shortName)),
                    onAddOfficeHours: () => _showSubmitOfficeHoursSheet(context),
                    onOpenUrl: _launchUrl,
                  ),

                  // TAB 4: Contact (Strictly zero mobile phone numbers)
                  FacultyContactTab(
                    faculty: widget.faculty,
                    colors: colors,
                    onSendEmail: _launchEmail,
                    onOpenUrl: _launchUrl,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sticky "Copy Email" Action
          if (widget.faculty.email != null && widget.faculty.email!.isNotEmpty)
            FacultyBottomBar(
              onCopyEmail: () => _copyEmail(context, widget.faculty.email!),
            ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}
