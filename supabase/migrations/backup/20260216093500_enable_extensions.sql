-- Enable pg_cron for scheduling tasks
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

-- Enable pg_net for HTTP requests (often used with cron)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA pg_catalog;
