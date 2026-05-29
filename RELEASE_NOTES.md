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
