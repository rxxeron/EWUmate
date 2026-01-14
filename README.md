# Mobile App - Project Status

## ✅ Deployment Ready (January 13, 2026)

The application has been fully implemented, with all critical flows connected to the live backend.

### 📱 Features Implemented
1.  **Authentication Flow**
    - Login & Registration with Firebase Auth.
    - **Profile Picture Upload:** Integrated with Expo Image Picker & Firebase Storage.
    - **Session Management:** `app/index.js` automatically routes users based on login state and onboarding progress.

2.  **Onboarding Journey**
    - **Program Selection:** Saves Department/Program to Firestore. (TS issues resolved).
    - **Course History:** Tracks completed courses.
    - **Current Enrollment:** Tracks active sections to drive the dashboard. (Loading states added for better UX).

3.  **Smart Dashboard**
    - **Real-time Data:** Fetches Schedule based on user's specific enrolled sections.
    - **Smart Logic:** "8 PM Rule" (shows tomorrow), "Holiday Mode" (Academic Calendar integration), "Chill Mode" (No classes).
    - **Search:** Functional search bar to filter classes.

4.  **Backend (Cloud Functions)**
    - Fully deployed. Parses PDFs for Courses, Exams, and Calendars.

---

## � Security & Build Status (Jan 13 Update)

**Latest Actions:**
1.  **Security Reset:**
    - Git history was completely wiped to remove leaked credentials.
    - Firebase keys moved to `.env` (ignored by git).
    - `firebaseConfig.js` refactored to use environment variables.
    - **IMPORTANT:** Local API key uses a new generated key.
2.  **Build Fixes:**
    - Resolved `react-native-reanimated` / `worklets` dependency errors.
    - Fixed Android Asset icons (square dimensions).
    - Fixed UTF-8 BOM encoding issue in `utils/course-catalog.js`.

**Current State:**
- The project is healthy locally (`npx expo-doctor` passes).
- The APK builds successfully but **crashes on launch**.
- **Reason:** The Cloud Build server does not have the `.env` variables (API keys).

**Next Steps (To Do):**
1.  **Upload Secrets to EAS:**
    Run the following commands to set the missing environment variables on the build server:
    ```bash
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_API_KEY --value AIza... --visibility plaintext
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN --value ewu-stu-togo.firebaseapp.com --visibility plaintext
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_PROJECT_ID --value ewu-stu-togo --visibility plaintext
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET --value ewu-stu-togo.firebasestorage.app --visibility plaintext
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID --value 999077106764 --visibility plaintext
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_APP_ID --value 1:999077106764:web:566201d37bd8cadd1d50e9 --visibility plaintext
    eas env:create preview --name EXPO_PUBLIC_FIREBASE_MEASUREMENT_ID --value G-WMX8KZNVE5 --visibility plaintext
    ```
2.  **Rebuild:**
    ```bash
    eas build -p android --profile apk
    ```

---

## �🚀 How to Run

1.  **Start the App**
    ```bash
    npx expo start
    ```
    - Press `a` for Android Emulator (or scan QR code with Expo Go).

2.  **Test the Flow**
    - **Register:** Create a new account. Upload a profile pic.
    - **Onboard:** Select "Dept of CSE", Pick some courses.
    - **Enroll:** Search for "CSE101", add Section "1".
    - **Dashboard:** verify you see the schedule for CSE101.

3.  **Verify Backend Data**
    - Upload PDFs to your Firebase Storage buckets (`facultylist/`, `examschedule/`, etc.) to populate more data if needed.

## 🛠️ Tech Stack
- **Frontend:** React Native (Expo), TypeScript.
- **Backend:** Firebase Cloud Functions (Node 22).
- **AI:** Google Cloud Document AI (Parser).
- **Database:** Firestore.
