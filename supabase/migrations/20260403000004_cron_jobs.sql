CREATE EXTENSION IF NOT EXISTS pg_cron;
-- pg_cron jobs export

-- Job Name: invoke-alert-scheduler
-- Schedule: 0 14 * * *
-- Active: True
SELECT cron.schedule('invoke-alert-scheduler', '0 14 * * *', $$
    SELECT
      net.http_post(
          url:='http://host.docker.internal:54321/functions/v1/alert-scheduler',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,        
          body:='{}'::jsonb
      ) AS request_id;
$$);



-- Job Name: invoke-alert-dispatcher
-- Schedule: * * * * *
-- Active: True
SELECT cron.schedule('invoke-alert-dispatcher', '* * * * *', $$
        SELECT
          net.http_post(
              url:='http://host.docker.internal:54321/functions/v1/alert-dispatcher',
              headers:='{"Content-Type": "application/json", "Authorization": "Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,    
              body:='{}'::jsonb
          ) AS request_id;
$$);
