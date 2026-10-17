# Flutter App Changes Summary (October 7, 2026)
**Location:** `ewumate_production_build/lib`  
**Commit:** `8016dad` — `feat(law): preserve law department course codes in azure functions and sync updates`

---

## Overview of Key Improvements
1. **Architecture & Refactoring:** Extracted heavy database syncing and parsing logic from `portal_sync_screen.dart` into a clean, dedicated `PortalSyncRepository`.
2. **Bi-Semester & Law Department Track Support:** Implemented centralized track normalization (`bi_semester` vs `tri_semester`) ensuring Law (LL.B) and Pharmacy students properly receive their bi-semester schedule, active semesters, and grades.
3. **Performance & Multi-Level Caching:** Integrated Upstash Redis L2 caching with TTL, in-memory date range caches, and exception caching to drastically minimize repetitive Supabase egress and latency.
4. **Concurrency & Thread Safety:** Eliminated Hive sync queue race conditions with a sequential execution lock (`_enqueueLock`).
5. **Provider Lifecycle & Memory Leak Fixes:** Ensured `SessionGuardian` and `FCMService` properly dispose listeners via Riverpod's `ref.onDispose`.

---

## Detailed List of Changed Files

### 1. New Files
* **[`lib/features/services/repositories/portal_sync_repository.dart`](lib/features/services/repositories/portal_sync_repository.dart)** *(+260 lines)*
  * **Purpose:** New dedicated repository for portal routine and schedule synchronization.
  * **Changes:** Handles active semester detection, weekly grid cache upserts (`user_semester_states`), schedule data persistence (`courses_{semester}`), and enrichment of course titles from metadata.

---

### 2. Core Architecture & Configuration
* **[`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart)**
  * Fixed publishable key parameter mapping (`publishableKey: anonKey`).
* **[`lib/core/utils/course_utils.dart`](lib/core/utils/course_utils.dart)**
  * Added `CourseUtils.normalizeTrack(String? track)` to reliably map variations to either `'bi_semester'` or `'tri_semester'`.
* **[`lib/core/providers/academic_providers.dart`](lib/core/providers/academic_providers.dart)**
  * Applied track normalization when loading academic semester data.
* **[`lib/core/providers/session_guardian.dart`](lib/core/providers/session_guardian.dart)**
  * Added `ref.onDispose(() => guardian.dispose())` to prevent lingering auth session listeners.
* **[`lib/main.dart`](lib/main.dart)**
  * Restricted global `HttpOverrides` solely to debug mode (`if (kDebugMode)`), maintaining strict SSL certificate security in production.

---

### 3. Caching & Service Layer
* **[`lib/core/services/redis_service.dart`](lib/core/services/redis_service.dart)**
  * Added `set(String key, dynamic value, {Duration? ttl})` for writing key-value pairs to Upstash Redis with custom expiration.
* **[`lib/core/repositories/course_repository.dart`](lib/core/repositories/course_repository.dart)**
  * Added background Redis L2 caching for course metadata with a 7-day TTL (`course_meta_{code}`).
* **[`lib/core/services/cache_service.dart`](lib/core/services/cache_service.dart)**
  * Fixed concurrent sync queue race condition by wrapping Hive queue operations in a sequential `_enqueueLock`.
* **[`lib/core/services/fcm_service.dart`](lib/core/services/fcm_service.dart)**
  * Added Riverpod provider disposal hook (`ref.onDispose`) to unbind token refresh listeners cleanly.
* **[`lib/core/repositories/active_semester_repository.dart`](lib/core/repositories/active_semester_repository.dart)**
  * Enforced normalized track parameters when querying the `active_semester` Supabase table.
* **[`lib/core/repositories/dashboard_repository.dart`](lib/core/repositories/dashboard_repository.dart)**
  * Safely captured errors in background pre-fetch calls (`_fetchAndCacheAnalytics` and `_fetchAndCacheState`).

---

### 4. Dashboard & Exceptions
* **[`lib/features/dashboard/controllers/dashboard_controller.dart`](lib/features/dashboard/controllers/dashboard_controller.dart)**
  * Integrated track normalization to distinguish bi-semester (Law / Pharmacy) from tri-semester users.
  * Added fast memory cache retrieval for weekly routine grids before network roundtrips.
* **[`lib/features/dashboard/dashboard_repository.dart`](lib/features/dashboard/dashboard_repository.dart)**
  * Added in-memory caching for active semester date ranges (`12-hour TTL`) to eliminate duplicate database hits.
* **[`lib/features/dashboard/exception_repository.dart`](lib/features/dashboard/exception_repository.dart)**
  * Added a 5-minute in-memory cache for schedule exceptions with `invalidateCache()` capability.

---

### 5. Services & Portal Sync Screen
* **[`lib/features/services/presentation/portal_sync_screen.dart`](lib/features/services/presentation/portal_sync_screen.dart)**
  * Refactored screen to delegate database write queries to `PortalSyncRepository`.
  * Removed 226 lines of tightly-coupled business logic, making the UI reactive and lean.
* **[`lib/features/services/repositories/faculty_assignment_repository.dart`](lib/features/services/repositories/faculty_assignment_repository.dart)**
  * Specified explicit column selection on `faculty_assignments` to reduce network payload.

---

### 6. Results & Semester Progress
* **[`lib/features/results/presentation/grade_entry_screen.dart`](lib/features/results/presentation/grade_entry_screen.dart)**
  * Added intelligent track detection checking for `bi`, `phrm`, `law`, and `llb` tokens so Law and Pharmacy students receive the bi-semester grading period.
* **[`lib/features/semester_progress/semester_progress_repository.dart`](lib/features/semester_progress/semester_progress_repository.dart)**
  * Added in-memory caching for active semester code queries.
* **[`lib/features/semester_progress/services/attendance_calendar_service.dart`](lib/features/semester_progress/services/attendance_calendar_service.dart)**
  * Added 12-hour in-memory cache for academic calendar dates.
  * Normalized user track when resolving semester date windows.

---

### 7. Auth, Onboarding & Notifications
* **[`lib/features/auth/auth_providers.dart`](lib/features/auth/auth_providers.dart)**
  * Normalized user profile track to ensure correct DB enum matching (`bi_semester` / `tri_semester`).
* **[`lib/features/onboarding/onboarding_repository.dart`](lib/features/onboarding/onboarding_repository.dart)**
  * Standardized fallback resolution between `track` and legacy `semester_type`.
* **[`lib/features/notifications/presentation/reminder_settings_screen.dart`](lib/features/notifications/presentation/reminder_settings_screen.dart)**
  * Applied track normalization when loading class reminder preferences.

---

### 8. Course Browser & Study Vault
* **[`lib/features/course_browser/presentation/providers/course_browser_providers.dart`](lib/features/course_browser/presentation/providers/course_browser_providers.dart)**
  * Added explicit column selection on `enrollments` query.
* **[`lib/features/study_vault/data/repositories/study_vault_repository.dart`](lib/features/study_vault/data/repositories/study_vault_repository.dart)**
  * Added relational foreign table join `profiles:uploader_id(full_name)` to display uploader names directly.
* **[`lib/features/study_vault/data/models/study_material.dart`](lib/features/study_vault/data/models/study_material.dart)**
  * Added mapping support for nested `uploader_name` from the joined profile query.
