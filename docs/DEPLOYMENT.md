<!-- generated-by: gsd-doc-writer -->
# Deployment Guide

This document details the build pipelines, release procedures, deployment targets, and rollback strategies for the EWUmate mobile application, admin dashboard, and backend services.

## Deployment Targets

1. **Android Mobile Application (APK & AAB)**:
   - Primary distribution via Google Play Store (App Bundle `.aab`) and direct student downloads (Universal Release APK `.apk`).
   - Package Name: `com.rxxeron.ewumate`.
2. **React Admin Panel**:
   - Deployed to GitHub Pages via automated CI/CD pipeline (`admin_panel/`).
3. **Azure Functions Microservices**:
   - Deployed to Azure App Service (`https://ewumate-parser-api.azurewebsites.net`) running Python 3.10/3.11 Linux Consumption plan.
4. **Supabase PostgreSQL & Edge Functions**:
   - Managed Supabase Cloud instance with schema migrations and RLS policies. <!-- VERIFY: Supabase project ID jwygjihrbwxhehijldiz deployment pipeline -->

## Build Pipeline

The project uses GitHub Actions and local batch scripts to automate release compilation.

### 1. Android Artifact Compilation (`.github/workflows/build-android.yml`)

The workflow runs on `ubuntu-latest` and can be triggered on-demand via `workflow_dispatch`:

1. **Checkout**: Checks out the code repository.
2. **Java 17 Setup**: Configures JDK 17 with Gradle caching via `actions/setup-java@v4`.
3. **Flutter Setup**: Configures the stable Flutter SDK channel via `subosito/flutter-action@v2`.
4. **Version Extraction**: Automatically parses version and build number from `pubspec.yaml` (e.g. `1.1.16+46`).
5. **Secret Injection**: Injects `.env`, decodes base64-encoded Android release keystore and `key.properties`.
6. **Artifact Compilation**:
   - Compiles Release APK:
     ```bash
     flutter build apk --release --no-tree-shake-icons
     ```
   - Compiles Release AAB:
     ```bash
     flutter build appbundle --release
     ```
7. **Artifact Upload**: Uploads APK and AAB as GitHub Action run artifacts for release packaging.

### 2. Local Windows Build Script (`build_production_apk.bat`)

Developers on Windows with Flutter and Android SDK configured locally can produce a production APK directly:

```bat
build_production_apk.bat
```

This runs:
```bash
flutter build apk --release --no-tree-shake-icons
```
The output file is generated at `build\app\outputs\flutter-apk\app-release.apk`.

### 3. Admin Panel Deployment (`.github/workflows/deploy-admin.yml`)

Triggered on push to `production`, `main`, `master`, or `testing` when files inside `admin_panel/**` change:
1. Sets up Node.js 24 with npm caching.
2. Executes `npm install` and `npm run build` in `admin_panel/`.
3. Uploads GitHub Pages artifact and deploys via `actions/deploy-pages@v4`.

## Environment Setup

The following secrets must be configured in GitHub Repository Secrets for production release builds:

- `ENV_FILE`: Complete production `.env` contents including Supabase and Azure URLs.
- `KEYSTORE_BASE64`: Base64 encoded release keystore file (`.jks` / `.keystore`). <!-- VERIFY: Keystore alias and password stored in repository secrets -->
- `KEY_PROPERTIES_BASE64`: Base64 encoded `android/key.properties` defining `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`.
- `ADMIN_PANEL_ENV`: Production environment variables for the React Admin Panel.

## Rollback Procedure

- **Mobile Client**:
  - Google Play Console: Use the Google Play Store Release Management dashboard to halt phased rollout or roll back to the previously published APK/AAB version code.
  - Direct Downloads: Re-upload the prior known-stable release APK to distribution channels and trigger an in-app update notification via `AppUpdateService`.
- **Admin Dashboard**:
  - Redeploy the previous Git commit on the `main` or `production` branch in GitHub Pages.
- **Azure Functions**:
  - Roll back using Azure CLI deployment slots or redeploy the prior commit using Azure Functions Core Tools (`func azure functionapp publish`).

## Monitoring & Telemetry

- **Crash Reporting & Analytics**: Mobile crashes and app health are monitored via Firebase Crashlytics and Firebase Core (`firebase_options.dart`).
- **Backend Logs**: Azure Functions invocations and errors are tracked in Azure Application Insights. <!-- VERIFY: Application Insights instrumentation key configured in Azure portal -->
- **Database & Auth Logs**: Monitored via the Supabase Cloud Management Console (Logs Explorer, Edge Function execution logs).
