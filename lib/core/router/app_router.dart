import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../widgets/main_shell.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/course_browser/course_browser_screen.dart';
import '../../features/onboarding/program_selection_screen.dart';
import '../../features/onboarding/course_history_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/semester_progress/semester_progress_screen.dart';
import '../../features/advising/advising_screen.dart';
import '../../features/auth/check_auth_screen.dart';

import '../../features/degree_progress/degree_progress_screen.dart';
import '../../features/dashboard/schedule_manager_screen.dart';
import '../../features/transition/next_semester_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/ramadan/ramadan_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/semester_progress/semester_summary_screen.dart';
import '../../features/semester_progress/grade_entry_gatekeeper_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/forgot_password_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static const String loginPath = '/login';
  static const String dashboardPath = '/dashboard';
  static const String tasksPath = '/tasks';
  static const String semesterProgressPath = '/semester-progress';
  static const String registerPath = '/register';
  static const String resetPasswordPath = '/reset-password';
  static const String forgotPasswordPath = '/forgot-password';

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CheckAuthScreen(),
      ),
      GoRoute(
        path: loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: registerPath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: resetPasswordPath,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: dashboardPath,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: tasksPath,
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: semesterProgressPath,
            builder: (context, state) => const SemesterProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/courses',
            builder: (context, state) => const CourseBrowserScreen(),
          ),
          GoRoute(
            path: '/advising',
            builder: (context, state) => const AdvisingScreen(),
          ),
          GoRoute(
            path: '/next-semester',
            builder: (context, state) => const NextSemesterScreen(),
          ),
          GoRoute(
            path: '/degree-progress',
            builder: (context, state) => const DegreeProgressScreen(),
          ),
          GoRoute(
            path: '/schedule-manager',
            builder: (context, state) => const ScheduleManagerScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/ramadan',
            builder: (context, state) => const RamadanScreen(),
          ),
          GoRoute(
            path: '/semester-summary',
            builder: (context, state) => const SemesterSummaryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/program',
        builder: (context, state) => const ProgramSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/course-history',
        builder: (context, state) => const CourseHistoryScreen(),
      ),
      GoRoute(
        path: '/gatekeeper',
        builder: (context, state) => GradeEntryGatekeeperScreen(
          onTransitionComplete: () {
            context.go(dashboardPath);
          },
        ),
      ),
    ],
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final user = session?.user;
      final path = state.uri.toString();

      // Define public routes
      final isPublic = path == loginPath ||
          path == registerPath ||
          path == resetPasswordPath ||
          path == forgotPasswordPath;

      if (user == null && !isPublic) return loginPath;
      if (user != null && isPublic) return '/';

      return null;
    },
  );
}
