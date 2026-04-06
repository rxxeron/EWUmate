CREATE OR REPLACE FUNCTION public.handle_enrollment_sync()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  service_key TEXT := 'YOUR_SERVICE_ROLE_KEY'; -- Replace with your Service Role Key
  project_url TEXT := 'https://YOUR_PROJECT_ID.supabase.co'; -- Replace with your Project URL
BEGIN
  PERFORM
    net.http_post(
      url := project_url || '/functions/v1/sync-schedule',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_key
      ),
      body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
    );
  RETURN NEW;
END;
$function$
;
