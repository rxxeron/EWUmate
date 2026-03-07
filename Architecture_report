# 1. Executive Summary

**Project Overview:**  
**EWUmate** is a comprehensive, centralized companion mobile application designed for students of East West University (EWU). The core business value of the platform is to unify fragmented academic data—such as course schedules, academic calendars, advising slots, task management, and result history—into a single, highly responsive mobile experience. The application aims to increase student productivity and engagement by integrating real-time scheduling functionality, localized offline data caching, and push notifications.

**Target Audience/Users:**  
The primary users are currently enrolled students at East West University who require a streamlined way to manage their academic lifecycle, from onboarding (checking admitted semester) to tracking degree progress and handling daily schedules. It also includes an administrative slice (Admin Panel) for broadcasting announcements and managing app configuration.

---

# 2. System Architecture

**Architectural Pattern:**  
The project leverages a hybrid **Serverless / BaaS (Backend-as-a-Service)** architectural pattern coupled with an **Event-Driven Mobile Client**. 
* **Frontend:** Built using a **Feature-First Layered Architecture** (Clean Architecture inspired), where domain logic is compartmentalized.
* **Backend:** Operates entirely on managed cloud services with no traditional monolithic server. Compute is split between **Supabase Serverless Edge Functions** and **Azure Functions** (Microservices).

**High-Level System Design:**  
1. **Client Tier (Flutter App):** Manages user interactions, local state, and offline persistence. It interfaces directly with Supabase via the Supabase Flutter SDK.
2. **Data & Auth Tier (Supabase):** Acts as the central hub. It provides PostgreSQL for relational data, GoTrue for JWT-based identity and access management, and Supabase Storage for media (profile pictures).
3. **Ingestion & ETL Tier (Azure Functions):** A cluster of Python-based microservices (`ewumate_api`) responsible for parsing unstructured university data formats (e.g., advising schedules from EML files, course listings) and transforming them into structured payloads that are pushed to Supabase.
4. **Messaging Tier (Firebase):** Handles reliable delivery of push notifications to user devices based on triggers from the database.

**Design Principles:**  
* **Separation of Concerns (SoC):** The frontend strictly segregates features by domain (e.g., `advising`, `calendar`, `tasks`). Each block further encapsulates its UI, logic, and models.
* **Offline-First Resilience:** Employs intelligent syncing (`SyncService`) and layered caching (`OfflineCacheService`) to ensure the app functions robustly under poor network conditions.
* **Secure by Default:** Utilizes Row Level Security (RLS) in PostgreSQL, enforcing authorization directly at the database layer.

---

# 3. Technology Stack

