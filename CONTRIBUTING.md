# EWUmate Mobile — Contributing Guidelines

Thank you for your interest in contributing to **EWUmate Mobile**! EWUmate is designed to enhance the academic experience of students at East West University.

---

## 🛠️ Target Platforms & Architecture

- **Primary Native Platform:** **Android** (Google Play Store release).
- **iOS Platform Support:** iOS users are supported via the **EWUmate PWA** (`https://app.ewumate.pro.bd`). Native iOS runners are archived and inactive.
- **Web Platform:** Managed in the dedicated `ewumate_pwa` repository.

1. **Flutter SDK:** Flutter 3.27+ (Dart 3.x)
2. **Android Studio / VS Code** with Flutter and Dart extensions
3. **Environment Setup:**
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Populate the variables with your development keys or mock endpoints.

---

## 🌿 Branching Strategy

- `production`: The stable branch corresponding to Google Play Store releases.
- `testing`: The pre-release integration branch.
- Feature branches:
  - `feature/description` for new features
  - `fix/description` for bug fixes
  - `refactor/description` for code refactoring

---

## 📐 Architectural Standards

1. **State Management:** Riverpod 2.x
   - Use `AsyncNotifier` or `Notifier` for business logic.
   - Keep UI widgets free from direct API calls.
2. **Offline-First:** Hive / Shared Preferences
   - Any screen fetching remote data should provide offline fallback or caching where appropriate.
3. **Design System:**
   - Follow the Dark Mode / Emerald Green design system defined in `core/theme/`.
   - Never hardcode color values; use `Theme.of(context)` or theme extensions.

---

## 🧪 Testing & Quality Checks

Before opening a Pull Request, verify:
```bash
# 1. Format code
flutter format .

# 2. Analyze for lints & errors
flutter analyze

# 3. Run test suite
flutter test
```

---

## 🔒 Security Requirements

- **NEVER** commit `.env`, keystore files (`*.jks`), or `key.properties`.
- Ensure all API endpoints communicate securely over HTTPS with Row Level Security (RLS) enforcement.

---

## 📝 Submitting a Pull Request

1. Fork the repository and create your branch from `testing` or `production`.
2. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat(advising): add search filter`, `fix(auth): handle token expiry`).
3. Push to your fork and submit a PR with a clear summary of changes and screenshots for UI updates.
