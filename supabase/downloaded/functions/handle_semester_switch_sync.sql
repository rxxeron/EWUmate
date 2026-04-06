CREATE OR REPLACE FUNCTION public.handle_semester_switch_sync()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  service_key TEXT := 'YOUR_SERVICE_ROLE_KEY';
  project_url TEXT := 'https://YOUR_PROJECT_ID.supabase.co';
BEGIN
  -- Only trigger if the current_semester_code actually changed
  IF (OLD.current_semester_code IS DISTINCT FROM NEW.current_semester_code) THEN
    PERFORM
      net.http_post(
        url := project_url || '/functions/v1/sync-semester-summary',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_key
        ),
        body := jsonb_build_object('track', NEW.track)
      );
  END IF;
  RETURN NEW;
END;
$function$
;
