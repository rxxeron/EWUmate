CREATE OR REPLACE FUNCTION public.trigger_track_sync()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  host_header text;
  dest_url text;
BEGIN
  -- 1. Try to get host from request headers (PostgREST)
  BEGIN
    host_header := current_setting('request.headers', true)::json->>'host';
  EXCEPTION WHEN OTHERS THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co'; -- Fallback
  END;

  IF host_header IS NULL THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co';
  END IF;

  -- 1. Trigger sync-schedule
  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,
      body := jsonb_build_object('track', NEW.track)
    );

  -- 2. Trigger sync-semester-meta (new)
  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-semester-meta',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,
      body := jsonb_build_object('record', jsonb_build_object('track', NEW.track, 'current_semester_code', NEW.current_semester_code))
    );

  -- 3. Trigger sync-profile-cache (new)
  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-profile-cache',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,
      body := jsonb_build_object('track', NEW.track)
    );

  RETURN NEW;
END;
$function$
;
