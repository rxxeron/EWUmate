# EWUmate — Unified Master System Architecture & Technical Documentation
**The Comprehensive Academic Ecosystem for East West University**

**Package:** `com.rxxeron.ewumate`  
**Production Version:** `1.1.16+46`  
**Primary Stack:** Flutter 3.27+ | Dart 3.x | Supabase (PostgreSQL 15 + Auth + Edge Functions) | Azure Functions (Python 3.11/3.13) | Upstash Redis | React 19 (TypeScript Admin Dashboard)

![Flutter](https://img.shields.io/badge/Flutter-3.27.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-SDK_36-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL_&_Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Azure Functions](https://img.shields.io/badge/Azure-Python_Microservices-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Upstash](https://img.shields.io/badge/Upstash-Edge_Redis-00E599?style=for-the-badge&logo=redis&logoColor=white)
![React Admin](https://img.shields.io/badge/React_19-Admin_Dashboard-61DAFB?style=for-the-badge&logo=react&logoColor=black)

> [!IMPORTANT]
> **Unified Master Architecture Manual:**  
> This document consolidates the complete, unabridged technical documentation across all core production pillars:
> 1. **Flutter Mobile Production App** (`ewumate_production_build/lib/`): All 42 screens across 17 feature modules and the full `lib/core` architecture.
> 2. **Azure Functions Cloud Backend & Scraping Engine** (`azure_functions/`): All 11 action endpoints, cron triggers, scrapers, and 60+ diagnostic scripts.
> 3. **React 19 Admin Web Dashboard** (`admin_panel/`): All 22 management pages, moderation queues, components, and dual Supabase client architecture.
>
> *(Note: The **Progressive Web App** is maintained as a separate, dedicated standalone build documented at [`ewumate_pwa/README.md`](file:///f:/EWUmate/EWUmate_Clean/ewumate_v2/ewumate_pwa/README.md) to serve iOS Safari web clip users independently).*

---

## Master Table of Contents

- [EWUmate — Unified Master System Architecture \& Technical Documentation](#ewumate--unified-master-system-architecture--technical-documentation)
  - [Master Table of Contents](#master-table-of-contents)
  - [PART I: Executive Overview \& System Foundations](#part-i-executive-overview--system-foundations)
    - [1. Executive Summary \& System Overview](#1-executive-summary--system-overview)
    - [2. Architecture \& Component Diagram](#2-architecture--component-diagram)
    - [3. End-to-End Data Flows](#3-end-to-end-data-flows)
    - [4. Tech Stack \& Architecture Matrix](#4-tech-stack--architecture-matrix)
    - [5. Project Structure \& Directory Rationale](#5-project-structure--directory-rationale)
    - [6. Prerequisites \& Environment Setup](#6-prerequisites--environment-setup)
    - [7. Configuration \& Environment Variables (.env)](#7-configuration--environment-variables-env)
    - [8. Getting Started \& Local First Run](#8-getting-started--local-first-run)
    - [9. Development Workflows, Build Commands \& Code Style](#9-development-workflows-build-commands--code-style)
    - [10. Testing Strategy \& Test Execution](#10-testing-strategy--test-execution)
    - [11. Application Entry Point (`main.dart` \& Bootloader)](#11-application-entry-point-maindart--bootloader)
  - [PART II: Flutter Production Application (`ewumate_production_build/lib/`)](#part-ii-flutter-production-application-ewumate_production_buildlib)
    - [A. Architectural Overview \& `lib/` Directory Taxonomy](#a-architectural-overview--lib-directory-taxonomy)
    - [B. Core Architecture \& System Foundations (`lib/core/`)](#b-core-architecture--system-foundations-libcore)
    - [C. Exhaustive Screen Reference (All 17 Feature Modules \& 42 Screens)](#c-exhaustive-screen-reference-all-17-feature-modules--42-screens)
      - [1. Advising Module (`features/advising/`)](#1-advising-module-featuresadvising)
      - [2. Authentication Module (`features/auth/`)](#2-authentication-module-featuresauth)
      - [3. Course Browser Module (`features/course_browser/`)](#3-course-browser-module-featurescourse_browser)
      - [4. Dashboard Module (`features/dashboard/`)](#4-dashboard-module-featuresdashboard)
      - [5. Faculty Directory Module (`features/faculty_directory/`)](#5-faculty-directory-module-featuresfaculty_directory)
      - [6. Layout Module (`features/layout/`)](#6-layout-module-featureslayout)
      - [7. Notifications Module (`features/notifications/`)](#7-notifications-module-featuresnotifications)
      - [8. Onboarding Module (`features/onboarding/`)](#8-onboarding-module-featuresonboarding)
      - [9. Profile Module (`features/profile/`)](#9-profile-module-featuresprofile)
      - [10. Progress Module (`features/progress/`)](#10-progress-module-featuresprogress)
      - [11. Results Module (`features/results/`)](#11-results-module-featuresresults)
      - [12. Schedule Module (`features/schedule/`)](#12-schedule-module-featuresschedule)
      - [13. Semester Progress Module (`features/semester_progress/`)](#13-semester-progress-module-featuressemester_progress)
      - [14. Services Module (`features/services/`)](#14-services-module-featuresservices)
      - [15. Study Vault Module (`features/study_vault/`)](#15-study-vault-module-featuresstudy_vault)
      - [16. Tasks Module (`features/tasks/`)](#16-tasks-module-featurestasks)
      - [17. Tutorials Module (`features/tutorials/`)](#17-tutorials-module-featurestutorials)
    - [D. Complete Repository Layer Catalog (`core/repositories/`)](#d-complete-repository-layer-catalog-corerepositories)
    - [E. Cross-Cutting Architectural Patterns](#e-cross-cutting-architectural-patterns)
    - [F. Index of All Application Routes](#f-index-of-all-application-routes)
  - [PART III: Cloud Backend \& Azure Functions (`azure_functions/`)](#part-iii-cloud-backend--azure-functions-azure_functions)
    - [A. System Role \& Architecture](#a-system-role--architecture)
    - [B. Function-by-Function Breakdown](#b-function-by-function-breakdown)
      - [`ewumate_api` — All 11 Action Endpoints](#ewumate_api--all-11-action-endpoints)
      - [`portal_sync_timer` — Scheduled Scrape Engine](#portal_sync_timer--scheduled-scrape-engine)
      - [`portal_sync_trigger` — Webhook Trigger](#portal_sync_trigger--webhook-trigger)
    - [C. Portal Scraping \& Automation Engine](#c-portal-scraping--automation-engine)
    - [D. Database Integration \& Supabase Sync](#d-database-integration--supabase-sync)
    - [E. Utility Scripts \& Diagnostic Tools Catalog (60+ Scripts)](#e-utility-scripts--diagnostic-tools-catalog-60-scripts)
    - [F. Local Development, Configuration \& Cloud Deployment](#f-local-development-configuration--cloud-deployment)
  - [PART IV: React Admin Web Control Panel (`admin_panel/`)](#part-iv-react-admin-web-control-panel-admin_panel)
    - [A. Executive Summary \& Administrative Capabilities](#a-executive-summary--administrative-capabilities)
    - [B. Technology Stack \& Core Dependencies](#b-technology-stack--core-dependencies)
    - [C. Authentication, Security \& Role-Based Access Control](#c-authentication-security--role-based-access-control)
    - [D. Supabase Client Architecture \& Edge Function Handshake](#d-supabase-client-architecture--edge-function-handshake)
    - [E. Global UI Shell \& Component Architecture](#e-global-ui-shell--component-architecture)
    - [F. Exhaustive Page-by-Page Architectural Breakdown (All 22 Pages)](#f-exhaustive-page-by-page-architectural-breakdown-all-22-pages)
    - [G. Shared UI Components \& Modals](#g-shared-ui-components--modals)
    - [H. Data Models, Type Definitions \& Schemas](#h-data-models-type-definitions--schemas)
    - [I. Local Setup, Environment Variables \& Production Hosting](#i-local-setup-environment-variables--production-hosting)
  - [PART V: Ecosystem Infrastructure \& Operational Standards](#part-v-ecosystem-infrastructure--operational-standards)
    - [1. Progressive Web App Standalone Notice (`ewumate_pwa/`)](#1-progressive-web-app-standalone-notice-ewumate_pwa)
    - [2. Firebase Cloud Messaging \& Push Alerts](#2-firebase-cloud-messaging--push-alerts)
    - [3. Native Android Integration (Jetpack Glance, Permissions)](#3-native-android-integration-jetpack-glance-permissions)
    - [4. Offline-First Architecture \& Zero-Wait Entry Engine](#4-offline-first-architecture--zero-wait-entry-engine)
    - [5. Security Architecture \& Privacy Safeguards](#5-security-architecture--privacy-safeguards)
    - [6. Build Automation, CI/CD \& Deployment Guide](#6-build-automation-cicd--deployment-guide)
    - [7. Monitoring, Telemetry \& Rollback Procedures](#7-monitoring-telemetry--rollback-procedures)
    - [8. Troubleshooting \& Common Pitfalls](#8-troubleshooting--common-pitfalls)
    - [9. Contributing \& Code Sync Protocol](#9-contributing--code-sync-protocol)
    - [10. License \& Credits](#10-license--credits)

---


## PART I: Executive Overview & System Foundations

### 1. Executive Summary & System Overview

**EWUmate** is a production-grade, multi-tier academic assistant platform built specifically for East West University (EWU) students, faculty, and administrators. 

The system couples a high-performance, cross-platform Flutter client with an offline-first caching layer (Hive multi-box storage and SharedPreferences), a real-time PostgreSQL backend on Supabase (featuring Row-Level Security, Edge Functions, and database triggers), serverless Python microservices on Microsoft Azure Functions for heavy compute (combinatorial routine generation, university portal scraping, and PDF report synthesis), an edge Redis cache on Upstash for zero-latency course lookups, and a React 19 web administration dashboard.

The application consumes raw university portal schedules, grade sheets, and academic bulletins, normalizes course loads, and delivers real-time timetable alerts, automated conflict-free routine planning, degree audit simulations, faculty directories with office hour crowdsourcing, and instant academic cover sheet creation.

---


### 2. Architecture & Component Diagram

EWUmate is structured into 5 cohesive tiers designed for extreme resilience, high performance, and zero client-side credential exposure:

1. **Client Tier**: Flutter mobile application (Android/iOS/Web) and React 19 Admin Panel.
2. **State & Offline Tier**: Riverpod 2.x reactive providers, GoRouter navigation guards, and Hive Zero-Wait offline boxes.
3. **Cloud Gateway & Compute Tier**: Azure Functions Python microservices executing schedule permutations, portal scraping, and PDF generation.
4. **Data & Auth Tier**: Supabase PostgreSQL featuring Row Level Security (RLS), Supabase Auth (Google OAuth & JWT), Supabase Storage, and Deno Edge Functions.
5. **Edge Caching & Notification Tier**: Upstash Redis REST cache and Firebase Cloud Messaging (FCM).

```mermaid
graph TD
    subgraph ClientLayer["Client Layer"]
        FlutterApp["Flutter Mobile App\n(Android / iOS / Web)"]
        AdminPanel["React 19 Admin Panel\n(Vite + Tailwind CSS)"]
    end

    subgraph AppState["Mobile App Architecture (Flutter)"]
        Riverpod["Riverpod 2.x State Management\n(SessionGuardian, AcademicProviders)"]
        GoRouter["GoRouter 17.x\n(Declarative Routes & Guards)"]
        Repositories["Repository Layer\n(Auth, Schedule, Faculty, Tasks, Marks)"]
        LocalCache["Zero-Wait Offline Storage\n(Hive Boxes & SharedPreferences)"]
    end

    subgraph ComputeLayer["Azure Functions (Python Microservices)"]
        EWUmateAPI["ewumate_api\n(/api/generate_schedules, /api/generate_pdf)"]
        PortalScraper["portal_sync_trigger / portal_sync_timer\n(Scrapers & Parsers)"]
        EWUPortal["EWU Academic Portal\n(External University System)"]
    end

    subgraph BackendTier["Supabase Cloud Backend"]
        SupabaseAuth["Supabase Auth\n(JWT & Google OAuth)"]
        SupabaseDB["PostgreSQL Database\n(RLS, Triggers, Partitioned Tables)"]
        SupabaseEdge["17 Supabase Edge Functions\n(Proxies, Sync Jobs, FCM Dispatch)"]
        SupabaseStorage["Supabase Storage\n(Avatars, Proofs, PDFs)"]
    end

    subgraph EdgeServices["Edge & Notification Services"]
        UpstashRedis["Upstash Redis\n(REST Edge Course Cache)"]
        FCM["Firebase Cloud Messaging\n(High Priority Alerts)"]
    end

    FlutterApp --> Riverpod
    Riverpod --> GoRouter
    Riverpod --> Repositories
    Repositories --> LocalCache
    Repositories --> SupabaseAuth
    Repositories --> SupabaseDB
    Repositories --> UpstashRedis
    Repositories --> EWUmateAPI
    FlutterApp --> FCM

    AdminPanel --> SupabaseEdge
    SupabaseEdge --> EWUmateAPI
    EWUmateAPI --> SupabaseDB
    PortalScraper --> EWUPortal
    PortalScraper --> SupabaseDB
```

---


### 3. End-to-End Data Flows

### 3.1 Client Bootstrapping & Zero-Wait Entry
1. `main()` initiates `_bootloader()` in `lib/main.dart`.
2. `CacheService.init()` loads Hive boxes (`profile_box`, `routine_box`, `academic_box`) into memory. The app renders Frame 1 instantly without awaiting network responses.
3. Concurrently, `Firebase.initializeApp()` configures FCM, and `SupabaseConfig.initialize()` loads `.env` variables and sets up `Supabase.instance`.
4. `SessionGuardian` inspects the active session: valid sessions proceed directly to `/dashboard`, unauthenticated sessions route to `/login`, and semester-end transitions route to the Grade Blocker (`/results/grade-entry`).

### 3.2 Schedule Permutation & Routine Generation
1. Student selects candidate courses and preferences (e.g., preferred time slots, free days, avoiding specific instructors) in `lib/features/schedule/`.
2. `AzureFunctionsService.generateSchedules()` dispatches an HTTP POST request to `/api/generate_schedules` with the user's Supabase JWT.
3. The Azure Python worker verifies the JWT, checks that `body.user_id == jwt.sub`, runs a combinatorial backtracking algorithm against the active term's course catalog (`courses_{semester}`), and returns valid, non-overlapping schedules with generation metrics.

### 3.3 Portal Scraping & Smart Diff Synchronization
1. Automated CRON jobs (`portal_sync_timer`) or administrative actions (`portal_sync_trigger`) query the university portal.
2. The scraper bypasses captchas, extracts updated sections, instructor allocations, and room assignments.
3. Data is sanitized and upserted into Supabase via `courses_sync_service.py`. Upstash Redis cache keys are invalidated to ensure all mobile clients instantly see fresh course capacity numbers.

---


### 4. Tech Stack & Architecture Matrix

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Mobile Framework** | Flutter | `>=3.27.0` | Cross-platform client framework |
| **Language** | Dart | `>=3.0.0 <4.0.0` | Strongly typed client code |
| **State Management** | Riverpod | `^2.5.1` | Reactive state, dependency injection, and code generation |
| **Declarative Router** | GoRouter | `^17.5.0` | Declarative routing, deep linking, and navigation guards |
| **Local Cache** | Hive | `^2.2.3` | Zero-Wait NoSQL key-value caching and offline mutation queue |
| **Backend as a Service** | Supabase Flutter | `^2.17.2` | Authentication, PostgreSQL database, Realtime, Storage |
| **Cloud Microservices** | Azure Functions | Python 3.10/3.11 | High-compute routine generation, portal scraping, ReportLab PDF |
| **Edge Cache** | Upstash Redis | REST API | Distributed course catalog caching and fast key-value lookups |
| **Push Notifications** | Firebase Messaging | `^16.7.0` | High-priority background class reminders and announcements |
| **Native Android** | Jetpack Glance | Android SDK 36 | Android launcher home screen widget (`ScheduleWidgetProvider.kt`) |
| **Admin Panel** | React / Vite | React 19, TS | Web administration dashboard for content moderation and portal sync |
| **Styling & UI** | Tailwind CSS / Glass Kit | Custom | Glassmorphism surfaces, Sora typography, shimmer loading states |

---


### 5. Project Structure & Directory Rationale

```
ewumate_production_build/
├── .github/
│   └── workflows/
│       ├── build-android.yml         # CI/CD: Release APK & AAB automated build
│       └── deploy-admin.yml          # CI/CD: React Admin deployment to GitHub Pages
├── admin_panel/                      # React 19 administrative web application
│   ├── src/                          # Admin modules (22 moderation and monitoring panels)
│   └── package.json                  # Node dependencies for admin dashboard
├── azure_functions/                  # Serverless Python microservices
│   ├── ewumate_api/                  # Core API handler (schedule gen, PDF, advising)
│   │   ├── services/                 # Auth, schedule, scraper, PDF, and calendar services
│   │   ├── function.json             # HTTP route binding: route="{action}"
│   │   └── __init__.py               # Action dispatcher and JWT validator
│   ├── portal_sync_timer/            # Scheduled CRON scraper worker
│   ├── portal_sync_trigger/          # HTTP triggered scraper endpoint
│   └── host.json                     # Azure Functions ExtensionBundle configuration
├── docs/                             # Project documentation library
│   ├── ARCHITECTURE.md               # 5-tier architecture and data flows
│   ├── CONFIGURATION.md              # Complete environment variables and defaults
│   ├── GETTING-STARTED.md            # Installation, prerequisites, and first run
│   ├── DEVELOPMENT.md                # Build commands, style guide, and branch conventions
│   ├── TESTING.md                    # Test execution, widget testing, and CI tests
│   ├── API.md                        # Azure Functions endpoints and JSON envelopes
│   ├── DEPLOYMENT.md                 # Production build scripts and store deployment
│   └── knowledge/                    # Live database schema and backend summaries
│       ├── BACKEND_LOGIC.md          # Stored procedures, active triggers, edge functions
│       ├── DATABASE_SCHEMA.md        # Comprehensive table catalog and column definitions
│       ├── MAINTENANCE_SCRIPTS.md    # Database maintenance and automation tools
│       ├── SCHEMA_DIFFERENCES.md     # Production vs local schema sync log
│       └── live_schema_dump.json     # Complete JSON schema extraction
├── lib/                              # Flutter client application root
│   ├── main.dart                     # App entry point, bootloader, HTTP overrides
│   ├── firebase_options.dart         # Generated Firebase configuration
│   ├── core/                         # Infrastructure shared across all features
│   │   ├── config/                   # AppConfig and environment readers
│   │   ├── constants/                # App constants, API routes, onboarding steps
│   │   ├── models/                   # 22 Domain models + View models
│   │   ├── providers/                # SessionGuardian and global Riverpod providers
│   │   ├── repositories/             # 13 Repositories encapsulating network & cache
│   │   ├── router/                   # AppRouter (GoRouter navigation tree)
│   │   ├── services/                 # 11 Core services (Cache, Redis, Azure, FCM, etc.)
│   │   ├── theme/                    # Color tokens, dark theme, and typography
│   │   ├── utils/                    # Date formatters, validators, and helpers
│   │   └── widgets/                  # MainShell, animations, glassmorphism components
│   └── features/                     # Domain modules organized by user journey
│       ├── advising/                 # Pre-advising, routine drafts, conflict solver
│       ├── auth/                     # Login, register, forgot password, check auth
│       ├── course_browser/           # Paginated course offering explorer
│       ├── dashboard/                # Central hub, countdown cards, schedule timeline
│       ├── faculty_directory/        # Faculty profiles, reviews, office hours
│       ├── notifications/            # Push notifications inbox and reminder settings
│       ├── onboarding/               # Profile setup, student ID formatting, tour
│       ├── profile/                  # Account settings, feedback, developer support
│       ├── results/                  # Transcripts, grade entry, and grade blocker
│       ├── schedule/                 # 2-week schedule viewer, makeup classes
│       ├── semester_progress/        # Target SGPA simulator, quiz strategies, marks
│       ├── services/                 # Cover page generator, faculty assignments, portal sync
│       ├── study_vault/              # Note sharing, past papers, Google Drive upload
│       ├── tasks/                    # Student assignment manager with offline queue
│       └── tutorials/                # Categorized YouTube onboarding videos
├── scripts/                          # Python & SQL maintenance and automation scripts
│   ├── check_rls_live.py             # Verifies RLS policies on all Supabase tables
│   ├── check_db_schema.py            # Compares live tables against catalog definition
│   ├── extract_live_schema.py        # Dumps live database structure to JSON
│   ├── run_cleanup.py                # Purges orphaned test data and dangling sessions
│   ├── sync_faculty_directory.py     # Scrapes and synchronizes EWU faculty directory
│   ├── parse_bulletin.py             # Parses academic course catalog from PDF
│   └── populate_course_metadata.py   # Populates course prerequisites and credit values
├── supabase/                         # Supabase backend definitions
│   ├── db_catalog/                   # Trigger definitions and SQL functions
│   ├── functions/                    # 17 Deno Edge Functions (sync-schedule, alert-scheduler)
│   └── migrations/                   # Version-controlled database migration scripts
├── test/                             # Flutter test suite (widget and unit tests)
├── build_production_apk.bat          # Windows batch script for release APK compilation
├── pubspec.yaml                      # Flutter dependencies and asset registrations
└── analysis_options.yaml             # Dart analyzer and linting rules
```

---


### 6. Prerequisites & Environment Setup

Verify that your local development workstation satisfies the following requirements:

- **Flutter SDK**: `Flutter >= 3.27.0` (channel `stable`)
- **Dart SDK**: `>= 3.0.0 < 4.0.0`
- **Java Development Kit**: `Java 17` (e.g., Eclipse Temurin 17 or OpenJDK 17). *Crucial: Java 17 is strictly enforced in Gradle builds and CI pipelines.*
- **Android Studio & SDK**: Android SDK Platform 34 or 36, Android SDK Command-line Tools, and Android Build-Tools `34.0.0` / `35.0.0`.
- **Node.js**: `Node.js >= 20.0.0` (required for React admin panel development).
- **Python**: `Python 3.10+` or `3.11` (required for local Azure Functions execution and maintenance scripts).

Validate tools via terminal:
```bash
flutter doctor -v
java -version
node --version
python --version
```

---


### 7. Configuration & Environment Variables (.env)

The application resolves configuration settings at runtime using `flutter_dotenv`. Place a `.env` file at the root of `ewumate_production_build/`:

### Environment Variable Reference

| Variable | Required | Default / Fallback | Description |
|---|---|---|---|
| `SUPABASE_URL` | **Required** | `https://jwygjihrbwxhehijldiz.supabase.co` | Supabase project endpoint for Auth, Realtime, and PostgreSQL. |
| `SUPABASE_ANON_KEY` | **Required** | Embedded Public Anon JWT | Anonymous public API token for client-side Supabase requests. |
| `AZURE_FUNCTION_URL` | **Required** | `https://ewumate-parser-api.azurewebsites.net` | Base URL for deployed Azure Functions microservices. |
| `GOOGLE_WEB_CLIENT_ID` | **Required** | `561956344734-ulqeqls...` | OAuth 2.0 Web Client ID registered in Google Cloud Console. |
| `GOOGLE_ANDROID_CLIENT_ID` | Optional | `None` | Android OAuth 2.0 Client ID for native Google Play services. |
| `UPSTASH_REDIS_REST_URL` | Optional | `None` | Upstash Redis REST endpoint for edge course catalog caching. |
| `UPSTASH_REDIS_REST_TOKEN` | Optional | `None` | Authentication bearer token for Upstash Redis REST queries. |

### Sample `.env` Template
```env
SUPABASE_URL=https://jwygjihrbwxhehijldiz.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
AZURE_FUNCTION_URL=https://ewumate-parser-api.azurewebsites.net
GOOGLE_WEB_CLIENT_ID=561956344734-ulqeqls9u4h1hmpec41l9lufk336a9ga.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id.apps.googleusercontent.com
UPSTASH_REDIS_REST_URL=https://your-database.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_upstash_bearer_token
```

> [!IMPORTANT]
> The mobile client binary contains **zero administrative secrets**. `SUPABASE_SERVICE_ROLE_KEY` and database passwords must **never** be included in the client `.env`. They are restricted exclusively to Azure Function App Settings and GitHub Actions Secrets.

---


### 8. Getting Started & Local First Run

### Step 1: Clone Repository
```bash
git clone https://github.com/your-org/ewumate.git
cd ewumate/ewumate_production_build
```

### Step 2: Configure Environment
```bash
cp .env.example .env
# Open .env and insert your active API keys
```

### Step 3: Install Flutter Packages
```bash
flutter pub get
```

### Step 4: Run Code Generator (If Required)
If Riverpod annotations, Freezed models, or json_serializable schemas have changed:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 5: Launch Application
```bash
# Launch on attached emulator or USB-connected Android device
flutter run

# Or run in Google Chrome for responsive web inspection
flutter run -d chrome
```

---


### 9. Development Workflows, Build Commands & Code Style

### Essential Build & CLI Commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Installs dependencies declared in `pubspec.yaml` |
| `flutter run` | Boots interactive debug mode with Hot Reload (`r`) and Hot Restart (`R`) |
| `flutter run --release` | Runs optimized release build on a connected device |
| `dart run build_runner watch --delete-conflicting-outputs` | Continuously watches and generates `*.g.dart` files on save |
| `flutter analyze` | Runs Dart static analysis enforcing rules in `analysis_options.yaml` |
| `dart format --line-length 120 .` | Formats all Dart files to project standard |
| `flutter test` | Executes the unit and widget test suite |
| `flutter build apk --release --no-tree-shake-icons` | Compiles production Android APK preserving all icon glyphs |
| `flutter build appbundle --release` | Compiles Android App Bundle (`.aab`) for Google Play Console |
| `build_production_apk.bat` | One-click Windows batch script for building production release APK |

### Code Style Guidelines
- **Const Constructors**: Always use `const` widgets wherever tree values are immutable.
- **Logging**: Do not use raw `print()` or `debugPrint()` in production logic; use `package:logging`.
- **Layer Isolation**: UI widgets must never query Supabase directly; all data must flow through Riverpod providers (`lib/core/providers/`) and repositories (`lib/core/repositories/`).
- **Null Safety**: Maintain strict null-safety; avoid force-unwrapping operators (`!`) unless guaranteed by guard conditions.

---


### 10. Testing Strategy & Test Execution

EWUmate employs `flutter_test` along with Riverpod `ProviderScope` overrides to ensure high stability across offline and network states.

### Running Tests
```bash
# Run the complete test suite
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with verbose expanded output
flutter test --reporter expanded

# Generate test coverage report
flutter test --coverage
```

### Writing Widget Tests with Mock Providers
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ewumate/main.dart';

void main() {
  testWidgets('Application boots to splash screen without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
```

---


### 11. Application Entry Point (`main.dart` & Bootloader)

`lib/main.dart` coordinates critical bootstrap steps before mounting the widget tree:

1. **`MyHttpOverrides`**: Configures custom HTTP security overrides for university networks with restrictive SSL gateways.
2. **`_bootloader(cache)`**:
   - `CacheService.init()`: Opens all Hive storage boxes.
   - `Firebase.initializeApp()`: Bypassed on Web to prevent JS interop crashes; initialized on native Android/iOS.
   - `SupabaseConfig.initialize()`: Parses `.env`, configures Supabase client with anon keys.
3. **`SessionGuardian`**: Continuously tracks Supabase session state, automatically handles token refresh, and coordinates with `GoRouter`.
4. **`AppUpdateService.checkForUpdate()`**: Informs the user if a mandatory update has been released on the Google Play Store.
5. **Crash Shield**: Injects a custom `ErrorWidget.builder` presenting a branded, graceful error screen (`#071426`) rather than the default Flutter red screen.

---



---

## PART II: Flutter Production Application (`ewumate_production_build/lib/`)

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
  - `getAzureFunctionUrl`: Retrieves `AZURE_FUNCTION_URL`. Falls back to `https://ewumate-parser-api.azurewebsites.net`.
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



---

## PART III: Cloud Backend & Azure Functions (`azure_functions/`)

## 1. System Role & Architecture

The **EWUmate Azure Functions Subsystem** serves as the automated cloud computation engine, scraping orchestrator, data sync pipeline, and backend proxy for the entire EWUmate platform. East West University (EWU) does not provide a public, documented REST API for its student portal (`portal.ewubd.edu`) or academic website (`ewubd.edu`). Consequently, the Azure Functions backend bridges this gap by acting as an intelligent intermediary between legacy ASP.NET/AngularJS university infrastructure, Supabase cloud databases, Google Drive document stores, and client applications (Flutter mobile app, React/Vite admin dashboard, and Progressive Web App).

### 1.1 Core Platform Responsibilities
1. **University Portal Scraping & Automation**: Authenticates against EWU student portal session handlers, automatically solves arithmetic challenges, negotiates anti-forgery tokens, traverses multi-department course catalogs, and extracts real-time capacity and schedule metrics.
2. **Crowdsourced Student Routine & Faculty Harvesting**: Aggregates enrolled student advising schedules (`GetSemesterStudentWiseAdvisingCourseListStudent`) to overcome universal "TBA" faculty masking during pre-advising periods, resolving faculty assignments and synchronizing them into the global course catalog.
3. **Faculty Directory & Public Website Enrichment**: Crawls public EWU faculty directories, resolves profile photos, designation titles, academic departments, and extracts physical office room numbers via multi-threaded HTML scraping.
4. **Academic Calendar Ingestion & Semester State Machine**: Ingests official PDF academic calendars, parses multi-date milestones via text-coordinate geometry, updates dynamic calendar tables, and automatically triggers semester promotion and enrollment status transitions according to Bangladesh Standard Time (BST / UTC+6).
5. **Backtracking Schedule Combination Solver**: Provides a constraint-satisfaction engine using the Minimum Remaining Values (MRV) heuristic to generate conflict-free academic timetables across candidate sections, respecting day exclusions and faculty filters, streaming batches into Supabase.
6. **Program Curriculum & Advising Eligibility Engine**: Computes degree curriculum progress, evaluates prerequisite satisfaction (passed and currently enrolled courses), checks credit gate thresholds, identifies retake-eligible courses, and enforces Outcome-Based Education (OBE) course numbering transformations.
7. **Vectorized PDF Cover Page Generation**: Renders standard academic assignment, lab report, term paper, and project report cover sheets in compliance with East West University visual branding guidelines using ReportLab canvas primitives.
8. **Automated Catalog Snapshots & Permanent Drive Archival**: Formats comprehensive course-offering catalogs into printable PDF ledgers, streams them to designated Google Drive folders via OAuth2 token exchange, and prunes stale historical records.

---

### 1.2 System Architecture & Component Interaction Flow

```mermaid
flowchart TD
    subgraph Client_Layer [Client Applications]
        Mobile["Flutter Mobile App (iOS / Android)"]
        Admin["Admin Management Dashboard (React / Vite)"]
        PWA["EWUmate Progressive Web App"]
    end

    subgraph Azure_Runtime [Azure Functions Worker Runtime v4 - Python]
        API["ewumate_api\n(HTTP Router & Action Dispatcher)"]
        Timer["portal_sync_timer\n(NCronTab: 0 0 11,23 * * *)"]
        Trigger["portal_sync_trigger\n(HTTP Webhook Trigger)"]
        
        subgraph Internal_Services [Internal Service Modules]
            AuthSvc["auth_service.py\n(JWT Verification & Client Init)"]
            PortalSvc["portal_service.py\n(Student Session & Routine Scraper)"]
            CoursesSvc["courses_sync_service.py\n(Catalog Ingestion & Diff Engine)"]
            AdvisingSvc["advising_service.py\n(Curriculum & Prereq Audit)"]
            ScheduleSvc["schedule_service.py\n(MRV Backtracking Solver)"]
            SemesterSvc["semester_service.py\n(State Machine & Milestones)"]
            CalendarSvc["calendar_service.py\n(PDF Calendar Parser)"]
            PDFSvc["pdf_service.py & ewumate_pdf_engine.py\n(Cover Sheet Vector Engine)"]
            SnapshotSvc["snapshot_service.py & snapshot_utils.py\n(Drive Sync & Ledger Engine)"]
            ScraperUtils["scraper_utils.py\n(Multi-Dept Crawler & Website Scraper)"]
        end
    end

    subgraph External_Services [External Upstream Systems]
        EWUPortal["EWU Student Portal\n(portal.ewubd.edu)"]
        EWUWeb["EWU Public Website\n(www.ewubd.edu)"]
        Supabase["Supabase Cloud\n(PostgreSQL, GoTrue Auth, Storage, RPC)"]
        GDrive["Google Drive API v3\n(Permanent Faculty Snapshot Folder)"]
        AppInsights["Azure Application Insights\n(Telemetry, Logs & Metrics)"]
    end

    %% Client Interactions
    Mobile -->|Bearer JWT / Action Payloads| API
    Admin -->|Direct Actions & Manual Triggers| API
    Admin -->|Webhook Triggers| Trigger
    PWA -->|Cached Lookups & Proxy Requests| API

    %% Function Triggers
    Timer -->|Cron Fire| SemesterSvc
    Timer -->|Cron Fire| ScraperUtils
    Trigger -->|HTTP Fire| ScraperUtils

    %% Dispatch Routing
    API --> AuthSvc
    API --> PortalSvc
    API --> CoursesSvc
    API --> AdvisingSvc
    API --> ScheduleSvc
    API --> SemesterSvc
    API --> CalendarSvc
    API --> PDFSvc
    API --> SnapshotSvc

    %% Service Integration
    PortalSvc -->|Arithmetic Captcha & Auth| EWUPortal
    ScraperUtils -->|Multi-Dept REST Fetch| EWUPortal
    ScraperUtils -->|AJAX Directory Crawl| EWUWeb
    CalendarSvc -->|Download Calendar PDF| Supabase
    SnapshotSvc -->|OAuth2 Refresh Token| GDrive
    CoursesSvc -->|Batch Upsert & UUID Protection| Supabase
    AdvisingSvc -->|Direct TCP Pooler Connection| Supabase
    ScheduleSvc -->|Stream Batches| Supabase
    Azure_Runtime -.->|Telemetry & Traces| AppInsights
```

---

### 1.3 Data Synchronization Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Client as Client Application
    participant Router as ewumate_api (__init__.py)
    participant Auth as auth_service
    participant Portal as portal_service (EWUStudentPortalSession)
    participant Scraper as scraper_utils (EWUAutomationEngine)
    participant Sync as courses_sync_service
    participant DB as Supabase PostgreSQL
    participant Drive as Google Drive v3

    %% Flow 1: Student Portal Sync & Crowdsourcing
    Note over Client, DB: 1. Student Crowd-Sourced Enrichment
    Client->>Router: POST /portal_sync_student {student_id, password}
    Router->>Portal: handle_portal_sync_student()
    Portal->>Portal: Solve dynamic math captcha (FirstNo + SecondNo)
    Portal->>Portal: Negotiate ASP.NET session cookie
    Portal->>Portal: Fetch advising routine (/api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent)
    Portal->>Sync: handle_sync_api_courses(enrolled_courses)
    Sync->>DB: Fetch existing courses_{semester}
    Note over Sync: Enforce Invariant: Retain existing UUIDs & Non-TBA Faculty
    Sync->>DB: Batch upsert modified courses (Chunk size: 100)
    Sync->>DB: Upsert newly discovered faculty to faculty_master
    Portal-->>Router: JSON (Profile, Courses, Weekly Grid, History)
    Router-->>Client: 200 OK Response

    %% Flow 2: Automated Scheduled Crawl
    Note over Router, Drive: 2. Scheduled Catalog Sync & Snapshot
    Router->>Scraper: run_sync(is_preview=False)
    Scraper->>Scraper: Multi-Department Scan (deptid 1..30)
    Scraper->>Sync: handle_sync_api_courses(catalog)
    Sync->>DB: Upsert catalog changes
    Sync->>DB: Bump app_config "catalog_cache_version"
    Sync->>Drive: run_automated_snapshot() -> Upload PDF
    Drive-->>Sync: drive_file_link
    Sync->>DB: Upsert app_config "faculty_snapshots"
```

---

## 2. Function-by-Function Breakdown

The serverless package exposes three Azure Function entry points configured via standard Azure Functions v4 binding specifications:
1. `ewumate_api` (HTTP Trigger API Proxy)
2. `portal_sync_timer` (NCRONTAB Scheduled Engine)
3. `portal_sync_trigger` (HTTP Webhook Scraper Dispatcher)

---

### 2.1 Function: `ewumate_api`

#### 2.1.1 Routing Architecture & Binding Definition (`function.json`)
The API uses a wildcard parameter route `{action}` to dynamically dispatch HTTP requests to specific Python service handlers.

```json
{
    "scriptFile": "__init__.py",
    "bindings": [
        {
            "authLevel": "anonymous",
            "type": "httpTrigger",
            "direction": "in",
            "name": "req",
            "methods": [
                "post"
            ],
            "route": "{action}"
        },
        {
            "type": "http",
            "direction": "out",
            "name": "$return"
        }
    ]
}
```

* **Route Pattern**: `https://<app-name>.azurewebsites.net/api/{action}`
* **Allowed Methods**: `POST` only.
* **Authorization Level**: `anonymous` at Azure gateway level. Access control is enforced in application code via Supabase GoTrue JWT verification for sensitive endpoints.
* **Cross-Origin Resource Sharing (CORS)**: All responses inject `Access-Control-Allow-Origin: *` headers, ensuring seamless execution across Flutter web, local testing, and desktop web environments.
* **Worker Bootstrap Resilience**: If an unhandled import error occurs during cold start, `_INIT_ERROR` captures the complete stack trace and returns a structured 500 JSON response (`Worker Module Init Error`) instead of crashing the Python worker process silently.

#### 2.1.2 Authentication & Security Layer (`auth_service.py`)
Sensitive actions belonging to `STUDENT_AUTH_ACTIONS = {"generate_schedules", "generate_pdf"}` require an authenticated user session:
1. **Header Extraction**: Inspects the HTTP `Authorization` header for format `Bearer <token>`. Missing or malformed headers raise HTTP 401.
2. **Local Bypass Protocol**: If executing in a local development environment (detected via `AZURE_WEB_JOBS_SCRIPT_ROOT is None` or `127.0.0.1` / `localhost` in URL) and the token equals `"local-test-token"`, the token is accepted with mock claims:
   ```json
   {"sub": "local-test-user-id", "role": "authenticated"}
   ```
3. **Supabase Auth Server Verification**: In production, the token is verified against Supabase Auth (`GET {SUPABASE_URL}/auth/v1/user`) using timeout `5.0s`. If expired or invalid, the error message returned by GoTrue is forwarded in an HTTP 401 response.
4. **Tenant Isolation / Ownership Verification**: On `generate_schedules`, the `user_id` inside the JSON body is compared directly against the JWT subject claim (`sub`). Any mismatch returns an HTTP 403 Forbidden (`Forbidden: User ID mismatch`).

---

#### 2.1.3 Complete Action Catalog & Endpoint Reference

```
+---------------------------------------------------------------------------------------------------------+
|                                    EWUMATE API ACTION DIRECTORY                                         |
+----+----------------------+---------------------------+-------------+-----------------------------------+
| #  | Action Name          | Handler Function          | Auth Reqd   | Primary Target / Output           |
+----+----------------------+---------------------------+-------------+-----------------------------------+
| 1  | parse_calendar       | handle_parse_calendar     | No (Admin)  | active_semester, calendar_* table |
| 2  | switch_semester      | handle_switch_semester    | No (Cron)   | active_semester, enrollments      |
| 3  | generate_schedules   | handle_generate_schedules | Yes (JWT)   | schedule_generations (streaming)  |
| 4  | generate_pdf         | handle_generate_pdf       | Yes (JWT)   | Binary PDF (CoverPage.pdf)        |
| 5  | generate_snapshot    | handle_generate_snapshot  | No (Cron)   | Google Drive & app_config         |
| 6  | parse_grade_sheet    | handle_parse_grade_sheet  | No (Creds)  | Completed course history JSON     |
| 7  | portal_sync_student  | handle_portal_sync_student| No (Creds)  | Enrolled courses & DB enrichment  |
| 8  | sync_api_courses     | handle_sync_api_courses   | No (Admin)  | courses_{semester} diff & upsert  |
| 9  | portal_sync          | handle_portal_sync        | No (Admin)  | Full catalog crawl & DB update    |
| 10 | faculty_sync         | handle_faculty_sync       | No (Admin)  | faculty_master & website profile  |
| 11 | get_advising_courses | handle_get_advising_courses| No (Profile)| Curriculum audit & prerequisites  |
+----+----------------------+---------------------------+-------------+-----------------------------------+
```

---

##### Endpoint 1: `parse_calendar`
* **Handler**: `calendar_service.py -> handle_parse_calendar`
* **Purpose**: Ingests an academic calendar PDF from Supabase Storage (`academic_documents` bucket), extracts semester dates and milestones, creates/updates the semester's calendar event table, and updates active semester records.
* **Request Payload**:
  ```json
  {
    "file_path": "calendar/Academic Calendar Summer 2026.pdf"
  }
  ```
* **Processing Mechanics**:
  1. Tracks department specialization: Detects terms like `PHRM`, `LAW`, `LLB`, `PHARMACY` in filename to set `track = "bi_semester"` and table suffix `_phrm_llb`. Otherwise defaults to `tri_semester`.
  2. Downloads PDF stream directly from Supabase Storage bucket `academic_documents`.
  3. Executes `parse_calendar_pdf()` using `pypdf`. Parses event rows using regex matching:
     ```python
     line_pattern = re.compile(rf"^\s*({date_pattern})\s+({day_names})\s+(.*)", re.IGNORECASE)
     ```
  4. Resolves milestone dates: `classes_start_date`, `classes_end_date`, `advising_start_date`, `advising_end_date`, `final_exam_start`, `final_exam_end`, `grade_submission_start`, `grade_submission_deadline`, `semester_switch_date`, and `upcoming_classes_start_date`.
  5. Corrects year-rollover anomalies: For Fall semesters spanning into January/February of the subsequent calendar year, increments the year index automatically.
  6. Upserts record into Supabase `active_semester` on conflict `track`.
  7. Invokes Supabase RPC `create_calendar_table(p_semester_code)`. Flushes stale events and inserts parsed events in batches of 100 into `calendar_{sem_code}`.
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "track": "tri_semester",
    "current_semester": "summer2026",
    "next_semester": "fall2026",
    "table": "calendar_summer2026",
    "events_count": 42,
    "milestones": {
      "classes_start_date": "2026-05-17",
      "classes_end_date": "2026-08-20",
      "advising_start_date": "2026-05-10",
      "advising_end_date": "2026-05-14",
      "final_exam_start": "2026-08-23",
      "final_exam_end": "2026-08-31",
      "grade_submission_deadline": "2026-09-03",
      "semester_switch_date": "2026-09-04",
      "upcoming_classes_start_date": "2026-09-20"
    }
  }
  ```

---

##### Endpoint 2: `switch_semester`
* **Handler**: `semester_service.py -> handle_switch_semester`
* **Purpose**: Evaluates temporal milestones in `active_semester` against Dhaka local time (UTC+6). Controls advising open/close flags, executes semester transitions, and shifts student enrollment lifecycles.
* **Request Payload**:
  ```json
  {
    "force": false,
    "track": "tri_semester"
  }
  ```
* **Evaluation Logic & Safeguards**:
  1. Computes Dhaka local date: `dhaka_today = (datetime.now(timezone.utc) + timedelta(hours=6)).date()`.
  2. Advising Status: Sets `is_advising_open = True` if and only if `advising_start <= dhaka_today <= advising_end`. Sets `is_next_semester_open = True` if `dhaka_today >= advising_start`.
  3. Semester Switch Validation:
     * Safeguard 1: `switch_date` cannot be earlier than `classes_start_date`.
     * Safeguard 2: Cannot promote semester while current classes are ongoing (`dhaka_today < classes_end_date`) unless `force = true`.
     * Trigger: If `dhaka_today >= semester_switch_date` and `next_semester_code` exists:
       - Sets `current_semester_code = next_semester_code`.
       - Computes subsequent `next_semester_code` (`spring` -> `summer` -> `fall` -> `spring+1`).
  4. Enrollment Lifecycle Migration:
     * Promotes: `UPDATE enrollments SET status = 'enrolled' WHERE semester_code = new_current AND status = 'upcoming'`.
     * Archives: `UPDATE enrollments SET status = 'completed' WHERE semester_code = old_current AND status = 'enrolled'`.
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "dhaka_today": "2026-09-04",
    "results": [
      {
        "track": "tri_semester",
        "switched": true,
        "current_semester": "fall2026",
        "next_semester": "spring2027",
        "updated_fields": {
          "current_semester_code": "fall2026",
          "next_semester_code": "spring2027",
          "is_advising_open": false,
          "is_next_semester_open": false
        }
      }
    ]
  }
  ```

---

##### Endpoint 3: `generate_schedules`
* **Handler**: `schedule_service.py -> handle_generate_schedules`
* **Authentication**: Requires Supabase Bearer JWT (`sub == body.user_id`).
* **Purpose**: Constraint satisfaction solver that generates clash-free class schedule combinations.
* **Request Payload**:
  ```json
  {
    "user_id": "83b9cf71-2918-472e-836f-bca12078cfbb",
    "semester": "fall2026",
    "courses": ["CSE103", "MAT101", "ENG101", "PHY109"],
    "generation_id": "optional-custom-uuid",
    "limit": 300,
    "filters": {
      "exclude_days": ["Friday", "Saturday"],
      "selected_faculties": {
        "CSE103": ["SRK", "MNA"],
        "MAT101": ["MDR"]
      }
    }
  }
  ```
* **Algorithmic Implementation**:
  1. **Course Section Resolution (`_fetch_sections_fuzzy`)**: Queries `courses_{semester}`. If no records match, falls back to `courses`. Supports fuzzy course numbers (handling 3-digit vs 4-digit OBE codes like `CSE103` vs `CSE7103`).
  2. **Section Filtering (`_is_section_valid`)**:
     * Capacity check: Discards sections where `enrolled >= total` (parsed from `"35/35"`).
     * Faculty filter: Discards sections where `faculty_initials` is not in `selected_faculties[course]`.
     * Day filter: Discards sections containing sessions matching `exclude_days`.
  3. **MRV (Minimum Remaining Values) Heuristic**: Sorts courses by candidate section count ascending (`key = len(valid[k])`). This minimizes tree branching factor and fails fast.
  4. **Pairwise Collision Detection**:
     * Days: Set intersection check across day initials (`S, M, T, W, R, F, A`).
     * Times: Minute conversion (`hour * 60 + minute`) evaluating `max(start1, start2) <= min(end1, end2)`.
  5. **Streaming Batch Writes**: Stream callback writes combinations into Supabase table `schedule_generations` on the 1st result and every 25 schedules thereafter, enabling client-side progress bars without waiting for solver completion.
  6. **Diagnostic Conflict Explainer**: If 0 valid combinations exist, iterates across all course pairs to identify the exact blocking conflict (e.g., `"CSE103 overlaps with MAT101 on ST (08:30 AM - 10:00 AM)"`).
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "generationId": "550e8400-e29b-41d4-a716-446655440000",
    "count": 48
  }
  ```

---

##### Endpoint 4: `generate_pdf`
* **Handler**: `pdf_service.py -> handle_generate_pdf` -> `ewumate_pdf_engine.py`
* **Authentication**: Requires Supabase Bearer JWT.
* **Purpose**: Generates high-resolution academic cover pages directly into a binary PDF byte stream.
* **Request Payload**:
  ```json
  {
    "template": "lab_report",
    "course_code": "CSE207",
    "course_name": "Data Structures",
    "section": "02",
    "topic": "Implementation of Red-Black Trees",
    "lab_experiment_no": "04",
    "instructor_name": "Dr. Taskeed Jabid",
    "instructor_designation": "Associate Professor",
    "department": "Department of Computer Science and Engineering",
    "student_name": "Rahim Ahmed",
    "student_id": "2022-1-60-001",
    "allocation_date": "2026-10-10",
    "submission_date": "2026-10-17"
  }
  ```
* **Supported Templates**:
  * `assignment` / `general_assignment`: Standard individual coursework sheet.
  * `lab_report`: Engineering and science laboratory experiments with dedicated experiment number headers.
  * `physics_lab`: Specialized physics department cover layout.
  * `mps_assignment`: Mathematical & Physical Sciences department formatted assignment sheet.
  * `group_project` / `term_paper` / `project_report`: Multi-student tabular team submission sheet.
* **Canvas Styling & Geometry**:
  * Page Size: A4 (`595.27 x 841.89` pt).
  * Perimeter Border: Drawn at margin `35pt` with stroke width `1.5pt` in official EWU Green (`#2e7d32` / `RGB(0.18, 0.49, 0.19)`).
  * Institutional Branding: Loads `logo.png` dynamically from local package directory, rendered at `140 x 50` pt centered at top.
  * Text Alignment: Two-column label-value alignment with strict colon coordinate pinning (`label_x = 75`, `colon_x = 180`, `value_x = 195`).
* **HTTP Response**:
  * Status: `200 OK`
  * Content-Type: `application/pdf`
  * Headers: `Content-Disposition: attachment; filename=CoverPage.pdf`

---

##### Endpoint 5: `generate_snapshot`
* **Handler**: `snapshot_service.py -> handle_generate_snapshot`
* **Purpose**: Generates an administrative faculty course assignment PDF ledger, uploads it to Google Drive, and records the snapshot metadata in Supabase `app_config`.
* **Request Payload**:
  ```json
  {
    "semester": "Fall 2026",
    "extract_portal": false,
    "triggered_by": "manual"
  }
  ```
* **Execution Flow**:
  1. Safeguard: Ignores non-semester categories (`FACULTY_MASTER`, `PORTAL_SYNC`, `PING`).
  2. If `extract_portal = true`, runs `scraper_utils.run_sync()` first to pull fresh data from EWU portal.
  3. Executes `snapshot_utils.run_automated_snapshot()`:
     * Queries all records from `courses_{clean_sem}` using pagination (bypassing 1000 row PostgREST limit).
     * Builds PDF document using ReportLab `SimpleDocTemplate` matching the admin portal table: `PROG | DESCRIPTION | SEC | FAC | CAP | SCHEDULE | ROOM | TYPE`.
     * Direct Google Drive Upload: Loads OAuth credentials from table `drive_accounts` (`purpose = 'facultylist'`, `is_active = true`), refreshes the Google access token via `https://oauth2.googleapis.com/token`, and uploads the multipart PDF directly to Google Drive Folder `117C1TyXx4Q1q1ihcgJoE1xk7CzCYniSD`.
     * Enforces the 1-snapshot-per-day rule: Replaces any previous snapshot generated on the same calendar day in `app_config.faculty_snapshots`.
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "message": "Snapshot generated for Fall 2026",
    "snapshot": {
      "status": "success",
      "file_name": "EWU_Faculty_List_2026-10-17_18-30-00.pdf",
      "drive_link": "https://drive.google.com/file/d/1a2b3c4d5e/view"
    }
  }
  ```

---

##### Endpoint 6: `parse_grade_sheet`
* **Handler**: `grade_sheet_service.py -> handle_parse_grade_sheet` -> `grade_sheet_parser.py`
* **Purpose**: Automates authentication against EWU student portal, requests the official student grade sheet report, downloads the server-side PDF, and parses complete academic history.
* **Request Payload**:
  ```json
  {
    "student_id": "2022-1-60-001",
    "password": "StudentPortalPassword"
  }
  ```
* **Extraction Pipeline**:
  1. `requests.Session` initializes connection to `https://portal.ewubd.edu/Account/Login`.
  2. HTML parsing via BeautifulSoup extracts hidden inputs `FirstNo` and `SecondNo`.
  3. Computes arithmetic verification response `Answer = int(FirstNo) + int(SecondNo)`.
  4. Submits login POST payload. Asserts redirection away from login page.
  5. Requests `/ReportForms/rptGradeSheetStudent.aspx`.
  6. Scrapes regex match for PDF endpoint: `"PdfDownloadUrl":"([^"]+)"`.
  7. Downloads the binary PDF stream and inspects with `pypdf.PdfReader`.
  8. Parses lines for semester headings (`^(\d{4})\s+(Spring|Summer|Fall)$`) and course lines (`^[A-Z]{2,4}\d{3,4}$`).
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "count": 36,
    "courses": [
      {
        "semester_code": "spring2023",
        "course_code": "CSE103",
        "course_name": "Structured Programming Language",
        "credits": 4.0,
        "grade": "A+",
        "grade_point": 4.0
      }
    ]
  }
  ```

---

##### Endpoint 7: `portal_sync_student`
* **Handler**: `portal_service.py -> handle_portal_sync_student`
* **Purpose**: Full student synchronization endpoint. Authenticates student portal session, extracts profile, harvesting enrolled routines, normalizes session times, executes crowd-sourced catalog enrichment, and parses historical grades.
* **Request Payload**:
  ```json
  {
    "student_id": "2022-1-60-001",
    "password": "StudentPortalPassword",
    "semester_code": "fall2026"
  }
  ```
* **Processing Highlights**:
  1. Resolves `target_sem_id` from Supabase `active_semester` or `semesters` table.
  2. Fetches student profile: `/api/StudentProfile/GetStudentProfile` (fallback `/api/utility/GetStudentProfile`).
  3. Fetches enrolled course routine: `/api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent/{sem_id}`.
  4. Parses time slots and rooms into discrete structured sessions:
     * Converts time representations to 12-hour AM/PM format.
     * Evaluates class session duration: If duration is $\ge 110$ minutes or room contains "lab", tags session as `Lab`; otherwise `Theory`.
     * Expands compound day codes (`ST` -> Sunday & Tuesday, `MW` -> Monday & Wednesday, `SR` -> Sunday & Thursday).
     * Tracks withdrawal and drop flags: `WithDrawStatus`, `DropStatus`, `IsWithdraw`, `IsDrop`.
  5. Assembles `weekly_grid` structured Monday through Sunday.
  6. **Crowdsourced Catalog Enrichment**: Extracts non-TBA faculty assignments and immediately dispatches them into `courses_sync_service.handle_sync_api_courses()`. Updates `courses_{semester}` without altering existing course UUIDs, while enriching `faculty_master` with faculty names, initials, and official emails.
  7. Concurrently parses full student grade sheet via `handle_parse_grade_sheet()`.
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "profile": {
      "StudentId": "2022-1-60-001",
      "StudentName": "Rahim Ahmed",
      "DepartmentName": "Computer Science & Engineering",
      "ProgramName": "B.Sc. in CSE"
    },
    "active_semester_id": 141,
    "active_semester_name": "Fall 2026",
    "semester_code": "fall2026",
    "enrolled_courses": [
      {
        "course_code": "CSE325",
        "original_code": "CSE325",
        "section": "1",
        "credits": 3.0,
        "timing": "ST 08:30 AM-10:00 AM",
        "room": "AB2-401",
        "faculty_name": "Dr. Taskeed Jabid",
        "faculty_initial": "TJB",
        "faculty_email": "tjb@ewubd.edu",
        "withdraw_status": "No",
        "drop_status": "No",
        "is_dropped_or_withdrawn": false,
        "sessions": [
          {
            "type": "Theory",
            "day": "Sunday",
            "startTime": "8:30 AM",
            "endTime": "10:00 AM",
            "room": "AB2-401",
            "faculty": "TJB",
            "faculty_name": "Dr. Taskeed Jabid",
            "faculty_email": "tjb@ewubd.edu"
          }
        ]
      }
    ],
    "weekly_grid": {
      "Sunday": [
        {
          "course_code": "CSE325",
          "section": "1",
          "time": "8:30 AM-10:00 AM",
          "room": "AB2-401",
          "faculty": "TJB",
          "faculty_name": "Dr. Taskeed Jabid",
          "faculty_email": "tjb@ewubd.edu",
          "type": "Theory"
        }
      ],
      "Monday": [],
      "Tuesday": [
        {
          "course_code": "CSE325",
          "section": "1",
          "time": "8:30 AM-10:00 AM",
          "room": "AB2-401",
          "faculty": "TJB",
          "faculty_name": "Dr. Taskeed Jabid",
          "faculty_email": "tjb@ewubd.edu",
          "type": "Theory"
        }
      ]
    },
    "parsed_grades": [
      {
        "semester_code": "spring2023",
        "course_code": "CSE103",
        "course_name": "Structured Programming Language",
        "credits": 4.0,
        "grade": "A+",
        "grade_point": 4.0
      }
    ],
    "degree_areas": [
      {
        "CourseAreaName": "Major Core",
        "CompletedCredit": 36.0,
        "RequiredCredit": 54.0
      }
    ]
  }
  ```

---

##### Endpoint 8: `sync_api_courses`
* **Handler**: `courses_sync_service.py -> handle_sync_api_courses`
* **Purpose**: Primary database synchronization pipeline for course catalog data coming from the scraper, portal student sync, or administrative panel.
* **Request Payload**:
  ```json
  {
    "semester": "fall2026",
    "courses": [
      {
        "code": "CSE103",
        "section": "1",
        "faculty": "SRK",
        "capacity": "32/35",
        "course_name": "Structured Programming",
        "credits": 4.0,
        "dedicated_department": "Computer Science and Engineering",
        "faculty_full_name": "Shahriar Rahman",
        "faculty_designation": "Lecturer",
        "sessions": [
          {
            "type": "Theory",
            "day": "S",
            "startTime": "08:30 AM",
            "endTime": "10:00 AM",
            "room": "AB2-401",
            "faculty": "SRK"
          }
        ]
      }
    ],
    "delete_missing": false
  }
  ```
* **Strict Synchronization Invariants**:
  1. **UUID Invariance**: The primary key `id` of an existing course section is **never** replaced or regenerated. If `(course_code, section_number)` exists in the database, `mc['id'] = old_c['id']`.
  2. **Non-TBA Faculty Protection**: If an existing database section already has an assigned faculty member (`faculty_initials` is not `TBA`, `NONE`, or empty), the incoming scraper record **cannot overwrite** the faculty initials, full name, or designation with `TBA`.
  3. **Diff Detection (`has_changed`)**: Only rows where attributes (`capacity`, `schedule_data`, `room`, `credit_val`, `department`) actually changed are sent for update, minimizing write traffic and trigger executions.
  4. **PostgREST Pagination Bypass**: Uses range-based pagination (`.range(offset, offset + limit - 1)`) to load and inspect all records in `courses_{semester}` without hitting Supabase's default 1000-row limit.
  5. **Client Cache Invalidation**: Updates `app_config.catalog_cache_version` with Unix epoch timestamp (`int(time.time())`) so mobile and web clients immediately recognize stale local caches.
* **Success Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "message": "Sync Complete for fall2026",
    "semester": "fall2026",
    "table": "courses_fall2026",
    "total": 450,
    "inserted": 12,
    "updated": 88,
    "deleted": 0,
    "pdf_snapshot": null
  }
  ```

---

##### Endpoint 9: `portal_sync`
* **Handler**: `courses_sync_service.py -> handle_portal_sync` -> `scraper_utils.run_sync`
* **Purpose**: Triggers an automated scrape of the active semester catalog from the EWU student portal.
* **Request Payload**:
  ```json
  {
    "semester": "Fall 2026",
    "preview": false
  }
  ```

##### Endpoint 10: `faculty_sync`
* **Handler**: `courses_sync_service.py -> handle_faculty_sync` -> `scraper_utils.run_faculty_master_sync`
* **Purpose**: Synchronizes the global faculty phonebook from `/api/utility/GetAllFaculty` and enriches with profile pictures, designations, and room numbers from `www.ewubd.edu/search-faculty`.

---

##### Endpoint 11: `get_advising_courses`
* **Handler**: `advising_service.py -> handle_get_advising_courses`
* **Purpose**: Evaluates a student's degree curriculum eligibility against completed courses, current enrollments, and prerequisites.
* **Request Payload**:
  ```json
  {
    "user_id": "83b9cf71-2918-472e-836f-bca12078cfbb",
    "semester": "fall2026",
    "program_code": "CSE"
  }
  ```
* **Architecture & Database Drivers**:
  * Directly connects to the Supabase PostgreSQL transaction pooler (`aws-1-ap-south-1.pooler.supabase.com:5432`) via `psycopg2` with `RealDictCursor`.
* **Business Rules & Curriculum Constraints**:
  * **OBE 7/9 Equivalence Rule**: Normalizes course codes by stripping prefixes 7 and 9 for 4-digit codes (`CSE7106` -> `CSE106`, `MBA9501` -> `MBA501`) while preserving Law department course codes and legitimate 7-series courses (`CE7`, `PHRM7`).
  * **Prerequisite Satisfaction**: A course's prerequisite is satisfied if it is present in either:
    1. `completed_courses` with a passing grade ($\ne$ `F`, `W`, `I`, `X`).
    2. `enrollments` with active status (`enrolled` or null grade).
  * **Credit Gate Thresholds**: Certain senior-level courses (e.g., Senior Design / Capstone / Internship) require a minimum threshold of passed credits (e.g., 100+ credits). Only passed courses contribute to this credit total; in-progress courses are excluded.
  * **Retake Eligibility**: Passed courses with grades `D`, `D+`, or `C-` are marked as retake-eligible.
  * **Course Categorization Output**:
    - `COMPLETED`: Already passed.
    - `CURRENTLY_ENROLLED`: In progress during current semester.
    - `ELIGIBLE`: Prerequisites and credit thresholds satisfied; ready for registration.
    - `LOCKED`: Blocked due to missing prerequisite courses or credit deficits.
* **Success Response (200 OK)**:
  ```json
  {
    "program_code": "CSE",
    "program_name": "B.Sc. in Computer Science and Engineering",
    "department_name": "Department of Computer Science and Engineering",
    "total_degree_credits": 140.0,
    "completed_credits": 78.0,
    "summary": {
      "total_curriculum_courses": 46,
      "completed_count": 22,
      "enrolled_count": 4,
      "eligible_count": 8,
      "locked_count": 12,
      "retake_eligible_count": 1
    },
    "eligible_courses": [
      {
        "code": "CSE325",
        "name": "Operating Systems",
        "credits": 3.0,
        "area_name": "Major Core",
        "is_compulsory": true,
        "status": "ELIGIBLE",
        "prerequisites": ["CSE225"],
        "fulfilled_prerequisites": ["CSE225"],
        "missing_prerequisites": [],
        "is_offered": true,
        "section_count": 6
      }
    ],
    "locked_courses": [
      {
        "code": "CSE499A",
        "name": "Senior Design Project I",
        "credits": 3.0,
        "status": "LOCKED",
        "lock_reasons": ["Requires 105 completed credits (you have 78, need 27 more)"]
      }
    ]
  }
  ```

---

### 2.2 Function: `portal_sync_timer`

#### 2.2.1 Cron Schedule Specification
* **File**: `portal_sync_timer/function.json`
* **Trigger Type**: `timerTrigger`
* **NCRONTAB Expression**: `"0 0 11,23 * * *"`
* **Schedule Interpretation**: Executes twice daily at `11:00:00 UTC` and `23:00:00 UTC`. In Bangladesh Standard Time (BST / UTC+6), this translates to:
  * **05:00 PM BST (17:00)**: Immediately follows daily university administrative office hours when course sections, capacities, and advising schedules are updated.
  * **05:00 AM BST (05:00)**: Overnight synchronization preparing up-to-date catalog and advising datasets before students log in for morning advising.

#### 2.2.2 Multi-Stage Execution Pipeline
```python
def main(mytimer: func.TimerRequest) -> None:
    # 1. Automated Semester Switch & Advising Window Evaluation
    check_and_switch_semesters()
    
    # 2. Automated Faculty Master & Website Directory Crawl
    # Conditional: Every Sunday (weekday 6) and 1st / 15th of month
    if today.weekday() == 6 or today.day in [1, 15]:
        run_faculty_master_sync()
        
    # 3. Portal Course Catalog Scraper Sync
    run_sync(is_preview=False)
```

1. **Semester Milestone Evaluation**: Executes `check_and_switch_semesters()`. Evaluates advising open/close flags and executes semester promotions if current date reaches `semester_switch_date`.
2. **Scheduled Faculty Directory Synchronization**: To prevent excessive bandwidth consumption against university infrastructure, full web directory enrichment runs on Sundays and on the 1st and 15th of every month.
3. **Portal Course Catalog Scraper Sync**: Runs `run_sync(is_preview=False)`, iterating through active and next semesters, updating course offerings, room allocations, times, and faculty assignments.
4. **Audit Logging**: Inserts execution results into `scraper_logs` in Supabase.

---

### 2.3 Function: `portal_sync_trigger`

#### 2.3.1 Webhook Contract & Request Normalization
* **File**: `portal_sync_trigger/function.json`
* **Route**: `scraper/portal_sync`
* **Methods**: `GET`, `POST`
* **Authorization**: `anonymous` (invoked via Admin dashboard, CI/CD webhooks, or automated Supabase database webhooks).

#### 2.3.2 Query & Body Parameters
The function extracts parameters from either query string parameters or JSON body fields:
* `semester` (string, optional): Specific semester code to scrape (e.g., `"fall2026"`). If omitted, loads target semesters from `scraper_config`.
* `preview` (boolean, optional): If `true`, runs the scraper in memory and returns extracted JSON without committing changes to Supabase.
* `action` / `target` (string, optional):
  * `"ping"` / `semester="PING"`: Fast health-check path that immediately returns `{"status": "live", "message": "Service healthy"}` without network scraping.
  * `"faculty_sync"`: Dispatches directly to `run_faculty_master_sync()`.
  * `"full_sync"`: Runs both faculty directory enrichment and catalog sync.
* `sync_faculty` (boolean, optional): When `true`, executes both faculty master sync and course catalog sync in a single invocation.

#### 2.3.3 HTTP Status Semantics
* `200 OK`: Successful crawl and synchronization.
* `401 Unauthorized`: Portal login failed (e.g. invalid scraper student credentials configured in `scraper_config`).
* `500 Internal Server Error`: Network exception, unhandled timeout, or Supabase connection failure.

---

## 3. Portal Scraping & Automation Engine

### 3.1 Authentication & Session Mechanics

East West University's portal uses ASP.NET MVC architecture with form-based session cookie authentication and a server-generated math captcha challenge on every login attempt.

```
+---------------------------------------------------------------------------------------------------------+
|                                  EWU PORTAL LOGIN AUTHENTICATION FLOW                                   |
+---------------------------------------------------------------------------------------------------------+
|  1. GET https://portal.ewubd.edu/Account/Login                                                          |
|     <input name="FirstNo" value="14" />                                                                |
|     <input name="SecondNo" value="7" />                                                                 |
|                                                                                                         |
|  2. Mathematical Evaluation:                                                                            |
|     Answer = int(FirstNo) + int(SecondNo)  =>  14 + 7 = 21                                              |
|                                                                                                         |
|  3. POST https://portal.ewubd.edu/Account/Login                                                         |
|     Payload: { Username: student_id, Password: password, FirstNo: 14, SecondNo: 7, Answer: 21 }         |
|     Headers: User-Agent, Referer, Accept                                                                |
|                                                                                                         |
|  4. Session Established:                                                                                |
|     Response Cookie: .ASPXAUTH, ASP.NET_SessionId                                                       |
|     Redirect Verification: Assert "Home/Index" or "/Home" in res.url                                   |
+---------------------------------------------------------------------------------------------------------+
```

* **Anti-Scraping Defenses**: The portal detects generic automation tools. The engine circumvents detection by injecting Chrome desktop User-Agent strings, setting `X-Requested-With: XMLHttpRequest`, and retaining complete cookie jars across subsequent calls via `requests.Session`.

---

### 3.2 Portal API Reverse-Engineered Directory

Through reverse-engineering client scripts (`main-bundle-supp2.js`, AngularJS controllers, and network requests), the following portal API endpoints were mapped:

```
+---------------------------------------------------------------------------------------------------------+
|                                    REVERSE-ENGINEERED PORTAL ENDPOINTS                                  |
+----+---------------------------------------------------------------+--------+---------------------------+
| #  | API Endpoint                                                  | Method | Output / Purpose          |
+----+---------------------------------------------------------------+--------+---------------------------+
| 1  | /Account/Login                                                | POST   | Auth & session cookie     |
| 2  | /api/utility/GetSemesterForDropDown                           | GET    | Active semester list & IDs|
| 3  | /api/utility/GetAllOfferedCoursesBySemAndDept                 | GET    | Dept-specific courses     |
| 4  | /api/utility/GetAllOfferedCourses                             | GET    | Master catalog fallback   |
| 5  | /api/utility/GetAllFaculty                                    | GET    | Faculty initials & emails |
| 6  | /api/StudentProfile/GetStudentProfile                         | GET    | Student bio & department  |
| 7  | /api/utility/GetStudentProfile                                | GET    | Profile lookup fallback   |
| 8  | /api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent  | GET    | Student routine & faculty |
| 9  | /api/DegreeReview/GetDegreeReviewCourseAreaCourses             | GET    | Degree curriculum audit   |
| 10 | /ReportForms/rptGradeSheetStudent.aspx                        | GET    | Dynamic PDF download URL  |
| 11 | https://www.ewubd.edu/search-faculty                          | POST   | OctoberCMS faculty search |
| 12 | https://www.ewubd.edu/faculty-profile/{slug}                  | GET    | Faculty office room & bio |
+----+---------------------------------------------------------------+--------+---------------------------+
```

---

### 3.3 Course Catalog Harvesting Pipeline (`scraper_utils.py`)

When harvesting a semester's course catalog:
1. **Dynamic Semester Resolution**: Fetches `/api/utility/GetSemesterForDropDown`. Matches semester names (e.g., `"Fall 2026"`, `"Summer 2026"`) to determine internal university integer IDs (`SemesterId`).
2. **Multi-Department Iterative Scanning**:
   * The university frequently throttles or returns empty arrays on the universal endpoint `/api/utility/GetAllOfferedCourses?deptid=0`.
   * The engine scans active department IDs from `1` to `30` against:
     ```
     /api/utility/GetAllOfferedCoursesBySemAndDept?deptid={dept_id}&semesterid={sem_id}
     ```
   * Aggregates records across all responding academic departments (CSE, EEE, BBA, Law, Pharmacy, English, MPS, and Economics).
3. **Session Timing & Room Parsing**:
   * Inspects `TimeSlotName` (e.g., `"MW 10:10 AM - 11:40 AM"`, `"ST 08:30 AM-10:00 AM"`).
   * Normalizes time strings using 12-hour AM/PM representations.
   * Differentiates Theory vs. Lab sessions based on duration: sessions lasting $\ge 110$ minutes or held in rooms designated with `"lab"` are marked as `Lab` (4 credits for undergraduate 100-400 level courses), while 90-minute sessions are marked as `Theory` (3 credits).
4. **Faculty Initials Normalization**:
   * Resolves faculty keys across multiple possible portal payload attributes: `ShortName`, `EmpShortName`, `TeacherInitial`, `FacultyInitials`, or `Teacher`.
   * Standardizes initials: Removes non-alphanumeric characters. Preserves `"RUTBA"` (a legitimate faculty member's initials) while converting `"TBA-1"`, `"TBA-2"`, or empty values to `"TBA"`.

---

### 3.4 Faculty Course Assignment Crowdsourcing & Submissions

#### The "TBA" Problem
During official pre-advising and early advising windows, EWU administration masks faculty initials as `"TBA"` in the public course offerings catalog to prevent section rushing. However, individual student advising routine queries (`GetSemesterStudentWiseAdvisingCourseListStudent`) return the actual assigned instructors.

```
+---------------------------------------------------------------------------------------------------------+
|                               FACULTY ASSIGNMENT RESOLUTION ARCHITECTURE                                |
+---------------------------------------------------------------------------------------------------------+
|                                                                                                         |
|   +----------------------------------------------------+                                                |
|   | Public Catalog API (/GetAllOfferedCoursesBySemAndDept) |                                                |
|   | Returns: CSE103 Sec 1 -> Faculty: "TBA"             |                                                |
|   +-------------------------+--------------------------+                                                |
|                             |                                                                           |
|                             v                                                                           |
|   +----------------------------------------------------+                                                |
|   | Student Advising Routine API                       |                                                |
|   | (/GetSemesterStudentWiseAdvisingCourseListStudent) |                                                |
|   | Returns: CSE103 Sec 1 -> ShortName: "SRK",         |                                                |
|   |          FacultyName: "Shahriar Rahman"            |                                                |
|   +-------------------------+--------------------------+                                                |
|                             |                                                                           |
|                             v                                                                           |
|   +----------------------------------------------------+                                                |
|   | Crowdsourced Database Synchronization              |                                                |
|   | 1. Enriches courses_{semester} where faculty='TBA' |                                                |
|   | 2. Updates faculty_master phonebook table          |                                                |
|   | 3. Preserves existing non-TBA assignments          |                                                |
|   +-------------------------+--------------------------+                                                |
|                             |                                                                           |
|                             v                                                                           |
|   +----------------------------------------------------+                                                |
|   | Community Submission Fallback System               |                                                |
|   | Table: faculty_assignment_submissions              |                                                |
|   | Proofs: storage bucket 'faculty_assignment_proofs' |                                                |
|   | RPC: approve_faculty_assignment_submission()        |                                                |
|   +----------------------------------------------------+                                                |
+---------------------------------------------------------------------------------------------------------+
```

1. **Automatic Crowdsourcing**: Every time any student logs in via `portal_sync_student`, their assigned faculty members are automatically harvested and backfilled into `courses_{semester}`.
2. **Community Verification Submissions**: Students can upload screenshots of departmental noticeboards or routine sheets. Submissions are queued in `faculty_assignment_submissions`:
   * Column `submission_type`: `'ENROLLED'` or `'BULK'`.
   * Column `status`: `'PENDING'`, `'APPROVED'`, `'REJECTED'`.
   * Storage: Image proofs stored in `faculty_assignment_proofs` bucket.
   * Admin Approval RPC: `approve_faculty_assignment_submission(submission_id, notes)` executes dynamic SQL to update `courses_{semester}` with verified faculty initials, names, and designations.

---

### 3.5 Official EWU Website Profile Harvester (`enrich_faculty_from_website`)

The scraper targets East West University's public October CMS directory at `https://www.ewubd.edu/search-faculty`.

* **AJAX Request Structure**:
  ```http
  POST https://www.ewubd.edu/search-faculty HTTP/1.1
  Host: www.ewubd.edu
  X-Requested-With: XMLHttpRequest
  X-OCTOBER-REQUEST-HANDLER: onFacultySearch
  X-OCTOBER-REQUEST-PARTIALS: search/facultysearch
  Content-Type: application/x-www-form-urlencoded

  department_id=all&faculty_designation=all
  ```
* **HTML Parsing & Extraction**:
  1. Parses the returned HTML partial into individual faculty profile cards.
  2. Extracts faculty slug, clean display name, designation, and normalized profile picture URL (`photo_url`).
  3. Multithreaded Profile Detail Crawling (`ThreadPoolExecutor(max_workers=15)`): Requests `https://www.ewubd.edu/faculty-profile/{slug}` for each member.
  4. Office Room Resolution: Inspects profile text for room patterns:
     ```python
     re.search(r'Room\s*(?:No#?|#|no\.?|number)?\s*[:#\-]?\s*([A-Za-z0-9]+(?:\s*-\s*[A-Za-z0-9]+)?)', line, re.IGNORECASE)
     ```
  5. Bulk SQL Execution: Executes batch updates via Supabase RPC `exec_sql`, enriching `faculty_master` with designations, official photos, departments, and room numbers.

---

## 4. Database Integration & Supabase Sync

### 4.1 Supabase Database Architecture & Entity Models

```
+---------------------------------------------------------------------------------------------------------+
|                                    SUPABASE SCHEMA RELATIONSHIPS                                        |
+---------------------------------------------------------------------------------------------------------+
|                                                                                                         |
|   +---------------------+             +----------------------+            +-----------------------+     |
|   |   active_semester   |             |       semesters      |            |     faculty_master    |     |
|   +---------------------+             +----------------------+            +-----------------------+     |
|   | track (PK)          |             | id (PK)              |            | id (PK, UUID)         |     |
|   | current_semester_code|            | code (UNIQUE)        |            | short_name (UNIQUE)   |     |
|   | next_semester_code  |             | portal_semester_id   |            | full_name             |     |
|   | classes_start_date  |             | title                |            | email                 |     |
|   | semester_switch_date|             | is_active            |            | designation_name      |     |
|   | is_advising_open    |             +----------------------+            | office_room           |     |
|   +---------------------+                                                 | photo_url             |     |
|                                                                           +-----------+-----------+     |
|                                                                                       |                 |
|                                                                                       v                 |
|   +---------------------+             +----------------------+            +-----------+-----------+     |
|   | course_metadata     |             | program_curriculum   |            |  courses_{semester}   |     |
|   +---------------------+             +----------------------+            +-----------------------+     |
|   | code (PK)           |             | program_code (FK)    |            | id (PK, UUID)         |     |
|   | name                |             | course_code (FK)     |            | course_code           |     |
|   | credit_val          |             | area_name            |            | section_number        |     |
|   | required_credits    |             | is_compulsory        |            | faculty_initials (FK) |     |
|   +----------+----------+             +----------------------+            | capacity              |     |
|              |                                                            | schedule_data (JSONB) |     |
|              v                                                            | credit_val            |     |
|   +----------+----------+             +----------------------+            +-----------------------+     |
|   |course_prerequisites |             | schedule_generations |                                          |
|   +---------------------+             +----------------------+                                          |
|   | course_code (FK)    |             | id (PK, UUID)        |                                          |
|   | prerequisite_code(FK|             | user_id (FK)         |                                          |
|   | required_credits    |             | combinations (JSONB) |                                          |
|   +---------------------+             | status               |                                          |
|                                       +----------------------+                                          |
+---------------------------------------------------------------------------------------------------------+
```

---

### 4.2 Primary Table Schema Definitions

#### 1. Dynamic Course Offering Tables (`courses_{semester}`)
*Table Name Pattern*: `courses_fall2026`, `courses_summer2026`, `courses_spring2026`
* Created dynamically via RPC `create_course_table(p_semester_code)`.
* Columns:
  * `id` (`UUID`, Primary Key, default `gen_random_uuid()`): Immutable unique section identifier.
  * `course_code` (`TEXT`): Standardized code (e.g., `CSE103`).
  * `section_number` (`TEXT`): Section designator (e.g., `1`, `02`).
  * `faculty_initials` (`TEXT`): Instructor initials (e.g., `SRK`, `TBA`).
  * `faculty_full_name` (`TEXT`): Enriched full instructor name.
  * `faculty_designation` (`TEXT`): Academic title.
  * `capacity` (`TEXT`): Format `"SeatTaken/SeatCapacity"` (e.g., `"35/35"`).
  * `schedule_data` (`JSONB`): Array of session objects:
    ```json
    [
      {
        "type": "Theory",
        "day": "S",
        "startTime": "08:30 AM",
        "endTime": "10:00 AM",
        "room": "AB2-401",
        "faculty": "SRK"
      }
    ]
    ```
  * `credit_val` (`NUMERIC`): Section credit weight (typically `3.0` or `4.0`).
  * `dedicated_department` (`TEXT`): Academic department restriction.
  * `updated_at` (`TIMESTAMPTZ`): Timestamp of last modification.

#### 2. Faculty Directory Master (`faculty_master`)
* Central phonebook storing historical and current EWU faculty profiles.
* Unique Constraint: `short_name` (Faculty Initials).
* Columns:
  * `id` (`UUID`, Primary Key)
  * `short_name` (`TEXT`, UNIQUE): Faculty initials.
  * `full_name` (`TEXT`): Official name.
  * `email` (`TEXT`): University email address.
  * `phone` (`TEXT`): Campus extension or contact phone.
  * `designation_name` (`TEXT`): Professor, Associate Professor, Assistant Professor, Senior Lecturer, Lecturer.
  * `department_name` (`TEXT`): Academic department.
  * `office_room` (`TEXT`): Physical office room (e.g., `"AB2-512"`).
  * `photo_url` (`TEXT`): Direct HTTPS URL to official headshot.

#### 3. Semester Lifecycle Tracking (`active_semester`)
* Tracks active terms across dual academic calendars: `tri_semester` (Standard) and `bi_semester` (Pharmacy & Law).
* Columns:
  * `track` (`TEXT`, Primary Key): `'tri_semester'` or `'bi_semester'`.
  * `current_semester_code` (`TEXT`): e.g. `'summer2026'`.
  * `next_semester_code` (`TEXT`): e.g. `'fall2026'`.
  * `classes_start_date` (`DATE`): First day of classes.
  * `classes_end_date` (`DATE`): Last day of instruction.
  * `advising_start_date` (`DATE`): Pre-advising launch date.
  * `advising_end_date` (`DATE`): Advising closing date.
  * `final_exam_start` / `final_exam_end` (`DATE`): Examination window.
  * `grade_submission_start` / `grade_submission_deadline` (`DATE`): Grading deadline.
  * `semester_switch_date` (`DATE`): Automated promotion date.
  * `upcoming_classes_start_date` (`DATE`): Next term opening date.
  * `is_advising_open` (`BOOLEAN`): Real-time registration state flag.
  * `is_next_semester_open` (`BOOLEAN`): Next term browsing flag.

#### 4. Scraper Logs & Execution Audit (`scraper_logs`)
* Ingests run reports for administrative observability.
* Columns:
  * `id` (`BIGINT`, Primary Key)
  * `semester` (`TEXT`): Term identifier.
  * `added` (`INT`): Number of newly inserted courses.
  * `updated` (`INT`): Number of modified courses.
  * `deleted` (`INT`): Number of deleted courses.
  * `status` (`TEXT`): `'success'` or `'error'`.
  * `report` (`JSONB`): Full execution diagnostic trace.
  * `created_at` (`TIMESTAMPTZ`): Execution timestamp.

---

### 4.3 Data Integrity Invariants & Conflict Resolution

#### Rule 1: The Immutable Course UUID
Courses in `courses_{semester}` are referenced by foreign keys in student schedule drafts, bookmarks, and enrollment tables. If the scraper deleted and re-inserted courses on every crawl, foreign keys would cascade-delete or break.
* Solution: `courses_sync_service.py` maintains an existing `(course_code, section_number) -> id` dictionary. When upserting:
  ```python
  if key in existing_data_map:
      mc["id"] = existing_data_map[key]["id"]
  ```

#### Rule 2: Non-TBA Faculty Preservation
When departments release initial catalogs, faculty names appear as `"TBA"`. As students enroll, crowdsourced routines replace `"TBA"` with real faculty names (e.g. `"SRK"`). Subsequent runs of the master scraper might still see `"TBA"` from the university's un-updated catalog endpoint.
* Solution: The synchronization engine inspects existing assignments:
  ```python
  old_fac = (old_c.get("faculty_initials") or "").strip()
  if old_fac and old_fac.upper() not in ("TBA", "NONE", "", "NULL"):
      mc["faculty_initials"] = old_c.get("faculty_initials")
      mc["faculty_full_name"] = old_c.get("faculty_full_name")
      mc["faculty_designation"] = old_c.get("faculty_designation")
  ```

#### Rule 3: Client Cache Invalidation
Client applications cache course offerings locally using SQLite / Hive. Whenever `handle_sync_api_courses` executes an insert or update, it commits an updated version timestamp to Supabase `app_config`:
```python
sb.table("app_config").upsert({
    "key": "catalog_cache_version",
    "value": {
        "version": int(time.time()),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
}, on_conflict="key").execute()
```
Client applications query this key on startup; if the remote version exceeds their local timestamp, they pull down the refreshed catalog.

---

## 5. Utility Scripts & Diagnostic Tools Catalog

The repository root contains an extensive array of diagnostic, reverse-engineering, maintenance, and migration scripts. Below is the comprehensive technical catalog of every script in `azure_functions/`.

---

### 5.1 Database & Schema Diagnostic Scripts

| Script File | Purpose & Operational Mechanics | Database / API Effects |
| :--- | :--- | :--- |
| `list_all_db_tables.py` | Connects to Supabase REST and queries Postgres information schema to list all public database tables, view definitions, and row counts. | Read-only inspection of schema. |
| `check_pg.py` | Direct TCP connection verification using `psycopg2` against AWS South Asia Supabase transaction pooler. Validates database port 5432 connectivity. | Read-only connection health check. |
| `check_rpc.py` | Tests whether custom Postgres functions (`create_course_table`, `create_calendar_table`, `exec_sql`) are callable via PostgREST RPC. | Executes test RPC calls. |
| `check_section.py` | Queries `courses_spring2026` to verify data integrity of `section_number` and `schedule_data` structures. | Read-only data inspection. |
| `check_user_schemas.py` | Inspects Supabase `profiles`, `auth.users`, and `completed_courses` table schemas for column type mismatches. | Read-only schema inspection. |
| `check_logs.py` | Retrieves and formats the last 20 execution records from `scraper_logs` to diagnose scraper failures. | Read-only log inspection. |
| `check_now.py` | Queries the current timestamp and connection status of the Supabase PostgreSQL cluster. | Read-only inspection. |
| `temp_query.py` | Ad-hoc SQL execution script for inspecting specific enrollment or faculty assignment records via `psycopg2`. | Read-only diagnostic queries. |
| `test_col.py` | Inspects column types and constraint definitions of `program_curriculum_courses` and `course_prerequisites`. | Read-only metadata query. |

---

### 5.2 Portal Reverse-Engineering & API Discovery Scripts

| Script File | Purpose & Operational Mechanics | Diagnostic Use Case |
| :--- | :--- | :--- |
| `extract_bundle_apis.py` | Authenticates to portal, downloads JavaScript bundle `/Assets/js/main-bundle-supp2.js`, and regex-extracts all internal `/api/*` endpoints. | Discovers unadvertised university API routes. |
| `find_angular_controller.py` | Scrapes portal DOM and scripts to extract AngularJS controller definitions (`ng-controller`) and attached scope functions. | Identifies how portal UI submits form data. |
| `find_class_schedule_js.py` | Analyzes `/Home/ClassSchedule` web scripts to locate AJAX endpoints serving live class timetables. | Discovered routine JSON structures. |
| `find_faportal_js.py` | Analyzes faculty-facing portal JavaScript bundles to identify endpoints used by instructors for grading and routines. | Maps faculty grade submission endpoints. |
| `scan_bundlealt.py` | Secondary bundle scanner parsing alternative JavaScript vendor assets for REST endpoint paths. | Comprehensive API mapping. |
| `scan_all_controllers.py` | Regex scans all portal scripts to map controller names to API routes. | Reverse-engineering portal navigation. |
| `deep_scan_dom.py` | Crawls portal HTML pages using BeautifulSoup to extract hidden input fields, form actions, and script variables. | Captcha and CSRF parameter discovery. |
| `dump_class_schedule_html.py` | Authenticates and dumps the full raw HTML markup of `/Home/ClassSchedule` to disk for inspection. | DOM structure verification. |
| `dump_keys.py` | Parses portal JSON responses to list all key names across student and faculty records. | Schema definition mapping. |
| `discover_portal_api.py` | Probes candidate portal endpoints with various HTTP methods to catalog valid routes. | API surface discovery. |
| `inspect_advising_page.py` | Authenticates as a student and dumps the pre-advising registration page DOM and JavaScript variables. | Maps advising window constraints. |
| `inspect_class_schedule.py` | Tests whether `/Home/ClassSchedule` returns server-rendered HTML or client-side AngularJS bindings. | Guided transition to API scraping. |
| `inspect_faculty_course_assignment.py` | Inspects portal responses to check if faculty initials are present or masked with TBA. | Verifies TBA masking rules. |
| `inspect_grids.py` | Queries `courses_{semester}` to inspect JSON structure of `schedule_data` for timetable rendering. | Debugs client grid alignment bugs. |
| `inspect_offered_courses_student.py` | Directly inspects student view of `/Home/OfferedCoursesStudent`. | Validates course table column mappings. |
| `inspect_page_scripts.py` | Extracts all inline `<script>` tags across portal pages to isolate session state logic. | Discovered captcha equation logic. |
| `test_advising_routines.py` | Tests candidate student routine endpoints against multiple active semester IDs. | Verified routine endpoint stability. |
| `test_routine_endpoints.py` | Probes 10+ candidate advising and routine URLs to identify which return live JSON vs 404/500 errors. | Discovered advising course routine API. |
| `test_class_schedule_apis.py` | Simulates HTTP requests against candidate class schedule endpoints. | Route verification. |
| `test_dept_resolution.py` | Scans department IDs 1 through 30 against the portal to discover active university department IDs. | Identified multi-department scan strategy. |
| `test_non_enrolled_apis.py` | Tests whether students can query course offerings for semesters in which they are not currently registered. | Confirmed cross-semester visibility. |

---

### 5.3 Faculty Synchronization & Verification Tools

| Script File | Purpose & Operational Mechanics | Database / API Effects |
| :--- | :--- | :--- |
| `check_assigned_faculty.py` | Runs `scraper_utils.run_sync(is_preview=True)` and counts how many courses return real faculty vs TBA. | Read-only preview audit. |
| `check_summer_faculty.py` | Verifies faculty assignment coverage for Summer semesters across all offered courses. | Diagnostic report. |
| `harvest_class_schedule.py` | Scrapes enrolled student advising routines across the last 10 semesters to harvest historical faculty mappings. | Compiles faculty assignment catalog. |
| `review_faculty_assignments.py` | CLI review tool to list, approve, or reject student faculty assignment submissions from `faculty_assignment_submissions`. | Invokes `approve_faculty_assignment_submission` RPC. |
| `apply_faculty_assignment_migration.py` | Creates table `faculty_assignment_submissions`, RLS policies, storage bucket `faculty_assignment_proofs`, and approval RPC. | Applies schema migration to Supabase. |
| `test_faculty_master_sync.py` | Tests execution of `run_faculty_master_sync()` from local terminal. | Updates `faculty_master` with live directory data. |
| `test_faculty_endpoints.py` | Probes portal faculty endpoints to test whether credentials have administrative directory access. | Tests permission boundaries. |
| `test_faculty_evaluation_apis.py` | Tests faculty evaluation questionnaire API endpoints for student feedback data. | Read-only evaluation audit. |
| `test_faportal.py` | Tests authentication against the faculty portal domain (`faportal.ewubd.edu`). | Tests faculty login compatibility. |
| `test_full_login_faculty.py` | Comprehensive test of faculty authentication with captcha solving. | Validates faculty session creation. |
| `test_auth_faculty_api.py` | Verifies headers required for faculty-facing REST services. | Validates authentication headers. |
| `test_supabase_login_faculty.py` | Cross-checks faculty credentials against Supabase auth records. | Authentication verification. |
| `test_student_advising_course_list.py`| Directly tests `/api/Advising/GetSemesterStudentWiseAdvisingCourseListStudent`. | Confirms routine JSON structure. |
| `test_portal_api.py` | Tests basic portal API connectivity and response formatting. | Health verification. |
| `test_portal_api_summer.py` | Tests portal API extraction specifically targeted at Summer terms. | Term-specific validation. |
| `test_updated_sync.py` | Verifies that updated synchronization scripts correctly update Supabase tables without data loss. | End-to-end sync verification. |
| `scan_all_depts.py` | Iterates across all 30 department IDs, outputting active course counts per academic department. | Validates department directory. |

---

### 5.4 PDF Ingestion, Parsing & Snapshot Maintenance

| Script File | Purpose & Operational Mechanics | Database / API Effects |
| :--- | :--- | :--- |
| `update_fall2026_from_pdf.py` | Ingests official university faculty assignment PDF using `pdfplumber`, parses multi-line rows, and updates `courses_fall2026`. | Batch updates course table from PDF. |
| `verify_fall2026_update.py` | Verifies that courses updated from PDF have valid faculty names and conflict-free schedules. | Validation audit. |
| `parse_summer.py` | Parses Summer semester calendar PDF and outputs structured JSON milestones. | Local JSON test output. |
| `cleanup_snapshots.py` | Queries `app_config.faculty_snapshots` and prunes redundant records, enforcing the 1-snapshot-per-day rule. | Updates `app_config` metadata. |
| `update_drive_config.py` | Updates Google Drive service account credentials and folder IDs in `drive_accounts`. | Updates OAuth configuration. |
| `test_calendar.py` | End-to-end test of `handle_parse_calendar` against sample calendar PDFs. | Verifies calendar parser. |
| `test_parse_cal.py` | Tests calendar milestone date extraction and year-rollover logic. | Unit test for calendar parser. |
| `test_parse_spring.py` | Tests Spring calendar PDF parsing against webhook storage handlers. | Webhook simulation. |
| `test_regex.py` | Unit tests calendar parser regex patterns against irregular date strings (e.g. `"Sept. 13, 14 & 15"`, `"Nov. 30-Dec. 03"`). | Pure Python regex testing. |
| `local_parse_test.py` | Local standalone test runner for `calendar_parser.py` without requiring Azure Functions runtime. | Local unit testing. |
| `run_parse_test.py` | Runs PDF parsing tests and prints extracted events and metadata dictionaries. | Test execution script. |
| `dl.py` | Utility script to download academic document files directly from Supabase Storage buckets. | Local file download. |
| `ls_storage.py` | Lists all files and buckets in Supabase Storage (`academic_documents`, `faculty_assignment_proofs`). | Storage inventory inspection. |

---

### 5.5 Enrollment, Schedule & Trigger Maintenance

| Script File | Purpose & Operational Mechanics | Database / Code Effects |
| :--- | :--- | :--- |
| `backfill_sections.py` | Queries `courses_spring2026` to map course IDs to `section_number`, then patches the `section` column in `enrollments`. | Fixes missing section numbers in student records. |
| `fix_supabase_trigger.py` | Drops legacy `parse_faculty_on_upload` trigger on `storage.objects` that was causing database upload timeouts. | Executes `DROP TRIGGER` via `psycopg2`. |
| `inspect_trigger_code.py` | Inspects SQL definitions of database triggers (`handle_scraper_log_trigger`, `parse_faculty_on_upload`). | Reads `pg_proc` and `pg_trigger`. |
| `find_all_triggers.py` | Catalogs all active triggers across all schemas in the PostgreSQL database cluster. | System trigger audit. |
| `check_enrollments.py` | Inspects student enrollment status values (`enrolled`, `upcoming`, `completed`) for data consistency. | Diagnostic query. |
| `check_fall2026_enrollments.py`| Inspects Fall 2026 student enrollments to verify status transitions. | Target term audit. |
| `check_fall2026_matches.py` | Cross-references Fall 2026 course codes against `course_metadata` to identify unmatched courses. | Identifies missing course metadata. |
| `fix_unmatched_fall2026.py` | Generates and inserts missing `course_metadata` entries for newly introduced Fall 2026 courses. | Inserts missing course metadata. |
| `check_gen.py` / `check_gen2.py` / `check_gen3.py` | Inspects combinations and status of active schedule generation runs in `schedule_generations`. | Debugs schedule generator performance. |
| `check_phrm_eng.py` | Verifies department courses for Pharmacy and English to ensure bi-semester tracks are handled correctly. | Curriculum track audit. |
| `find_phrm.py` | Searches database for Pharmacy course codes and verifies credit calculation rules. | Course validation query. |
| `fix_ids.py` / `fix_ids2.py` / `fix_ids3.py` / `fix_ids4.py` | Migration scripts that harmonized UUID formats across legacy integer and string course identifiers. | Standardized UUID primary keys. |
| `fix_forgotten.py` | Cleans up orphaned course sections left behind by interrupted sync runs. | Removes dangling course records. |
| `verify_insertion.py` | Verifies that batch course inserts committed successfully with all session objects intact. | Data integrity assertion. |
| `manual_trigger_verify.py` | Simulates an Azure Functions `TimerRequest` to verify timer execution without waiting for cron schedule. | Local timer unit test. |
| `test_http.py` | Direct HTTP request test against Azure Functions endpoints validating response headers and JSON serialization. | Network integration test. |
| `test_local.py` | Integration test verifying `ewumate_api` handlers locally without launching Functions Core Tools. | Fast local verification. |
| `test_local_spring.py` | Local execution test simulating Spring semester data processing. | Term simulation test. |
| `test_new_endpoint.py` | Tests newly deployed Azure Functions endpoints for latency and response codes. | Production deployment smoke test. |
| `patch.py` / `patch2.py` / `patch_4_broken.py` | Maintenance scripts that patched specific schema discrepancies and client widget references. | Code and database hotfixes. |
| `fix_dart.py` / `fix_dart3.py` / `fix_dart4.py` / `fix_dart5.py` / `fix_dart6.py` | Flutter client repository hotfix scripts modifying Dart data models to match backend API structures. | Flutter codebase patches. |
| `write_course_card.py` | Generates and overwrites Dart course card widget code with updated UI components. | Flutter codebase maintenance. |

---

## 6. Local Development, Configuration & Deployment

### 6.1 Configuration & Environment Variables

The application relies on specific environment variables configured in `local.settings.json` (for local development) and Azure App Settings (for production cloud execution).

#### Local Settings Configuration (`local.settings.json`)
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=ewumatestorage1771164445;AccountKey=Y5VznMMHCs9k7mrz2XkU4yWHixuiClbBAxLiG/6BPvgLgEWMGioNvk3VqUcPde43ExWXAo99GfwN+AStkXiWKA==",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "SUPABASE_URL": "https://jwygjihrbwxhehijldiz.supabase.co",
    "SUPABASE_SERVICE_KEY": "REDACTED_SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_SERVICE_ROLE_KEY": "REDACTED_SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_DB_URL": "postgresql://postgres.jwygjihrbwxhehijldiz:PASSWORD@aws-1-ap-south-1.pooler.supabase.com:5432/postgres",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=247a8707-c2a3-4aef-9cdf-18716e04dd84;IngestionEndpoint=https://southeastasia-1.in.applicationinsights.azure.com/;LiveEndpoint=https://southeastasia.livediagnostics.monitor.azure.com/;ApplicationId=6df3d770-df76-4bb5-a887-4ab2b90aa57f"
  },
  "ConnectionStrings": {},
  "Host": {
    "CORS": "*"
  }
}
```

#### Environment Variable Directory

| Key | Required | Purpose & Technical Scope |
| :--- | :--- | :--- |
| `AzureWebJobsStorage` | Yes | Azure Storage account connection string utilized by the Functions runtime for timer triggers, leases, and state tracking. |
| `FUNCTIONS_WORKER_RUNTIME` | Yes | Must be set to `python`. |
| `FUNCTIONS_EXTENSION_VERSION`| Yes | Set to `~4` (Azure Functions Runtime v4). |
| `SUPABASE_URL` | Yes | Base HTTPS URL of the Supabase project cluster. |
| `SUPABASE_SERVICE_KEY` | Yes | Supabase Service Role JWT token used to bypass RLS policies for administrative sync operations. |
| `SUPABASE_DB_URL` | Optional | Direct PostgreSQL connection string used by `advising_service.py` for transaction pooler queries. |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Recommended | Connection string for Azure Application Insights telemetry, traces, and performance counters. |

---

### 6.2 Host Configuration (`host.json`)

The Functions host is configured with extension bundles for Azure Functions v4:

```json
{
    "version": "2.0",
    "extensionBundle": {
        "id": "Microsoft.Azure.Functions.ExtensionBundle",
        "version": "[4.*, 5.0.0)"
    }
}
```

---

### 6.3 Local Development & Testing Workflow

#### Prerequisites
1. **Python 3.11 or 3.13**: Matches the Azure Functions Python worker runtime.
2. **Azure Functions Core Tools v4**: Installed globally via npm:
   ```bash
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```
3. **ReportLab & PDF Dependencies**: Required for local PDF generation testing.

#### Setup Instructions
```powershell
# 1. Navigate to azure_functions directory
cd f:\EWUmate\EWUmate_Clean\ewumate_v2\azure_functions

# 2. Create and activate a Python virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 3. Install production requirements
pip install -r requirements.txt

# 4. Verify local configuration exists
Get-Content local.settings.json

# 5. Launch local Azure Functions Host
func start
```

Once running, the functions will be hosted locally at:
* `ewumate_api`: `http://localhost:7071/api/{action}`
* `portal_sync_trigger`: `http://localhost:7071/api/scraper/portal_sync`
* `portal_sync_timer`: Monitored by the Functions runtime and executable on-demand via the admin endpoint:
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:7071/admin/functions/portal_sync_timer" -Method Post -Body "{}" -ContentType "application/json"
  ```

---

### 6.4 Cloud Deployment Protocol

Deployments are published directly to Microsoft Azure using Azure Functions Core Tools:

```powershell
# 1. Login to Azure CLI
az login

# 2. Set active Azure subscription (if multiple subscriptions exist)
az account set --subscription "<subscription-id-or-name>"

# 3. Publish to Function App (e.g. ewumate-parser or ewumate-api)
func azure functionapp publish <FUNCTION_APP_NAME> --python

# Example with build-native dependencies:
func azure functionapp publish ewumate-parser --build-native-deps
```

#### Deployment Verification
To verify deployment health and inspect live logs:
```powershell
# Stream live logs from Azure Application Insights / Log Stream
func azure functionapp logstream <FUNCTION_APP_NAME>

# Query Health-Check endpoint
Invoke-RestMethod -Uri "https://<FUNCTION_APP_NAME>.azurewebsites.net/api/scraper/portal_sync?semester=PING"
```

---

### 6.5 Monitoring, Diagnostics & Observability

1. **Application Insights Integration**:
   * All log calls (`logging.info`, `logging.warning`, `logging.error`, `logging.exception`) stream into Azure Application Insights.
   * Query failure traces in Application Insights via Kusto (KQL):
     ```kusto
     traces
     | where severityLevel >= 3
     | order by timestamp desc
     | project timestamp, message, customDimensions
     ```
2. **Supabase Scraper Audit Table (`scraper_logs`)**:
   * The scraper automatically writes every execution record to Supabase.
   * If a run encounters authentication failure or portal network error, `scraper_logs` records the failure with `status = 'error'` and the full error message in `report`.
3. **Portal UI / API Breakdown Recovery Playbook**:
   * **Symptom: Portal Login Fails (`401 Unauthorized`)**:
     1. Verify credentials in Supabase table `scraper_config`. Student password may have expired or was reset by the university.
     2. Run `python test_portal_api.py` locally to test arithmetic captcha response.
   * **Symptom: Missing Courses / Empty Sections**:
     1. University may have disabled `/GetAllOfferedCoursesBySemAndDept`.
     2. Run `python test_dept_resolution.py` to check if department IDs changed.
     3. Check fallback endpoint `/GetAllOfferedCourses?deptid=0`.
   * **Symptom: Stale Client Timetables**:
     1. Bump `catalog_cache_version` in `app_config` to force client refresh.
     2. Run `python harvest_class_schedule.py` to crowdsource latest faculty assignments from enrolled student routines.



---

## PART IV: React Admin Web Control Panel (`admin_panel/`)

## 1. Executive Summary & Purpose

The **EWUmate Admin Panel** is the operational nerve center and mission-control dashboard for the **EWUmate** private university ecosystem serving students of East West University (EWU), Dhaka, Bangladesh.

The administrative console empowers university system administrators, moderators, and software engineers to:
1. **Automate & Scrape Institutional Data:** Orchestrate and trigger headless Azure Function scrapers to extract semester course offerings, faculty initials, section seat capacities, and exam routines directly from the university portals.
2. **Curriculum & Academic Calendar Governance:** Manage multi-track term systems (standard tri-semester and bi-semester programs like Pharmacy and Law), exam schedules, grade submission deadlines, and advising windows.
3. **Crowd-Sourced Content Moderation:** Moderate student submissions for study materials (Study Vault), faculty office hour routine photos, crowd-sourced faculty assignment proofs, and student faculty evaluations.
4. **Push Notification Broadcasting:** Deploy global and departmental push notifications via Firebase Cloud Messaging (FCM), schedule future broadcast alerts, and monitor client-side local notification background alarms.
5. **Data Hygiene & Anomaly Audits:** Automatically run heuristic anomaly scans to detect orphan course sections, missing professors, section overlaps, unsynced student CGPAs, and onboarding drop-offs.
6. **Support & Financial Accountability:** Verify mobile financial transactions (bKash, Nagad, Rocket) contributed by students to sustain server operations and provide real-time support via two-way feedback threads.

```mermaid
flowchart TD
    subgraph Client Application Ecosystem
        MA[EWUmate Mobile App / Flutter]
        PWA[EWUmate PWA / Web Client]
    end

    subgraph Administrative Operations
        AP[EWUmate Admin Panel / React 19]
    end

    subgraph Cloud Infrastructure
        SB[(Supabase PostgreSQL 15)]
        EF[Supabase Deno Edge Functions]
        ST[Supabase Object Storage]
        AZ[Azure Functions Python Scraper Engine]
        GD[Google Drive Storage Pools]
    end

    AP -->|Authenticate via Admin Users Guard| SB
    AP -->|Direct High-Privilege Administration| SB
    AP -->|Invoke Secure Proxies with Admin JWT| EF
    EF -->|Trigger Scrape & Portal Sync| AZ
    EF -->|Dispatch Multi-Cast Push Notifications| MA
    AZ -->|Upsert Course Catalog & Timetables| SB
    MA -->|Upload Proofs & Submissions| SB
    MA -->|Store Large Documents & Routines| GD
    AP -->|Verify, Approve, or Reject Submissions| SB
    AP -->|Manage Cloud Bucket Documents| ST
```

---

## 2. Technology Stack & Core Dependencies

The Admin Panel is engineered with modern frontend practices:

| Category | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Runtime & Core** | React | `^19.2.4` | UI component library with concurrent features |
| **DOM Renderer** | React DOM | `^19.2.4` | Virtual DOM rendering engine |
| **Language** | TypeScript | `~5.9.3` | Type safety and schema definitions |
| **Bundler & Dev Server** | Vite | `^8.0.1` | Fast HMR dev server and production builder |
| **Styling Engine** | Tailwind CSS | `^4.2.2` | Utility-first CSS engine with dark mode |
| **Routing** | React Router DOM | `^7.13.2` | Client-side routing, route guards, URL search param synchronization |
| **Animation Engine** | Framer Motion | `^12.38.0` | Motion graphics, page transitions, collapsible accordions |
| **Data Visualization** | Recharts | `^3.8.1` | High-performance SVG charts (Area, Composed, Bar) |
| **Database & Auth** | Supabase JS | `^2.101.1` | PostgreSQL ORM client, Auth session, Storage API, Edge Functions |
| **Iconography** | Lucide React | `^1.7.0` | Comprehensive icon library |
| **PDF Generation** | jsPDF + jsPDF-AutoTable | `^2.5.1` / `^3.8.2` | Client-side academic PDF report and catalog compilation |
| **Feedback Toasts** | React Hot Toast | `^2.6.0` | Toast notification provider with custom dark styling |

---

## 3. Authentication, Security & Role-Based Access Control

### 3.1 Authentication Handshake
Authentication is managed via `src/components/AuthGuard.tsx` wrapping all operational routes:
1. **Supabase Auth Session:** `AuthGuard` queries `supabase.auth.getSession()` on initial mounting and establishes an active listener via `supabase.auth.onAuthStateChange`.
2. **Database Verification in `admin_users`:** Holding a valid Supabase Auth account is not enough. The authenticated user's `user.id` is queried against the restricted table:
   ```sql
   SELECT user_id, role FROM public.admin_users WHERE user_id = :userId;
   ```
3. **Escalation & Lockout:** If no record matches in `admin_users`, access is denied immediately, presenting an error screen with a sign-out trigger.
4. **Active Session Persistence:** Session tokens are stored in `window.localStorage` under the dedicated key `ewumate_admin_auth` to prevent collision with mobile or PWA auth tokens.

### 3.2 Dual-Client Privilege Model
Defined in `src/lib/supabase.ts`:
- **`supabase` (Standard Client):** Initialized using `VITE_SUPABASE_ANON_KEY`. Subject to Postgres Row Level Security (RLS) policies. Used for authentication handshakes and standard user operations.
- **`supabaseAdmin` (High-Privilege Service Client):** Initialized using `VITE_SUPABASE_SERVICE_ROLE_KEY`. Bypasses Row Level Security to allow administrative data manipulation, user profile auditing, and global catalog updates.
- **Session Forwarding to Edge Functions:**
  ```typescript
  Object.defineProperty(supabaseAdmin, 'functions', {
    value: supabase.functions,
    writable: true,
    configurable: true,
    enumerable: true
  });
  ```
  Edge functions receive the authenticated admin's session JWT, guaranteeing audit logging and caller authorization.

---

## 4. Supabase Client Architecture & Edge Function Handshake

### 4.1 Edge Functions Invoked by the Admin Panel
The Admin Panel invokes four serverless Deno Edge Functions hosted on Supabase:

1. **`azure-admin-proxy`:**
   - **Actions:**
     - `portal_sync`: Triggers Azure Functions scraper for a given semester with preview mode or production database sync.
     - `sync_api_courses`: Chunks scraped routines (400 records per batch) and upserts them into dynamic course tables.
     - `faculty_sync`: Scrapes the university website directory to harvest fresh professor profiles, emails, and office room assignments.
     - `parse_calendar`, `parse_faculty`, `parse_exam`, `parse_advising`: Triggers backend document parsers after PDF/EML uploads.
2. **`broadcast`:**
   - Handles multi-cast push notification dispatch via Firebase Cloud Messaging (FCM). Supports targeting by UUID, Department, Onboarding Status, App Version, or Global broadcast.
3. **`sync-academic-stats`:**
   - Accepts `{ user_id }` and recalculates total completed credits and cumulative grade point average (CGPA) directly from the `completed_courses` table.
4. **`admin-purge-user`:**
   - Executes a cascade deletion of a student account from Supabase Auth (`auth.users`) and cleans up corresponding relational tables.

---

## 5. Global UI Shell & Component Architecture

### 5.1 `src/components/Layout.tsx`
`Layout.tsx` wraps every authenticated screen:
- **Responsive Navigation Drawer:** Desktop fixed 72-column glassmorphic sidebar with auto-collapsing mobile drawer overlay.
- **Real-Time Badge Polling:** Executes a background poll every 20 seconds across 6 database queues:
  - `study_materials` (status: `pending`)
  - `faculty_office_hours` (status: `pending`)
  - `feedbacks` (status: `open` or `pending`)
  - `donations` (status: `pending`)
  - `faculty_assignment_submissions` (status: `PENDING`)
  - `faculty_reviews` (status: `pending`)
- **Consolidated Faculty Hub:** Accordion menu consolidating Faculty Directory, Office Hours, Faculty Proofs, and Student Reviews with an aggregated badge counter.
- **Theme Switcher:** Toggles light/dark modes with persistence in `localStorage` under key `theme`.
- **User Identity Badge:** Displays the administrator's name, initials avatar, and role ("System Architect" if verified in `admin_users`, otherwise "Staff Member").

### 5.2 Global Keyboard Shortcuts & Command Palette (`CommandPalette.tsx`)
- Triggered by <kbd>Ctrl</kbd> + <kbd>K</kbd> or <kbd>Cmd</kbd> + <kbd>K</kbd>.
- Searches across all administrative routes and performs live ILIKE searches against student names and student IDs in the `profiles` table.
- Accessible keyboard navigation (<kbd>↑</kbd>, <kbd>↓</kbd>, <kbd>Enter</kbd>, <kbd>Esc</kbd>).

---

## 6. Exhaustive Page-by-Page Architectural Breakdown

---

### 6.1 Dashboard (`Dashboard.tsx`)
- **File Path:** `src/pages/Dashboard.tsx`
- **Component Name:** `Dashboard`
- **Purpose:** Primary operational overview providing real-time platform metrics, active user counters, infrastructure diagnostic triggers, semester track status switches, and incoming registration activity.

#### UI & Interactive Elements
- **Search Bar:** Debounced input (300ms) executing queries against student names and IDs in `profiles`, showing direct profile shortcuts.
- **Top Metrics Cards:**
  - Total Registered Users (formatted with localized commas).
  - Active Users in the last 24 Hours (`activeUsers24h`).
  - Total Academic Programs.
  - Live Courses currently registered in active semester tables.
- **Growth Trend Chart (Recharts AreaChart):** Plots 14-day cumulative user registration history with gradient shading.
- **Activity Heatmap Chart (Recharts AreaChart):** Plots daily active users (DAU) across a rolling 7-day window.
- **System Infrastructure Diagnostics:**
  - "Run Diagnostics" button tests DB Edge Latency (`performance.now()` probe on `profiles`), Azure Function connectivity (`portal_sync` PING), and Push Broadcaster status (`broadcast` PING).
- **Feedback & Vault Pipeline Widgets:** Breakdown cards showing Pending, In Progress, Resolved, and Ignored feedback tickets, alongside Study Vault approval pipelines.
- **Semester Track Cards & Fast Toggles:** Displays Current and Upcoming semester codes with course/section counts. Features interactive toggle switches for Advising System (`is_advising_open`) and Next Semester Visibility (`is_next_semester_open`) with optimistic UI updates.
- **Live Student Activity Tables:** Lists recent student registrations and active user sessions (`app_open_count` and formatted timestamps).

#### Database Queries, Tables & RPCs
- `supabase.rpc('get_admin_dashboard_stats')`: Returns aggregated stats, vault counts, recent users, active users, semester track mappings, and registration trends.
- `supabase.from('active_semester').update(...)`: Persists advising and next-semester visibility toggles.
- `supabase.from('profiles').select(...)`: Powers header student search.

---

### 6.2 Academic Data (`AcademicData.tsx`)
- **File Path:** `src/pages/AcademicData.tsx`
- **Component Name:** `AcademicData`
- **Purpose:** Core institutional repository editor managing course catalog metadata, departmental scholarship policies, grading cutoffs, and semester track rules.

#### UI & Interactive Elements
- **Four-Quadrant Tab Bar:**
  1. `course_metadata`: Course code, course title, credit weighting, equivalent course code.
  2. `grade_scale`: Letter grades, grade points (4.0 scale), minimum score percentages, policy descriptions.
  3. `scholarship_policies`: Minimum annual credits, Merit CGPA range, Dean's List CGPA, Medha Scholarship CGPA per department.
  4. `active_semester`: Start and end dates for classes, advising, final exams, and grade submissions.
- **Instant Search Bar:** Filters rows across all visible columns in real-time.
- **Visual Track Editor Link:** Direct shortcut to `/active-semester`.
- **Inline CRUD Actions:**
  - "Add Record" button creates an editable row at the top of the table.
  - Row edit button (`Edit2`) switches cells into typed inputs (`text`, `number`, `date`, `checkbox`).
  - One-click status pill toggles for boolean flags (`is_advising_open`, `is_next_semester_open`).
  - Row delete button (`Trash2`) with confirmation modal.

#### Database Queries, Tables & RPCs
- `supabase.from('course_metadata')` (Primary Key: `code`, uppercase normalized).
- `supabase.from('grade_scale')` (Primary Key: `grade`, ordered by point descending).
- `supabase.from('scholarship_policies')` (Primary Key: `id`).
- `supabase.from('active_semester')` (Primary Key: `track`).

---

### 6.3 Active Semester (`ActiveSemester.tsx`)
- **File Path:** `src/pages/ActiveSemester.tsx`
- **Component Name:** `ActiveSemester`
- **Purpose:** High-level term switcher and feature gate controller for undergraduate tri-semester and pharmacy/law bi-semester tracks.

#### UI & Interactive Elements
- **Track Status Cards:** One card per track (e.g. `tri_semester`, `bi_semester`).
- **Term Code Inputs:** Editable inputs for `current_semester_code` (e.g. `spring2026`) and `next_semester_code` (e.g. `summer2026`). Values are automatically normalized (lowercase, spaces and hyphens removed) prior to database submission.
- **Feature Toggle Switches:**
  - Advising System: Green toggle setting `is_advising_open` to `OPEN` or `CLOSED`.
  - Next Semester Screen: Blue toggle setting `is_next_semester_open` to `VISIBLE` or `HIDDEN`.
- **Sync Configuration Button:** Commits the track state to the database with loading spinners.

#### Database Queries, Tables & RPCs
- `supabase.from('active_semester').select(...)`
- `supabase.from('active_semester').update({ current_semester_code, next_semester_code, is_advising_open, is_next_semester_open }).eq('track', track)`

---

### 6.4 Advanced Analytics (`Analytics.tsx`)
- **File Path:** `src/pages/Analytics.tsx`
- **Component Name:** `Analytics`
- **Purpose:** Deep ecosystem telemetry, retention cohort intelligence, DAU/MAU activity ratios, and multi-stage onboarding funnel conversion analytics.

#### UI & Interactive Elements
- **Time Window Filter Pills:** `1W` (7 days), `14D` (14 days), `1M` (30 days), `3M` (90 days), `6M` (180 days), and `1Y` (365 days).
- **Core KPI Cards:** Daily Active Users (DAU), Monthly Active Users (MAU - 30d rolling), Yearly Active Users (YAU - 365d rolling), Total Ecosystem Profiles with percentage growth rate.
- **Ecosystem Growth Engine (AreaChart):** Visualizes cumulative user adoption curve with total new students added in the timeframe.
- **Active Pulse & Heatmap (ComposedChart):** Co-plots Daily Active Users as vertical green bars and Monthly Active Users as an indigo area overlay. Bar thickness adjusts dynamically based on time window (2px for 1Y up to 16px for 1W).
- **Onboarding Conversion Funnel:**
  - Stage 1: Account Created (`totalUsers`).
  - Stage 2: Academic Setup (entered course history or planned semester).
  - Stage 3: Profile Completed (fully onboarded).
  - Progress bars rendered via Framer Motion with conversion efficiency percentages, churn rates, and drop-off analysis.

#### Database Queries, Tables & RPCs
- `supabase.rpc('get_admin_analytics_stats', { timeframe_days: days })`

---

### 6.5 Calendar Editor (`CalendarEditor.tsx`)
- **File Path:** `src/pages/CalendarEditor.tsx`
- **Component Name:** `CalendarEditor`
- **Purpose:** Academic calendar event scheduler directly targeting dynamic per-semester tables for standard and bi-semester tracks.

#### UI & Interactive Elements
- **Track Switcher Pills:** Toggles between `tri_semester` and `bi_semester`.
- **Dynamic Table Targeter:** Automatically resolves table names:
  - Tri-Semester: `calendar_{semester_code}` (e.g. `calendar_spring2026`).
  - Bi-Semester: `calendar_{semester_code}_phrm_llb`.
- **"Inject Event" Form Drawer:**
  - Date input (`event_date`).
  - Event title input (`title`).
  - Event classification selector (`Holiday`, `General`, `Exam`).
  - Target Track selector (`tri_semester`, `bi_semester`, or `both`). If `both` is selected, simultaneously inserts records into both calendar tables using `Promise.all`.
- **Calendar Event Table:** Shows formatted date (`weekday, month day, year`), event title, track target, classification badges (Holiday: rose, Exam: amber, General: indigo), and delete action.

#### Database Queries, Tables & RPCs
- `supabase.from('active_semester').select('*')`
- `supabase.from(tableName).select('*').order('event_date')`
- `supabase.from(tableName).insert([...])`
- `supabase.from(tableName).delete().eq('id', id)`

---

### 6.6 Course Catalog (`CoursesList.tsx`)
- **File Path:** `src/pages/CoursesList.tsx`
- **Component Name:** `CoursesList`
- **Purpose:** Comprehensive inspection table for all course sections offered across university departments for any semester.

#### UI & Interactive Elements
- **Semester Selector:** Dropdown populated from `semesters`, defaulting to the active term.
- **Instant Search Filter:** Real-time search against course codes and course names synchronized with URL query parameter `q`.
- **Catalog Table:**
  - Course Code (bold indigo).
  - Course Title & Information (with responsive mobile fallback displaying section and credit count).
  - Section number pill badge.
  - Credit weighting.
  - Faculty initials tag with lightning icon (or "TBA").
- **Pagination Controls:** Previous/Next page buttons (pageSize = 20) with URL query param `page` synchronization.

#### Database Queries, Tables & RPCs
- `supabase.from('semesters').select('*').order('created_at', { ascending: false })`
- `supabase.from('courses_' + selectedSemester).select('id, course_code, course_name, section_number, faculty_initials, credit_val', { count: 'exact' }).range(...)`

---

### 6.7 Data Integrity Guard (`DataQuality.tsx`)
- **File Path:** `src/pages/DataQuality.tsx`
- **Component Name:** `DataQuality`
- **Purpose:** Automated heuristic auditor detecting catalog anomalies, missing professors, section schedule overlaps, unsynced CGPAs, and onboarding drop-offs.

#### UI & Interactive Elements
- **Audit Type Selector Tabs:**
  1. `courses`: Catalog Integrity.
  2. `users`: Student Profile Integrity.
- **"Execute Audit" Trigger Button:** Runs client-assisted paginated scans across all records.
- **Catalog Integrity Metrics:** Total Sections, Unique Courses, Completeness Score %, Missing Faculty Initials, Duplicate Overlaps (`course_code` + `section_number`).
- **Student Profile Integrity Metrics:** Total Students, Complete Profiles %, Stage 1 Drop-offs, Stage 2 Drop-offs, Vitals Anomalies (Missing Department, Missing Program, Unsynced CGPA where earned credits > 0 but CGPA is 0.0).
- **Duplication Matrix Grid:** Highlights duplicate sections and indicates instance count (e.g. `2x`, `3x`).
- **Anomaly Audit Table:** Lists flagged courses or student profiles with anomaly badges. Clicking student profiles navigates directly to `/users/:id`.

#### Database Queries, Tables & RPCs
- `supabase.from('active_semester').select('current_semester_code').eq('track', 'tri_semester')`
- `supabase.from('courses_' + cleanSem).select('...').range(from, from + 999)`
- `supabase.from('profiles').select('id, full_name, student_id, program_code, department_name, onboarding_status, total_credits_earned, cgpa').range(...)`

---

### 6.8 Developer Support Contributions (`Donations.tsx`)
- **File Path:** `src/pages/Donations.tsx`
- **Component Name:** `Donations`
- **Purpose:** Verification and financial accounting dashboard for voluntary student donations (bKash / Nagad / Rocket) to sustain hosting and API costs.

#### UI & Interactive Elements
- **Monthly Summary Cards:** Aggregates approved contributions by calendar month, displaying total BDT collected and contribution count.
- **Search & Filter Controls:** Search by TrxID, sender phone number, student name, or ID; filter by status (`pending`, `approved`, `rejected`, `all`).
- **Collapsible Contribution Cards:**
  - Header: Status badge, payment method (bKash/Nagad), amount in BDT, transaction ID, student details.
  - Expanded Details: Verification controls (`Approve`, `Reject`, `Set Pending`), metadata grid, and screenshot receipt image preview with full-size viewer.
- **Automated Push Notifications:** Approving or rejecting a contribution automatically inserts a personalized push notification into the `notifications` table thanking the user or detailing verification rejection.

#### Database Queries, Tables & RPCs
- `supabase.from('donations').select('*, profiles(full_name, student_id, program_code)').order('created_at', { ascending: false })`
- `supabase.from('donations').update({ status, updated_at }).eq('id', id)`
- `supabase.from('notifications').insert([{ user_id, title, body, type: 'push_alert', ... }])`

---

### 6.9 Faculty Course Assignment Proofs (`FacultyAssignmentsModeration.tsx`)
- **File Path:** `src/pages/FacultyAssignmentsModeration.tsx`
- **Component Name:** `FacultyAssignmentsModeration`
- **Purpose:** Moderation queue for crowd-sourced faculty-to-course section mappings submitted by students along with portal screenshot proofs.

#### UI & Interactive Elements
- **Status Filter Tabs:** `PENDING`, `APPROVED`, `REJECTED`, `ALL`.
- **Submission Cards:**
  - Tag: `ENROLLED SUBMISSION` (student's own courses) or `BULK SUBMISSION` (bulk mapping of a specific professor).
  - Target assignments list: pills displaying `course_code Sec section_number → faculty_initial`.
  - "View Portal Proof Screenshot" button: opens a lightbox modal displaying the student's portal screenshot.
  - Rejection note input field.
  - Action buttons: "Approve & Update DB" and "Reject".
- **Database Synchronization:** Approving calls the database RPC `approve_faculty_assignment_submission`, which automatically writes the faculty initials into the active semester's course catalog table.

#### Database Queries, Tables & RPCs
- `supabase.from('faculty_assignment_submissions').select('*').order('created_at', { ascending: false })`
- `supabase.rpc('approve_faculty_assignment_submission', { submission_id: id, notes: '...' })`
- `supabase.from('faculty_assignment_submissions').update({ status: 'REJECTED', admin_notes }).eq('id', id)`

---

### 6.10 Faculty Master Directory (`FacultyMaster.tsx`)
- **File Path:** `src/pages/FacultyMaster.tsx`
- **Component Name:** `FacultyMaster`
- **Purpose:** Centralized directory of all university professors, designations, contact details, office room allocations, and Azure web-scraping synchronizer.

#### UI & Interactive Elements
- **Header Counters:** Total professor count and verified office room count.
- **"Update Faculty Master" Button:** Calls Edge Function `azure-admin-proxy` with action `faculty_sync`. Triggers an Azure scraper to crawl the university website directory and updates office rooms and emails.
- **New Faculty Detection Modal:** If the scrape identifies new faculty members not previously in the database, opens a modal detailing names, designations, departments, rooms, and photos for administrator review.
- **Search Bar:** Real-time filter across professor names, initials, and room numbers (e.g. `807`, `AIA`).
- **Faculty Profile Cards:** Photo/initials avatar, short name badge, office room pill badge, department, email, phone number, and designation.
- **Pagination Controls:** Navigates directory pages with pageSize = 100.

#### Database Queries, Tables & RPCs
- `supabase.from('faculty_master').select('*', { count: 'exact' }).range(...)`
- `supabase.functions.invoke('azure-admin-proxy', { body: { action: 'faculty_sync' } })`

---

### 6.11 Faculty Reviews Moderation & Scorecards (`FacultyReviewsModeration.tsx`)
- **File Path:** `src/pages/FacultyReviewsModeration.tsx`
- **Component Name:** `FacultyReviewsModeration`
- **Purpose:** Moderation queue for student-submitted faculty evaluations, toxicity reviews, and university-wide faculty scorecards with multi-dimensional rating metrics.

#### UI & Interactive Elements
- **Real-Time Subscription:** Listens to `postgres_changes` on `faculty_reviews`.
- **View Switcher:**
  1. **Moderation Queue:**
     - Status tabs (`pending`, `approved`, `rejected`, `all`) with counter badges.
     - Review cards with star ratings, course code, semester, delivery type (theory/lab), grade received, and student ID.
     - Multi-dimensional rating bars: Clarity, Grading Fairness, Exam Alignment, Office Hours Accessibility, Attendance Strictness (1.0 to 5.0 scale).
     - Teaching style trait pills (e.g. "Strict Attendance", "Helpful in Office Hours").
     - Workload, slide reliance, quiz frequency, and textbook need badges.
     - "Would Take Again" indicator.
     - Written comments and Exam Preparation Tips.
     - Actions: "Approve" (dispatches positive notification), "Reject" (opens modal for rejection note sent to student), "Delete" (permanently deletes).
  2. **Faculty Scorecards & Aggregate Intelligence:**
     - Overall university rating, total reviews, and would-take-again percentages.
     - Sorting: Highest Rated, Lowest Rated, Most Reviewed.
     - Search by professor initials, full name, or course code.
     - Course-by-course average rating breakdowns and top 5 recurring traits.
     - Detailed drilldown view listing all individual reviews for a selected professor.

#### Database Queries, Tables & RPCs
- `supabase.from('faculty_reviews').select('*, profiles:user_id(full_name, student_id)').order('created_at', { ascending: false })`
- `supabase.from('faculty_reviews').update({ status, admin_rejection_note, updated_at }).eq('id', review.id)`
- `supabase.from('faculty_reviews').delete().eq('id', review.id)`
- `supabase.from('notifications').insert([...])`

---

### 6.12 Feedback & Issue Inbox (`Feedbacks.tsx`)
- **File Path:** `src/pages/Feedbacks.tsx`
- **Component Name:** `Feedbacks`
- **Purpose:** Student customer support desk, issue tracking system, and two-way messaging portal.

#### UI & Interactive Elements
- **Status Filter Dropdown:** All Entries, Pending, In Progress, Resolved, Ignored.
- **Collapsible Ticket Cards:**
  - Header: Status badge, creation date, student name and ID, response message count.
  - Expanded View:
    - Status changer dropdown (updating status automatically dispatches a push notification to the student).
    - Original student feedback text.
    - Conversation Thread: Chronological timeline distinguishing Admin Responses (indigo, right-aligned) from Student Messages (slate, left-aligned).
    - Inline comment editor on blur (`updateComment`) and comment deletion button (`deleteComment`).
    - Interactive Reply Box (<kbd>Enter</kbd> to send): Posts comment with `is_admin: true` and sends a push notification to the student's device.

#### Database Queries, Tables & RPCs
- `supabase.from('feedbacks').select('*, profiles(full_name, student_id, program_code), comments:feedback_comments(*)').order('created_at', { ascending: false })`
- `supabase.from('feedbacks').update({ status, updated_at }).eq('id', id)`
- `supabase.from('feedback_comments').insert([{ feedback_id, comment, is_admin: true }])`
- `supabase.from('notifications').insert([...])`

---

### 6.13 Academic File Ingestion & Parsing (`FileParser.tsx`)
- **File Path:** `src/pages/FileParser.tsx`
- **Component Name:** `FileParser`
- **Purpose:** Academic document uploader and Azure OCR/Regex extraction pipeline for official university PDF and EML schedules.

#### UI & Interactive Elements
- **Track & Context Selectors:**
  - Academic Track: `tri_semester` (Standard) or `bi_semester` (Pharmacy/Law). For bi-semester files, appends `PHRM LLB` to the filename to guarantee proper Azure routing.
  - Target Semester Context: `current` or `next` (upcoming term).
  - Document Type: `exam` (Exam Schedule), `course` (Faculty List / Advising), `calendar` (Academic Calendar), `advising` (Faculty Advising Routine).
- **Auto-Generated Filename Input:** Formats standard names e.g. `Exam Schedule Spring 2026.pdf` or `Faculty Advising Summer 2026 PHRM LLB.eml`.
- **Drag-and-Drop File Uploader:** Accepts `.pdf` or `.eml` binaries up to 10MB.
- **Upload & Parse Trigger:**
  1. Uploads binary to Supabase Storage bucket `academic_documents` under `{folder}/{filename}`.
  2. Invokes Edge Function `azure-admin-proxy` with action: `parse_exam`, `parse_faculty`, `parse_calendar`, or `parse_advising`.
  3. Displays live status banner with parsed event and entry counts.
- **Academic Repository Storage Explorer:** Lists uploaded files across bucket folders (`facultylist`, `calendar`, `examschedule`, `advisingschedule`) with file size, creation date, and delete actions.

#### Database Queries, Tables & RPCs
- `supabase.storage.from('academic_documents').upload(...)`
- `supabase.storage.from('academic_documents').list(...)`
- `supabase.storage.from('academic_documents').remove(...)`
- `supabase.functions.invoke('azure-admin-proxy', { body: { action, payload: { file_path } } })`

---

### 6.14 Admin Login & Handshake (`Login.tsx`)
- **File Path:** `src/pages/Login.tsx`
- **Component Name:** `Login`
- **Purpose:** Administrative authentication entry point with email/password and Google OAuth providers.

#### UI & Interactive Elements
- **Visual Design:** Cyber/mission-control aesthetics with dark backdrop, radial glows, and pulsing Zap icon.
- **Session Auto-Redirect:** Automatically navigates to `/` if an active session exists.
- **Form Fields:** Email input (`commander@ewumate.com`) and password cipher input.
- **Google Identity SSO Button:** Initiates OAuth login via `supabase.auth.signInWithOAuth({ provider: 'google' })`.
- **Error Banner:** Displays security rejection reasons with a Shield icon.

#### Database Queries, Tables & RPCs
- `supabase.auth.getSession()`
- `supabase.auth.signInWithPassword({ email, password })`
- `supabase.auth.signInWithOAuth({ provider: 'google', ... })`

---

### 6.15 Push Broadcaster & Local Alarms Telemetry (`Notifications.tsx`)
- **File Path:** `src/pages/Notifications.tsx`
- **Component Name:** `Notifications`
- **Purpose:** Dual-engine notification management: Cloud Push Broadcaster (FCM) and Client-Side Local Notification Alarm Telemetry.

#### UI & Interactive Elements
- **Three Main Modes:**
  1. **Composer Mode (`composer`):**
     - Target Segment Tabs:
       - `global`: Broadcast to all registered devices.
       - `department`: Targets specific department (e.g. CSE, BBA, EEE, Pharmacy).
       - `user`: Targets individual student by UUID.
       - `status`: Targets onboarding status (`registered`, `course_history`, `completed`).
       - `version`: Targets installed app versions (e.g. `1.1.18+48`).
     - Scheduling: Optional date-time picker for future UTC/BDT release.
     - Action URL: Optional deep link or web URL opened on tap.
     - Live Mobile Preview: Renders an interactive Android/iOS notification drawer card.
     - Notification Templates: Save and load templates from `localStorage`.
     - Dispatch Action: Invokes `broadcast` Edge Function.
     - Broadcast History: Shows sent push batches grouped by alert key with success/failure counters.
  2. **Local Alarms Telemetry Mode (`local_stats`):**
     - Sub-tab `telemetry`: Displays device alarm schedulers from `local_notification_states` (checksums, active alarm keys, last scheduled timestamp, device time, app version, OS version). Expandable drawer displays all active alarm keys on the physical device.
     - Sub-tab `live_logs`: Detailed dispatch logs from `local_notification_logs` (`scheduled`, `delivered`, `failed`) with filter pills and search bar.
  3. **System Health Mode (`system_health`):**
     - System overview cards: Total Cloud Notifications, Dispatched, Pending, Registered FCM Tokens, Active Local Devices, Total Scheduled Alarms, and Platform Distribution (Android, iOS, Web).

#### Database Queries, Tables & RPCs
- `supabase.functions.invoke('broadcast', { body: payload })`
- `supabase.from('notifications').select('*').limit(5000)`
- `supabase.from('local_notification_states').select('*, profiles(...)')`
- `supabase.from('local_notification_logs').select('*, profiles(...)')`
- `supabase.from('fcm_tokens').select('*', { count: 'exact', head: true })`

---

### 6.16 Faculty Office Hours Moderation (`OfficeHoursModeration.tsx`)
- **File Path:** `src/pages/OfficeHoursModeration.tsx`
- **Component Name:** `OfficeHoursModeration`
- **Purpose:** Moderation queue for student-submitted faculty weekly consultation hours with attached routine photo proofs.

#### UI & Interactive Elements
- **Status Filter Tabs:** `pending`, `approved`, `rejected` with live counter badges.
- **Search Bar:** Filters by professor initials, file name, day of week, student name, or ID.
- **Storage Pools Drawer:** Displays linked Google Drive storage pools (`purpose === 'office_hours'`), capacity, and usage.
- **Batch Grouping:** Automatically groups individual consultation time slots that share the same uploaded routine image (`drive_file_id`).
- **Routine Image Lightbox:** Modal preview for inspecting uploaded routine images.
- **Office Room Cascade:** Approving an office hour with an `office_room` value automatically updates `office_room` in `faculty_master` where `short_name = faculty_initials`.
- **Batch Actions:** "Approve Batch" and "Reject Batch" approve/reject all slots in a single click and send a consolidated notification to the submitting student.

#### Database Queries, Tables & RPCs
- `supabase.from('faculty_office_hours').select('*, profiles:submitted_by(full_name, student_id)')`
- `supabase.from('faculty_office_hours').update({ status, updated_at }).eq('id', id)`
- `supabase.from('faculty_master').update({ office_room }).ilike('short_name', initials)`
- `supabase.from('notifications').insert([...])`

---

### 6.17 Portal Automation & Live Scraper (`PortalAutomation.tsx`)
- **File Path:** `src/pages/PortalAutomation.tsx`
- **Component Name:** `PortalAutomation`
- **Purpose:** Extraction console interacting with Azure Functions scrapers to harvest class routines, section capacities, and schedules from the university portal.

#### UI & Interactive Elements
- **Configuration Bar:** Displays scraper credentials loaded from `scraper_config`.
- **Semester Selector:** Dropdown populated from `semesters`.
- **Azure Core Health Indicator:** Live status badge (`live`, `checking`, `down`).
- **"Start Scraping" Action:** Calls `azure-admin-proxy` with `{ action: 'portal_sync', semester, preview: true }`. Returns extracted courses in preview mode.
- **Interactive Scraped Data Table:** Inspect extracted courses, sections, titles, faculty, seat capacities, and weekly meeting times (day, time, room, type) with client-side search.
- **"Push to Supabase (Sync DB)" Action:** Chunks extracted courses into batches of 400 (`BATCH_SIZE = 400`) and calls `sync_api_courses` via Azure proxy. Generates an academic PDF and uploads it to storage.
- **Live Terminal Console:** Log window displaying timestamps, batch progress, and error traces.
- **Sync History Log:** Records past syncs (`scraper_logs`) with added/updated/deleted counts and a "Reconstruct PDF" button (`jspdf` + `jspdf-autotable`).

#### Database Queries, Tables & RPCs
- `supabase.from('scraper_config').select('*').single()`
- `supabase.from('semesters').select('title')`
- `supabase.from('scraper_logs').select('*')`
- `supabase.functions.invoke('azure-admin-proxy', { body: { action: 'portal_sync' | 'sync_api_courses', ... } })`

---

### 6.18 App Config & Version CMS (`Settings.tsx`)
- **File Path:** `src/pages/Settings.tsx`
- **Component Name:** `Settings`
- **Purpose:** Global CMS, remote feature flags, mobile AdMob monetization controls, version enforcement, promo banner CMS, and cache invalidation.

#### UI & Interactive Elements
- **"Flush All Users' Cache" Button:** Updates `catalog_cache_version` with `Date.now()`, forcing all active mobile apps to purge cached course catalogs and re-fetch fresh data.
- **Active Version Settings:**
  - Target Live Version input (e.g. `1.1.18+48`).
  - Update Download URL (Play Store / APK link).
  - "Show Update Prompt to Users" toggle switch (`update_available`).
- **AdMob Monetization Controls:**
  - Master Switch: Enables/disables all mobile advertisements across the app.
  - Format Toggles: Banner Ads, Native Ads, Interstitial Ads.
  - Screen Placement Toggles: Pre-Advising Interstitials, Cover Page Interstitials, Semester Progress Banners, Degree Progress Native, Course Browser Native, Faculty Directory Native, Services Tab Native, Study Vault Native, Tasks Manager Native.
- **Promo Banner CMS (Dashboard Top):**
  - Show Banner toggle (`is_active`).
  - Image/GIF URL (with recommended 800x120px ratio).
  - Tap Destination URL (deep link or web link).
  - Live preview box with error fallback.
- **Donation Popup CMS:**
  - Toggle for daily server donation prompt (`donation_popup.is_active`).
- **Detected App Versions & User Adoption:**
  - Groups students by `profiles.app_version` with percentage progress bars.
  - Expandable student list showing names and student IDs on each version.

#### Database Queries, Tables & RPCs
- `supabase.from('app_config').select('*')`
- `supabase.from('app_config').update({ value }).eq('key', ...)`
- `supabase.from('app_config').insert([{ key, value }])`
- `supabase.from('profiles').select('app_version, full_name, student_id')`

---

### 6.19 Study Vault Moderation & Storage Pools (`StudyVaultManager.tsx`)
- **File Path:** `src/pages/StudyVaultManager.tsx`
- **Component Name:** `StudyVaultManager`
- **Purpose:** Academic resource repository moderator, Google Drive service account pool manager, and bulk approval engine.

#### UI & Interactive Elements
- **Real-Time Subscription:** Listens to `postgres_changes` on `study_materials`.
- **12 Document Classifications:** Term Paper, Mid Questions, Final Question, Quiz Questions, Course Outline, Slide, Sample Code, Book, Lab Manual, Lab Report, Project Report, Other.
- **Bulk Selection System:** Checkbox selection with "Select All Visible" for batch approvals and rejections.
- **Consolidated Batch Notifications:** When approving or rejecting multiple materials, groups them by submitting student and sends a single consolidated notification.
- **Storage Pools Drawer:** Lists Google Drive accounts from `drive_accounts` (`purpose === 'study_vault'`) with capacity, used bytes, and active toggles.
- **Document Classification Editor:** Dropdown for re-categorizing a document's `file_type` on the fly.
- **Google Drive Preview Lightbox:** Embedded iframe preview (`drive.google.com/file/d/${drive_file_id}/preview`) with direct external link.
- **Filters:** Status pills (Pending, Approved, Rejected, Removal Requested), Semester dropdown, File Type dropdown, and search bar.

#### Database Queries, Tables & RPCs
- `supabase.from('study_materials').select('*, profiles:uploader_id(full_name, student_id)')`
- `supabase.from('study_materials').update({ status, updated_at }).in('id', ids)`
- `supabase.from('drive_accounts').select('*')`
- `supabase.from('drive_accounts').update({ is_active }).eq('id', accountId)`
- `supabase.from('notifications').insert([...])`

---

### 6.20 Video Tutorials Manager (`TutorialsManager.tsx`)
- **File Path:** `src/pages/TutorialsManager.tsx`
- **Component Name:** `TutorialsManager`
- **Purpose:** Video guide and walkthrough manager controlling YouTube embeds displayed in the mobile client.

#### UI & Interactive Elements
- **YouTube Video ID Extractor:** Parses `youtu.be`, `watch?v=`, and `/embed/` links.
- **Automatic Thumbnail Generation:** Generates thumbnails via YouTube CDN (`img.youtube.com/vi/${id}/hqdefault.jpg`) with custom override support.
- **7 Video Categories:** Getting Started, Features, Study Vault, Faculty, Advising, Schedule, General.
- **Add/Edit Modal:** Title, description, YouTube URL, category selector, thumbnail URL, Featured toggle, and Active toggle.
- **Display Order Rearrangement:** Up/Down chevron buttons that swap `display_order` between adjacent rows in Supabase.
- **Featured Video Star Toggle:** Highlights video as primary featured tutorial in the mobile app.
- **Active/Hidden Eye Toggle:** Instantly shows or hides video in the mobile feed.

#### Database Queries, Tables & RPCs
- `supabase.from('tutorials').select('*').order('display_order', { ascending: true })`
- `supabase.from('tutorials').insert(...)`
- `supabase.from('tutorials').update(...).eq('id', id)`
- `supabase.from('tutorials').delete().eq('id', id)`

---

### 6.21 Student Profile Inspector & Audit Engine (`UserDetails.tsx`)
- **File Path:** `src/pages/UserDetails.tsx`
- **Component Name:** `UserDetails`
- **Purpose:** 360-degree student profile inspector, academic audit engine, and account administration interface.

#### UI & Interactive Elements
- **Profile Header & Quick Actions:**
  - Student avatar, name, student ID, program, department, and CGPA badge.
  - "Recalculate Stats" button: Calls Edge Function `sync-academic-stats` to recompute CGPA and earned credits.
  - "Edit Profile" button: Opens modal to edit name, student ID, program, department, CGPA, credits, track, and onboarding status.
  - "Send Notification" button: Opens modal to dispatch a custom push notification directly to this user.
  - "Purge Account" button: Calls Edge Function `admin-purge-user` after two-step text confirmation dialog (`DELETE ${user.full_name}`).
- **Seven Inspection Tabs:**
  1. `overview`: Key vitals, CGPA, completed credits, degree progress percentage.
  2. `courses`: Course history table with letter grades and credits; inline "Add Course" modal and row deletion with automatic recalculation.
  3. `enrollments`: Enrolled courses for current and upcoming terms with sections, faculty, meeting days, and rooms.
  4. `routine`: Visual weekly timetable rendering Monday-Sunday periods.
  5. `marks`: Midterm and final exam marks with grade distributions.
  6. `telemetry`: Device-level alarm scheduler states, device IDs, platforms, and active alarm keys.
  7. `notifications`: Push notification delivery logs for this student.

#### Database Queries, Tables & RPCs
- `supabase.from('profiles').select('*').eq('id', userId).single()`
- `supabase.from('completed_courses').select('*').eq('user_id', userId)`
- `supabase.from('enrollments').select('*').eq('user_id', userId)`
- `supabase.from('user_semester_states').select('*').eq('user_id', userId)`
- `supabase.from('tasks').select('*').eq('user_id', userId)`
- `supabase.from('semester_course_marks').select('*').eq('user_id', userId)`
- `supabase.from('local_notification_states').select('*').eq('user_id', userId)`
- `supabase.from('notifications').select('*').eq('user_id', userId)`
- `supabase.functions.invoke('sync-academic-stats', { body: { user_id } })`
- `supabase.functions.invoke('admin-purge-user', { body: { targetUserId } })`

---

### 6.22 Student Directory & Data Exporter (`UsersList.tsx`)
- **File Path:** `src/pages/UsersList.tsx`
- **Component Name:** `UsersList`
- **Purpose:** Paginated, searchable, multi-filter student directory and bulk CSV data exporter.

#### UI & Interactive Elements
- **Search & Multi-Filter Bar:**
  - Search input: Student name or student ID (synced to query param `q`).
  - Department dropdown: Filters programs by department (param `dept`).
  - Program dropdown: Filters by `program_code` (e.g. `CSE`, `BBA`) (param `prog`).
  - Admission batch dropdown: Filters by `admitted_semester` (param `sem`).
  - "Reset Intelligent Filters" button.
- **Bulk CSV Data Exporter:**
  - "Export Intelligence" button queries profiles in batches of 1000 from Supabase, compiles CSV rows, and triggers a browser download (`ewumate_export_{date}.csv`).
- **Student Directory Table:**
  - Student identity, avatar initials, student ID, program code.
  - Department name.
  - CGPA pill badge (green for >= 3.5, indigo for >= 3.0, amber for < 3.0).
  - Earned credits count.
  - Onboarding status badge (`completed`, `course_history`, `registered`).
  - Joined date and time.
  - Clicking any row navigates to `/users/:id`.
- **Pagination Controls:** Previous/Next buttons (pageSize = 20) with URL param `page` synchronization.

#### Database Queries, Tables & RPCs
- `supabase.from('programs').select('program_code, name, department_name')`
- `supabase.from('semesters').select('code, title')`
- `supabase.from('profiles').select('*', { count: 'exact' }).range(...)`

---

## 7. Shared UI Components & Modals

### 7.1 `src/components/ThemeContext.tsx`
- Provides application-wide light/dark theme management.
- Persists user preference in `localStorage` under key `theme`.
- Synchronizes the `.dark` class on the root HTML document element.
- Auto-detects operating system color scheme via `window.matchMedia('(prefers-color-scheme: dark)')`.

### 7.2 `src/components/Skeleton.tsx`
- Lightweight loading state placeholders utilizing Tailwind's `animate-pulse`:
  - `Skeleton`: Generic responsive pulse block.
  - `CardSkeleton`: Card header, avatar, and two pulse lines.
  - `TableSkeleton`: Structured table header and alternating row skeletons.

### 7.3 `src/components/ConfirmProvider.tsx` & `ConfirmModal.tsx`
- Global asynchronous confirmation dialog provider (`useConfirm()` hook).
- Replaces standard browser `window.confirm()` with styled modals supporting destructive/confirm actions.

---

## 8. Data Models, Type Definitions & Schemas

Defined centrally in `src/types.ts`:

```typescript
export interface Profile {
  id: string;
  full_name: string | null;
  nickname: string | null;
  student_id: string | null;
  program_code: string | null;
  program_name: string | null;
  department_name: string | null;
  track: string | null;
  cgpa: number | null;
  total_credits_earned: number | null;
  total_courses_completed: number | null;
  credits_completed: number | null;
  enrolled_sections: string[] | null;
  enrolled_sections_next: string[] | null;
  enrolled_credits: number | null;
  enrolled_credits_next: number | null;
  onboarding_status: string | null;
  last_active_at: string | null;
  app_open_count: number | null;
  reminder_settings?: Record<string, number[]> | null;
  created_at: string;
  updated_at: string | null;
}

export interface Faculty {
  id: string;
  short_name: string;
  full_name: string | null;
  designation_name: string | null;
  email: string | null;
  photo_url: string | null;
  phone: string | null;
  office_room?: string | null;
  department_name?: string | null;
  created_at: string;
  updated_at: string;
}

export interface CourseSection {
  id: string;
  course_code: string;
  course_name: string | null;
  section_number: number | null;
  faculty_initials: string | null;
  credit_val: number | null;
  schedule_data?: ScheduleSession[] | null;
}

export interface ScheduleSession {
  day: string;
  startTime: string;
  endTime: string;
  room: string;
  type: string;
  faculty: string;
}

export interface FacultyOfficeHour {
  id: string;
  faculty_initials: string;
  day: string;
  start_time: string;
  end_time: string;
  drive_account_id: string | null;
  drive_file_id: string;
  file_name: string;
  submitted_by: string | null;
  status: 'pending' | 'approved' | 'rejected';
  semester_code: string;
  office_room: string | null;
  created_at: string;
  updated_at: string | null;
}

export interface FacultyReview {
  id: string;
  faculty_initials: string;
  faculty_name: string | null;
  user_id: string;
  course_code: string;
  semester: string;
  semester_code?: string | null;
  grade_received?: string | null;
  delivery_type: string;
  clarity_rating: number;
  grading_fairness: number;
  exam_alignment: number;
  office_hours_accessibility: number;
  attendance_strictness: number;
  workload_level: string;
  slide_reliance: string;
  quiz_frequency: string;
  textbook_need: string;
  would_take_again: boolean;
  traits: string[];
  exam_prep_tips?: string | null;
  review_note?: string | null;
  status: 'pending' | 'approved' | 'rejected';
  admin_rejection_note?: string | null;
  created_at: string;
  updated_at: string;
}

export interface LocalNotificationState {
  id: string;
  user_id: string;
  device_id: string;
  platform: string;
  semester_code: string | null;
  checksum: string | null;
  scheduled_count: number;
  active_keys: string[];
  last_scheduled_at: string;
  status: string;
  metadata?: {
    next_alert_time?: string;
    device_time?: string;
    app_version?: string;
    os_version?: string;
  };
  updated_at: string;
}

export interface LocalNotificationLog {
  id: string;
  user_id: string;
  device_id: string;
  platform: string;
  alert_key: string;
  title: string | null;
  body: string | null;
  trigger_at: string | null;
  status: 'scheduled' | 'delivered' | 'failed';
  error_message: string | null;
  dispatched_at: string | null;
  created_at: string;
  updated_at: string;
}
```

---

## 9. Local Setup, Environment Variables & Deployment

### 9.1 Prerequisites
- **Node.js:** `v20.0.0` or later.
- **Package Manager:** `npm` (v10+).

### 9.2 Environment Configuration
Create a `.env` file in the root of `admin_panel`:

```env
# Supabase Project Credentials
VITE_SUPABASE_URL=https://<your-project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-public-key>

# High-Privilege Service Role Key (Required for Admin DB operations and RLS bypass)
VITE_SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

> **Security Note:** The `VITE_SUPABASE_SERVICE_ROLE_KEY` bypasses PostgreSQL Row Level Security. Ensure this application is deployed strictly on authenticated internal networks or protected behind VPN/SSO and role-based route guards.

### 9.3 Package Scripts
```bash
# Install dependencies
npm install

# Start development server (runs with Vite HMR at http://localhost:5173)
npm run dev

# Run TypeScript compilation and build production assets
npm run build

# Preview production build locally
npm run preview

# Run ESLint linter
npm run lint
```

### 9.4 Production Deployment
- **Static Hosting:** The build output (`dist/`) can be deployed to Vercel, Netlify, Cloudflare Pages, or Azure Static Web Apps.
- **Single Page Application Routing:** Configure routing fallbacks so that all paths redirect to `index.html` (e.g. `/* -> /index.html 200` in `_redirects` or `vercel.json`).

---

*Authored by Antigravity Technical Architecture Team for the EWUmate Platform Ecosystem.*



---

## PART V: Ecosystem Infrastructure & Operational Standards

### 1. Progressive Web App Standalone Notice (`ewumate_pwa/`)
The **EWUmate Progressive Web App (PWA)** is intentionally decoupled and maintained in its own dedicated project repository folder:
`ewumate_pwa/`

**Key Rationale for Keeping PWA Standalone:**
- **Zero App-Store Friction for iOS Users:** East West University students on iPhones and iPads install EWUmate via Safari's "Add to Home Screen" (`apple-mobile-web-app-capable`).
- **Gated Environment:** The PWA features an exclusive device gate (`ios_only_gate_screen.dart`) that diverts Android visitors to the native Google Play Store build (`com.rxxeron.ewumate`) while allowing seamless iOS access.
- **Web-Optimized Engine:** Utilizes Flutter 3.27+ Web with CanvasKit/Wasm, Web Push VAPID Service Workers (`web/firebase-messaging-sw.js`), and IndexedDB browser storage rather than Android native SQLite/FCM alarms.
- **Dedicated Documentation:** For the complete 1,000+ line technical manual detailing all 42 PWA screens and web manifest configuration, refer directly to:
  👉 **[`ewumate_pwa/README.md`](file:///f:/EWUmate/EWUmate_Clean/ewumate_v2/ewumate_pwa/README.md)**

---

### 20. Maintenance & Automation Scripts (`scripts/`)

The `scripts/` directory contains tools for database administration and automation:

- **`scripts/check_rls_live.py`**: Audits all live database tables to guarantee Row Level Security is active and policies are enforced.
- **`scripts/check_db_schema.py`**: Compares the production PostgreSQL schema against `docs/knowledge/DATABASE_SCHEMA.md`.
- **`scripts/extract_live_schema.py`**: Extracts the live Supabase schema and exports to `docs/knowledge/live_schema_dump.json`.
- **`scripts/run_cleanup.py`**: Cleans up dangling sessions and orphaned test records.
- **`scripts/sync_faculty_directory.py`**: Scrapes and updates the faculty directory catalog.
- **`scripts/parse_bulletin.py`**: Extracts course definitions, credit weights, and prerequisites from the official EWU Academic Bulletin PDF.
- **`scripts/populate_course_metadata.py`**: Populates the `course_metadata` table with degree curriculum mappings.

---


### 21. Firebase Cloud Messaging & Push Alerts

- **Android Notification Channel**: `ewumate_high_priority_v4` (Importance: High / Urgent).
- **Custom Sound**: Bound to `notification_sound.wav` bundled in Android raw resources.
- **Vibration Pattern**: `[0, 1000, 300, 1000]`.
- **Background Handler**: Registered with `@pragma('vm:entry-point')` in `lib/main.dart` to handle incoming pushes when the app is killed.
- **Token Registration**: Device FCM tokens are synchronized to `fcm_tokens` on authentication.

---


### 22. Native Android Integration (Jetpack Glance, Permissions)

- **Home Screen Routine Widget**: Implemented in native Kotlin via Jetpack Glance (`ScheduleWidgetProvider.kt`), rendering today's classes directly onto the user's home screen launcher.
- **Deep Linking**: Intent filters configured for `ewumate://login-callback`.
- **Android Manifest Permissions**:
  - `android.permission.POST_NOTIFICATIONS`: Push alerts.
  - `android.permission.VIBRATE`: Custom notification vibration patterns.
  - `android.permission.WAKE_LOCK`: Background routine alarms.
  - *Privacy Policy*: `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO` are completely removed; modern Android photo pickers are used instead.
- **Compilation Targets**: Compile SDK 36, Target SDK 34, Min SDK 21, Java 17 desugaring enabled in `android/app/build.gradle`.

---


### 25. Offline-First Architecture & Zero-Wait Entry Engine

- **Zero-Wait Entry**: Reads `profile_box` and `routine_box` synchronously on startup. The app renders immediately without displaying blocking spinners.
- **Optimistic UI Updates**: Marking a task as done updates local Hive storage instantly and appends the operation to the offline mutation queue.
- **Auto-Reconnection Sync**: `SyncService` listens to network connectivity changes via `connectivityProvider`, draining pending requests to Supabase upon reconnection.
- **Hive Storage Boxes**: `auth_box`, `academic_box`, `routine_box`, `metadata_box`, `profile_box`, `dashboard_box`, `schedule_box`, `sync_queue_box`, `semester_progress_box`, `notifications_box`, `course_catalog`, `faculty`.

---


### 26. Security Architecture & Privacy Safeguards

- **Zero Client Secrets**: Client bundles contain NO service role keys or database credentials.
- **JWT Verification**: Azure Function microservices enforce JWT verification and confirm that `body.user_id == jwt.sub`.
- **Database RLS**: Every table in Supabase PostgreSQL enforces strict Row Level Security.
- **`FLAG_SECURE` Privacy**: Automatically applied on sensitive screens (Advising, Results) to block screenshots and screen recording.
- **Admin Defense**: The React admin panel communicates exclusively through secure proxy edge functions (`azure-admin-proxy`).

---


### 27. Build Automation, CI/CD & Deployment Guide

### 27.1 Automated Android Build Pipeline (`.github/workflows/build-android.yml`)
Triggered via `workflow_dispatch` on GitHub:
1. Configures JDK 17 using `actions/setup-java@v4`.
2. Configures Flutter stable using `subosito/flutter-action@v2`.
3. Extracts app version from `pubspec.yaml` (e.g. `1.1.16+46`).
4. Injects production secrets from GitHub Repository Secrets (`ENV_FILE`, `KEYSTORE_BASE64`, `KEY_PROPERTIES_BASE64`).
5. Executes release builds:
   ```bash
   flutter build apk --release --no-tree-shake-icons
   flutter build appbundle --release
   ```
6. Uploads release APK and AAB as downloadable workflow artifacts.

### 27.2 Local Windows Build Script (`build_production_apk.bat`)
```bat
@echo off
echo Compiling EWUmate Production APK...
flutter build apk --release --no-tree-shake-icons
echo Build Complete! Output at: build\app\outputs\flutter-apk\app-release.apk
pause
```

### 27.3 Admin Panel Deployment (`.github/workflows/deploy-admin.yml`)
Triggered on push to `main`, `production`, or `testing` when files inside `admin_panel/**` change:
1. Configures Node.js 24 with npm caching.
2. Runs `npm install` and `npm run build` in `admin_panel/`.
3. Deploys static build artifacts to GitHub Pages via `actions/deploy-pages@v4`.

---


### 28. Monitoring, Telemetry & Rollback Procedures

### Telemetry
- **Crash Reporting**: Firebase Crashlytics and Firebase Core (`firebase_options.dart`).
- **Backend Monitoring**: Azure Application Insights tracks function latency, execution counts, and failure rates.
- **Database Health**: Monitored via the Supabase Cloud Management Console (Logs Explorer, Edge Function metrics).

### Rollback Procedures
- **Mobile Client (Google Play)**: Halt staged rollouts in Google Play Console or roll back to the previously published APK/AAB version code.
- **Direct APK Distribution**: Publish prior stable APK release and trigger an in-app update banner via `AppUpdateService`.
- **Admin Panel**: Revert to previous Git commit on `main` branch to trigger immediate GitHub Pages redeployment.
- **Azure Functions**: Roll back deployment slots via Azure CLI (`func azure functionapp publish`).

---


### 30. Troubleshooting & Common Pitfalls

- **JDK Incompatibility**: Gradle fails with `Unsupported class file major version`. Ensure `JAVA_HOME` points strictly to JDK 17.
- **Missing `.env` File**: Logs display `[SupabaseConfig] .env load notice`. Ensure `.env` is created at the root of `ewumate_production_build/`.
- **Hive Schema Mismatch**: Clear app storage if models change without a corresponding Hive adapter migration during development.
- **Azure Functions Cold Starts**: Ensure client requests implement exponential backoff retry logic to handle initial cold start latency.
- **Google Sign-In SHA-1 Mismatch**: Verify that your debug and release keystore SHA-1 fingerprints are registered in Google Cloud Console.

---


### 31. Contributing & Code Sync Protocol

To maintain consistency across app channels, adhere to the **Code Sync Protocol**:

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
2. Implement and test changes inside `ewumate_production_build`.
3. Verify static analysis and tests pass:
   ```bash
   flutter analyze
   flutter test
   ```
4. Submit a Pull Request.
5. Upon approval and merge to `main`, cherry-pick applicable commits to the `ewumate_v2` and `ewumate_pwa` branches.

---


### 32. License & Credits

**Proprietary Software.** © 2026 East West University / Rxxeron. All Rights Reserved.  
Architected, Designed, and Maintained by the **EWUmate Core Engineering Team**.

For administrative inquiries, technical escalations, or security reports, please contact the development team through the in-app developer feedback portal.

