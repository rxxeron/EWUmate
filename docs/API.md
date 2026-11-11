<!-- generated-by: gsd-doc-writer -->
# API Reference

The EWUmate backend exposes HTTP microservices hosted on Microsoft Azure Functions (`ewumate-parser-api.azurewebsites.net`) and Supabase PostgreSQL Edge Functions. These services power schedule generation, portal data scraping, document rendering, and semester lifecycle operations.

## Authentication

- **Mechanism**: JWT Bearer authentication issued by Supabase Auth (`verify_supabase_jwt` in `azure_functions/ewumate_api/services/auth_service.py`).
- **Header**: Requests must include the authorization header:
  ```http
  Authorization: Bearer <supabase_access_token>
  ```
- **Protected Actions**: Student-specific operations (`generate_schedules`, `generate_pdf`, `portal_sync_student`) strictly enforce JWT verification and validate that the `sub` claim matches the `user_id` provided in the request payload to prevent ID spoofing.
- **Service & Admin Actions**: Scraper jobs, semester switching, and bulk sync functions are invoked securely via admin proxy or scheduled timer triggers.

## Endpoints Overview

All primary Azure microservices are routed under `/api/{action}`:

| Method | Path | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/generate_schedules` | Generates conflict-free routine schedules for student course list | **Yes** (Supabase JWT) |
| `POST` | `/api/generate_pdf` | Compiles academic cover pages and assignment PDFs | **Yes** (Supabase JWT) |
| `POST` | `/api/generate_snapshot` | Produces downloadable PNG/PDF image snapshot of routine | No |
| `POST` | `/api/get_advising_courses` | Computes eligible next-term advising courses and prerequisites | No |
| `POST` | `/api/parse_calendar` | Parses EWU academic calendar text/PDF into calendar event dates | No |
| `POST` | `/api/switch_semester` | Administrative action to rollover the active academic semester | **Yes** (Admin) |
| `POST` | `/api/parse_grade_sheet` | Extracts completed course grades and CGPA from portal grade PDF | No |
| `POST` | `/api/portal_sync_student` | Scrapes and syncs student-specific routine from the portal | **Yes** (Supabase JWT) |
| `POST` | `/api/sync_api_courses` | Synchronizes course offering metadata into database | **Yes** (Admin) |
| `POST` | `/api/portal_sync` | Triggers full university portal course catalog scraper | **Yes** (Admin) |
| `POST` | `/api/faculty_sync` | Synchronizes EWU faculty directory profiles and departments | **Yes** (Admin) |

## Request and Response Formats

All requests and responses use `application/json` formatting.

### 1. Schedule Generation (`POST /api/generate_schedules`)

**Request**:
```json
{
  "user_id": "8f8b8098-b80c-4e46-bb1e-a579da93dfd6",
  "semester": "Spring 2026",
  "courses": ["CSE106", "MAT101", "ENG101"],
  "filters": {
    "free_days": ["Thursday"],
    "time_preference": "morning",
    "avoid_faculties": []
  }
}
```

**Response**:
```json
{
  "status": "success",
  "generationId": "gen_894120934812",
  "total_combinations": 4,
  "schedules": [
    {
      "combination_index": 1,
      "courses": [
        {
          "course_code": "CSE106",
          "section": 1,
          "faculty": "MSM",
          "time_slot": "ST 08:30 AM - 10:00 AM",
          "room": "AB2-401"
        }
      ]
    }
  ]
}
```

### 2. Advising Courses (`POST /api/get_advising_courses`)

**Request**:
```json
{
  "user_id": "8f8b8098-b80c-4e46-bb1e-a579da93dfd6",
  "semester": "Summer 2026",
  "program_code": "CSE"
}
```

**Response**:
```json
{
  "status": "success",
  "program": "B.Sc. in CSE",
  "recommended_courses": [
    {
      "course_code": "CSE207",
      "course_title": "Data Structures",
      "credits": 3,
      "prerequisites_met": true
    }
  ]
}
```

### 3. Portal Sync (`POST /api/portal_sync`)

**Request**:
```json
{
  "semester": "Spring 2026",
  "preview": false
}
```

**Response**:
```json
{
  "status": "success",
  "synced_sections": 1420,
  "updated_at": "2026-10-13T14:10:00Z"
}
```

## Error Codes

When an error occurs, the server responds with a standard error envelope:

```json
{
  "error": "Descriptive error message",
  "trace": "Traceback information (debug only)"
}
```

Standard HTTP status codes:

- `200 OK`: Request succeeded.
- `400 Bad Request`: Missing mandatory parameters or invalid JSON body.
- `401 Unauthorized`: Missing or invalid Supabase JWT in `Authorization` header.
- `403 Forbidden`: `user_id` mismatch between JWT `sub` and request body.
- `404 Not Found`: Requested action handler or resource not found.
- `500 Internal Server Error`: Unhandled worker exception or scraping execution failure.

## Rate Limits

- **Public Endpoints**: Azure Consumption Plan default concurrency thresholds apply. <!-- VERIFY: Maximum concurrency and rate limit settings in Azure Function App Host -->
- **Client Throttling**: Client applications must debounce schedule generation requests and limit full portal synchronization calls to avoid rate-limiting or IP blocks by the university portal.
