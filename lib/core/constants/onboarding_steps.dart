import 'package:flutter/material.dart';
import '../../core/widgets/onboarding_overlay.dart';

/// Centralized onboarding step definitions for every screen in EWUmate.
/// Single source of truth — import and reference by key.
class OnboardingSteps {
  OnboardingSteps._();

  // ── Welcome Tour (full-screen, first login) ──────────────────────────
  static const String welcomeTourKey = 'welcome_tour_v1';

  static const List<OnboardingStep> welcomeTour = [
    OnboardingStep(
      title: 'Welcome to EWUmate 🎓',
      description:
          'Your complete academic companion for East West University. '
          "Let's take a quick tour of everything you can do!",
      icon: Icons.school_rounded,
    ),
    OnboardingStep(
      title: 'Dashboard',
      description:
          "Your academic hub — see today's classes, upcoming deadlines, "
          'pending tasks, and important announcements all in one glance.',
      icon: Icons.grid_view_rounded,
    ),
    OnboardingStep(
      title: 'Task Manager',
      description:
          'Create assignments, quizzes, and project deadlines. '
          'Set reminders so you never miss a submission.',
      icon: Icons.check_circle_rounded,
    ),
    OnboardingStep(
      title: 'Semester Progress',
      description:
          'Track your live CGPA projection, course-by-course marks breakdown, '
          'attendance, and scholarship eligibility in real time.',
      icon: Icons.auto_graph_rounded,
    ),
    OnboardingStep(
      title: 'Schedule Manager',
      description:
          'View your weekly class routine, manage time slots, and get '
          'notifications before each class starts.',
      icon: Icons.calendar_today_rounded,
    ),
    OnboardingStep(
      title: 'Services Hub',
      description:
          'Generate assignment cover pages, browse faculty directory, access '
          'the Study Vault for shared materials, and more.',
      icon: Icons.widgets_rounded,
    ),
    OnboardingStep(
      title: 'Pre-Advising Planner',
      description:
          'Plan your next semester courses, generate optimized section '
          'combinations, and save drafts — all before the portal opens.',
      icon: Icons.event_note_rounded,
    ),
    OnboardingStep(
      title: 'Course Browser',
      description:
          'Browse active and upcoming semester courses, view section details, '
          'and save courses to your enrollment plan.',
      icon: Icons.search_rounded,
    ),
    OnboardingStep(
      title: 'Degree Progress',
      description:
          "Visualize how many credits you've completed vs. remaining, track "
          'prerequisite chains, and see your graduation timeline.',
      icon: Icons.bar_chart_rounded,
    ),
    OnboardingStep(
      title: 'Portal Sync',
      description:
          'Sync your official EWU portal data — enrolled courses, grades, and '
          'routine — directly into EWUmate.',
      icon: Icons.cloud_sync_rounded,
    ),
  ];

  // ── Per-Screen Contextual Tips ───────────────────────────────────────

  // Dashboard
  static const String dashboardKey = 'screen_dashboard';
  static const List<OnboardingStep> dashboard = [
    OnboardingStep(
      title: 'Your Academic Hub',
      description:
          "Welcome to your dashboard! Here you'll find your classes, "
          'deadlines, and important university updates.',
      icon: Icons.dashboard_rounded,
    ),
    OnboardingStep(
      title: 'Quick Actions',
      description:
          'Use the shortcut pills to jump to your Routine, CGPA Calculator, '
          'Faculty Directory, or Tasks instantly.',
      icon: Icons.touch_app_rounded,
    ),
    OnboardingStep(
      title: 'Live Schedule',
      description:
          'Your daily classes appear here automatically. '
          "We'll remind you 15 minutes before they start!",
      icon: Icons.calendar_today_rounded,
    ),
    OnboardingStep(
      title: 'Pull to Refresh',
      description:
          'Swipe down anywhere to refresh your dashboard data, '
          'or tap the refresh icon in the top bar.',
      icon: Icons.refresh_rounded,
    ),
  ];

