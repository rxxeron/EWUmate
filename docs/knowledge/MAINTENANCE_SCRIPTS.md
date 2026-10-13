# EWUmate Maintenance Scripts Summary

The `scripts/` directory contains numerous Python scripts used for database management, data integrity, and automation tasks.

## Script Categories

| Category | Scripts | Description |
| :--- | :--- | :--- |
| **Audit & Integrity** | `scripts/analyze_data_coverage.py`, `scripts/check_rls_live.py`, `scripts/check_db_schema.py` | Checks data coverage, RLS policies, and database schema. |
| **Schema & Extraction** | `scripts/extract_live_schema.py`, `supabase/migrations/` | Used to inspect live tables and manage versioned migrations. |
| **Fix & Cleanup** | `scripts/run_cleanup.py`, `scripts/cleanup_non_target_users.sql` | Automated scripts to clean test/non-target profiles and dangling records. |
| **Parsing & Sync** | `scripts/parse_bulletin.py`, `scripts/parse_faculty_list.py`, `scripts/sync_faculty_directory.py`, `scripts/portal_schedule_automation.py` | Utilities to ingest bulletin data, faculty directories, and schedule automation. |
| **Course Metadata** | `scripts/populate_course_metadata.py`, `scripts/reconcile_equivalence.py`, `scripts/finalize_master_list.py` | Maintains global course catalog, equivalents, and degree prerequisite maps. |

---

## Key Maintenance Workflows

### 1. Verifying Database Integrity & RLS
Run `python scripts/check_rls_live.py` and `python scripts/check_db_schema.py` to check for common issues like:
- Missing RLS policies on public tables.
- Schema deviations between local catalog and production.
- Data coverage gaps across semesters.

### 2. Applying Schema Changes
Database schema modifications are managed via SQL files in `supabase/migrations/` and verified with `python scripts/extract_live_schema.py`.

### 3. Running Data Cleanup
Run `python scripts/run_cleanup.py` to remove orphaned records or execute targeted maintenance queries in `scripts/cleanup_non_target_users.sql`.

---

> [!CAUTION]
> **Production Env**: Most of these scripts use the `DATABASE_URL` from the `.env` file. Be extremely careful when running "Fix" or "Cleanup" scripts against the production database, as they often perform destructive `DELETE` or `UPDATE` operations.

> [!TIP]
> Use `python list_tables.py` for a quick check of which tables are currently visible in the `public` schema.