**Frontend / Client:**  
* **Framework:** Flutter (Dart >= 3.2.0) targeting primarily Android and iOS.
* **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`) integrated with Provider for theme configurations.
* **Routing:** GoRouter for declarative, path-based navigation.
* **Data Serialization:** Freezed (`freezed_annotation`) and JSON Serializable.

**Backend / API:**  
* **Primary Backend Engine:** Supabase (Database, Auth, Storage).
* **Data Ingestion Engine:** Azure Functions running Python 3. 
* **Scripting Plugins:** Integration scripts mapping parsed scraped data (`advising_parser.py`, `course_parser.py`).

**Database & Storage:**  
* **Relational Database:** PostgreSQL (via Supabase) utilizing natively supported JSONB columns for flexible data structures.
* **Local Caching Layer:** Hive (`hive_flutter`) and SharedPreferences for offline persistence. 
* **Object Storage:** Supabase Storage (publicly accessible bucket for `profile_images`).

**Infrastructure & DevOps:**  
* **Push Notifications:** Firebase Cloud Messaging (FCM).
* **Environment Management:** Multi-environment configuration powered by `.env` and `flutter_dotenv`.
* **CI/CD Triggers:** Supabase migrations are cleanly structured within the `/supabase/migrations` directory, indicating automated database schematic deployments.

---

# 4. Codebase & Module Breakdown

**Directory Structure Analysis:**  
* `lib/core/`: Contains structural boilerplate—global configurations (`SupabaseConfig`), routing, and fundamental services like `SyncService`, `OfflineCacheService`, and `NotificationService`.
* `lib/features/`: The heart of the business logic. Subdivided into bounded contexts: `auth`, `calendar`, `course_browser`, `dashboard`, `tasks`, `results`, `advising`, etc.
* `supabase/`: Contains the comprehensive `schema.sql` defining the PostgreSQL database, alongside SQL migration files and triggers (e.g., `setup_alert_dispatcher_cron.sql`).
* `azure_functions/ewumate_api/`: Python microservices that act as ETL pipelines. Contains regex-heavy parsers translating the University's raw data formats into consumable JSON APIs.
* `admin_panel/`: A lightweight, vanilla HTML/JS web dashboard designed for system administrators to trigger broadcasts.

**Core Modules & File Analysis:**  
* **`lib/main.dart`:** The high-level entry point that safely initializes critical SDKs (Firebase, Supabase, Timezones) wrapped in a hard timeout barrier to ensure poor network conditions don't halt app launch. Implements a global exception fallback UI.
* **`lib/core/services/sync_service.dart`:** An essential infrastructural glue. It listens to connectivity changes and proactively performs a throttled fetch of courses, calendar holidays, and academic profiles ensuring the client’s local SQL/Hive cache is continually hydrated.
* **`supabase/schema.sql`:** Denotes business primitives. Heavy utilization of `JSONB` for dynamically structured data (e.g., `sessions` in courses, `course_history` in academic data). It is strictly wrapped in RLS policies ensuring users only query rows matching `auth.uid() = id/user_id`.
* **`azure_functions/ewumate_api/advising_parser.py`:** A prime example of the ingestion layer. It ingests EML (email) payload bytes containing raw advising schedules, applies complex regex pattern matching to extract date/time/credits, and structures an advised schedule payload.

---

# 5. Data Flow & Integration

**Request Lifecycle:**  
1. **App Initialization:** The app starts and triggers `SyncService`. If a connection is available, the client queries Supabase securely using an authenticated JWT. 
2. **Data Ingestion (Background):** Azure Functions periodically parse university documents (or intercept webhooks) and update the central Supabase PostgreSQL DB.
3. **Data Caching:** The client fetches updated records via domain Repositories. These Repositories write directly to Hive / SharedPreferences to persist local state.
4. **UI Binding:** Riverpod Providers listen to the local cache or repository streams and lazily rebuild the Flutter UI components.

**External Integrations:**  
* **Firebase Cloud Messaging:** Handled passively via background isolation. Device tokens are intercepted and stored in the `fcm_tokens` Supabase table for targeted message routing.
* **University Web Portals:** Interfaced indirectly via custom Python parsers (`course_parser.py`, `exam_parser.py`) deployed on Azure Functions.

---

# 6. Security & Error Handling

**Authentication & Authorization:**  
* Driven entirely by Supabase Auth (GoTrue). 
* **Row Level Security (RLS):** Policies are rigorously defined across tables. For example, `CREATE POLICY "Users can manage own academic data" ON academic_data FOR ALL USING (auth.uid() = user_id);`. This means even if the client app is compromised or a token is copied, an attacker cannot query another student's data.

**Data Protection:**  
* Sensitive tokens and configurations (e.g., `flutter_secure_storage`) are encrypted on the device securely using Keychain/Keystore.
* Parameterized Database Queries: By using the Supabase SDK, the app inherently guards against classical SQL Injection.

**Error Management:**  
* **Global Error Wrapping:** Core initialization in `main.dart` catches hard crashes via global try-catch and gracefully degrading to a custom error UI, saving the user from infinite splash screens.
* **Network Resilience:** Network calls utilize explicit `timeout()` closures appended with `.catchError()`, guaranteeing the app never hangs indefinitely on failing requests.

---

# 7. Scalability & Performance

**Bottlenecks:**  
* **Scraping Fragility:** The Azure Python functions heavily depend on regex parsing of unstructured plain text or HTML (like University EML files). Any unannounced layout changes from the university's IT department will silently fail the ETL process, causing data staleness.
* **Fat Payloads:** Heavy reliance on JSONB columns (`semesters`, `course_history`) means querying large aggregate datasets requires pulling down large JSON blobs instead of clean normalized SQL joins. This could inflate memory usage on low-end mobile devices during synchronization.

**Scalability Strategy:**  
* The architecture is profoundly scalable. The decoupling of the parsing layer (Azure Microservices) from the consumption layer (Supabase Edge) protects the database from CPU-heavy parsing constraints.
* Supabase (PostgreSQL) can scale compute instances dynamically, and the use of offline-first caching via Riverpod + Hive ensures the server only answers to delta synchronization, drastically reducing active server load.

---

# 8. Technical Debt & Recommendations

**Code Quality Assessment:**  
The codebase is extremely well-structured for a mobile application, adhering well to modern Flutter paradigms (Riverpod/Clean Architecture). RLS policies are beautifully executed, preventing basic architectural vulnerabilities. Error handling during initialization is robust. On the downside, test coverage (Unit/Widget) is noticeably sparse, and the ingestion layer's reliance on Regex exposes the pipeline to structural drift.

**Actionable Improvements:**  
1. **Stabilize Data Ingestion Pipelines:** Migrate the regex-heavy Azure Functions to use Headless Browser automation (like Playwright/Puppeteer) or BeautifulSoup for DOM awareness. This makes scraping resilient to minor stylistic text changes.
2. **Implement Automated Testing:** Establish core unit tests targeting Riverpod `StateNotifiers` and the `SyncService` logic. Follow up with integration tests verifying the RLS policies in Supabase using the pgTAP testing framework.
3. **Normalize Heavy JSONB Columns:** Consider migrating large nested JSONB arrays (like `tasks`, `user_schedules`, or `course_history`) into their own dedicated relational tables to significantly reduce payload sizes and improve query performance for complex filtering operations.
4. **Implement Request Pagination:** Ensure that as the `courses` dataset grows historically, list views in the UI paginate the results (e.g. `range()` queries in Supabase) rather than querying the entire collection into memory at once.
5. **Observability & Logging Integration:** Integrate a modern telemetry tool (e.g., Sentry, Firebase Crashlytics) to effectively capture production exceptions beyond the local console `debugPrint()` invocations.
