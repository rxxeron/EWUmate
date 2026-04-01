# EWUmate V2 - Project Handover Plan

## 1. Project Overview & Architecture
**EWUmate V2** is a Flutter-based mobile application designed for students of East West University (EWU) to track their academic progress, schedules, semesters, tasks, and advising.

- **Frontend:** Flutter (Dart) using Riverpod for State Management and GoRouter for Navigation.
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions) for real-time remote syncing and authentication.

## 2. Directory Structure Context
- lib/core/
  - config/: Contains .env variables and supabase_config.dart.
  - models/: Models for generic data.
  - epositories/: Direct Supabase Database interaction layers.
  - outer/: GoRouter implementation (pp_router.dart).
  - widgets/: Reusable UI like MainShell (Bottom Nav layout) and AppDrawer (Sidebar).
- lib/features/
  - Feature-sliced architecture: Every feature has its own folder containing a presentation (UI) and epository (Data) file.
  - Core Features: uth, dashboard, 	asks, semester_progress, progress (Degree tracker), schedule, dvising, course_browser.

## 3. Currently Completed Modules (Stable State)
1. **Routing & Shell:** 
   - GoRouter fully mapped.
   - Fixed missing screens accessed by the Drawer. pp_router.dart is the single source of truth for routing.
2. **Tasks Manager:**
   - Full CRUD. Handled in 	asks_screen.dart and 	ask_repository.dart.
   - Bug fixed where Riverpod needs ef.invalidate() to hot-reload state asynchronously after DB mutations.
3. **Semester Progress (Marks Calculator):**
   - 2x2 Grid dashboard successfully extracting obtained marks.
   - Comprehensive Details view allowing calculation configurations (Sum Top N, Avg of all, Sum of all, etc.)
   - Dynamic Quiz arrays via JSONB and List representations.
   - Database has customized columns: obt_project, dist_project, dist_presentation, dist_viva, etc. mapped.
   
## 4. Current Bug / Next Immediate Focus
### The Dashboard "Schedule Card" Issue
**Symptom:** The Dashboard loads but says "Nothing Found / No classes scheduled for this day" even if the student is supposedly enrolled.
**Suspected Cause Pathway:**
1. Dashboard logic relies on the database table user_semester_states specifically the weekly_grid_cache JSON column.
2. The logic (lib/features/dashboard/dashboard_logic.dart) tries to match today's 'Day' (e.g. "Tuesday") against that cached grid.
3. The cache appears to be empty, not generated, or structured differently than what _buildScheduleSection expects to iterate over.

**Required Action for Next Agent:**
1. Investigate the Supabase enrollments table vs user_semester_states.
2. Check if a backend Edge Function (sync-schedule) is failing to populate the weekly_grid_cache.
3. Check dashboard_logic.dart inside processDashboardData and dashboard_repository.dart to debug exactly why schedule: [] is always returning empty. 
   - Look specifically around weeklyGrid[stdDay] vs weeklyGrid[phrmDay].

## 5. Instructions for the Next AI Agent
1. **DO NOT** rewrite any of the Semester Progress mark calculations unless specifically instructed (it represents a delicate, working state).
2. **DO NOT** modify Riverpod State Providers randomly. If you alter the database via a repository, remember to call ef.invalidate() on the related Stream/Future provider in Riverpod to refresh the Flutter UI seamlessly.
3. When debugging the DB, use inline Python scripts via terminal (psycopg2) connected to the Supabase URL, as this has been highly effective in checking schema data limits safely. The .env variables have the direct DB URL.
4. Dive directly into lib/features/dashboard/dashboard_logic.dart and the user_semester_states database table mapping to fix the schedule rendering issue. 


## 6. Database Configuration & Credentials
**Where the AI can find the Database connections:**
1. **The .env file:** The root directory contains a .env file (D:\EWUmate\EWUmate_Clean\ewumate_v2\.env). This contains the SUPABASE_URL, SUPABASE_ANON_KEY, and likely the DATABASE_URL (the direct PostgreSQL connection string needed for Python psycopg2).
2. **Flutter Configuration:** Look in lib/core/config/ (usually env.dart or similar) to see how Flutter initializes the Supabase.initialize() client.
3. **Python Scripts Context:** Previous Python scripts used for diagnostics (like check_schedule.py, ix_dashboard.py, 	est_db2.py in the root) might hold hardcoded or .env-referenced connection strings.
   
**To the Next AI Agent:** *Before trying to query the database, read the .env file in the root directory to grab the live Supabase PostgreSQL connection URI.*

