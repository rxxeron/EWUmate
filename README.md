# EWUmate

EWUmate is a Flutter application backed by Supabase, Edge Functions, PostgreSQL,
and Azure automation.

## Production Database Handoff

The production project is `ewumate` in Supabase. Migration history is
synchronized through `20260916000003_fix_failed_course_credits`.

### Deployed Improvements

- Notifications older than five days are archived in `notifications_archive`.
- Notification archiving runs in bounded batches through `alert-scheduler`.
- Redundant profile, faculty, schedule, study-material, and notification
  triggers are guarded against unchanged values.
- The unused `promote_active_semester()` function was removed.
- Schedule and academic synchronization now use a deduplicated `sync_jobs`
  queue with retries and `pg_cron` dispatch.
- `sync-schedule` now uses catalog lookup maps instead of one query per missing
  enrollment.
- Failed grades `F` and `F*` no longer count as earned/completed credits.
- Embedded database credentials and service-role JWTs were removed from the
  maintained source paths.

### Remaining Work

1. Rotate the Supabase service-role key and any previously exposed database or
	Firebase credentials. Removing a secret from source does not revoke it.
2. Monitor `sync_jobs` for failed jobs, retries, and stale `running` rows:

	```sql
	SELECT status, job_type, count(*)
	FROM public.sync_jobs
	GROUP BY status, job_type
	ORDER BY status, job_type;
	```

3. Batch the remaining `alert-scheduler` per-user queries and test duplicate
	reminder behavior before deployment.
4. Move the remaining scraper snapshot and semester-summary HTTP triggers to
	the queue after their deployed endpoint contracts are verified.
5. Replace runtime table creation and arbitrary SQL RPCs with reviewed
	migrations or restricted admin-only operations.
6. Resolve the remaining database lint findings for the Supabase
	`extensions.index_advisor` installation and the unused variable in
	`get_admin_dashboard_stats`.
7. Add automated tests for failed grades, retakes, withdrawals, incomplete
	grades, notification archiving, queue retries, and schedule repairs.

### Operational Checks

```bash
npx supabase migration list --linked
npx supabase db lint --linked
npx supabase inspect db role-stats --linked
npx supabase inspect db blocking --linked
npx supabase inspect db long-running-queries --linked
```

The queue worker is `process-sync-jobs`; the notification scheduler is
`alert-scheduler`. Do not run `supabase db push` with local Vault updates in
production; use `--skip-vault` unless secret changes have been reviewed.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
