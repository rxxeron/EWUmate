# EWU Mate (Flutter V2)

This is the new Flutter version of the EWU Mate application, designed to replace the legacy React Native implementation.

## Features
- **Authentication**: Firebase Auth integration.
- **Dashboard**: Smart schedule handling, holiday modes.
- **Course Browser**: Firestore-backed course search and enrollment.
- **Profile**: User profile management with image upload.
- **Onboarding**: Program selection and course history tracking.

## Setup
1.  Ensure you have the Android SDK installed and configured.
2.  Ensure `android/app/google-services.json` exists (from Firebase Console).
3.  Run `flutter pub get` to install dependencies.

## Running
```bash
flutter run
```

## Architecture
- **State Management**: `Provider` (lightweight usage currently).
- **Routing**: `go_router` for declarative navigation.
- **Backend**: Firebase (Auth, Firestore, Storage).
