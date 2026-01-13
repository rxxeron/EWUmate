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

## 🚀 How to Run

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
