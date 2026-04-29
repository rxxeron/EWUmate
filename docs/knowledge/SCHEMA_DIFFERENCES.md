# Database Schema Differences: Live vs Local

This document highlights the discrepancies between the live Supabase database and the local `supabase/schema.sql` file.

> [!WARNING]
> The local `supabase/schema.sql` is significantly outdated. Using it to reset a database will result in a broken environment missing 60% of required tables and all backend logic (functions/triggers).

## Missing Tables in Local SQL

The following tables exist in **Live** but are completely missing from the local `schema.sql`:

| Table Name | Purpose |
| :--- | :--- |
| `active_semester` | Tracks current/upcoming semesters for different tracks. |
| `completed_courses`| Persistent history of finished courses. |
| `enrollments` | Current/upcoming course registrations. |
| `grade_scale` | Mapping for GPA calculations. |
| `programs` | Academic program definitions. |
| `scholarship_policies`| Rules for scholarship eligibility. |
| `semester_summaries` | Aggregated stats per semester for each user. |
| `admin_users` | List of UUIDs with administrative access. |
| `app_config` | Global app-level settings. |

---

## Table Definition Discrepancies

### `profiles` Table
The live `profiles` table has evolved significantly:
- **Missing Columns in Local**: `cgpa`, `total_credits_earned`, `semester_type`, `department_name`, `program_name`, `track`, `enrolled_sections_next`, `past_history`, `enrolled_credits`, `total_courses_completed`.
- **Note**: The local version still references `email` and `department`, which seem to have been superseded by more specific fields in live.

### `course_metadata` Table
- **Live**: Includes `equivalent_code` for course waivers/substitutions.
- **Local**: Missing `equivalent_code`.

---

## Missing Backend Logic

The local `schema.sql` contains **no** logic definitions. The following are missing:

1.  **Stored Procedures**: 21 functions are missing, including critical ones like `get_grade_point`, `sync_profile_enrolled_sections`, and `trg_shift_enrollment`.
2.  **Triggers**: 18 triggers are missing, which means automation (like updating profile credits or shifting enrollments to history) will not work.
3.  **RLS Policies**: While some basic policies exist in the local SQL, many advanced policies for the new tables are missing.

---

## Recommendations

1.  **Update Local Schema**: Use the [live_schema_dump.json](file:///d:/EWUmate/EWUmate_Clean/ewumate_v2/docs/knowledge/live_schema_dump.json) to generate a new, comprehensive `schema.sql`.
2.  **Manual Sync**: Use the `extract_live_schema.py` script periodically to ensure local documentation stays in sync with production.
3.  **Logic Export**: Consider exporting the live functions and triggers to individual `.sql` files in the `supabase/` directory for better version control.
