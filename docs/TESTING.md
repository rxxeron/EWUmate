<!-- generated-by: gsd-doc-writer -->
# Testing Strategy

This document outlines the testing architecture, test suites, execution commands, and guidelines for testing EWUmate.

## Test Framework and Setup

EWUmate uses the standard Flutter testing framework provided by the Flutter SDK:

- **Framework**: `flutter_test` (bundled directly with the Flutter SDK).
- **Environment**: Dart 3.x execution runtime with `testWidgets` and `WidgetTester` capabilities.
- **Dependencies**: In addition to `flutter_test`, tests involving state management utilize `ProviderScope` overrides from `flutter_riverpod: ^2.5.1`.
- **Global Setup**: Run `flutter pub get` prior to test runs to verify all test harness dependencies are present.

## Running Tests

Execute tests using the standard Flutter CLI commands:

- **Run all tests**:
  ```bash
  flutter test
  ```
- **Run a specific test file**:
  ```bash
  flutter test test/widget_test.dart
  ```
- **Run tests with verbose reporter**:
  ```bash
  flutter test --reporter expanded
  ```
- **Run tests and generate coverage information**:
  ```bash
  flutter test --coverage
  ```
  The resulting coverage file is output to `coverage/lcov.info`.

## Writing New Tests

When creating new tests, adhere to the following directory layout and file conventions:

1. **File Naming**:
   - Place all test files in the `test/` directory, mirroring the structure of `lib/`.
   - Test files must end with the suffix `_test.dart` (for example, `test/core/services/cache_service_test.dart`, `test/features/auth/login_screen_test.dart`).

2. **Widget Tests & Riverpod**:
   - Wrap widgets under test in a `ProviderScope` to supply mock or initialized providers:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:ewumate/main.dart';

   void main() {
     testWidgets('Application boots and renders without crashing', (WidgetTester tester) async {
       await tester.pumpWidget(
         const ProviderScope(
           child: MyApp(),
         ),
       );
       await tester.pumpAndSettle();
       expect(find.byType(MyApp), findsOneWidget);
     });
   }
   ```

3. **Repository & Service Unit Tests**:
   - Mock network endpoints and Supabase clients using mock adapters or mockito/mocktail.
   - Avoid executing live database writes or Azure Function HTTP queries in automated test runs.

## Coverage Requirements

- **Thresholds**: No formal coverage gate is currently enforced in CI.
- **Recommendations**: Critical path components (such as auth token refreshes, schedule permutation calculators, and offline cache hydration) are expected to maintain comprehensive regression coverage.

## CI Integration

Automated builds and tests run via GitHub Actions (`.github/workflows/build-android.yml` and `.github/workflows/deploy-admin.yml`). Build workflows check out the codebase, set up Java 17 and Flutter stable, compile Android release artifacts, and verify build health on pull requests and branch updates.
