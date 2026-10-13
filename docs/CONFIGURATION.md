<!-- generated-by: gsd-doc-writer -->
# Configuration Guide

## Environment Variables

The mobile client, Azure Functions, and automation scripts require configuration flags and secrets to communicate with backend databases and services. The Flutter application loads values at runtime via `flutter_dotenv` from a root-level `.env` file.

| Variable | Required | Default | Description |
|---|---|---|---|
| `SUPABASE_URL` | **Required** | `https://jwygjihrbwxhehijldiz.supabase.co` | Base URL of the Supabase project instance. Used for authentication and PostgreSQL data queries. |
| `SUPABASE_ANON_KEY` | **Required** | Public Anon JWT | Anonymous public API key for Supabase client initialization. |
| `AZURE_FUNCTION_URL` | **Required** | `https://ewumate-parser.azurewebsites.net` | Base URL for deployed Azure Functions hosting routine generation and scrapers. |
| `GOOGLE_WEB_CLIENT_ID` | **Required** | Embedded in `AppConfig` | OAuth 2.0 Web Client ID registered in Google Cloud Console for Google Sign-In. |
| `GOOGLE_ANDROID_CLIENT_ID` | Optional | None | OAuth 2.0 Android Client ID for native Android Google Play authentication. |
| `UPSTASH_REDIS_REST_URL` | Optional | None | REST API endpoint URL for Upstash Redis database instance used for course caching. |
| `UPSTASH_REDIS_REST_TOKEN` | Optional | None | Bearer token for authenticating REST requests against Upstash Redis. |
| `SUPABASE_SERVICE_ROLE_KEY` | Optional | None | Service role administrative secret for backend scripts and Azure scraper workers. <!-- VERIFY: Secret managed in deployment environment secret manager --> |

## Config File Format

### 1. `.env` File (Application Root)
Standard key-value environment configuration parsed by `flutter_dotenv`:
```env
SUPABASE_URL=https://jwygjihrbwxhehijldiz.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
AZURE_FUNCTION_URL=https://ewumate-parser.azurewebsites.net
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your_google_android_client_id.apps.googleusercontent.com
UPSTASH_REDIS_REST_URL=https://your-upstash-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_upstash_redis_token
```

### 2. `azure_functions/host.json`
Azure Functions host configuration specifying extension bundle runtime settings:
```json
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

### 3. `analysis_options.yaml`
Dart analyzer and linter configuration referencing official Flutter lint rules:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - avoid_print
```

## Required vs Optional Settings

- **Required Settings**:
  - `SUPABASE_URL` & `SUPABASE_ANON_KEY`: Essential for mobile client database connectivity, real-time subscriptions, and authentication. While fallback default values are defined in `AppConfig` (`lib/core/config/supabase_config.dart`), omitting both during execution prints a warning to console in debug mode and prevents remote persistence if credentials expire.
  - `AZURE_FUNCTION_URL`: Required for triggering routine compilation and PDF syllabus processing. If missing, cloud computation features will fail with network resolution errors.
  - `GOOGLE_WEB_CLIENT_ID`: Required when students authenticate via Google OAuth.
- **Optional Settings**:
  - `UPSTASH_REDIS_REST_URL` & `UPSTASH_REDIS_REST_TOKEN`: If omitted, `RedisService` gracefully degrades and falls back directly to Supabase PostgreSQL queries and Hive local storage.
  - `GOOGLE_ANDROID_CLIENT_ID`: Required only for custom native Android OAuth credential verification when using specific Android keystores.

## Defaults

Default values for essential configurations are declared in `AppConfig` (`lib/core/config/supabase_config.dart`):

```dart
class AppConfig {
  static String get getSupabaseUrl {
    final val = _env('SUPABASE_URL');
    return val.isNotEmpty ? val : 'https://jwygjihrbwxhehijldiz.supabase.co';
  }

  static String get getSupabaseAnonKey {
    final val = _env('SUPABASE_ANON_KEY');
    return val.isNotEmpty ? val : 'eyJhbGciOiJIUzI1NiIsInR5cCI6...';
  }

  static String get getAzureFunctionUrl {
    final val = _env('AZURE_FUNCTION_URL');
    return val.isNotEmpty ? val : 'https://ewumate-parser.azurewebsites.net';
  }

  static String get getGoogleWebClientId {
    final val = _env('GOOGLE_WEB_CLIENT_ID');
    return val.isNotEmpty ? val : '561956344734-ulqeqls9u4h1hmpec41l9lufk336a9ga.apps.googleusercontent.com';
  }
}
```

## Per-Environment Overrides

- **Local Development**:
  Developers place a local `.env` file at the root of `ewumate_production_build/`. The `.env` file is included in `.gitignore` to prevent credential leakage into source control.
- **Continuous Integration & Release Builds (GitHub Actions)**:
  In automated builds (`.github/workflows/build-android.yml`), environment variables are securely injected from GitHub Repository Secrets (`secrets.ENV_FILE`, `secrets.KEYSTORE_BASE64`, `secrets.KEY_PROPERTIES_BASE64`) before invoking the Flutter build runner.
- **Azure Functions Runtime**:
  In Azure Functions, environment settings (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AZURE_STORAGE_CONNECTION_STRING`) are set in Azure App Service Configuration or locally in `azure_functions/local.settings.json`. <!-- VERIFY: Connection strings and keys configured in Azure App Settings portal -->
