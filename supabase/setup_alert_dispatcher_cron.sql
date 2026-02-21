-- Enable the pg_net and pg_cron extensions if they are not already enabled
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Note: If you ever need to remove the job later, you can run:
-- SELECT cron.unschedule('invoke-alert-dispatcher');

-- Create a scheduled job that runs every minute
-- Note: Replace 'your-project-ref' with your actual Supabase project reference
-- Replace 'service-role-key' with your actual Supabase service role key
SELECT cron.schedule(
    'invoke-alert-dispatcher', -- Job name
    '* * * * *',               -- Cron expression (every minute)
    $$
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-dispatcher',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    $$
);

/*
After running this script in the Supabase SQL Editor:
1. Don't forget to replace `your-project-ref` and `service-role-key` BEFORE running it.
2. The `net.http_post` request will run asynchronously every minute.
3. You can check the status of the pg_net requests in the `net.http_request_queue` and `net._http_response` tables if you have access to them, or just monitor the Edge Function logs in the dashboard.
*/
