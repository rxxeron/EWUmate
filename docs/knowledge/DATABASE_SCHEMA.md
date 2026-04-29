# EWUmate Live Database Schema

This document provides a comprehensive overview of the **live** database schema for the EWUmate project, extracted on 2026-04-02.

> [!NOTE]
> This schema is more comprehensive than the local `supabase/schema.sql` and includes several tables and columns that are only present in the live environment.

## Table Summary

| Table Category | Tables |
| :--- | :--- |
| **User & Profiles** | `profiles`, `admin_users`, `fcm_tokens`, `user_semester_states`, `user_drafts` |
| **Academic Meta** | `active_semester`, `semesters`, `programs`, `grade_scale`, `scholarship_policies`, `course_metadata` |
| **Course Offerings** | `courses_spring2026`, `courses_summer2026`, `calendar_spring2026`, `calendar_spring2026_phrm_llb` |
| **Enrollment & Stats** | `enrollments`, `completed_courses`, `semester_summaries`, `semester_course_marks`, `semester_course_stats`, `semester_analytics` |
| **App Features** | `tasks`, `notifications`, `feedbacks`, `schedule_exceptions`, `schedule_generations`, `app_config` |

---

## Core Tables Detail

### `profiles`
Extends Supabase Auth users with student-specific information.
- **Key Columns**: `id` (UUID, PK), `student_id`, `full_name`, `nickname`, `program_code`, `admitted_semester`, `cgpa`, `total_credits_earned`, `track`, `enrolled_sections` (TEXT[]), `enrolled_credits`.
- **Note**: This table is the central hub for user data and is updated by various triggers.

### `active_semester`
Stores the current and upcoming semester codes for different academic tracks.
- **Key Columns**: `track` (PK, tri_semester/bi_semester), `current_semester_code`, `next_semester_code`, `classes_start_date`, `final_exam_start`, etc.

### `enrollments`
Tracks the sections a user is currently enrolled in or planning to take.
- **Key Columns**: `id` (UUID, PK), `user_id`, `semester_code`, `course_code`, `section_id`, `status` (enrolled/upcoming/completed), `grade`.

### `completed_courses`
History of all courses a user has finished.
- **Key Columns**: `user_id`, `course_code`, `semester_code`, `grade`, `grade_point`, `credits`.
- **Note**: populated automatically when an enrollment is marked as completed.

---

## Configuration & Metadata

### `course_metadata`
The global course catalog.
- **Key Columns**: `code` (PK), `name`, `credit_val`, `equivalent_code`.

### `grade_scale`
Defines the mapping from letter grades to grade points based on policies (legacy vs modern).
- **Key Columns**: `grade` (PK), `point`, `min_score`, `policy`.

### `app_config`
Global key-value configuration for the application.
- **Key Columns**: `key` (PK), `value` (JSONB).

---

## Automation & Tracking

### `notifications`
System and user-triggered notifications.
- **Key Columns**: `id`, `user_id`, `type`, `title`, `body`, `is_dispatched`, `is_read`.

### `tasks`
User-defined academic tasks/reminders.
- **Key Columns**: `id`, `user_id`, `title`, `course_code`, `due_date`, `is_completed`.

---

> [!TIP]
> For a full list of columns and types, refer to the [live_schema_dump.json](file:///d:/EWUmate/EWUmate_Clean/ewumate_v2/docs/knowledge/live_schema_dump.json).
