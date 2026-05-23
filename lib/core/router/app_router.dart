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

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/semester_progress/semester_progress_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../../features/services/presentation/cover_page_screen.dart';
import '../../features/services/presentation/faculty_list_screen.dart';
import '../../features/faculty_directory/presentation/faculty_directory_screen.dart';
import '../../features/study_vault/presentation/study_vault_screen.dart';
import '../../features/study_vault/presentation/upload_study_material_screen.dart';
import '../../features/study_vault/presentation/my_study_materials_screen.dart';
import '../../core/widgets/main_shell.dart';

import '../../features/profile/presentation/profile_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/advising/presentation/degree_progress_screen.dart';
import '../../features/semester_progress/semester_summary_screen.dart';
import '../../features/course_browser/presentation/course_browser_screen.dart';
import '../../features/advising/presentation/advising_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/advising/presentation/next_semester_screen.dart';
import '../../features/results/presentation/grade_entry_screen.dart';
import '../../features/profile/presentation/feedback_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const CheckAuthScreen()),

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      GoRoute(path: '/onboarding/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(path: '/onboarding/program', builder: (context, state) => const ProgramSelectionScreen()),
      GoRoute(path: '/onboarding/course-history', builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isEdit = extra?['isEditMode'] as bool? ?? false;
        final admitted = extra?['admittedSemester'] as String?;
        return CourseHistoryScreen(isEditMode: isEdit, admittedSemester: admitted);
      }),

      // Main Pages wrapped in a single ShellRoute
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),
          GoRoute(path: '/semester-progress', builder: (context, state) => const SemesterProgressScreen()),
          GoRoute(path: '/services', builder: (context, state) => const ServicesScreen()),
          GoRoute(path: '/services/cover-page', builder: (context, state) => const CoverPageScreen()),
          GoRoute(path: '/services/faculty-list', builder: (context, state) => const FacultyListScreen()),
          GoRoute(path: '/services/faculty-directory', builder: (context, state) => const FacultyDirectoryScreen()),
          GoRoute(
            path: '/services/study-vault',
            builder: (context, state) => const StudyVaultScreen(),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) => const UploadStudyMaterialScreen(),
              ),
              GoRoute(
                path: 'my-uploads',
                builder: (context, state) => const MyStudyMaterialsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Drawer Pages
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/degree-progress', builder: (context, state) => const DegreeProgressScreen()),
      GoRoute(path: '/semester-summary', builder: (context, state) => const SemesterSummaryScreen()),
      GoRoute(path: '/courses', builder: (context, state) => const CourseBrowserScreen()),
      GoRoute(path: '/advising', builder: (context, state) => const AdvisingScreen()),
      GoRoute(path: '/schedule-manager', builder: (context, state) => const ScheduleScreen()),
      GoRoute(path: '/next-semester', builder: (context, state) => const NextSemesterScreen()),
      GoRoute(path: '/results/grade-entry', builder: (context, state) => const GradeEntryScreen()),
      GoRoute(path: '/feedback', builder: (context, state) => const FeedbackScreen()),
    ],
  );
});