  // Tasks
  static const String tasksKey = 'screen_tasks';
  static const List<OnboardingStep> tasks = [
    OnboardingStep(
      title: 'Task Manager',
      description:
          'Keep track of all your academic deadlines — assignments, quizzes, '
          'midterms, projects, and more.',
      icon: Icons.check_circle_rounded,
    ),
    OnboardingStep(
      title: 'Create Tasks',
      description:
          'Tap the + button to add a new task. Set a title, due date, '
          'course, priority, and optional reminder.',
      icon: Icons.add_circle_outline_rounded,
    ),
    OnboardingStep(
      title: 'Manage & Filter',
      description:
          'Swipe to complete or delete. Filter tasks by type, course, '
          'or status to find what you need fast.',
      icon: Icons.filter_list_rounded,
    ),
  ];

  // Semester Progress
  static const String semesterProgressKey = 'screen_semester_progress';
  static const List<OnboardingStep> semesterProgress = [
    OnboardingStep(
      title: 'Course Progress Grid',
      description:
          'Each card shows a course with your live marks — quizzes, midterms, '
          'attendance, and assignments updated in real time.',
      icon: Icons.auto_graph_rounded,
    ),
    OnboardingStep(
      title: 'Tap for Details',
      description:
          'Tap any course card to see the full marks breakdown, add or edit '
          'scores, and track your predicted grade.',
      icon: Icons.touch_app_rounded,
    ),
    OnboardingStep(
      title: 'Predicted SGPA',
      description:
          'Your semester GPA is predicted live based on all entered marks. '
          'Keep it updated for accurate projections!',
      icon: Icons.insights_rounded,
    ),
  ];

  // Schedule
  static const String scheduleKey = 'screen_schedule';
  static const List<OnboardingStep> schedule = [
    OnboardingStep(
      title: 'Weekly Routine',
      description:
          'Your complete class schedule at a glance. Each day shows your '
          'time slots, rooms, and faculty info.',
      icon: Icons.calendar_today_rounded,
    ),
    OnboardingStep(
      title: 'Add Custom Slots',
      description:
          'Add personal study sessions, lab timings, or events that '
          "aren't part of your official routine.",
      icon: Icons.add_alarm_rounded,
    ),
    OnboardingStep(
      title: 'Class Reminders',
      description:
          'Automatic notifications fire 15 minutes before each class. '
          'Configure timing in notification settings.',
      icon: Icons.notifications_active_rounded,
    ),
  ];

  // Services
  static const String servicesKey = 'screen_services';
  static const List<OnboardingStep> services = [
    OnboardingStep(
      title: 'App Services',
      description:
          'Your toolkit for academic utilities — cover pages, faculty info, '
          'study materials, and more.',
      icon: Icons.widgets_rounded,
    ),
    OnboardingStep(
      title: 'Cover Page Generator',
      description:
          'Generate formatted assignment cover pages instantly with your '
          'course, section, and faculty details pre-filled.',
      icon: Icons.description_rounded,
    ),
    OnboardingStep(
      title: 'Study Vault',
      description:
          'A community library where students share notes, slides, and '
          'past papers. Upload yours to help others!',
      icon: Icons.folder_shared_rounded,
    ),
  ];

  // Profile
  static const String profileKey = 'screen_profile';
  static const List<OnboardingStep> profile = [
    OnboardingStep(
      title: 'Your Profile',
      description:
          'View and update your name, nickname, photo, and academic details.',
      icon: Icons.person_rounded,
    ),
    OnboardingStep(
      title: 'Academic Info',
      description:
          'Change your program, admitted semester, or course history. '
          'This data powers your degree progress tracking.',
      icon: Icons.school_rounded,
    ),
  ];

  // Notifications
  static const String notificationsKey = 'screen_notifications';
  static const List<OnboardingStep> notifications = [
    OnboardingStep(
      title: 'Notifications',
      description:
          'All your alerts — task reminders, class notifications, and app '
          'announcements — collected in one place.',
      icon: Icons.notifications_rounded,
    ),
    OnboardingStep(
      title: 'Manage Settings',
      description:
          'Tap the settings icon to customize which notifications you '
          'receive and when reminders fire.',
      icon: Icons.settings_rounded,
    ),
  ];

