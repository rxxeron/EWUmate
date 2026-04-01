-- Setup Daily Cron for Semester Switch
-- This job runs every day at 00:00 UTC
-- It invokes the 'sync-semester-meta' Edge Function to check if a semester switch is needed.

-- 1. Ensure extensions are enabled (usually already done by Supabase)
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Clear old job if exists
DO $$
BEGIN
  PERFORM cron.unschedule('invoke-semester-switch-bot');
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END $$;

-- 3. Schedule the new job
SELECT
  cron.schedule(
    'invoke-semester-switch-bot',
    '0 0 * * *', -- Every day at 00:00 UTC
    $$
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-semester-meta',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    $$
  );

-- Verification:
-- SELECT * FROM cron.job WHERE jobname = 'invoke-semester-switch-bot';
