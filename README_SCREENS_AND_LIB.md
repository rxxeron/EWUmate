# EWUmate — Comprehensive Screen & `lib/` Architecture Manual
**Definitive Technical Blueprint, Screen-by-Screen Reference, and Core System Architecture**

*Package:* `com.rxxeron.ewumate`  
*Target Environment:* Production Mobile (Android SDK 36 / iOS) & Web  
*Flutter Version:* 3.27+ | *Dart:* 3.x | *Riverpod:* 2.x  
*Backend:* Supabase PostgreSQL + Auth + Storage | Azure Functions Python | Upstash Edge Redis  

---

## Table of Contents

1. [Architectural Overview & `lib/` Directory Taxonomy](#1-architectural-overview--lib-directory-taxonomy)
2. [Core Architecture & System Foundations (`lib/core/`)](#2-core-architecture--system-foundations-libcore)
   - 2.1 [`core/config/` — Environment & Client Configuration](#21-coreconfig--environment--client-configuration)
   - 2.2 [`core/constants/` — Onboarding Steps, Storage Keys & Enums](#22-coreconstants--onboarding-steps-storage-keys--enums)
   - 2.3 [`core/database/` & Offline Storage — Zero-Wait Hive Architecture](#23-coredatabase--offline-storage--zero-wait-hive-architecture)
   - 2.4 [`core/network/` & Serverless Integrations](#24-corenetwork--serverless-integrations)
   - 2.5 [`core/services/` — System & Background Services Catalog](#25-coreservices--system--background-services-catalog)
   - 2.6 [`core/models/` — Domain Data Models & Freezed Entities](#26-coremodels--domain-data-models--freezed-entities)
   - 2.7 [`core/providers/` — Global State & Session Guardianship](#27-coreproviders--global-state--session-guardianship)
   - 2.8 [`core/router/` — GoRouter Navigation, ShellRoute & Route Guards](#28-corerouter--gorouter-navigation-shellroute--route-guards)
   - 2.9 [`core/theme/` — Design System Tokens, Sora Typography & Palette](#29-coretheme--design-system-tokens-sora-typography--palette)
   - 2.10 [`core/utils/` — Academic Calculation Helpers & Utility Suite](#210-coreutils--academic-calculation-helpers--utility-suite)
   - 2.11 [`core/widgets/` — Design System Primitive Components](#211-corewidgets--design-system-primitive-components)
3. [Exhaustive Screen Reference (All 17 Feature Modules in `lib/features/`)](#3-exhaustive-screen-reference-all-17-feature-modules-in-libfeatures)
   - [3.1 Feature 01: Advising & Degree Audit](#31-feature-01-advising--degree-audit)
   - [3.2 Feature 02: Authentication & Session Recovery](#32-feature-02-authentication--session-recovery)
   - [3.3 Feature 03: Course Browser](#33-feature-03-course-browser)
   - [3.4 Feature 04: Dashboard (Daily Academic Command Hub)](#34-feature-04-dashboard-daily-academic-command-hub)
   - [3.5 Feature 05: Faculty Directory & Community Reviews](#35-feature-05-faculty-directory--community-reviews)
   - [3.6 Feature 06: Layout & Navigation Shell](#36-feature-06-layout--navigation-shell)
   - [3.7 Feature 07: Notifications & Class Reminders](#37-feature-07-notifications--class-reminders)
   - [3.8 Feature 08: Onboarding & Academic Bootstrapping](#38-feature-08-onboarding--academic-bootstrapping)
   - [3.9 Feature 09: Profile, Feedback & Developer Support](#39-feature-09-profile-feedback--developer-support)
   - [3.10 Feature 10: Progress & Course Marks Editor](#310-feature-10-progress--course-marks-editor)
   - [3.11 Feature 11: Results & Mandatory Grade Blocker](#311-feature-11-results--mandatory-grade-blocker)
   - [3.12 Feature 12: Schedule Manager & Weekly Timetable](#312-feature-12-schedule-manager--weekly-timetable)
   - [3.13 Feature 13: Semester Progress, CGPA Simulation & Attendance](#313-feature-13-semester-progress-cgpa-simulation--attendance)
   - [3.14 Feature 14: Services, Cover Page & EWU Portal Sync](#314-feature-14-services-cover-page--ewu-portal-sync)
   - [3.15 Feature 15: Study Vault (Crowdsourced Academic Repository)](#315-feature-15-study-vault-crowdsourced-academic-repository)
   - [3.16 Feature 16: Tasks Manager](#316-feature-16-tasks-manager)
   - [3.17 Feature 17: Video Tutorials & Walkthrough Guides](#317-feature-17-video-tutorials--walkthrough-guides)
4. [Complete Repository Layer Catalog (`core/repositories/`)](#4-complete-repository-layer-catalog-corerepositories)
5. [Cross-Cutting Architectural Patterns](#5-cross-cutting-architectural-patterns)
   - 5.1 Zero-Wait Entry Architecture (Frame 1 Rendering)
   - 5.2 Offline Mutation Synchronization Queue
   - 5.3 Bi-Semester vs. Tri-Semester Dynamic Track Resolution
   - 5.4 Dual-Grading Policy (Legacy ≤ Summer 2023 vs. Modern ≥ Fall 2023)
   - 5.5 Checksum-Driven Routine Cache & Alarm Rescheduling
   - 5.6 Hardware Security & OS Screen Protection
6. [Index of All Application Routes](#6-index-of-all-application-routes)

---

## 1. Architectural Overview & `lib/` Directory Taxonomy

The production codebase of EWUmate (`ewumate_production_build/lib/`) represents a modular, clean-architecture mobile application built with Flutter 3.27+, utilizing declarative routing, reactive state management via Flutter Riverpod 2.x with code generation (`riverpod_annotation`), and an offline-first caching paradigm powered by Hive multi-box storage.

```
lib/
├── core/                                # Enterprise foundations & shared infrastructure
│   ├── config/                          # Supabase and Azure configuration loaders
│   ├── constants/                       # Central onboarding steps, storage keys, enums
│   ├── models/                          # Immutable data models & Freezed entities
│   │   └── models/                      # Legacy and sub-domain entity serializers
│   ├── providers/                       # Global Riverpod state providers & guardians
│   ├── repositories/                    # Data repository abstractions (Supabase + Hive)
│   ├── router/                          # GoRouter configuration, route guards & ShellRoute
│   ├── services/                        # Native platform bridges, FCM, Upstash, Scrapers
│   ├── theme/                           # Sora typography, Figma dark palette & extensions
│   ├── utils/                           # CGPA calculator, formatters, course utils, time helpers
│   └── widgets/                         # Design system primitives, GlassKit, animations, app bar
├── features/                            # 17 domain-driven feature modules
│   ├── advising/                        # Pre-advising solver, routine permutations & degree audit
│   ├── auth/                            # Email & Google OAuth, OTP password recovery, splash
│   ├── course_browser/                  # University course catalog, section filters, pagination
│   ├── dashboard/                       # Dynamic sky header, next class countdown, daily timeline
│   ├── faculty_directory/               # Professor directory, reviews scorecard, crowdsourcing
│   ├── layout/                          # App root layout, bottom navigation bar
│   ├── notifications/                   # Notification center & granular class reminder offsets
│   ├── onboarding/                      # Department, program selection, history & welcome tour
│   ├── profile/                         # User profile editing, bug feedback & donation tracker
│   ├── progress/                        # Course marks editor & breakdown simulator
│   ├── results/                         # Academic results viewer & mandatory grade entry blocker
│   ├── schedule/                        # Weekly routine timetable, exceptions & manual classes
│   ├── semester_progress/               # Live CGPA dial, attendance calendar, scholarship tiers
│   ├── services/                        # PDF cover page, faculty assignments & EWU portal sync
│   ├── study_vault/                     # Past papers, notes, slides, Google Drive integration
│   ├── tasks/                           # Assignment/quiz deadlines with offline queuing
│   └── tutorials/                       # Curated video walkthroughs & external YouTube player
├── firebase_options.dart                # Generated Firebase project configuration
└── main.dart                            # Application bootloader, Hive init & crash boundaries
```

---

## 2. Core Architecture & System Foundations (`lib/core/`)

### 2.1 `core/config/` — Environment & Client Configuration
- **File:** `lib/core/config/supabase_config.dart`
- **Class `AppConfig`:**
  - `getSupabaseUrl`: Retrieves `SUPABASE_URL` from `.env` via `flutter_dotenv`. Falls back to production URL `https://jwygjihrbwxhehijldiz.supabase.co`.
  - `getSupabaseAnonKey`: Retrieves `SUPABASE_ANON_KEY`. Falls back to production anonymous public key with JWT expiration.
  - `getAzureFunctionUrl`: Retrieves `AZURE_FUNCTION_URL`. Falls back to `https://ewumate-parser.azurewebsites.net`.
  - `getGoogleWebClientId`: Retrieves `GOOGLE_WEB_CLIENT_ID` for Google Sign-In authentication (`561956344734-ulqeqls9u4h1hmpec41l9lufk336a9ga.apps.googleusercontent.com`).
- **Class `SupabaseConfig`:**
  - `initialize()`: Boots `dotenv.load(fileName: ".env")` and calls `Supabase.initialize(...)` with `publishableKey` and `url`. Safeguards against null keys in production environments.

### 2.2 `core/constants/` — Onboarding Steps, Storage Keys & Enums
- **File:** `lib/core/constants/onboarding_steps.dart`
- **Class `OnboardingSteps`:** Centralized catalog of walkthrough tours and contextual feature guidance tooltips displayed via `OnboardingOverlay.show(...)`.
  - `welcomeTourKey` (`welcome_tour_v1`): 10-step full-screen onboarding experience triggered on initial login:
    1. Welcome to EWUmate (🎓 `Icons.school_rounded`)
    2. Dashboard Hub (🗂️ `Icons.grid_view_rounded`)
    3. Task Manager (✅ `Icons.check_circle_rounded`)
    4. Semester Progress & CGPA (📈 `Icons.auto_graph_rounded`)
    5. Schedule Manager (📅 `Icons.calendar_today_rounded`)
    6. Services Hub (🧩 `Icons.widgets_rounded`)
    7. Pre-Advising Planner (📝 `Icons.event_note_rounded`)
    8. Course Browser (🔍 `Icons.search_rounded`)
    9. Degree Progress (📊 `Icons.bar_chart_rounded`)
    10. Portal Sync (🔄 `Icons.cloud_sync_rounded`)
  - **Screen-Specific Step Definitions:**
    - `dashboardKey` (`screen_dashboard`): Highlights schedule timeline, next class card, tasks preview, quick action pills.
    - `tasksKey` (`screen_tasks`): Details categories (Quiz, Lab, Assignment, Project), completion toggles, and offline sync.
    - `semesterProgressKey` (`screen_semester_progress`): Explains grade breakdown, attendance sessions, and mark forecasting.
    - `scheduleKey` (`screen_schedule`): Guides through 2-week rolling timetable, schedule exceptions, and manual class injection.
    - `servicesKey` (`screen_services`): Covers PDF Cover Page synthesis, Faculty Directory, and Portal Sync.
    - `advisingKey` (`screen_advising`): Outlines course selection, faculty filters, combinatorial cloud routine generation.
    - `courseBrowserKey` (`screen_course_browser`): Demonstrates credit filters, instructor filtering, and section conflict checks.
    - `degreeProgressKey` (`screen_degree_progress`): Details graduation credit requirements and prerequisite fulfillment.
    - `portalSyncKey` (`screen_portal_sync`): Explains university credential transmission, captcha solving, and safe credential storage.
    - `studyVaultKey` (`screen_study_vault`): Highlights community notes, search filters, and file approval lifecycle.
    - `profileKey` (`screen_profile`): Profile picture upload, nickname customization, and donation status.
    - `tutorialsKey` (`screen_tutorials`): Video guide categories and replay mechanisms.

### 2.3 `core/database/` & Offline Storage — Zero-Wait Hive Architecture
- **Files:** `lib/core/services/cache_service.dart`, `lib/core/services/routine_cache_service.dart`
- **Class `CacheService`:** Manages 10 discrete, encrypted/typed Hive storage boxes:
  1. `profile_box`: Stores raw JSON profile records, academic track (`bi_semester` / `tri_semester`), student ID, and avatars keyed by `userId`.
  2. `dashboard_box`: Caches daily schedule timeline, next class, semester analytics, and pending grade checkpoints (`${userId}_${semesterCode}_schedule`).
  3. `schedule_box`: Retains full weekly grid routines, enrolled section IDs, and class timeslots.
  4. `sync_queue_box`: Persistent offline mutation queue. Stores serialized database operations (`save_course_marks`, `update_task_status`, `create_task`, `delete_task`) when network connectivity is lost.
  5. `semester_progress_box`: Local cache for continuous evaluation marks, attendance session dates, and weight distributions.
  6. `notifications_box`: Caches received push notifications, unread counters, and notification preferences.
  7. `routine_cache_box`: Specialized storage for deterministic routine calendar hashes, delivered alert keys, and scheduled alarm keys.
  8. `auth_box`: Persists `last_user_id` for Zero-Wait Entry, allowing the app to render the student's dashboard before remote JWT verification completes.
  9. `course_catalog`: Global un-invalidated cache containing course codes, prerequisites, credit hours, and descriptions.
  10. `faculty`: Cached faculty directory snapshot (names, designations, initials, emails, departments).
- **Class `RoutineCacheService`:**
  - Calculates deterministic SHA-256 composite checksums: `calculateChecksum(calendar, weeklyGrid, exceptions)`.
  - Compares stored checksum with server-provided checksum on every dashboard boot. If checksums match, network timetable fetch is bypassed, reducing Supabase load by >80%.
  - Maintains `active_scheduled_keys` and `delivered_alert_keys` maps with a 45-minute deduplication window to guarantee duplicate class reminder notifications are never fired.

### 2.4 `core/network/` & Serverless Integrations
- **Class `AzureFunctionsService` (`lib/core/services/azure_functions_service.dart`):**
  - Communicates directly with Microsoft Azure Python serverless functions via HTTP POST/GET, attaching Supabase JWT Bearer tokens.
  - Endpoints consumed:
    - `/api/generate_schedules`: Passes selected courses and faculty preference filters to Python combinatorial solver. Returns `generationId`.
    - `/api/scraper/portal_sync`: Executes automated scraping jobs against the EWU portal.
    - `/api/get_advising_courses`: Retrieves degree curriculum advising recommendations for a student based on completed credits.
- **Class `RedisService` (`lib/core/services/redis_service.dart`):**
  - Connects to Upstash Edge Redis via REST protocol using `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`.
  - Executes raw commands `['GET', key]` and `['SET', key, value, 'EX', ttl]` with a strict 3-second HTTP timeout, providing sub-50ms cache hits for global course lists.
- **Class `PortalService` (`lib/core/services/portal_service.dart`):**
  - Direct HTTP scraping client for `https://portal.ewubd.edu`.
  - Arithmetic Captcha Solver: Extracts regex tokens `FirstNo` and `SecondNo` from login HTML, solves `firstNo + secondNo`, and posts to `/Account/Login` to establish session cookie `ASP.NET_SessionId`.
  - Consumes:
    - `/api/StudentProfile/GetStudentProfile`: Retrieves official name, department, program, admitted semester, and mentor.
    - `/api/utility/GetSemesterForDropDown`: Detects active semester dropdown ID.
    - `/api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent/{id}`: Retrieves official enrolled courses, section numbers, rooms, and faculty initials.
    - `/api/DegreeReview/GetDegreeReviewCourseAreaCourses?studentId={id}`: Extracts historical course marks, earned credits, and letter grades across all degree areas.

### 2.5 `core/services/` — System & Background Services Catalog
- **`FCMService` (`lib/core/services/fcm_service.dart`):**
  - Initializes Firebase Cloud Messaging, requests OS notification permissions, and registers `firebaseMessagingBackgroundHandler`.
  - Registers FCM tokens into Supabase `profiles.fcm_token` column upon login and token refresh.
  - Handles foreground, background, and terminated app launches. Features a 2.5s settling delay to allow GoRouter auth redirects to complete before presenting `showNotificationPopup`.
- **`LocalNotificationScheduler` (`lib/core/services/local_notification_scheduler.dart`):**
  - Configures `FlutterLocalNotificationsPlugin` with channel `ewumate_high_priority_reminders_v2` (`Importance.max`, `Priority.high`).
  - Utilizes `timezone` package with timezone `Asia/Dhaka` to schedule exact alarms (`AndroidScheduleMode.exactAllowWhileIdle`).
  - Schedules class reminders according to user-configured offsets (10m, 15m, 30m, 1h). Records delivery in Supabase table `local_notification_logs`.
- **`ScreenProtectionService` (`lib/core/services/screen_protection_service.dart`):**
  - Invokes native Android platform method channel `com.rxxeron.ewumate/screen_protection`.
  - Calls `enableSecure` (`WindowManager.LayoutParams.FLAG_SECURE`) to block OS screenshots and screen recording on sensitive screens (e.g., Pre-Advising during live section allocation) and `disableSecure` when viewing user drafts.
- **`SyncService` (`lib/core/services/sync_service.dart`):**
  - Monitors network status via `connectivity_plus`. Automatically triggers `flushQueue()` when transitioning to Wi-Fi or Mobile data.
  - Iterates through `sync_queue_box`, upserting pending `semester_course_marks` and `tasks` to Supabase, removing successfully synchronized records.
- **`StorageService` (`lib/core/services/storage_service.dart`):**
  - Interacts with Supabase Storage bucket `profile_images`. Uploads user avatar binaries (`XFile`) with upsert mode and generates public CDN URLs.
- **`TutorialService` (`lib/core/services/tutorial_service.dart`):**
  - Manages persistent walkthrough keys in `SharedPreferences` (`hasCompletedWelcomeTour`, `markAsSeen`, `resetAll`).
- **`AppUpdateService` (`lib/core/services/app_update_service.dart`):**
  - Connects to Google Play In-App Updates (`in_app_update`). Triggers Flexible or Immediate update flows on Android devices.

### 2.6 `core/models/` — Domain Data Models & Freezed Entities
All domain models are immutable and generated with `freezed` and `json_serializable`:
- **`AcademicState` (`academic_state.dart`):** Contains `currentSemesterCode`, `nextSemesterCode`, `track` (`bi_semester` / `tri_semester`), `advisingOpen`, `isGradeBlocked`.
- **`ActiveSemester` (`active_semester.dart`):** Maps Supabase table `active_semester` (`current_semester_code`, `next_semester_code`, `track`, `grade_submission_start`, `grade_submission_end`, `advising_start`, `advising_end`).
- **`CourseMetadata` (`course_metadata.dart`):** Represents course catalog entity (`course_code`, `course_title`, `credit_hours`, `department_code`, `prerequisites`, `course_type`).
- **`CourseSection` (`course_section.dart`):** Represents timetable offerings (`section_number`, `faculty_initial`, `room_number`, `days`, `start_time`, `end_time`, `seat_capacity`, `enrolled_count`).
- **`Enrollment` (`enrollment.dart`):** Maps student enrolled course row (`course_code`, `section`, `semester_code`, `status`, `grade`, `grade_point`, `is_retake`).
- **`Faculty` (`faculty.dart`):** Professor directory entity (`initials`, `name`, `email`, `department`, `designation`, `room`, `phone`, `avatar_url`, `rating_average`, `rating_count`).
- **`FacultyReview` (`faculty_review.dart`):** Review entity (`faculty_initials`, `rating`, `difficulty_rating`, `grading_leniency`, `attendance_strictness`, `review_text`, `course_code`, `created_at`).
- **`FacultyOfficeHour` (`faculty_office_hour.dart`):** Crowdsourced office hours (`faculty_initials`, `semester_code`, `day`, `start_time`, `end_time`, `room`, `status`).
- **`Profile` (`profile.dart`):** Core user record (`id`, `email`, `fullName`, `nickname`, `studentId`, `programCode`, `departmentCode`, `admittedSemester`, `track`, `cgpa`, `creditsEarned`, `photoUrl`, `onboardingStatus`, `preferences`).
- **`SemesterCourseMarks` (`semester_course_marks.dart`):** Continuous assessment marks breakdown (`course_code`, `semester_code`, `dist_mid`, `dist_final`, `dist_quiz`, `dist_assignment`, `dist_presentation`, `dist_attendance`, `dist_lab`, `obt_mid`, `obt_final`, `obt_quiz`, `obt_assignment`, `obt_presentation`, `obt_attendance`, `obt_lab`, `custom_breakdown`, `attendance_data`).
- **`SemesterSummary` (`semester_summary.dart`):** Historical semester grade report (`semester_code`, `gpa`, `credits_attempted`, `credits_earned`, `courses_count`, `academic_standing`).
- **`Task` (`task.dart`):** To-do deadline item (`id`, `title`, `description`, `courseCode`, `dueDate`, `category`, `isCompleted`, `reminderMinutesBefore`).
- **`StudyMaterial` (`features/study_vault/data/models/study_material.dart`):** Crowdsourced file metadata (`id`, `title`, `courseCode`, `department`, `fileType`, `semester`, `driveFileId`, `fileSizeBytes`, `status`, `uploaderEmail`, `downloadCount`).

### 2.7 `core/providers/` — Global State & Session Guardianship
- **`sessionGuardianProvider` (`session_guardian.dart`):**
  - Listens to `Supabase.instance.client.auth.onAuthStateChange`.
  - Automatically invokes `ProfileRepository.recordActivity(userId)` and `FCMService.syncToken()` upon `signedIn`, `initialSession`, and `tokenRefreshed` events.
  - Proactively executes `refreshNow()` if auth tokens near expiration.
- **`academicStateProvider` (`academic_providers.dart`):**
  - Dual-yield StreamProvider. Yields local cached `AcademicState` immediately on Frame 1.
  - Subsequently evaluates freshness (< 1 day). If stale or absent, fetches active semester from Supabase `active_semester` table filtered by student's normalized track, writing updated snapshot back to Hive.
- **`currentUserProvider` & `authStateProvider` (`lib/features/auth/auth_providers.dart`):**
  - Exposes reactive `User?` and Supabase `AuthState` stream for instant UI re-renders on login/logout.
- **`requiresGradeEntryProvider` (`auth_providers.dart`):**
  - Async evaluation determining whether the student has ungraded enrollments from previous semesters or whether active semester grade submission deadline has arrived. Triggers global application block.
- **`scaffoldKeyProvider` (`scaffold_provider.dart`):**
  - Exposes global `GlobalKey<ScaffoldState>` allowing any nested screen or app bar to programmatically open the `AppDrawer`.
- **`featureFlagsProvider` (`feature_flag_provider.dart`):**
  - Streams runtime feature flags (`pre_advising_open`, `portal_sync_enabled`, `study_vault_uploads`) from Supabase table `app_config`.

### 2.8 `core/router/` — GoRouter Navigation, ShellRoute & Route Guards
- **File:** `lib/core/router/app_router.dart`
- **Global Key:** `rootNavigatorKey = GlobalKey<NavigatorState>()`
- **Architecture:** GoRouter 14+ setup configured with a declarative `ShellRoute` housing `MainShell` and 5 bottom navigation branches (`/dashboard`, `/tasks`, `/semester-progress`, `/degree-progress`, `/schedule-manager`, `/services`), accompanied by modal and fullscreen sub-routes.
- **Route Interception & Guards:**
  - `CheckAuthScreen` (`/`): Evaluates authentication, profile completeness, grade blocking, and tutorial completion before delegating navigation.
  - `MainShell` Grade Guard: Injects a reactive listener `ref.listen(requiresGradeEntryProvider)` directly into the root scaffold. If `requiresGradeEntry` becomes true at runtime, the student is instantly forced to `/results/grade-entry`.
  - Legacy Redirection: Route `/next-semester` automatically redirects to `/courses` with `selectedSemesterScopeProvider = SemesterScope.upcoming`.

### 2.9 `core/theme/` — Design System Tokens, Sora Typography & Palette
- **Files:** `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart`, `lib/core/theme/ewu_theme_extension.dart`
- **Palette Tokens (`AppColors`):**
  - `primaryNavy`: `0xFF071426` (App scaffold background)
  - `surfaceNavyBlue`: `0xFF0D2342` (Cards, dialogs, surfaces)
  - `primaryCyan`: `0xFF19D9F5` (Primary call to action & glowing accents)
  - `secondarySoftBlue`: `0xFF5EA8FF` (Secondary information & badges)
  - `primaryText`: `Colors.white`
  - `secondaryText`: `0xFF8493A8` (Muted blue-gray subtitles & hints)
  - `success`: `0xFF22C55E` | `warning`: `0xFFF59E0B` | `error`: `0xFFEF4444` | `academic`: `0xFF8B5CF6`
- **Typography:** Configured via `GoogleFonts.soraTextTheme(baseDark.textTheme)`. Sora provides geometric clarity, optical weight balancing, and high legibility on high-density OLED and LCD screens.
- **Theme Extension (`EwuThemeExtension` / `EwuColors`):**
  - Provides type-safe theme access across build contexts via `context.ewuColors`.
  - Properties: `background`, `surfaceNavyBlue`, `primaryCyan`, `secondarySoftBlue`, `textPrimary`, `textSecondary`, `borderSubtle`, `success`, `warning`, `error`.

### 2.10 `core/utils/` — Academic Calculation Helpers & Utility Suite
- **`GradeHelper` (`lib/core/utils/grade_helper.dart`):**
  - **Dual-Grading Scale Policy Engine:**
    - `getPolicyForSemester(semesterCode)`: Evaluates semester code year and season. Semesters strictly up to `Summer2023` use `legacy` policy. Semesters from `Fall2023` onwards use `modern` policy.
    - **Modern Scale (Fall 2023+):** A+ (4.00), A (3.75), A- (3.50), B+ (3.25), B (3.00), B- (2.75), C+ (2.50), C (2.25), D (2.00), F (0.00). *No C- or D+ exist.*
    - **Legacy Scale (Up to Summer 2023):** A+ (4.00), A (4.00), A- (3.70), B+ (3.30), B (3.00), B- (2.70), C+ (2.30), C (2.00), C- (1.70), D+ (1.30), D (1.00), F (0.00).
  - `calculateCGPA(results)`: Chronologically sorts semesters, filters non-credit courses (W, I, S, U), processes retakes (keeping latest grade), and computes cumulative CGPA to two decimal places.
- **`CourseUtils` (`lib/core/utils/course_utils.dart`):**
  - `normalize(code)`: Strips whitespace and non-alphanumerics, converting e.g. `cse 103` to `CSE103`.
  - `cleanSemester(semester)`: Formats `Spring 2026` to `Spring2026`.
  - `normalizeTrack(track)`: Maps department code / track string to canonical `bi_semester` (Pharmacy, Law) or `tri_semester` (Engineering, Business, Sciences).
- **`TimeUtils` (`lib/core/utils/time_utils.dart`):**
  - Parses East West University time slot formats (e.g. `08:30 AM-10:00 AM`, `01:30 PM-04:30 PM`) into Dart `DateTime` instances for today's date.
  - Generates countdown strings (e.g., `Starts in 24m`, `In progress - ends in 18m`).
- **`ErrorUtils` & `AuthErrorUtils` (`lib/core/utils/error_utils.dart`):**
  - Translates Supabase PostgREST, PostgREST auth exceptions, socket exceptions, and timeout errors into user-friendly messages.

### 2.11 `core/widgets/` — Design System Primitive Components
- **`GlassKit` (`lib/core/widgets/glass_kit.dart`):**
  - `FullGradientScaffold`: Root scaffolding wrapping pages in a rich 3-stop vertical navy gradient (`0xFF091A33` -> `0xFF061224` -> `0xFF040A14`) with custom app bar, bottom nav bar, and drawer binding.
  - `GlassContainer`: Frosted glass container featuring customizable background opacity, blur sigma, rounded borders, and subtle cyan/white borders.
- **`EWUmateAppBar` (`lib/core/widgets/ewumate_app_bar.dart`):** Standard header featuring custom back button, drawer trigger, actions slot, and stylized Sora title.
- **`SkyAnimationWidget` (`lib/core/widgets/sky_animation.dart`):** Dynamic Lottie sky presentation reflecting current time of day (morning dawn, afternoon sunny, dusk sunset, night starfield).
- **`EwuFloatingNavBar` (`lib/core/widgets/primitives/ewu_floating_nav_bar.dart`):** Floating curved bottom navigation bar with active cyan indicators, haptic feedback, and frosted glass backing.
- **`AppDrawer` (`lib/core/widgets/app_drawer.dart`):** Slide-out drawer with user avatar, name, email, active student status pill, complete app route shortcuts, Google Play review trigger, and red-themed logout dialog.
- **`LoadingShimmer` & `SkeletonLoader` (`lib/core/widgets/animations/`):** Shimmer placeholders mimicking text, cards, and list tiles during network fetch.

---

## 3. Exhaustive Screen Reference (All 17 Feature Modules in `lib/features/`)

```
================================================================================
FEATURE MODULE INDEX:
3.1  Advising             3.7  Notifications        3.13 Semester Progress
3.2  Auth                 3.8  Onboarding           3.14 Services
3.3  Course Browser       3.9  Profile              3.15 Study Vault
3.4  Dashboard            3.10 Progress             3.16 Tasks
3.5  Faculty Directory    3.11 Results              3.17 Tutorials
3.6  Layout               3.12 Schedule
================================================================================
```

---

### 3.1 Feature 01: Advising & Degree Audit

#### Screen 01: Pre-Advising Planner Screen
- **Exact File Path:** `lib/features/advising/presentation/advising_screen.dart`
- **Class Name:** `AdvisingScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - The central pre-advising engine where students select desired courses for the upcoming semester, set preferred instructors, and trigger combinatorial cloud schedule generation.
  - Solves the university's infamous pre-advising section-clash dilemma by generating all possible non-conflicting section combinations before the official portal opens.
  - Automatically locks when pre-advising is closed via runtime feature flags or active semester schedules.
- **Visual & Interactive Widgets:**
  - **App Bar:** `AppBar` with title "Pre-Advising", tab bar hosting 3 tabs ("Select Courses", "Saved Drafts", "Generation History"), and contextual action icons.
  - **Dynamic Tab Header:** Tab 0 ("Pick Courses"), Tab 1 ("My Drafts"), Tab 2 ("Generations").
  - **Generation Overview / Locked View:** Displays `AdvisingLockedView` when advising window is inactive. Displays `AdvisingGenerationOverviewView` when schedule generation is active or finished.
  - **Course Selector Grid:** Filter chips, search bar, course cards with expandable faculty selection sheets (`FacultySelectionSheet`).
  - **Bottom Action Bar:** Sticky cyan button displaying selected course count, total estimated credit load, and "Generate Schedules" trigger.
- **State Management & Providers:**
  - `advisingNotifierProvider` (`advising_notifier.dart`): Manages `AdvisingState` (`selectedCourses`, `generationId`, `isGenerating`, `error`).
  - `activeSemesterProvider`: Streams active semester advising status and start/end dates.
  - `availableAdvisingCoursesProvider`: Loads curriculum courses available for advising.
  - `isAdvisingOpenProvider`: Evaluates `featureFlagsProvider` to toggle locked state.
- **Backend / Data Layer:**
  - Supabase table `active_semester` queried for `advising_start` and `advising_end`.
  - Azure Function `/api/generate_schedules`: Receives `userId`, `semester`, `courses`, and `filters` (`selected_faculties`).
  - Hive Box `dashboard_box`: Caches generation drafts locally.
- **User Flow & Navigation:**
  - Entry: Via Drawer -> "Pre-Advising" (`/advising`) or Dashboard quick action pill.
  - Exit: Back navigation pops to previous route or switches between tabs.
  - Tapping "Generate Schedules" starts background Azure task, switching to `AdvisingGenerationOverviewView`.
  - Tap on saved draft allows one-click export to local schedule.
  - Hardware Security: Screenshot blocking automatically activated on Tabs 0 & 2 via `ScreenProtectionService.enableProtection()`, and disabled on Tab 1 ("My Drafts").

#### Screen 02: Degree Progress & Audit Screen
- **Exact File Path:** `lib/features/advising/presentation/degree_progress_screen.dart`
- **Class Name:** `DegreeProgressScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Complete degree audit visualizer detailing graduation requirements, credits completed versus remaining, cumulative CGPA milestones, and chronological academic standing.
  - Calculates estimated semesters remaining based on average credit load per semester.
- **Visual & Interactive Widgets:**
  - **App Bar:** "Degree Progress" with refresh button and back navigation.
  - **Hero Dial Card (`DegreeHeroCard`):** Radial progress ring indicating completed credits vs total required (e.g., 112 / 140 Credits — 80%).
  - **Stats Grid (`DegreeStatsGrid`):** 4-card metric grid: Cumulative CGPA, Completed Credits, Remaining Credits, Estimated Semesters Remaining.
  - **Milestones Card (`DegreeMilestonesCard`):** Linear step progress highlighting Freshman (0-30), Sophomore (31-60), Junior (61-90), Senior (91+), and Capstone/Thesis eligibility.
  - **CGPA Action Card (`DegreeCgpaActionCard`):** Motivational status highlighting Dean's List or Magna Cum Laude graduation honors potential.
  - **Academic History List (`DegreeAcademicHistoryList`):** Expandable semester-by-semester course cards detailing course codes, section, credits earned, and letter grades.
- **State Management & Providers:**
  - `profileRepositoryProvider`: Streams student's `Profile` (`creditsEarned`, `cgpa`, `programCode`).
  - `allSemesterSummariesProvider`: Loads all past completed semester summaries.
  - `programDetailsProvider`: Fetches required degree credits (e.g. 140 for CSE, 130 for BBA).
- **Backend / Data Layer:**
  - Supabase tables `profiles`, `semester_summaries`, `programs`.
  - Local caching via `CacheService.getMapData('profile_box', userId)`.
- **User Flow & Navigation:**
  - Entry: Drawer -> "Degree Progress" (`/degree-progress`) or Dashboard quick action.
  - Pull-to-refresh invalidates `profileRepositoryProvider` and re-computes graduation milestones.

#### Screen 03: Next Semester Screen (Legacy Forwarder)
- **Exact File Path:** `lib/features/advising/presentation/next_semester_screen.dart`
- **Class Name:** `NextSemesterScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown:**
  - Architectural transition route. Intercepts calls to `/next-semester`, sets `selectedSemesterScopeProvider = SemesterScope.upcoming`, and redirects immediately to `/courses`.

---

### 3.2 Feature 02: Authentication & Session Recovery

#### Screen 04: Check Auth Screen (Bootloader & Session Validator)
- **Exact File Path:** `lib/features/auth/check_auth_screen.dart`
- **Class Name:** `CheckAuthScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - The fundamental bootloader and zero-wait traffic controller for the entire application.
  - Inspects Supabase session validity, profile record existence, onboarding step status, grade blocking requirements, and welcome tour completion.
  - Enforces a minimum 3500ms aesthetic startup delay while playing the Lottie sky animation, ensuring smooth brand presentation.
- **Visual & Interactive Widgets:**
  - `SkyAnimationWidget`: Fullscreen animated atmospheric sky matching current time of day.
  - `CircularProgressBinding`: Custom frosted glass status card displaying dynamic status messages ("Restoring session...", "Securing universe...", "Preparing Dashboard...").
  - `_ErrorView`: Connection error card with retry button and emergency "Sign Out & Reset" button triggered if startup hangs.
  - Stall Timer: 45-second failsafe timer preventing the user from being trapped in an infinite loading state.
- **State Management & Providers:**
  - `currentUserProvider`: Reactive auth user provider.
  - `profileProvider`: Streams user's database `Profile`.
  - `requiresGradeEntryProvider`: Scans past/current semester enrollments for missing grades.
  - `cacheServiceProvider`: Checks `getLastUserId()` for zero-wait routing.
- **Backend / Data Layer:**
  - Supabase Auth: `currentSession`.
  - Supabase table `profiles`: Fetched via `ProfileRepository`.
- **User Flow & Navigation (Routing Matrix):**
  1. `user == null && hasSession == false`: Redirects to `/login`.
  2. `profile == null`: Redirects to `/onboarding/program` (new user registration).
  3. `profile.onboardingStatus == 'pending' || 'registered'`: Redirects to `/onboarding/profile-setup`.
  4. `profile.onboardingStatus == 'course_history'`: Redirects to `/onboarding/course-history`.
  5. `requiresGradeEntry == true`: Redirects to `/results/grade-entry` (Grade Blocker).
  6. `TutorialService.hasCompletedWelcomeTour() == false`: Redirects to `/onboarding/welcome-tour`.
  7. Default Fallback: Redirects to `/dashboard`.

#### Screen 05: Login Screen
- **Exact File Path:** `lib/features/auth/login_screen.dart`
- **Class Name:** `LoginScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Primary authentication gateway supporting EWU G-Suite student email credentials (`@std.ewubd.edu`), general emails, and single-tap Google OAuth.
- **Visual & Interactive Widgets:**
  - Logo & Header: EWUmate crest with gradient glow and welcome typography.
  - Input Fields: Email field with email validation; Password field with eye-icon visibility toggle.
  - "Forgot Password?" button navigating to OTP recovery flow.
  - Primary Button: Cyan gradient "Sign In" button with internal loading spinner.
  - Social Divider: "OR CONTINUE WITH" divider line.
  - Google Sign-In Button: Glassmorphic button with Google logo invoking native/web OAuth.
  - Sign-Up Navigation: Bottom footer prompting new students to register.
- **State Management & Providers:**
  - `authRepositoryProvider`: Executes `signIn(email, password)` and `signInWithGoogle()`.
  - `fcmServiceProvider`: Triggers `syncToken()` immediately after successful auth.
  - `profileProvider`: Invalidated to force fresh user profile pull.
- **Backend / Data Layer:**
  - Supabase Auth: `signInWithPassword`, `signInWithOAuth(OAuthProvider.google)`.
- **User Flow & Navigation:**
  - Success: Context routed to `/` (`CheckAuthScreen`) for full profile and grade verification.
  - Unregistered Google user caught with error `account-not-found`: Redirects automatically to `/register` with warning snackbar.

#### Screen 06: Registration Screen
- **Exact File Path:** `lib/features/auth/register_screen.dart`
- **Class Name:** `RegisterScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Student registration portal capturing university identity details (Full Name, Nickname, Official Student ID, Student Email, Password).
- **Visual & Interactive Widgets:**
  - Form Fields: Full Name, Nickname, 13-digit Student ID (e.g. `2021-1-60-001`), Email Address, Password, Confirm Password.
  - Password strength and confirmation validator.
  - "Create Account" cyan gradient button.
  - "Verify Email" Dialog: Modal popup displayed if Supabase session is null post-registration, notifying the student to click the email confirmation link.
- **State Management & Providers:**
  - `authRepositoryProvider`: Invokes `signUp(...)`.
- **Backend / Data Layer:**
  - Supabase Auth `signUp`: Stores user metadata (`displayName`, `fullName`, `studentId`).
  - Database Trigger: PostgreSQL trigger `handle_new_user` intercepts auth creation and inserts default row into table `profiles`.

#### Screen 07: Forgot Password Screen
- **Exact File Path:** `lib/features/auth/forgot_password_screen.dart`
- **Class Name:** `ForgotPasswordScreen` (`StatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Two-step password recovery engine. Step 1 sends an OTP/recovery link to the student email; Step 2 verifies the OTP code and accepts the new password.
- **Visual & Interactive Widgets:**
  - State 1: Email input form with "Send Recovery Code" button.
  - State 2: 6-digit OTP input field, New Password input with visibility toggle, and "Verify & Update Password" button.
- **State Management & Backend:**
  - Supabase Auth: `resetPasswordForEmail`, `verifyOTP(type: OtpType.recovery)`, `updateUser(UserAttributes(password))`.
  - Navigation: On successful update, routes directly to `/dashboard`.

#### Screen 08: Reset Password Screen
- **Exact File Path:** `lib/features/auth/reset_password_screen.dart`
- **Class Name:** `ResetPasswordScreen` (`StatefulWidget`)
- **Functional Breakdown:**
  - Deep-link landing screen for email recovery callback URLs (`ewumate://login-callback`). Accepts new password and updates credentials via `Supabase.instance.client.auth.updateUser`.

---

### 3.3 Feature 03: Course Browser

#### Screen 09: Course Browser Screen
- **Exact File Path:** `lib/features/course_browser/presentation/course_browser_screen.dart`
- **Class Name:** `CourseBrowserScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Unified university course directory and section inspection tool.
  - Supports searching across hundreds of courses, filtering by credit hours, faculty initials, days of the week, and toggling between Current Semester and Upcoming Semester offerings.
- **Visual & Interactive Widgets:**
  - **App Bar:** Back navigation, "Course Browser" title, and scope toggle pill ("Active Semester" vs "Upcoming Semester").
  - **Search Bar:** Real-time search input with 400ms debouncing and clear button.
  - **Filter Row:** Horizontal scrollable chips: "Filter by Faculty", "Credits (1, 1.5, 3, 4)", "Class Days (ST, MW, RA, F)".
  - **Course Card (`CourseCard`):** Frosted glass container displaying Course Code (e.g. `CSE207`), Course Name, Credit count, Prerequisites pill, and expandable section list showing section number, room, timeslot, and assigned instructor.
  - **Infinite Scroll / Pagination:** Loads 50 courses per page via `PaginatedCoursesNotifier`.
- **State Management & Providers:**
  - `courseSearchQueryProvider`: Tracks active text search.
  - `courseBrowserFilterProvider`: Stores active multi-parameter filters (`faculty`, `credits`, `days`).
  - `paginatedCoursesProvider`: Infinite-scroll async notifier.
  - `selectedSemesterScopeProvider`: Toggles between `SemesterScope.active` and `SemesterScope.upcoming`.
- **Backend / Data Layer:**
  - Supabase table `courses`, `course_sections`.
  - Upstash Edge Redis: High-speed caching for full course catalogs.
- **User Flow & Navigation:**
  - Entry: Drawer -> "Course Browser" (`/courses`) or Dashboard "Courses" shortcut.
  - Tapping section reveals section details, faculty profile link, and prerequisite dependencies.

---

### 3.4 Feature 04: Dashboard (Daily Academic Command Hub)

#### Screen 10: Dashboard Screen
- **Exact File Path:** `lib/features/dashboard/dashboard_screen.dart`
- **Class Name:** `DashboardScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - The central command center of EWUmate. Combines dynamic ambient weather/sky visuals, class countdowns, daily timeline schedules, upcoming deadlines, overdue assignment alerts, and university announcements into a single unified view.
  - Employs Zero-Wait Entry: Renders cached daily routine from Hive within 1 frame (sub-16ms) before verifying network updates.
- **Visual & Interactive Widgets:**
  - **Dynamic Sky Header (`DashboardHeader`, `SkyAnimationWidget`):** Live Lottie animation displaying dawn, daylight, sunset, or starfield based on device clock. Displays student's first name, current date, and active semester badge.
  - **Next Class Hero Card (`NextClassCard`):** Prominent glowing cyan card highlighting the immediate upcoming class, room number, faculty initial, and live countdown timer ("Starts in 22 minutes").
  - **Today's Schedule Timeline (`DashboardScheduleTimeline`, `TimelineScheduleCard`):** Interactive vertical timeline showing every class of the day with status badges ("Completed", "In Progress", "Upcoming").
  - **Exam Timeline (`DashboardExamTimeline`):** Collapsible countdown card showing midterm and final exam schedules when within 14 days of exam week.
  - **Tasks Preview Widget (`DashboardTasksPreview`):** Top 3 impending assignments and quizzes with direct checkbox completion toggles and "See All" shortcut.
  - **Pending Attendance Widget (`PendingAttendanceWidget`):** Interactive prompt alerting students to unconfirmed classes from the past 24 hours, allowing instant "Present" or "Absent" marking.
  - **Dynamic Banner Tray (`DashboardBannerTray`):** Carousel displaying advising announcements, portal sync reminders, and system updates.
  - **Overdue Checkpoint (`DashboardOverdueCheckpoint`):** Red warning card for overdue tasks.
  - **Pre-Course Assessment Modal (`PreCourseAssessmentDialog`):** Dialog checking whether course outline and marks distribution have been initialized.
  - **Floating Action Button:** Quick "+ Add Task" button invoking `AddTaskBottomSheet`.
- **State Management & Providers:**
  - `DashboardController`: Orchestrates background refreshes, Hive reads, silent polling every 5 minutes, and local notification delivery checks.
  - `academicStateProvider`: Resolves current semester code and track.
  - `allTasksStreamProvider`: Real-time task stream.
  - `fcmServiceProvider`: Pops pending notification dialogs if app opened from a push alert.
- **Backend / Data Layer:**
  - Hive Box `dashboard_box`: Key `${userId}_${semesterCode}_schedule`.
  - Supabase RPC: `get_daily_schedule_v2`.
  - Supabase tables: `tasks`, `schedule_exceptions`, `user_semester_states`, `app_config`.
- **User Flow & Navigation:**
  - Entry: Root `/dashboard` via `MainShell`.
  - Tapping hamburger opens `AppDrawer`.
  - Tapping Next Class opens `ScheduleScreen`.
  - Tapping any task opens `TasksScreen`.
  - Pull-to-refresh invalidates cache and queries fresh Supabase timetable.

---

### 3.5 Feature 05: Faculty Directory & Community Reviews

#### Screen 11: Faculty Directory Screen
- **Exact File Path:** `lib/features/faculty_directory/presentation/faculty_directory_screen.dart`
- **Class Name:** `FacultyDirectoryScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Comprehensive searchable directory of all East West University academic faculty across all departments.
  - Displays crowdsourced ratings, department filters, and search by name, initial, or designation.
- **Visual & Interactive Widgets:**
  - **App Bar:** `EWUmateAppBar` with title "Faculty Directory".
  - **Search Bar:** Glowing cyan text field with 400ms debouncing and search icon.
  - **Department Selector:** Horizontal pill selector (`All`, `CSE`, `BUS`, `ENG`, `EEE`, `MATH`, `LAW`, `PHR`).
  - **Faculty Card (`FacultyCard`):** Card displaying faculty initials badge, full name, designation, department, email, star rating, and review count.
- **State Management & Providers:**
  - `facultyDirectoryProvider`: Loads and filters faculty list.
  - `facultySearchQueryProvider`: Holds active search string.
  - `facultyDepartmentFilterProvider`: Holds selected department.
- **Backend / Data Layer:**
  - Supabase table `faculties` (joined with ratings view).
  - Hive Box `faculty`: Persists offline directory snapshot.
- **User Flow & Navigation:**
  - Tapping any faculty card navigates to `FacultyDetailsScreen` (`/services/faculty-directory/details`, passing `Faculty` entity as `state.extra`).

#### Screen 12: Faculty Details Screen
- **Exact File Path:** `lib/features/faculty_directory/presentation/faculty_details_screen.dart`
- **Class Name:** `FacultyDetailsScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Deep inspection view for an individual professor. Features 5 tabs covering bio, courses taught, crowdsourced office hours, student reviews, and direct email/phone contact.
- **Visual & Interactive Widgets:**
  - **Hero Card (`FacultyHeroCard`):** Avatar, full name, initials badge, designation, department, room number, average rating star bar.
  - **5-Tab Navigation Bar:**
    1. About (`FacultyAboutTab`): Academic background, room location, official phone extension.
    2. Courses (`FacultyCoursesTab`): Enrolled sections taught this semester and historically.
    3. Office Hours (`FacultyOfficeHoursTab`): Approved student consultation hours. Features button to open `SubmitOfficeHoursSheet`.
    4. Reviews (`FacultyReviewsTab`): Student review cards, difficulty meter, grading leniency, attendance strictness, and "+ Write Review" trigger.
    5. Contact (`FacultyContactTab`): Tap-to-email with automatic clipboard copy toast and tap-to-dial.
  - **Sticky Bottom Action Bar (`FacultyBottomBar`):** "Review Professor" and "Submit Office Hours" buttons.
  - **Modals & Sheets:**
    - `SubmitFacultyReviewSheet`: Form with 5-star rating, difficulty rating, grading leniency, attendance strictness, and anonymous review text.
    - `SubmitOfficeHoursSheet`: Crowdsourcing form to submit office hours with photo proof upload.
    - `FacultyReviewsSpotlightDialog`: Dialog highlighting top positive and constructive reviews.
- **State Management & Providers:**
  - `approvedOfficeHoursProvider`: Family FutureProvider fetching verified office hours for `faculty.initials`.
  - `facultyReviewsRepositoryProvider`: Streams student review records.
- **Backend / Data Layer:**
  - Supabase tables: `faculties`, `faculty_reviews`, `faculty_office_hours`.

---

### 3.6 Feature 06: Layout & Navigation Shell

#### Screen 13: Main Shell (`MainShell`)
- **Exact File Path:** `lib/core/widgets/main_shell.dart`
- **Class Name:** `MainShell` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - The master container wrapping the 5 primary tabs of the app inside a `ShellRoute`.
  - Manages global scaffold keys, persistent drawer binding, floating bottom navigation, and grade-blocking runtime redirects.
- **Visual & Interactive Widgets:**
  - `FullGradientScaffold`: Persistent dark navy gradient wrapper.
  - `EwuFloatingNavBar`: Custom curved navigation bar floating above bottom edge with 5 destinations:
    1. Home (`/dashboard`)
    2. Tasks (`/tasks`)
    3. Progress (`/semester-progress`)
    4. Schedule (`/schedule-manager`)
    5. Services (`/services`)
  - `AnimatedSwitcher`: 250ms cross-fade page transition between top-level tab destinations.
  - `AppDrawer`: Linked drawer opened via swipe or app bar hamburger icon.
- **State Management & Providers:**
  - `scaffoldKeyProvider`: Overrides default scaffold key for deep widget access.
  - `requiresGradeEntryProvider`: Listens to grade blocking status. If active, forces `context.go('/results/grade-entry')`.

#### Screen 14: Main Layout Screen (`MainLayoutScreen`)
- **Exact File Path:** `lib/features/layout/presentation/main_layout_screen.dart`
- **Class Name:** `MainLayoutScreen` (`StatelessWidget`)
- **Functional Breakdown:**
  - Standalone Material 3 `NavigationBar` wrapper provided as an alternative lightweight layout scaffold.

---

### 3.7 Feature 07: Notifications & Class Reminders

#### Screen 15: Notifications Screen
- **Exact File Path:** `lib/features/notifications/presentation/notifications_screen.dart`
- **Class Name:** `NotificationsScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - In-app notification center displaying university announcements, routine updates, task deadlines, and administrative notices.
- **Visual & Interactive Widgets:**
  - **App Bar:** Title "Notifications", "Class Reminder Settings" wrench icon, and "Mark All as Read" checkmark icon.
  - **Notification List:** Grouped cards showing category icon, title, body, timestamp, unread cyan indicator dot, and image thumbnail.
  - **Empty State:** Illustrated card displayed when no notifications exist.
  - **Notification Detail Popup:** Triggered on tap via `FCMService.showNotificationPopup`, displaying complete body text, image, and action URL button.
- **State Management & Providers:**
  - `userNotificationsProvider`: Streams all notifications for current user from `NotificationRepository`.
- **Backend / Data Layer:**
  - Supabase table `notifications`. Mutations: `markAsRead(id)`, `markAllAsRead(userId)`.

#### Screen 16: Reminder Settings Screen
- **Exact File Path:** `lib/features/notifications/presentation/reminder_settings_screen.dart`
- **Class Name:** `ReminderSettingsScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Advanced class reminder customization engine. Allows students to configure exact notification lead times (e.g. 10m, 15m, 30m, 1h 45m) globally or independently for each enrolled course.
- **Visual & Interactive Widgets:**
  - Course Selector: Horizontal chips to switch between "Global (All Classes)" and specific course codes (e.g., `CSE325`, `ENG102`).
  - Active Reminder Pills: Removable chips showing configured offsets (e.g., `30m before`, `10m before`).
  - "+ Add Reminder" button invoking `ReminderDurationPickerDialog`.
  - Preview Action: "Preview Weekly Schedule" button opening `ReminderSchedulePreviewSheet` to verify exact trigger times.
  - Save Button: Cyan button persisting offsets to user preferences.
- **State Management & Providers:**
  - `profileRepositoryProvider`: Reads and updates `profile.preferences['reminder_offsets']`.
  - `localNotificationSchedulerProvider`: Re-schedules alarms upon saving.
- **Backend / Data Layer:**
  - Supabase table `profiles`.
  - Hive Box `routine_cache_box`: Updates scheduled notification alarm records.

---

### 3.8 Feature 08: Onboarding & Academic Bootstrapping

#### Screen 17: Program Selection Screen
- **Exact File Path:** `lib/features/onboarding/program_selection_screen.dart`
- **Class Name:** `ProgramSelectionScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Initial step of student onboarding. Captures student's Department, Degree Program (e.g. B.Sc. in CSE, BBA, B.Pharm), and Admitted Semester (e.g. `Spring 2022`).
- **Visual & Interactive Widgets:**
  - Stepper indicator showing Step 1 of 3.
  - Department Dropdown / Cards: Populated dynamically from database.
  - Program Dropdown: Filtered by chosen department.
  - Admitted Semester Dropdown: Populated from historical semester records.
  - "Continue" button validating selections and saving to database.
- **State Management & Providers:**
  - `onboardingRepositoryProvider`: Executes `fetchDepartments()`, `fetchSemesters()`, `updateProgram(...)`.
- **Backend / Data Layer:**
  - Supabase tables `departments`, `programs`, `semesters`, `profiles`.

#### Screen 18: Profile Setup Screen
- **Exact File Path:** `lib/features/onboarding/presentation/profile_setup_screen.dart`
- **Class Name:** `ProfileSetupScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Step 2 of onboarding. Captures student avatar, Full Legal Name, Preferred Nickname, and 13-digit Student ID.
- **Visual & Interactive Widgets:**
  - Avatar Picker: Circular avatar container with camera overlay icon; opens gallery via `ImagePicker`.
  - Form Fields: Full Name, Nickname, Student ID (validated against EWU format `YYYY-S-DD-NNN`).
  - "Save & Continue" cyan button with progress spinner.
- **State Management & Providers:**
  - `onboardingRepositoryProvider`: Saves profile updates and sets `onboarding_status = 'course_history'`.
  - `StorageService`: Uploads avatar image to Supabase Storage bucket `profile_images`.

#### Screen 19: Course History Screen
- **Exact File Path:** `lib/features/onboarding/course_history_screen.dart`
- **Class Name:** `CourseHistoryScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Step 3 of onboarding (and accessible in edit mode from Profile).
  - Allows students to record all previously completed courses, enrolled sections, and letter grades semester-by-semester, generating the baseline for CGPA calculation and degree progress.
- **Visual & Interactive Widgets:**
  - **Semester Navigator (`CourseHistoryHeaderCard`):** Forward/backward arrows to step through semesters from Admitted Semester to Current Semester.
  - **Course List (`CourseHistoryCourseList`):** Searchable course catalog for selected semester.
  - **Grade Selector Dialog (`CourseHistoryGradeDialog`):** Modal wheel/grid to assign letter grades (A+, A, A-, B+, etc.).
  - **Sync Overlay (`CourseHistorySyncOverlay`):** Direct shortcut button to launch `PortalSyncScreen` to auto-import course history from the official university portal.
  - **Bottom Summary Bar (`CourseHistoryBottomBar`):** Real-time calculated semester GPA, total credits earned, and "Finish Setup" button.
- **State Management & Providers:**
  - `onboardingRepositoryProvider`: Saves semester enrollments and marks `onboarding_status = 'completed'`.
  - `allSemesterSummariesProvider`: Invalidated to recalculate CGPA.
- **Backend / Data Layer:**
  - Supabase tables `enrollments`, `semester_summaries`, `profiles`.

#### Screen 20: Welcome Tour Screen
- **Exact File Path:** `lib/features/onboarding/presentation/welcome_tour_screen.dart`
- **Class Name:** `WelcomeTourScreen` (`StatefulWidget`)
- **Functional Breakdown:**
  - 10-slide interactive page-view tour presenting the core feature pillars of EWUmate.
  - Features smooth page indicator dots, skip button, and "Get Started" completion button setting `TutorialService.markAsSeen('welcome_tour_v1')`. Routes directly to `/dashboard`.

#### Screen 21: Generic Onboarding Screen
- **Exact File Path:** `lib/features/onboarding/presentation/onboarding_screen.dart`
- **Class Name:** `OnboardingScreen` (`ConsumerWidget`)
- **Functional Breakdown:**
  - Master state forwarder directing students to `ProgramSelectionScreen`, `ProfileSetupScreen`, or `CourseHistoryScreen` based on their stored `onboardingStatus`.

---

### 3.9 Feature 09: Profile, Feedback & Developer Support

#### Screen 22: Profile Screen
- **Exact File Path:** `lib/features/profile/presentation/profile_screen.dart`
- **Class Name:** `ProfileScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - User account hub displaying profile picture, student credentials, academic program, cumulative CGPA, earned credits, app preferences, and session controls.
- **Visual & Interactive Widgets:**
  - **Avatar & Identity Card:** Tappable avatar to upload new photo; display of full name, nickname, student ID, and email.
  - **Academic Metric Tiles:** Cumulative CGPA tile, Credits Completed tile, Degree Track badge (`Tri-Semester` / `Bi-Semester`).
  - **Action Menu:**
    - "Edit Course History" -> pushes `/onboarding/course-history` in edit mode.
    - "Notification & Reminder Settings" -> pushes `/notifications/settings`.
    - "Portal Sync" -> pushes `/portal-sync`.
    - "Send Feedback & Report Bugs" -> pushes `/feedback`.
    - "Support Developer" -> pushes `/profile/support-developer`.
    - "Rate on Google Play" -> opens Play Store review modal.
  - **Sign Out Button:** Red button with confirmation dialog. Empties all Hive boxes (`CacheService.clearAll()`) and invokes `AuthRepository.signOut()`.
- **State Management & Providers:**
  - `userProfileProvider`: Streams user `Profile`.
  - `authRepositoryProvider`: Handles authentication teardown.
- **Backend / Data Layer:**
  - Supabase table `profiles`.
  - Hive Box `profile_box`.

#### Screen 23: Feedback & Support Screen
- **Exact File Path:** `lib/features/profile/presentation/feedback_screen.dart`
- **Class Name:** `FeedbackScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Direct communication pipeline between students and the EWUmate engineering team.
  - Features a two-tab interface: Tab 1 ("Submit Feedback") for submitting bug reports or feature requests with device logs; Tab 2 ("My Feedbacks") for viewing two-way support chat threads with administrator replies.
- **Visual & Interactive Widgets:**
  - Tab 0: Feedback type chips (Bug, Feature Request, Academic Discrepancy, Other), message text area, app version display (`PackageInfo`), and "Submit Feedback" cyan button.
  - Tab 1: List of past submissions with status tags ("Open", "In Progress", "Resolved"), administrator response bubbles, and reply text input.
- **State Management & Backend:**
  - Supabase tables `feedbacks` and `feedback_comments`. Real-time comment updates.

#### Screen 24: Support Developer Screen
- **Exact File Path:** `lib/features/profile/presentation/support_developer_screen.dart`
- **Class Name:** `SupportDeveloperScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Community crowdfunding page allowing students to contribute to server hosting costs (Supabase, Azure, Upstash Redis, Google Play developer accounts).
  - Displays bKash, Nagad, Rocket, and Upay merchant/personal payment numbers with one-tap clipboard copy.
  - Verification submission form: Captures Payment Method, Transaction ID (TrxID), Sender Number, Amount, and payment screenshot upload.
- **State Management & Backend:**
  - Supabase Storage bucket `donation_proofs`.
  - Supabase table `donations`.

---

### 3.10 Feature 10: Progress & Course Marks Editor

#### Screen 25: Progress Screen
- **Exact File Path:** `lib/features/progress/presentation/progress_screen.dart`
- **Class Name:** `ProgressScreen` (`ConsumerWidget`)
- **Functional Breakdown & Purpose:**
  - Overview of all currently enrolled courses in the active semester, showing real-time marks progress bars and total projected scores.
- **Visual & Interactive Widgets:**
  - **App Bar:** Title "Semester Progress".
  - **Course Progress Cards:** Displays Course Code (e.g. `CSE311`), title, credit hours, total marks scored so far out of 100, and grade projection badge.
  - **Empty State:** Illustrated empty state when no courses are enrolled.
- **State Management & Navigation:**
  - `currentSemesterMarksProvider`: Reads current marks list from `ProgressRepository`.
  - Tapping any card pushes `CourseMarksEditorScreen`.

#### Screen 26: Course Marks Editor Screen
- **Exact File Path:** `lib/features/progress/presentation/screens/course_marks_editor_screen.dart`
- **Class Name:** `CourseMarksEditorScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Deep marks editor for an individual course.
  - Allows students to configure the syllabus weight distribution (Midterm, Final, Quizzes, Assignments, Presentations, Attendance, Labs) and input obtained scores.
- **Visual & Interactive Widgets:**
  - **2-Tab Layout:** Tab 0 ("Obtained Scores"), Tab 1 ("Weight Distribution").
  - Form Fields: Number fields for `distMid`, `distFinal`, `distQuiz`, `distAssignment`, `distPresentation`, `distAttendance`, `distLab` and corresponding `obt*` fields.
  - "Save Marks" button with offline queuing support.
- **State Management & Backend:**
  - `ProgressRepository.updateCourseMarks(...)`: Upserts into Supabase table `semester_course_marks`.
  - Offline Sync: Enqueues mutation into Hive `sync_queue_box` if disconnected.

---

### 3.11 Feature 11: Results & Mandatory Grade Blocker

#### Screen 27: Academic Results Screen
- **Exact File Path:** `lib/features/results/presentation/results_screen.dart`
- **Class Name:** `ResultsScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Complete transcript history viewer. Lists all completed semesters with SGPA, completed credits, and individual course letter grades.
- **Visual & Interactive Widgets:**
  - **Header Summary Card:** Cumulative CGPA dial, total degree credits earned, and honors standing.
  - **Semester Accordions:** Expandable cards for each completed semester (e.g. `Spring 2024 — GPA 3.85 | 12 Credits`).
  - **Course Table:** Course Code, Title, Credits, Grade Point, and Letter Grade with colored badge.
- **State Management & Backend:**
  - `allSemesterSummariesProvider`: Fetches from Supabase `semester_summaries`.
  - Pull-to-refresh invalidates `allSemesterSummariesProvider` and `userProfileProvider`.

#### Screen 28: Grade Entry Screen (Mandatory Grade Blocker)
- **Exact File Path:** `lib/features/results/presentation/grade_entry_screen.dart`
- **Class Name:** `GradeEntryScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - **Critical Architectural Gatekeeper:** Enforces academic integrity by blocking app access when a student has completed a semester but has not yet recorded their official letter grades.
  - Activated in two phases:
    - *Phase 1 (Hanging Past Courses):* Ungraded enrollments from previous semesters (`grade IS NULL`).
    - *Phase 2 (Semester Conclusion):* Active semester has concluded and `active_semester.grade_submission_start` date has passed.
  - Prevents students from bypassing to the Dashboard until every pending course is assigned a grade or marked as "Dropped" / "Withdrawn".
- **Visual & Interactive Widgets:**
  - **Warning Header:** Amber alert card explaining why the screen is displayed and which semester requires grades.
  - **Course Grade Form Cards:** Displays course code and section; provides dropdown to select letter grade (A+, A, A-, B+, B, B-, C+, C, D, F) or status (Dropped, Withdrawn).
  - **Dynamic Grade Point Indicator:** Displays corresponding grade point using `GradeHelper` according to the active semester's policy (Legacy vs. Modern).
  - **"Submit Grades & Unlock App" Button:** Validates all fields are filled, batch-upserts grades to Supabase, triggers CGPA recalculation, and unblocks the app.
- **State Management & Providers:**
  - `pendingGradesProvider`: Queries blocking enrollments from `enrollments` table.
  - `requiresGradeEntryProvider`: Re-evaluated upon submission. When it resolves to `false`, GoRouter routes to `/dashboard`.
- **Backend / Data Layer:**
  - Supabase table `enrollments`: Batch updates `grade`, `grade_point`, `status`.
  - Supabase table `semester_summaries`: Automatically updated via database trigger.

---

### 3.12 Feature 12: Schedule Manager & Weekly Timetable

#### Screen 29: Schedule Screen
- **Exact File Path:** `lib/features/schedule/presentation/schedule_screen.dart`
- **Class Name:** `ScheduleScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Comprehensive timetable manager offering a 2-week rolling schedule view, routine exception tracking, and custom manual class injection.
- **Visual & Interactive Widgets:**
  - **Day Selector Bar (`ScheduleDaySelector`):** Horizontal calendar strip allowing students to tap any day of the current or next week.
  - **3-Tab View:**
    1. Upcoming (`ScheduleUpcomingTab`): Future classes for the selected day.
    2. Past (`SchedulePastTab`): Classes already completed today.
    3. Pending Events (`PendingEventsTab`): Make-up classes, exam slots, room changes, or cancelled sessions.
  - **Timetable Cards:** Room number, course code, section number, instructor name, class start/end times, and live status.
  - **Schedule Exceptions Actions:** Allows student to mark a class as "Cancelled", "Rescheduled", or "Make-up".
  - **"+ Add Class" FAB:** Opens `AddManualClassSheet` to add non-portal classes or lab sessions.
- **State Management & Providers:**
  - `academicStateProvider`: Resolves current semester code.
  - `dashboardRepositoryProvider`: Loads daily schedule and exceptions.
  - `routineCacheServiceProvider`: Updates local routine checksums and re-schedules exact alarms.
- **Backend / Data Layer:**
  - Supabase tables `schedule_exceptions`, `user_semester_states`, `enrollments`.
  - Hive Box `routine_cache_box`.

---

### 3.13 Feature 13: Semester Progress, CGPA Simulation & Attendance

#### Screen 30: Semester Progress Screen
- **Exact File Path:** `lib/features/semester_progress/semester_progress_screen.dart`
- **Class Name:** `SemesterProgressScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - High-level progress tracker for the running semester. Displays real-time course marks cards, overall semester attendance percentage, and target grade simulations.
- **Visual & Interactive Widgets:**
  - **Semester Switcher:** Allows toggling between current semester and historical records.
  - **Course Progress Cards (`CourseProgressCard`):** Displays course code, instructor, marks scored out of total evaluated so far, and attendance percentage ring.
  - **Target Grade Simulator (`TargetGradeSimulator`):** Interactive slider simulating what marks are required in final exams to secure an A or A-.
  - **Heartbeat Sync:** Periodic 2-minute timer pushing offline marks mutations to Supabase.
- **State Management & Navigation:**
  - `semesterProgressDataProvider`: Family provider loading course marks and attendance.
  - Tapping any card pushes `CourseProgressDetailScreen`.

#### Screen 31: Course Progress Detail Screen
- **Exact File Path:** `lib/features/semester_progress/course_progress_detail_screen.dart`
- **Class Name:** `CourseProgressDetailScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Exhaustive course evaluation workbench featuring 3 tabs:
    1. **Marks Input (`CourseMarksInputTab`):** Numerical entry of scores achieved in every assessment.
    2. **Attendance Sessions (`AttendanceSessionsTab`):** Calendar grid of all theoretical and laboratory lecture dates generated via `AttendanceCalendarService`. Students tap dates to toggle Present, Absent, or Cancelled.
    3. **Course Outline Setup (`CourseOutlineSetupTab`):** Customizes total marks per component to match the professor's syllabus.
  - **Summary Card (`CourseProgressSummaryCard`):** Real-time weighted percentage scored and attendance rate.
- **State Management & Backend:**
  - `CourseMarksController`: Local state manager for marks mutations.
  - `AttendanceCalendarService`: Generates calendar sessions based on class days (ST, MW, RA) and university holidays.
  - Supabase table `semester_course_marks`.

#### Screen 32: Semester Summary & Academic Journey Screen
- **Exact File Path:** `lib/features/semester_progress/semester_summary_screen.dart`
- **Class Name:** `SemesterSummaryScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Visual analytics dashboard for academic goals, scholarship eligibility, and grade distribution.
- **Visual & Interactive Widgets:**
  - **CGPA Hero Dial Card (`CgpaHeroDialCard`):** Radial CGPA meter with target comparison.
  - **Scholarship Selector Card (`ScholarshipSelectorCard`):** Live evaluation against East West University scholarship criteria:
    - 100% Tuition Waiver: CGPA ≥ 3.97
    - 50% Tuition Waiver: CGPA ≥ 3.93
    - Medha Lalon / Financial Assistance
  - **Goal Input Grid (`GoalInputGrid`):** What-if simulator calculating future CGPA based on target semester GPA.
  - **Awards Status Card (`AwardsStatusCard`):** Badges for Dean's Honor List and Merit Scholarships.
  - **Academic Years Timeline (`AcademicYearsTimeline`):** Year-over-year progression chart.
  - **Grade Distribution Chart (`GradeDistributionChart`):** Bar chart displaying count of A's, B's, C's, etc.
- **State Management & Providers:**
  - `semesterSummaryProviders.dart`: Provides `userScholarshipPolicyProvider`, `currentAnalyticsProvider`, `academicYearsFutureProvider`.

---

### 3.14 Feature 14: Services, Cover Page & EWU Portal Sync

#### Screen 33: Services Hub Screen
- **Exact File Path:** `lib/features/services/presentation/services_screen.dart`
- **Class Name:** `ServicesScreen` (`ConsumerWidget`)
- **Functional Breakdown & Purpose:**
  - Utility launcher presenting tiles for all academic micro-services:
    1. Cover Page Generator (`/services/cover-page`)
    2. Faculty Directory & Reviews (`/services/faculty-directory`)
    3. Study Materials Vault (`/services/study-vault`)
    4. EWU Portal Sync (`/portal-sync`)
    5. Faculty Assignment Tracker (`/services/faculty-assignment`)
    6. Faculty List PDF Download (`/services/faculty-list`)

#### Screen 34: Cover Page Generator Screen
- **Exact File Path:** `lib/features/services/presentation/cover_page_screen.dart`
- **Class Name:** `CoverPageScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Comprehensive PDF cover sheet synthesizer tailored specifically to East West University assignment standards.
  - Generates print-ready PDFs formatted with official department headers, logos, course titles, instructor designations, student group members, allocation dates, and submission dates.
- **Visual & Interactive Widgets:**
  - **Template Selector:** Horizontal selector for 6 official formats:
    - `assignment`: Standard individual assignment
    - `lab_report`: Engineering/Science laboratory report
    - `physics_lab`: Physics lab format with experiment number
    - `group_project`: Multi-student project report
    - `term_paper`: Formal term paper format
    - `mps_assignment`: Management & Public Sector format
  - **Course Autofill:** Dropdown populated from active enrolled courses, autofilling course title, code, section, and instructor details.
  - **Instructor Details:** Faculty name, department, designation (`Lecturer`, `Senior Lecturer`, `Assistant Professor`, `Associate Professor`, `Professor`).
  - **Group Members Builder:** Dynamic form to add up to 10 additional students (Name, ID, Department).
  - **Date Pickers:** Allocation date and submission date pickers with calendar dialogs.
  - **"Generate Cover Page PDF" Button:** Invokes Azure Function microservice `/api/generate_pdf` or client-side generator. Downloads file, saves to device storage via `path_provider`, and launches system PDF viewer via `open_filex`.
- **Backend & Network:**
  - Azure Function `/api/generate_pdf`.
  - Supabase table `courses`.

#### Screen 35: Faculty Assignment Tracker Screen
- **Exact File Path:** `lib/features/services/presentation/faculty_assignment_screen.dart`
- **Class Name:** `FacultyAssignmentScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Crowdsourced section instructor verification engine.
  - Allows students to report newly assigned faculty members for unannounced sections and upload verification proof (e.g. portal routine screenshot, LMS screenshot) for administrator review.
- **Visual & Interactive Widgets:**
  - **Stepper (`FacultyAssignmentStepper`):** Step 1: Assign Courses; Step 2: Upload Proof.
  - **Course & Section Picker:** Search modal (`CourseSearchModal`) and section dropdown.
  - **Faculty Search Modal (`FacultySearchModal`):** Search by faculty name or initials.
  - **Proof Upload Step (`UploadProofStep`):** Image and document picker (`file_picker`, `image_picker`) with image preview dialog (`ProofPreviewDialog`).
  - **Submission History Sheet (`FacultySubmissionsSheet`):** Slide-up sheet showing student's past reports and approval statuses.
- **State Management & Backend:**
  - `FacultyAssignmentRepository`: Interacts with Supabase bucket `assignment_proofs` and table `faculty_course_assignments`.

#### Screen 36: Faculty List (PDF) Screen
- **Exact File Path:** `lib/features/services/presentation/faculty_list_screen.dart`
- **Class Name:** `FacultyListScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown:**
  - Direct integration card linking to the official university Google Drive directory containing all department faculty PDF rosters. Supports external browser launch via `url_launcher`.

#### Screen 37: EWU Portal Sync Screen (6-Phase Synchronization Wizard)
- **Exact File Path:** `lib/features/services/presentation/portal_sync_screen.dart`
- **Class Name:** `PortalSyncScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Fully automated, client-side bidirectional synchronization tool that directly logs into `https://portal.ewubd.edu`, parses student profile metadata, downloads current semester course sections and class routines, extracts complete historical degree grades, and writes them into Supabase and Hive storage.
  - Features arithmetic captcha solving, cookie session extraction, and a 6-phase state machine architecture.
- **Visual & Interactive Widgets (6 State Views):**
  1. **Phase 1: `PortalSyncStartView` (`portal_sync_start_view.dart`):**
     - Form: Student ID input, Password input with visibility toggle, "Remember Credentials" checkbox, security disclaimer banner stating credentials are never transmitted to third-party servers.
  2. **Phase 2: `PortalSyncConnectingView` (`portal_sync_connecting_view.dart`):**
     - Live Animated Pulse & Spinner: 5-step checklist animated sequentially as portal requests succeed:
       - Step 1: Connecting to `portal.ewubd.edu`
       - Step 2: Solving arithmetic security captcha
       - Step 3: Authenticating student session
       - Step 4: Extracting active enrolled courses & faculty
       - Step 5: Fetching complete degree audit records
  3. **Phase 3: `PortalSyncReadyView` (`portal_sync_ready_view.dart`):**
     - Connection success banner; displays student's official name, department, and active semester.
  4. **Phase 4: `PortalSyncPreviewView` (`portal_sync_preview_view.dart`):**
     - Verification checklist allowing student to select what to sync:
       - [x] Current Class Routine & Section Timeslots
       - [x] Historical Semester Grades & Credits
       - [ ] Profile Metadata (Admitted semester, Track)
     - Expandable course cards displaying section times and assigned teachers found on the portal.
  5. **Phase 5: `PortalSyncSyncingView` (`portal_sync_syncing_view.dart`):**
     - Progress animation showing database batch writes into Supabase `enrollments`, `user_semester_states`, and `profiles`.
  6. **Phase 6: `PortalSyncCompleteView` (`portal_sync_complete_view.dart`):**
     - Success confetti/illustration; summary of imported courses and updated CGPA. Action button "Go to Dashboard" which refreshes all app providers.
- **State Management & Providers:**
  - `PortalService` (`portal_service.dart`): Executes HTTP requests against university portal.
  - `portalSyncRepositoryProvider`: Executes batch Supabase database operations.
  - `cacheServiceProvider`: Clears and repopulates dashboard and schedule caches.
- **Backend & Network:**
  - Target: `https://portal.ewubd.edu/Account/Login`, `/api/StudentProfile/GetStudentProfile`, `/api/Advising/...`, `/api/DegreeReview/...`.
  - Supabase tables: `enrollments`, `user_semester_states`, `profiles`, `semester_summaries`.

---

### 3.15 Feature 15: Study Vault (Crowdsourced Academic Repository)

#### Screen 38: Study Vault Screen
- **Exact File Path:** `lib/features/study_vault/presentation/study_vault_screen.dart`
- **Class Name:** `StudyVaultScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Crowdsourced academic document repository. Students search, filter, preview, and download past exam papers, lecture notes, lab manuals, sample code, and course outlines.
- **Visual & Interactive Widgets:**
  - **App Bar:** Title "Study Materials Vault", "+ Upload" button, and "My Uploads" folder icon.
  - **Search Bar:** 400ms debounced search input supporting course codes and material titles.
  - **Filter Row:** Department filters (`All`, `CSE`, `BUS`, etc.) and Material Type filters (`Mid Questions`, `Final Questions`, `Notes`, `Slides`, `Lab Manuals`).
  - **Document Card:** Displays file type badge (PDF, DOC, XLS, PPT, IMG), course code, semester, uploader nickname, download count, and date.
  - **Action Menu:** Tap opens Google Drive preview link; download increments `download_count`.
- **State Management & Providers:**
  - `studyMaterialsProvider`: Paginated stream of verified study materials from `StudyVaultRepository`.
  - `vaultFiltersProvider`: State provider holding active search and category filters.
- **Backend / Data Layer:**
  - Supabase table `study_materials`.
  - Google Drive REST API / Shared Drive folder.

#### Screen 39: My Study Materials Screen
- **Exact File Path:** `lib/features/study_vault/presentation/my_study_materials_screen.dart`
- **Class Name:** `MyStudyMaterialsScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Personal management screen listing all materials uploaded by the current student.
  - Displays moderation status badges: `Pending Review`, `Approved / Live`, `Rejected`.
  - Provides delete action via `DeleteMaterialSheet`. (Pending items deleted immediately; live items generate removal request for admin review).

#### Screen 40: Upload Study Material Screen
- **Exact File Path:** `lib/features/study_vault/presentation/upload_study_material_screen.dart`
- **Class Name:** `UploadStudyMaterialScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Multi-file upload portal allowing students to contribute academic resources.
- **Visual & Interactive Widgets:**
  - **Course & Faculty Pickers:** Opens `PaginatedSearchBottomSheet` to select Course Code and Faculty Initials.
  - **Semester Dropdown:** Dynamic semester list from database.
  - **File Picker Zone:** Drag/tap box opening `FilePicker` (PDF, DOCX, PPTX, XLSX, images; max 25MB).
  - **Per-File Type Tagging:** Dropdown beside each selected file to assign material type (`Mid Questions`, `Final Questions`, `Slide`, etc.).
  - **"Submit for Review" Button:** Uploads file to Google Drive / Supabase Storage and inserts record with `status = 'pending'`.

---

### 3.16 Feature 16: Tasks Manager

#### Screen 41: Tasks Screen
- **Exact File Path:** `lib/features/tasks/presentation/tasks_screen.dart`
- **Class Name:** `TasksScreen` (`ConsumerStatefulWidget`)
- **Functional Breakdown & Purpose:**
  - Full-featured academic to-do and deadline management screen.
  - Supports 4 categories: `Quiz`, `Lab`, `Assignment`, `Project`.
  - Features offline-first optimistic completion toggling with automated background synchronization queue.
- **Visual & Interactive Widgets:**
  - **3-Tab Header:**
    - Tab 0: Pending Tasks (sorted by nearest deadline).
    - Tab 1: Completed Tasks (with strikethrough and completion timestamp).
    - Tab 2: Overdue Tasks (highlighted in soft red with days overdue counter).
  - **Category Filter Chips:** Horizontal chips (`All`, `Quiz`, `Lab`, `Assignment`, `Project`).
  - **Task Card:** Course code badge, task title, description, due date/time countdown, priority flag, and circular completion checkbox with spring animation.
  - **Dismissible Swiping:** Swipe left to delete with undo snackbar; swipe right to edit.
  - **Floating Action Button:** Cyan "+ Add Task" button opening `AddTaskBottomSheet`.
  - **Offline Heartbeat:** 2-minute timer that monitors network status and flushes pending task creations/status updates.
- **State Management & Providers:**
  - `allTasksStreamProvider`: Real-time task stream from `TaskRepository`.
  - `cacheServiceProvider`: Enqueues offline mutations (`update_task_status`, `delete_task`, `create_task`).
- **Backend / Data Layer:**
  - Supabase table `tasks`.
  - Hive Box `sync_queue_box`.

---

### 3.17 Feature 17: Video Tutorials & Walkthrough Guides

#### Screen 42: Video Tutorials Screen
- **Exact File Path:** `lib/features/tutorials/presentation/tutorials_screen.dart`
- **Class Name:** `TutorialsScreen` (`ConsumerWidget`)
- **Functional Breakdown & Purpose:**
  - Curated university guide and application walkthrough video screen.
  - Helps freshmen and senior students master advising algorithms, CGPA calculations, and portal syncing.
- **Visual & Interactive Widgets:**
  - **App Bar:** Title "Video Tutorials" and "Replay Welcome Tour" action button.
  - **Category Chips:** `All`, `Advising`, `Portal Sync`, `CGPA Calculation`, `Cover Page`.
  - **Video Card:** High-resolution YouTube thumbnail, video title, duration badge, category pill, and play button icon.
  - **Video Launcher:** Launches external YouTube player or browser via `url_launcher`.
- **State Management & Backend:**
  - `tutorialsRepositoryProvider`: Fetches tutorial records from Supabase table `tutorials`.

---

## 4. Complete Repository Layer Catalog (`core/repositories/`)

| Repository Class | File Location | Data Sources | Primary Functions & Queries |
|---|---|---|---|
| `ActiveSemesterRepository` | `lib/core/repositories/active_semester_repository.dart` | Supabase `active_semester`, Hive `dashboard_box` | `getActiveSemester(track)`: Resolves active semester dates for `bi_semester` or `tri_semester`. `getAllSemesters()`: Fetches semester archive. |
| `AuthRepository` | `lib/core/repositories/auth_repository.dart` | Supabase Auth, Google Sign-In, Hive `auth_box` | `signIn()`, `signUp()`, `signInWithGoogle()`, `signOut()`, `getCurrentUser()`. Manages auth session persistence. |
| `CourseRepository` | `lib/core/repositories/course_repository.dart` | Supabase `courses`, Upstash Redis REST, Hive `course_catalog` | `getAllCourses(offset, limit)`: Paginated course fetching. `getSemesterCourses(semester)`: Fetches active semester courses. `searchCourses(query)`: Fuzzy catalog search. |
| `DashboardRepository` | `lib/core/repositories/dashboard_repository.dart` | Supabase RPC `get_daily_schedule_v2`, Hive `dashboard_box` | `getSimplifiedDashboardData(semester, date, track)`: Compiles today's classes, countdowns, and exams into a single cached payload. |
| `FacultyRepository` | `lib/core/repositories/faculty_repository.dart` | Supabase `faculties`, Hive `faculty` | `getAllFaculty()`: Fetches entire faculty directory. `searchFaculty(query, dept)`: Filters professors by initial or department. |
| `FacultyReviewsRepository` | `lib/core/repositories/faculty_reviews_repository.dart` | Supabase `faculty_reviews`, `faculties` | `getReviewsForFaculty(initials)`: Fetches student reviews. `submitReview(review)`: Submits anonymous rating. |
| `OfficeHoursRepository` | `lib/core/repositories/office_hours_repository.dart` | Supabase `faculty_office_hours`, Storage bucket `office_hour_proofs` | `getApprovedOfficeHours(initials, semester)`: Retrieves verified hours. `submitOfficeHours(...)`: Uploads crowdsourced hours with proof image. |
| `NotificationRepository` | `lib/core/repositories/notification_repository.dart` | Supabase `notifications`, Hive `notifications_box` | `getUserNotifications(userId)`: Streams notifications. `markAsRead(id)`, `markAllAsRead(userId)`: Updates read flags. |
| `ProfileRepository` | `lib/core/repositories/profile_repository.dart` | Supabase `profiles`, Hive `profile_box` | `getProfile(userId)`, `streamProfile(userId)`, `updateProfile(profile)`, `recordActivity(userId)`: Updates last active timestamp. |
| `ProgressRepository` | `lib/core/repositories/progress_repository.dart` | Supabase `semester_course_marks`, `semester_summaries` | `getCurrentSemesterMarks(userId, semester)`, `updateCourseMarks(marks)`, `getSemesterSummaries(userId)`, `getProgramDetails(code)`. |
| `ScheduleRepository` | `lib/core/repositories/schedule_repository.dart` | Supabase `user_semester_states`, `schedule_exceptions`, Hive | `getUserSchedule(userId, semester)`, `saveSchedule(...)`, `getScheduleExceptions(userId, semester)`. |
| `ScholarshipRepository` | `lib/core/repositories/scholarship_repository.dart` | Supabase `scholarship_rules`, `user_scholarships` | `getScholarshipRules()`, `checkEligibility(cgpa, credits, track)`: Validates 100% and 50% waiver rules. |
| `TaskRepository` | `lib/core/repositories/task_repository.dart` | Supabase `tasks`, Hive `sync_queue_box` | `getTasksStream(userId)`: Real-time task stream. `createTask(task)`, `updateTaskStatus(id, bool)`, `deleteTask(id)`. |
| `OnboardingRepository` | `lib/features/onboarding/onboarding_repository.dart` | Supabase `departments`, `programs`, `semesters`, `enrollments` | `fetchDepartments()`, `fetchSemesters()`, `fetchCourseCatalog()`, `saveCourseHistory()`, `updateProgram()`. |
| `StudyVaultRepository` | `lib/features/study_vault/data/repositories/study_vault_repository.dart` | Supabase `study_materials`, Google Drive REST | `fetchMaterials(filters)`: Searches approved study materials. `uploadMaterial(...)`: Submits new files. `deleteOrRequestRemoval(item)`. |
| `PortalSyncRepository` | `lib/features/services/repositories/portal_sync_repository.dart` | Supabase `enrollments`, `user_semester_states`, `profiles` | `saveSyncedPortalData(...)`: Batch transactional upsert of routine, courses, and historical grades imported from portal. |
| `FacultyAssignmentRepository` | `lib/features/services/repositories/faculty_assignment_repository.dart` | Supabase `faculty_course_assignments`, Storage | `fetchFacultyMasterList()`, `submitAssignmentReport(report, proofBytes)`: Crowdsources section teacher assignments. |

---

## 5. Cross-Cutting Architectural Patterns

### 5.1 Zero-Wait Entry Architecture (Frame 1 Rendering)
To eliminate splash-screen latency, EWUmate implements an offline-first Zero-Wait engine:
1. When `CheckAuthScreen` boots, it reads `last_user_id` from Hive `auth_box`.
2. Simultaneously, `DashboardController` scans `dashboard_box` for keys matching `${last_user_id}_*_*_schedule`.
3. If a cached schedule matching today's date exists, `state.lastValidScheduleData` is hydrated instantly, and the dashboard frame is presented to the user within Frame 1 (< 16ms), completely skipping the initial Supabase network request.
4. In the background, `academicStateProvider` and `DashboardController` asynchronously poll Supabase and Upstash Redis. If the remote payload differs from the local cache, the UI seamlessly updates via `onStateChanged`.

### 5.2 Offline Mutation Synchronization Queue
When network connectivity is unavailable:
1. User actions (`save_course_marks`, `update_task_status`, `create_task`, `delete_task`) are intercepted.
2. The UI is updated optimistically.
3. The mutation is serialized as a JSON object and appended to `sync_queue_box` keyed by `${userId}_queue`.
4. `SyncService` monitors network status via `connectivity_plus`. When connectivity returns (or during the 2-minute periodic heartbeats in `DashboardScreen`, `TasksScreen`, and `SemesterProgressScreen`), `flushQueue()` processes each mutation sequentially against Supabase, removing successfully processed items.

### 5.3 Bi-Semester vs. Tri-Semester Dynamic Track Resolution
East West University operates two distinct academic calendars:
- **Tri-Semester (3 terms/year):** CSE, EEE, BBA, Economics, English, Social Sciences (Spring, Summer, Fall).
- **Bi-Semester (2 terms/year):** Pharmacy (B.Pharm) and Law (LL.B) (Spring, Fall).

`CourseUtils.normalizeTrack(profile.track)` automatically categorizes students into `bi_semester` or `tri_semester`. All queries against `active_semester`, routine generators, scholarship policies, and semester progress charts automatically pass this track parameter, ensuring Pharmacy and Law students never see irrelevant tri-semester dates.

### 5.4 Dual-Grading Policy (Legacy ≤ Summer 2023 vs. Modern ≥ Fall 2023)
In Fall 2023, East West University revised its official academic grading scale. EWUmate implements a dual-policy engine in `GradeHelper`:
- For any course taken in or prior to `Summer 2023`, `defaultLegacyScale` is applied (A+=4.0, A=4.0, A-=3.7, B+=3.3, B=3.0, B-=2.7, C+=2.3, C=2.0, C-=1.7, D+=1.3, D=1.0, F=0.0).
- For any course taken in `Fall 2023` or later, `defaultModernScale` is applied (A+=4.0, A=3.75, A-=3.5, B+=3.25, B=3.0, B-=2.75, C+=2.5, C=2.25, D=2.0, F=0.0).
- This guarantees historical CGPA calculations match official university grade transcripts to the exact decimal point.

### 5.5 Checksum-Driven Routine Cache & Alarm Rescheduling
To prevent device battery drain from redundant alarm registrations:
1. `RoutineCacheService` computes a composite SHA-256 hash of the student's calendar events, weekly grid, and schedule exceptions.
2. If the newly computed checksum matches the stored checksum in Hive `routine_cache_box`, all local notification re-scheduling is skipped.
3. If the checksum has changed (e.g. after Portal Sync or adding a class), `LocalNotificationScheduler` cancels previous alarms and schedules exact notifications for the upcoming 14 days using timezone `Asia/Dhaka`.

### 5.6 Hardware Security & OS Screen Protection
During live pre-advising sessions, section availability changes within milliseconds. To prevent automated bot scraping or screenshot sharing that leads to seat hoarding, `ScreenProtectionService` communicates via a native Android method channel to invoke `WindowManager.LayoutParams.FLAG_SECURE`. This renders screenshots completely black and blocks screen mirroring while on active section-picking tabs, while dynamically unblocking when students view their own finalized drafts.

---

## 6. Index of All Application Routes

All routes registered in `appRouterProvider` (`lib/core/router/app_router.dart`):

| Route Path | Route Name | Screen Class | Guard / Protection | Purpose |
|---|---|---|---|---|
| `/` | `CheckAuth` | `CheckAuthScreen` | Session & Grade Guard | Root bootloader & splash screen |
| `/login-callback` | `LoginCallback` | `CheckAuthScreen` | Auth Token Callback | Email magic-link & OAuth landing |
| `/login` | `Login` | `LoginScreen` | Guest Only | Student sign-in |
| `/register` | `Register` | `RegisterScreen` | Guest Only | Student sign-up |
| `/forgot-password` | `ForgotPassword` | `ForgotPasswordScreen` | Guest Only | OTP password reset request |
| `/onboarding/program` | `ProgramSelection` | `ProgramSelectionScreen` | Auth Required | Onboarding Step 1 (Dept & Program) |
| `/onboarding/profile-setup` | `ProfileSetup` | `ProfileSetupScreen` | Auth Required | Onboarding Step 2 (Avatar & Name) |
| `/onboarding/course-history` | `CourseHistory` | `CourseHistoryScreen` | Auth Required | Onboarding Step 3 (Grade History) |
| `/onboarding/welcome-tour` | `WelcomeTour` | `WelcomeTourScreen` | Auth Required | 10-step full-screen feature tour |
| `/dashboard` | `Dashboard` | `DashboardScreen` | ShellRoute (MainShell) | Daily command center & next class |
| `/tasks` | `Tasks` | `TasksScreen` | ShellRoute (MainShell) | Homework & assignment manager |
| `/semester-progress` | `SemesterProgress` | `SemesterProgressScreen` | ShellRoute (MainShell) | Course marks & attendance tracker |
| `/degree-progress` | `DegreeProgress` | `DegreeProgressScreen` | ShellRoute (MainShell) | Graduation credit audit & milestones |
| `/schedule-manager` | `Schedule` | `ScheduleScreen` | ShellRoute (MainShell) | Weekly timetable & class exceptions |
| `/services` | `Services` | `ServicesScreen` | ShellRoute (MainShell) | Academic utilities directory |
| `/services/cover-page` | `CoverPage` | `CoverPageScreen` | ShellRoute (MainShell) | PDF Assignment cover page generator |
| `/services/faculty-list` | `FacultyList` | `FacultyListScreen` | ShellRoute (MainShell) | Official faculty PDF drive roster |
| `/services/faculty-directory` | `FacultyDirectory` | `FacultyDirectoryScreen` | ShellRoute (MainShell) | Professor directory & search |
| `/services/faculty-directory/details` | `FacultyDetails` | `FacultyDetailsScreen` | ShellRoute (MainShell) | Professor reviews, bio & office hours |
| `/services/faculty-assignment` | `FacultyAssignment` | `FacultyAssignmentScreen` | ShellRoute (MainShell) | Crowdsourced section teacher tracker |
| `/services/study-vault` | `StudyVault` | `StudyVaultScreen` | ShellRoute (MainShell) | Past papers & lecture notes vault |
| `/services/study-vault/upload` | `UploadStudyMaterial` | `UploadStudyMaterialScreen` | ShellRoute (MainShell) | Upload past papers & notes |
| `/services/study-vault/my-uploads` | `MyStudyMaterials` | `MyStudyMaterialsScreen` | ShellRoute (MainShell) | Manage student's uploaded files |
| `/profile` | `Profile` | `ProfileScreen` | Fullscreen Modal | User profile, preferences & sign out |
| `/notifications` | `Notifications` | `NotificationsScreen` | Fullscreen Modal | In-app notification center |
| `/notifications/settings` | `ReminderSettings` | `ReminderSettingsScreen` | Fullscreen Modal | Class reminder offset settings |
| `/semester-summary` | `SemesterSummary` | `SemesterSummaryScreen` | Fullscreen Modal | CGPA simulator & scholarship tiers |
| `/courses` | `CourseBrowser` | `CourseBrowserScreen` | Fullscreen Modal | University course & section browser |
| `/advising` | `Advising` | `AdvisingScreen` | FLAG_SECURE Protected | Pre-advising solver & schedule builder |
| `/next-semester` | *Redirect* | `NextSemesterScreen` | Auto-Redirect | Redirects to `/courses` (Upcoming) |
| `/results/grade-entry` | `GradeEntry` | `GradeEntryScreen` | **MANDATORY BLOCKER** | Unlocks app upon grade entry |
| `/portal-sync` | `PortalSync` | `PortalSyncScreen` | Fullscreen Wizard | Direct university portal sync |
| `/feedback` | `Feedback` | `FeedbackScreen` | Fullscreen Modal | Bug reports & 2-way support chat |
| `/tutorials` | `Tutorials` | `TutorialsScreen` | Fullscreen Modal | Video guides & walkthroughs |