  // Course Browser
  static const String courseBrowserKey = 'screen_course_browser';
  static const List<OnboardingStep> courseBrowser = [
    OnboardingStep(
      title: 'Course Browser',
      description:
          'Browse all courses offered this semester and upcoming. '
          'Search by code, title, or department.',
      icon: Icons.search_rounded,
    ),
    OnboardingStep(
      title: 'Active vs Upcoming',
      description:
          'Switch between Active (current semester) and Upcoming '
          '(next semester) courses with the scope toggle.',
      icon: Icons.swap_horiz_rounded,
    ),
    OnboardingStep(
      title: 'Save to Plan',
      description:
          'Tap any upcoming course to view details and save it to your '
          'enrollment plan for next semester.',
      icon: Icons.bookmark_add_rounded,
    ),
  ];

  // Pre-Advising
  static const String advisingKey = 'screen_advising';
  static const List<OnboardingStep> advising = [
    OnboardingStep(
      title: 'Pre-Advising Planner',
      description:
          'Plan your next semester before registration opens. Pick courses, '
          'generate section combinations, and save drafts.',
      icon: Icons.event_note_rounded,
    ),
    OnboardingStep(
      title: 'Pick Courses',
      description:
          'Select the courses you want to take. The system will find '
          'non-conflicting section combinations for you.',
      icon: Icons.playlist_add_check_rounded,
    ),
    OnboardingStep(
      title: 'Security Notice',
      description:
          'Screenshots and screen recording are blocked on the advising '
          'screen to protect your course selections. My Drafts tab allows screenshots.',
      icon: Icons.shield_rounded,
    ),
  ];

  // Degree Progress
  static const String degreeProgressKey = 'screen_degree_progress';
  static const List<OnboardingStep> degreeProgress = [
    OnboardingStep(
      title: 'Degree Progress',
      description:
          'See your total credits completed vs. required for graduation. '
          'Track your academic journey visually.',
      icon: Icons.bar_chart_rounded,
    ),
    OnboardingStep(
      title: 'Category Breakdown',
      description:
          'Filter by Core, Elective, General Education, or Free Elective '
          'to see exactly where you stand.',
      icon: Icons.category_rounded,
    ),
  ];

  // Semester Summary
  static const String semesterSummaryKey = 'screen_semester_summary';
  static const List<OnboardingStep> semesterSummary = [
    OnboardingStep(
      title: 'Semester Summary',
      description:
          'A comprehensive view of your academic performance — grade '
          'distribution, CGPA dial, and scholarship eligibility.',
      icon: Icons.insights_rounded,
    ),
    OnboardingStep(
      title: 'Scholarship Tracker',
      description:
          "See if you qualify for Medha Lalon, Dean's List, or Merit 100% "
          'based on your current and predicted CGPA.',
      icon: Icons.emoji_events_rounded,
    ),
  ];

  // Portal Sync
  static const String portalSyncKey = 'screen_portal_sync';
  static const List<OnboardingStep> portalSync = [
    OnboardingStep(
      title: 'Portal Sync',
      description:
          'Connect your official EWU student portal to import enrolled '
          'courses, grades, and class routine automatically.',
      icon: Icons.cloud_sync_rounded,
    ),
    OnboardingStep(
      title: 'Secure & Private',
      description:
          'Your portal credentials are used only for syncing and are never '
          'stored on our servers. All data stays on your device.',
      icon: Icons.lock_rounded,
    ),
  ];

  // Tutorials
  static const String tutorialsKey = 'screen_tutorials';
  static const List<OnboardingStep> tutorials = [
    OnboardingStep(
      title: 'Video Tutorials',
      description:
          'Step-by-step video guides on how to use every feature of EWUmate. '
          'Perfect for getting started quickly!',
      icon: Icons.play_circle_rounded,
    ),
  ];

  // Study Vault
  static const String studyVaultKey = 'screen_study_vault';
  static const List<OnboardingStep> studyVault = [
    OnboardingStep(
      title: 'Study Vault',
      description:
          'Browse community-shared study materials — notes, slides, past '
          'papers, and resources organized by course.',
      icon: Icons.folder_shared_rounded,
    ),
    OnboardingStep(
      title: 'Upload & Share',
      description:
          'Contribute your own materials to help fellow students. '
          'Upload notes, slides, or any academic resources.',
      icon: Icons.upload_file_rounded,
    ),
  ];
}
