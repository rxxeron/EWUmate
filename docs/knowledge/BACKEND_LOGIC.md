# EWUmate Backend Logic Summary

This document summarizes the **stored procedures**, **triggers**, and **Supabase Edge Functions** that drive the EWUmate backend, based on live data extracted on 2026-04-02.

## Stored Procedures (PL/pgSQL Functions)

| Function Name | Description | Arguments |
| :--- | :--- | :--- |
| `get_grade_point` | Returns the grade point (0-4.0) based on semester code and grade. Handles legacy (pre-2023) and modern policies. | `p_semester_code`, `p_grade` |
| `sync_profile_enrolled_sections` | A trigger function that updates a user's `enrolled_sections` and `enrolled_credits` in the `profiles` table after an enrollment change. | `none` (trigger-only) |
| `trg_shift_enrollment` | Moves an enrollment to `completed_courses` once a grade is assigned, and then deletes it from `enrollments`. | `none` (trigger-only) |
| `shift_enrollments_by_track` | Bulk shifts enrollments for an entire academic track (e.g., from 'upcoming' to 'enrolled'). | `p_track`, `p_semester_code`, `p_new_status` |
| `sync_bulk_profile_enrollments` | Forces a re-sync of the `enrolled_sections` array for all users in a track. | `p_track`, `p_semester`, `p_user_id` |
| `create_course_table` | Dynamically creates a new `courses_SEASON_YEAR` table with a standard set of columns and RLS. | `p_semester_code` |
| `create_calendar_table` | Dynamically creates a new `calendar_SEASON_YEAR` table. | `p_semester_code` |
| `exec_sql` | Executes a raw SQL query with service-role permissions. (Use with caution). | `sql_query` |

---

## Active Triggers

| Trigger Name | Table | Event | Function |
| :--- | :--- | :--- | :--- |
| `enrollments_shift_trigger` | `enrollments` | AFTER UPDATE | `trg_shift_enrollment()` |
| `trg_sync_profile_enrollments`| `enrollments` | AFTER I/U/D | `sync_profile_enrolled_sections()` |
| `on_semester_change` | `active_semester`| AFTER UPDATE | `trigger_track_sync()` |
| `on_semester_switch` | `active_semester`| AFTER UPDATE | `handle_semester_switch_sync()` |
| `sync_profiles_updated` | `profiles` | BEFORE UPDATE| `update_timestamp()` |
| `completed_courses_sync_trigger`| `completed_courses`| AFTER I/U/D | `trg_notify_academic_sync()` |

---

## Supabase Edge Functions

These are located in the `supabase/functions/` directory and are triggered via HTTP or the `net.http_post` extension.

| Function Name | Responsibility |
| :--- | :--- |
| `sync-schedule` | Recalculates and caches a user's weekly grid and schedule template based on their enrollments. |
| `sync-academic-stats` | Re-calculates CGPA, total credits, and semester-level results in the `academic_data` column. |
| `alert-scheduler` | Predicts when a user's classes will start/end and schedules push notifications. |
| `alert-dispatcher` | Dispatches scheduled notifications via Firebase Cloud Messaging (FCM). |
| `pdf-parser` | Parses EWU faculty lists and academic calendars from PDF to JSON. |
| `broadcast` | Sends admin-level broadcast notifications to all users. |
| `sync-semester-meta` | Updates the `semesters` table and other metadata when the active semester switches. |

---

> [!IMPORTANT]
> **Service Role Keys**: Several triggers (`trg_notify_academic_sync`, `trg_notify_schedule_sync`, etc.) are hardcoded to call the project URL with a specific Service Role Key. If the project URL or key changes, these triggers **must** be updated.

> [!WARNING]
> **Dynamic Table Creation**: The `create_course_table` and similar functions create tables with names like `courses_spring2026`. This means any logic that queries courses must be dynamic or updated every semester.
