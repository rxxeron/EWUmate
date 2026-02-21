# EWUmate: A University Companion App

EWUmate is a robust and scalable mobile application framework built with **Flutter** and powered by a **Firebase** backend. It is designed to serve as a digital assistant for university students, providing a centralized platform to access academic schedules, important documents, and other essential information.

While initially developed for a specific institution, its modular architecture allows it to be easily adapted for any university or educational organization.

---

## 🚀 Core Features

- **Cross-Platform Availability**: Built with Flutter for a consistent and native experience on both **Android** and **iOS** from a single codebase.
- **Serverless Backend**: Leverages the full power of the Firebase ecosystem, including Authentication, Firestore, Realtime Database, and Cloud Functions for a secure, scalable, and low-maintenance backend.
- **Dynamic Document Management**: Easily integrates and displays various documents such as academic calendars, exam schedules, and course catalogs using a built-in PDF viewer.
- **Automated Data Processing**: Includes a powerful data pipeline with **Python scripts** to parse, process, and structure information from source files (like PDFs) into a queryable format for the app.
- **Rich User Interface**: Features a modern and intuitive UI with components like calendars, animations, and cached images to provide a smooth user experience.
- **User Authentication**: Secure user sign-in and management with Firebase Authentication, including support for social providers like Google Sign-In.
- **State Management**: Built with **Riverpod** for robust and scalable state management.

---

## 🛠️ Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase (Auth, Firestore, Realtime Database, Storage, Cloud Functions)
- **Data Processing**: Python
- **State Management**: Flutter Riverpod & Provider
- **Navigation**: `go_router`
- **UI Components**: `google_fonts`, `lottie`, `shimmer`, `table_calendar`
- **PDF Viewing**: `syncfusion_flutter_pdfviewer`

---

## ⚙️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- A [Firebase](https://firebase.google.com/) project
- [Python 3.x](https://www.python.org/downloads/) (for running data processing scripts)

### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/rxxeron/EWUmate.git
    cd EWUmate
    ```

2.  **Set up Firebase:**
    - Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    - Add an Android and/or iOS app to your project.
    - Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) configuration files and place them in the appropriate directories within the `android` and `ios` folders.

3.  **Install Flutter dependencies:**
    ```sh
    flutter pub get
    ```

4.  **Run the app:**
    ```sh
    flutter run
    ```

---

## 🤝 How to Contribute

Contributions are welcome! If you have ideas for new features, bug fixes, or improvements, please feel free to open an issue or submit a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for more details.