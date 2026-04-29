-- Enable the pg_net and pg_cron extensions if they are not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create a scheduled job that runs daily at 2 PM UTC (8 PM Dhaka Time)
SELECT cron.schedule(
    'invoke-alert-scheduler', -- Job name
    '0 14 * * *',               -- Cron expression (Daily at 14:00 UTC)
    $$
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-scheduler',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    $$
);
