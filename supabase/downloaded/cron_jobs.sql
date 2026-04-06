-- pg_cron jobs export

-- Job Name: invoke-alert-scheduler
-- Schedule: 0 14 * * *
-- Active: True
SELECT cron.schedule('invoke-alert-scheduler', '0 14 * * *', '
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-scheduler',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    ');

-- Job Name: invoke-semester-switch-bot
-- Schedule: 0 0 * * *
-- Active: True
SELECT cron.schedule('invoke-semester-switch-bot', '0 0 * * *', '
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-semester-meta',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    ');

-- Job Name: invoke-alert-dispatcher
-- Schedule: * * * * *
-- Active: True
SELECT cron.schedule('invoke-alert-dispatcher', '* * * * *', '
        SELECT
          net.http_post(
              url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-dispatcher',
              headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
              body:='{}'::jsonb
          ) AS request_id;
        ');

