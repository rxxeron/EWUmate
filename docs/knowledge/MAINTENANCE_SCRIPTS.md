# EWUmate Maintenance Scripts Summary

The root directory of this project contains numerous Python scripts used for database management, data integrity, and local development tasks.

## Script Categories

| Category | Scripts | Description |
| :--- | :--- | :--- |
| **Audit & Integrity** | `audit_data.py`, `audit_fk.py`, `audit_v2.py`, `verify_academic_integrity.py` | Checks for missing foreign keys, mismatched credits, and inconsistent schedules. |
| **Schema & Migration** | `apply_schema_v2.py`, `apply_academic_stats_schema.py`, `migrate_academic_data.py`, `fix_db_constraints.py` | Used to update table definitions and migrate data between versions. |
| **Fix & Repair** | `run_global_fix.py`, `repair_credits.py`, `fix_permissions.py`, `cleanup_academic.py`, `fix_unprotected_tables.py` | Automated scripts to repair common data issues and RLS policies. |
| **Parsing & Sync** | `parse_pdf.py`, `sync_semesters.py`, `extract_text.py`, `push_update.py` | Utilities to ingest data from PDF faculty lists or sync semester metadata. |
| **Testing** | `test_db.py`, `test_sync.py`, `test_programs.py`, `check_schema.py`, `check_active.py` | Small utility scripts to verify specific subsets of the database. |

---

## Key Maintenance Workflows

### 1. Verifying Database Integrity
Run `python audit_data.py` to check for common issues like:
- Enrollments with missing courses.
- Profiles with incorrect track data.
- Mismatched CGPA calculations.

### 2. Applying Schema Changes
When the schema needs an update, use `python apply_schema_v2.py`. This script is designed to be idempotent and handles both table creation and column updates.

### 3. Repairing RLS Policies
If users are reporting "Permission Denied" errors, run `python fix_permissions_v3.py`. This script ensures that all tables have RLS enabled and that the standard anonymous/authenticated/service-role policies are in place.

### 4. Cleaning Up Academic Data
`python cleanup_academic.py` was used to migrate from the old JSONB-based `academic_data.semesters` format to the new normalized `completed_courses` table.

---

> [!CAUTION]
> **Production Env**: Most of these scripts use the `DATABASE_URL` from the `.env` file. Be extremely careful when running "Fix" or "Cleanup" scripts against the production database, as they often perform destructive `DELETE` or `UPDATE` operations.

> [!TIP]
> Use `python list_tables.py` for a quick check of which tables are currently visible in the `public` schema.
