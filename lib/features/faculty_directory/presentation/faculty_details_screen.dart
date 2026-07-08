import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/faculty.dart';
import '../../../core/models/faculty_office_hour.dart';
import '../../../core/models/course_section.dart';
import '../../../core/repositories/faculty_repository.dart';
import '../../../core/repositories/office_hours_repository.dart';
import '../../../core/providers/academic_providers.dart';
import 'widgets/submit_office_hours_sheet.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email copied to clipboard'),
        backgroundColor: const Color(0xFF00E5FF).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        // Refresh the office hours list
        ref.invalidate(approvedOfficeHoursProvider(widget.faculty.shortName));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine image rendering parameters
    String? photoUrl = widget.faculty.photoUrl;
    bool isLiveUrl = photoUrl != null && photoUrl.startsWith('http');
    final activeSemesterAsync = ref.watch(academicStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF16202A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.faculty.shortName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.faculty.profileUrl != null)
            IconButton(
              icon: const Icon(Icons.public_rounded, color: Colors.white70),
              onPressed: () => _launchUrl(widget.faculty.profileUrl!),
              tooltip: 'Official Web Profile',
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sleek Glassmorphic Header Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E2836).withOpacity(0.8),
                            const Color(0xFF16202A).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // High-Res Hero Avatar
                          Hero(
                            tag: 'faculty_${widget.faculty.id}',
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFF0F172A),
                                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                                image: isLiveUrl
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: !isLiveUrl
                                  ? const Icon(Icons.person_rounded, color: Colors.white24, size: 45)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          
                          // Profile Detail Lines
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.faculty.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                
                                if (widget.faculty.designation != null && widget.faculty.designation!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.faculty.designation!,
                                      style: const TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                if (widget.faculty.officeRoom != null && widget.faculty.officeRoom!.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.room_rounded, color: Color(0xFF00E5FF), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Office: ${widget.faculty.officeRoom}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // Interactive Email Field
                                if (widget.faculty.email != null && widget.faculty.email!.isNotEmpty)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _launchEmail(widget.faculty.email!),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.04),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.white10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.email_rounded, color: Color(0xFF00E5FF), size: 14),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    widget.faculty.email!,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _copyEmail(context, widget.faculty.email!),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.04),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00E5FF),
                  indicatorWeight: 3.0,
                  labelColor: const Color(0xFF00E5FF),
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                  tabs: const [
                    Tab(text: 'CLASS SCHEDULE', icon: Icon(Icons.calendar_month_rounded, size: 20)),
                    Tab(text: 'OFFICE HOURS', icon: Icon(Icons.history_toggle_off_rounded, size: 20)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
              children: [
                // TAB 1: Class Schedule (Timetable)
                activeSemesterAsync.when(
                  data: (state) {
                    if (state == null) {
                      return const Center(child: Text('Active semester not loaded.', style: TextStyle(color: Colors.grey)));
                    }
                    
                    final semesterCode = state.currentSemesterCode;
                    final scheduleAsync = ref.watch(facultySectionsProvider(
                      initials: widget.faculty.shortName,
                      semesterCode: semesterCode,
                    ));

                    return scheduleAsync.when(
                      data: (sections) {
                        if (sections.isEmpty) {
                          return _buildEmptyState(
                            icon: Icons.free_breakfast_rounded,
                            title: 'No Classes Scheduled',
                            subtitle: 'This faculty member does not have any classes on schedule for $semesterCode.',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            final section = sections[index];
                            return _buildClassScheduleCard(section);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                      error: (err, stack) => Center(child: Text('Error loading schedule: $err', style: const TextStyle(color: Colors.redAccent))),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                ),

                // TAB 2: Crowdsourced Office Hours
                Consumer(
                  builder: (context, ref, child) {
                    final officeHoursAsync = ref.watch(approvedOfficeHoursProvider(widget.faculty.shortName));

                    return officeHoursAsync.when(
                      data: (officeHours) {
                        return Stack(
                          children: [
                            if (officeHours.isEmpty)
                              _buildEmptyState(
                                icon: Icons.help_outline_rounded,
                                title: 'No Office Hours Reported',
                                subtitle: 'Help other students by contributing approved office hours with verification proof!',
                              )
                            else
                              ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
                                onPressed: () => _showSubmitOfficeHoursSheet(context),
                                icon: const Icon(Icons.add, color: Colors.black),
                                label: const Text('Add Office Hours', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.cyanAccent,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                      error: (err, stack) => Center(child: Text('Error loading office hours: $err', style: const TextStyle(color: Colors.redAccent))),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Icon(icon, color: Colors.white24, size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassScheduleCard(CourseSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        section.code,
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SEC: ${section.section}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CR: ${section.credits}',
                style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.courseName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          
          // Class sessions list
          ...section.sessions.map((session) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 75,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      session.day,
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${session.startTime} - ${session.endTime}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.room_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      session.room,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOfficeHourCard(BuildContext context, FacultyOfficeHour slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Graphic indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off_rounded, color: Colors.cyanAccent, size: 20),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // View Proof button
          ElevatedButton.icon(
            onPressed: () {
              final url = 'https://drive.google.com/file/d/${slot.driveFileId}/view';
              _launchUrl(url);
            },
            icon: const Icon(Icons.verified_user_rounded, color: Colors.black, size: 13),
            label: const Text('Proof', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
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
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overridesHeader) {
    return Container(
      color: const Color(0xFF16202A),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
