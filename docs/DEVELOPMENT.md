<!-- generated-by: gsd-doc-writer -->
# Development Guide

This guide describes development workflows, code standards, build commands, and branching conventions for engineering contributors on EWUmate.

## Local Setup

1. **Repository Setup**:
   Clone the repository and verify Git branch status:
   ```bash
   git clone https://github.com/your-org/ewumate.git
   cd ewumate/ewumate_production_build
   ```

2. **Environment Configuration**:
   Ensure `.env` exists in the root folder. For development, default sandbox endpoints and fallback Supabase instances are supported. Never commit `.env` or production credentials.

3. **Install Client Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Code Generation**:
   Whenever Riverpod annotations, Freezed models, or JsonSerializable schemas are updated:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   To run active file watching during development:
   ```bash
   dart run build_runner watch --delete-conflicting-outputs
   ```

## Build Commands

| Command | Category | Description |
|---|---|---|
| `flutter pub get` | Dependency Management | Downloads and updates packages defined in `pubspec.yaml`. |
| `flutter run` | Development | Boots application in interactive debug mode with hot reload. |
| `flutter run -d chrome` | Web Development | Runs the web build target in Google Chrome for responsive testing. |
| `dart run build_runner build --delete-conflicting-outputs` | Code Generation | Runs code generators for Riverpod and json_serializable models. |
| `flutter analyze` | Linting | Executes static analysis across all Dart files using `analysis_options.yaml`. |
| `dart format .` | Formatting | Formats Dart codebase according to official Dart style conventions. |
| `flutter test` | Testing | Executes the Flutter test suite. |
| `flutter build apk --release --no-tree-shake-icons` | Production Build | Compiles the production Android release APK, preserving all Material icons. |
| `build_production_apk.bat` | Build Automation | Windows batch script automating clean compilation of release APK. |
| `flutter build appbundle --release` | Store Release | Generates Android App Bundle (AAB) for Google Play distribution. |

## Code Style

- **Linter**: The project adheres to `package:flutter_lints/flutter.yaml` configured in `analysis_options.yaml`.
- **Formatting**: Code must pass `dart format --line-length 120 .` prior to opening pull requests.
- **Rules**:
  - Prefer `const` constructors wherever possible to optimize Flutter widget build trees.
  - Avoid raw `debugPrint` or `print` statements in production repositories; utilize structured logging (`logging: ^1.3.0`).
  - Encapsulate remote network queries inside the repository layer (`lib/core/repositories/`). UI widgets must consume data exclusively through Riverpod providers (`lib/core/providers/`).
  - Preserve null-safety idioms across all model definitions.

## Branch Conventions

The repository uses Git feature branches structured around release channels:

- `main` / `master`: Production release-ready code. Commits trigger production CI validations.
- `production`: Mirrored production release branch for Google Play and automated builds.
- `testing`: Integration branch for QA, pre-release staging, and test verification.
- `feat/<feature-name>`: Dedicated feature development branches (e.g. `feat/routine-export`, `feat/faculty-rating`).
- `fix/<bug-name>`: Targeted bug fixes (e.g. `fix/calendar-parsing-offset`).

## PR Process

1. **Self-Review**: Run static analysis and automated tests before pushing:
   ```bash
   flutter analyze
   flutter test
   ```
2. **Commit Hygiene**: Write clear, descriptive commit messages adhering to conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`).
3. **Branch Target**: Submit pull requests targeting the `testing` branch or `main` depending on release milestone.
4. **CI Verification**: Ensure all GitHub Actions checks (Android artifact build, admin panel build) complete successfully without errors.
5. **Approval**: At least one peer review approval is required prior to merging into protected branches.
