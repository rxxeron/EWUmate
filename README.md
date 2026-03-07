<h1 align="center">🎓 EWUmate</h1>

<p align="center">
  <strong>The Ultimate Companion App for East West University Students</strong>
</p>

## Overview

**EWUmate** is a comprehensive, centralized mobile application designed specifically for the students of East West University (EWU). It acts as a highly responsive digital assistant, unifying fragmented academic data—such as course schedules, academic calendars, advising slots, task management, and result history—into a single, offline-resilient mobile experience.

## ✨ Key Features

- **📅 Dynamic Schedule Manager:** Merges your enrolled courses with the current academic week, handling holiday overrides, makeup classes, and exam schedules automatically.
- **🗳️ Advising & Registration Planner:** Conflict-free timeline generation for upcoming semesters.
- **🔌 Offline-First Architecture:** Essential data is cached locally via Hive. Reminders and notifications are managed via local device alarms, ensuring you never miss a class, even in cellular dead zones.
- **📊 Academic Progress Tracking:** Real-time calculation of CGPA, credits earned, and customized projections.
- **🔔 Push Notifications:** Instant updates via Firebase Cloud Messaging for university-wide broadcasts or personal task alerts.

## 🏗️ System Architecture

> **Deep Dive:** For a complete engineering breakdown of the project, including data flow, scale, and security mechanisms, please read our comprehensive **[Project Architecture & Engineering Report](file:///d:/EWUmate/EWUmate_Clean/architecture_report.md)**.

EWUmate employs a **Serverless / BaaS** architecture paired with an **Event-Driven Mobile Client**.

1. **Client Tier (Flutter App):** Built with a Feature-First Layered Architecture using Riverpod for robust state management.
2. **Data & Auth Tier (Supabase):** PostgreSQL database acting as the authoritative source of truth, heavily protected by Row Level Security (RLS). GoTrue manages JWT-based identity.
3. **Ingestion & ETL Tier (Azure Functions):** Python-based serverless microservices that parse unstructured University data (EML files, PDFs) into structured JSON.
4. **Admin Dashboard:** A lightweight web interface (`admin_panel/`) allowing administrators to broadcast messages and push manual database syncs.

## 🧰 Technology Stack

### Frontend (Mobile App)
- **Framework:** Flutter (Dart >= 3.2.0)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter
- **Local Storage:** Hive (`hive_flutter`), SharedPreferences

### Backend & API
- **Database As A Service:** Supabase (PostgreSQL)
- **Authentication:** Supabase Auth (GoTrue)
- **Storage:** Supabase Storage (Profile pictures, attachments)
- **Microservices:** Azure Functions (Python 3) for ETL data parsing.
- **Push Notifications:** Firebase Cloud Messaging (FCM)

## 📁 Directory Structure

```text
EWUmate/
├── admin_panel/            # HTML/JS admin dashboard for broadcasts
├── azure_functions/        # Python microservices for data scraping/parsing
│   └── ewumate_api/        # Advising, calendar, and course parsers (Regex/EML)
├── lib/                    # Main Flutter application source
│   ├── core/               # App-wide routing, theme, sync, and network logic
│   └── features/           # Domain-driven feature modules (auth, dashboard, tasks, etc.)
├── supabase/               # Database schematics and migrations
│   ├── migrations/         # CI/CD deployment migrations
│   └── schema.sql          # Master database definition & RLS policies
└── pubspec.yaml            # Dart dependencies and project configuration
```

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>=3.2.0)
- Supabase Project (Database, Auth, Storage configured)
- Firebase Project (for FCM)
- Azure Functions Core Tools (if modifying the ingestion layer)

### Environment Setup
Create a `.env` file in the root directory and provide your Supabase credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Run the Mobile App
```bash
flutter pub get
flutter run
```

### Deploying the Backend
1. **Supabase Schema:** Execute the SQL found in `supabase/schema.sql` via the Supabase SQL editor to scaffold the Postgres database, storage buckets, and RLS policies.
2. **Azure Functions:** Navigate to `azure_functions/ewumate_api` and deploy using the Azure CLI:
   ```bash
   func azure functionapp publish <YourFunctionAppName>
   ```

## 🛡️ Security & Privacy

EWUmate is built with a "Secure by Default" mindset:
- **Zero-Trust Client:** The Flutter app assumes no direct database privileges. All queries hit Supabase's PostgREST API and are evaluated against strict **Row Level Security (RLS)** policies. Users can only query their own `auth.uid()`.
- **Encrypted Local Storage:** Sensitive items like session tokens are handled natively via `flutter_secure_storage`.

## 🤝 Contributing

We welcome contributions to improve EWUmate. To contribute:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---
*Built to empower the students of East West University.*
