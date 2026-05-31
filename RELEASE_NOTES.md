# 🚀 EWUmate Release Notes - Version 1.1.3+33

We are pleased to introduce EWUmate version `1.1.3+33` (Production & Testing). This major update implements **Option B (Seamless Deep Linking Auto-Open flow)** across mobile and web platforms, refactors the user onboarding process to safely bypass RLS picture upload blocks, resolves administrative user purging errors in the database, and implements dynamic academic parameters for BBA graduation criteria.

---

## 🔑 Key Features & Enhancements

### 🔗 1. Seamless Deep Linking Auto-Open & Auto-Login Flow (Option B)
To deliver a frictionless, modern verification experience:
- **Mobile Deep Linking:** Configured custom URI schemes (`ewumate://login-callback`) inside native files (`AndroidManifest.xml` on Android and `Info.plist` on iOS). Clicking the email verification link in the Zoho confirmation inbox now automatically launches the EWUmate app on the user's device.
- **Dynamic Web-Safe Origin (PWA):** Built origin-adaptive redirects (`kIsWeb`) so that web/PWA clients automatically detect their running location (e.g., `https://app.ewumate.pro.bd/login-callback` in production or `http://localhost:5000/login-callback` in local testing) and redirect confirmed users back to the web portal.
- **Auto-Login Router Handshake:** Added the `/login-callback` path in GoRouter. The app automatically extracts the `#access_token` parameter from the incoming URL, logs the user in in the background, and seamlessly transitions them to the onboarding profile setup page.

### 🛡️ 2. Safe Onboarding Split & RLS Bypass
- **Sign-Up Sanitization:** Decoupled the avatar picker from the initial registration screen (where users are unauthenticated and would trigger Supabase Row Level Security violations on storage upload) and relocated it safely to the post-authenticated `ProfileSetupScreen`.
- **Identity Prefilling:** Re-architected the `ProfileSetupScreen` to dynamically load values created upon registration by the database `handle_new_user` trigger. Text fields are now pre-populated, allowing students to pick an avatar and save details smoothly on their first authenticated session.

### 🔌 3. PWA Play Store Banner Suppression
- **Web Usability Fix:** Solved a critical user experience bug where web/PWA users were incorrectly shown the update banner directing them to the Google Play Store. We wrapped the update-banner prompt in mobile-only checks (`!kIsWeb`). Web/PWA clients will now download and update assets silently in the background via browser Service Workers.

### ⚙️ 4. Admin Purging Security Optimization (`admin-purge-user`)
- **Database Cascade Resolution:** Patched the admin user purge Deno Edge Function (`supabase/functions/admin-purge-user/index.ts`). The function now deletes related rows in dependent custom tables (`public.tasks` and `public.profiles`) **before** invoking the Auth delete API. This bypasses Postgres foreign key blocks, permanently resolving unexpected `500 Database error deleting user` failures.

### 🎓 5. Dynamic BBA Graduation Credits Enforcer
- **Admitted-Semester Credit Mapping:** Aligned program graduation calculations in `DegreeProgressScreen` and `CourseUtils` to enforce dynamic credit requirements for the BBA program:
  - **123 Credits:** Enforced for students admitted in **Fall 2024 and older**.
  - **130 Credits:** Enforced for students admitted in **Spring 2025 and newer**.

---

## 📈 Version Progression Summary

- **Previous Stable Release:** `1.1.2+32`
* **Current Production Build:** `1.1.3+33`
* **Platforms Sync:** Fully synchronized across parent `ewumate_v2`, release build `ewumate_production_build`, and web `ewumate_pwa`.
* **Deep Link Scheme Registered:** `ewumate://login-callback` (Mobile) & `/login-callback` (Web)

---

<br>

# 🚀 EWUmate Release Notes - Version 1.1.2+32

We are pleased to introduce EWUmate version `1.1.2+32` (Production). This release delivers crucial security hardening, complete compatibility with our Admin Panel Settings CMS, installer-specific download routing, and vital mobile application startup fixes.

---

## 🔑 Key Features & Enhancements

### 🛡️ 1. Complete Security Hardening & Zero-Secrets Client Binary
To prevent any risk of credential extraction, database tampering, or reverse engineering of the compiled Android application package (APK):
- **Removed High-Privilege Secrets**: Cleaned the production environment file (`.env`), completely deleting the highly sensitive `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL`, and `AZURE_FUNCTION_KEY`.
- **JWT Authorization Proxying**: Refactored the mobile client to fetch the active user session's `Bearer` access token (`Supabase.instance.client.auth.currentSession.accessToken`) dynamically on every request. 
- **Python Azure Functions Validation**: Migrated python-based academic tools (`generate_schedules` and `generate_pdf`) to use rigorous JWT validation, verifying ownership (matching `sub` claims) to guarantee that no student can perform academic operations on behalf of another user.

### 🌐 2. Dynamic Update Banners & Admin CMS Integration
The application's update alert banners are now fully dynamic and seamlessly integrate with the React Admin Panel configuration:
- **Installer Store Detection**: The app detects if it was installed from the **Google Play Store** (`com.android.vending`) or sideloaded as a **manual APK** (e.g., via browser or sharing).
- **Custom Redirects**:
  - **Play Store Users**: Led directly to the official Google Play Store link for automatic background updating.
  - **Manual APK Users**: Routed directly to the custom `Update Download URL` defined dynamically by administrators through the CMS.
- **Admin Panel Control**: The mobile app now fully respects the **"Show Update Prompt to Users"** master switch from the Admin Panel's settings. Turning it off disables update prompts globally instantly.

### ⚡ 3. Startup & Notification Race Condition Fixes
- **Auth Flow Stalling Fix**: Addressed a startup race condition on the `CheckAuthScreen`. When users with offline cached local Hive profiles signed out, the app could transiently load a blank dashboard saying "Please log in." We added a hard primary session validation check (`user == null && !hasSession`) to block bypass attempts and smoothly redirect signed-out users back to the Login wall.
- **Push Notification Stability**: Prevented crashes and race conditions when users tap on notification items during early startup. If the dashboard is not fully loaded, `FCMService` now safely queues the action, executing it smoothly only once the dashboard is stable and active.

---

## 📈 Version Progression Summary

- **Previous Stable Release**: `1.1.1+31`
- **Current Production Build**: `1.1.2+32`
- **Installer Sources Supported**: Google Play Store & Sideloaded Manual APKs
- **CMS Compatibility**: Fully verified against `app_config` schema column states (`latest_version`, `download_url`, and `value.update_available`).
