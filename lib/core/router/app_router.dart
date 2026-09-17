import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/check_auth_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/onboarding/program_selection_screen.dart';
import '../../features/onboarding/course_history_screen.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/onboarding/presentation/welcome_tour_screen.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/semester_progress/semester_progress_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/services/presentation/cover_page_screen.dart';
import '../../features/services/presentation/faculty_list_screen.dart';
import '../../features/services/presentation/faculty_assignment_screen.dart';
import '../../features/faculty_directory/presentation/faculty_directory_screen.dart';
import '../../features/faculty_directory/presentation/faculty_details_screen.dart';
import '../../core/models/faculty.dart';
import '../../features/study_vault/presentation/study_vault_screen.dart';
import '../../features/study_vault/presentation/upload_study_material_screen.dart';
import '../../features/study_vault/presentation/my_study_materials_screen.dart';
import '../../core/widgets/main_shell.dart';

import '../../features/profile/presentation/profile_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/notifications/presentation/reminder_settings_screen.dart';
import '../../features/advising/presentation/degree_progress_screen.dart';
import '../../features/semester_progress/semester_summary_screen.dart';
import '../../features/course_browser/presentation/course_browser_screen.dart';
import '../../features/advising/presentation/advising_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/results/presentation/grade_entry_screen.dart';
import '../../features/profile/presentation/feedback_screen.dart';
import '../../features/tutorials/presentation/tutorials_screen.dart';
import '../../features/services/presentation/portal_sync_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    initialLocation: '/',
    routes: [
      GoRoute(name: 'CheckAuth', path: '/', builder: (context, state) => const CheckAuthScreen()),
      GoRoute(name: 'LoginCallback', path: '/login-callback', builder: (context, state) => const CheckAuthScreen()),

      GoRoute(name: 'Login', path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(name: 'Register', path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(name: 'ForgotPassword', path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      GoRoute(name: 'ProfileSetup', path: '/onboarding/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(name: 'ProgramSelection', path: '/onboarding/program', builder: (context, state) => const ProgramSelectionScreen()),
      GoRoute(
        name: 'CourseHistory',
        path: '/onboarding/course-history',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isEdit = extra?['isEditMode'] as bool? ?? false;
          final admitted = extra?['admittedSemester'] as String?;
          return CourseHistoryScreen(isEditMode: isEdit, admittedSemester: admitted);
        },
      ),

      GoRoute(name: 'WelcomeTour', path: '/onboarding/welcome-tour', builder: (context, state) => const WelcomeTourScreen()),

      // Main Pages wrapped in a single ShellRoute
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(name: 'Dashboard', path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(name: 'Tasks', path: '/tasks', builder: (context, state) => const TasksScreen()),
          GoRoute(name: 'SemesterProgress', path: '/semester-progress', builder: (context, state) => const SemesterProgressScreen()),
          GoRoute(name: 'DegreeProgress', path: '/degree-progress', builder: (context, state) => const DegreeProgressScreen()),
          GoRoute(name: 'Schedule', path: '/schedule-manager', builder: (context, state) => const ScheduleScreen()),
          GoRoute(name: 'Services', path: '/services', builder: (context, state) => const ServicesScreen()),
          GoRoute(name: 'CoverPage', path: '/services/cover-page', builder: (context, state) => const CoverPageScreen()),
          GoRoute(name: 'FacultyList', path: '/services/faculty-list', builder: (context, state) => const FacultyListScreen()),
          GoRoute(
            name: 'FacultyDirectory',
            path: '/services/faculty-directory',
            builder: (context, state) => const FacultyDirectoryScreen(),
            routes: [
              GoRoute(
                name: 'FacultyDetails',
                path: 'details',
                builder: (context, state) {
                  final faculty = state.extra as Faculty;
                  return FacultyDetailsScreen(faculty: faculty);
                },
              ),
            ],
          ),
          GoRoute(
            name: 'FacultyAssignment',
            path: '/services/faculty-assignment',
            builder: (context, state) {
              final extra = state.extra as Map<String, String>?;
              return FacultyAssignmentScreen(
                initialCourseCode: extra?['course_code'],
                initialSection: extra?['section'],
              );
            },
          ),
          GoRoute(
            name: 'StudyVault',
            path: '/services/study-vault',
            builder: (context, state) => const StudyVaultScreen(),
            routes: [
              GoRoute(
                name: 'UploadStudyMaterial',
                path: 'upload',
                builder: (context, state) => const UploadStudyMaterialScreen(),
              ),
              GoRoute(
                name: 'MyStudyMaterials',
                path: 'my-uploads',
                builder: (context, state) => const MyStudyMaterialsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Drawer Pages
      GoRoute(name: 'Profile', path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(name: 'Notifications', path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(name: 'ReminderSettings', path: '/notifications/settings', builder: (context, state) => const ReminderSettingsScreen()),
      GoRoute(name: 'SemesterSummary', path: '/semester-summary', builder: (context, state) => const SemesterSummaryScreen()),
      GoRoute(name: 'CourseBrowser', path: '/courses', builder: (context, state) => const CourseBrowserScreen()),
      GoRoute(name: 'Advising', path: '/advising', builder: (context, state) => const AdvisingScreen()),
      GoRoute(path: '/next-semester', redirect: (context, state) => '/courses'),
      GoRoute(name: 'GradeEntry', path: '/results/grade-entry', builder: (context, state) => const GradeEntryScreen()),
      GoRoute(name: 'PortalSync', path: '/portal-sync', builder: (context, state) => const PortalSyncScreen()),
      GoRoute(name: 'Feedback', path: '/feedback', builder: (context, state) => const FeedbackScreen()),
      GoRoute(name: 'Tutorials', path: '/tutorials', builder: (context, state) => const TutorialsScreen()),
    ],
  );
});

