# Mobile App - Project Status & Roadmap

## Current Status (January 13, 2026)

### ✅ Core Features Completed
- **User Routing:** `app/index.js` now handles Auto-Login and Onboarding checks.
- **Profile Picture:** `register.tsx` supports image upload to Firebase Storage.
- **Dashboard Search:** Added Search Bar to `dashboard.js`.
- **Security:** `firestore.rules` updated to restrict access to authenticated users and owners.
- **Configuration:** `app.json` updated with Bundle IDs and Plugin permissions.

### ⚠️ Pending Actions (Manual Steps Required)
1. **Install Dependencies:**
   Run the following command to install the new image picker package:
   ```bash
   npx expo install expo-image-picker
   ```
2. **Add Assets:**
   The `assets/` folder has been created but is empty. You must add the following files for the build to succeed:
   - `assets/icon.png` (1024x1024)
   - `assets/splash.png` (1242x2436)
   - `assets/adaptive-icon.png` (1024x1024)
   - `assets/favicon.png` (48x48)

3. **Build:**
   Once assets are added, you can build for production:
   ```bash
   eas build --platform android
   ```

---

## 📅 Roadmap: Tomorrow's Tasks

### 1. User Session & Routing (Priority High)
- **DONE** - `app/index.js` implemented.

### 2. UI Polish & Error Handling
- **Program Selection:** Verify/Add `@ts-ignore` to the `View` map to silence `ViewProps` error.
- **Empty States:** Ensure `useDashboardSchedule` handles empty enrollment gracefuly (no crash).
- **Toasts/Feedback:** Add visual feedback (Toast) for "Saved Successfully" on onboarding steps.

### 3. Feature Completion
- **DONE** - Profile Picture Upload.

### 4. Data Validation
- **DONE** - Search implemented in Dashboard.

## 📂 Project Structure Vitals
- **Functions:** `functions/index.js` (Core Logic).
- **Context:** `context/CourseContext.js` (Data Hydration).
- **Onboarding:** `app/onboarding/*.tsx` (User Setup).

## 🚀 Commands
- **Run App:** `npx expo start` (or `npx expo start --android`)
- **Deploy Backend:** `firebase deploy --only functions`
- **Check Logs:** `firebase functions:log`
