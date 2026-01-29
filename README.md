# EWUmate

This is a Flutter project with a Firebase backend.

## Project Structure

The project is structured as follows:

*   `lib/`: Contains the Dart code for the Flutter application.
*   `functions/`: Contains the Python Cloud Functions for the Firebase backend.
*   `functions-node/`: Contains the Node.js Cloud Functions for the Firebase backend.
*   `public/`: Contains the public assets for Firebase Hosting.
*   `android/`: Contains the Android-specific project files.
*   `ios/`: Contains the iOS-specific project files.
*   `web/`: Contains the web-specific project files.
*   `linux/`: Contains the Linux-specific project files.
*   `windows/`: Contains the Windows-specific project files.
*   `macos/`: Contains the macOS-specific project files.

## How to Run the Project

1.  **Set up Flutter:** Make sure you have the Flutter SDK installed and configured.
2.  **Set up Firebase:** Create a Firebase project and configure the Firebase CLI.
3.  **Install dependencies:**
    *   Run `flutter pub get` to install the Flutter dependencies.
    *   Run `npm install` in the `functions-node` directory to install the Node.js dependencies.
    *   Run `pip install -r requirements.txt` in the `functions` directory to install the Python dependencies.
4.  **Run the app:**
    *   Run `flutter run` to run the app on a connected device or emulator.
    *   Run `firebase deploy` to deploy the Cloud Functions and hosting.
