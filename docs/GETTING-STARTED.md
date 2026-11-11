<!-- generated-by: gsd-doc-writer -->
# Getting Started with EWUmate

This guide provides step-by-step instructions for setting up the EWUmate development environment, resolving runtime prerequisites, and launching the mobile application locally.

## Prerequisites

Ensure the following tools and SDK versions are installed on your workstation:

- **Flutter SDK**: `Flutter >= 3.27.0` (Dart SDK `>= 3.0.0 < 4.0.0`)
- **Java Development Kit (JDK)**: `Java 17` (e.g. Eclipse Temurin 17 or OpenJDK 17). Verified in CI workflows.
- **Android Studio & SDK**: Android SDK Platform 34 or 36 with Build-Tools and Android Command-line Tools.
- **Python**: `Python 3.10+` or `3.11` (required only if testing Azure Functions microservices locally).
- **Node.js**: `Node.js >= 20.0.0` (required only for developing the React `admin_panel`).
- **Git**: Installed and configured on PATH.

Verify your environment by running:
```bash
flutter doctor -v
java -version
```

## Installation Steps

Follow these steps to clone the repository and install all required client dependencies:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/ewumate.git
   cd ewumate/ewumate_production_build
   ```

2. **Configure Environment Secrets**:
   Copy the sample environment values or create a `.env` file in the project root:
   ```bash
   # Create .env in ewumate_production_build/
   cp .env.example .env
   ```
   Populate `.env` with your active Supabase and Azure Functions endpoints:
   ```env
   SUPABASE_URL=https://jwygjihrbwxhehijldiz.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
   AZURE_FUNCTION_URL=https://ewumate-parser-api.azurewebsites.net
   GOOGLE_WEB_CLIENT_ID=561956344734-ulqeqls9u4h1hmpec41l9lufk336a9ga.apps.googleusercontent.com
   ```

3. **Install Flutter Dependencies**:
   Resolve all Dart packages declared in `pubspec.yaml`:
   ```bash
   flutter pub get
   ```

4. **Generate Code Artifacts (Optional / If Needed)**:
   If generated files (`*.g.dart`) are missing or modified, execute build runner:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## First Run

Launch the application on an attached Android emulator, physical device, or desktop target:

```bash
flutter run
```

To target a specific device identifier:
```bash
flutter devices
flutter run -d <device-id>
```

Upon boot, the application initializes Hive offline cache boxes, connects to Supabase, and presents the onboarding screen or authentication gateway.

## Common Setup Issues

1. **Gradle Build Failures due to JDK Version Incompatibility**:
   - *Symptom*: Gradle fails with `Unsupported class file major version` or Java compilation errors.
   - *Solution*: Ensure `JAVA_HOME` points strictly to JDK 17:
     ```bash
     # Windows PowerShell
     $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.x"
     ```
2. **Missing `.env` File Warning**:
   - *Symptom*: Log output displays `[SupabaseConfig] .env load notice` and uses embedded fallback keys.
   - *Solution*: Verify that `.env` is created directly inside `ewumate_production_build/` and listed in Flutter assets in `pubspec.yaml`.
3. **Android Keystore / Signing Configuration**:
   - *Symptom*: Release build fails due to missing `key.properties`.
   - *Solution*: Run debug mode for local testing (`flutter run --debug`), which uses default Android debug keys.

## Next Steps

- Explore the system architecture and data flows in [ARCHITECTURE.md](ARCHITECTURE.md).
- Review all configurable parameters and defaults in [CONFIGURATION.md](CONFIGURATION.md).
- Read the daily workflow, linting, and build commands in [DEVELOPMENT.md](DEVELOPMENT.md).
- Check test execution and coverage details in [TESTING.md](TESTING.md).
- Inspect backend microservices and endpoint schemas in [API.md](API.md).
