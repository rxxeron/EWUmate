CREATE OR REPLACE FUNCTION public.trigger_sync_schedule()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  host_header text;
  service_key text;
  dest_url text;
BEGIN
  -- 1. Try to get host from request headers (PostgREST)
  BEGIN
    host_header := current_setting('request.headers', true)::json->>'host';
  EXCEPTION WHEN OTHERS THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co'; -- Fallback to project-specific host
  END;

  IF host_header IS NULL THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co';
  END IF;

  dest_url := 'https://' || host_header || '/functions/v1/sync-schedule';

  -- 2. Trigger the Edge Function
  -- Note: service_role_key is usually available as a secret in vault or env
  PERFORM
    net.http_post(
      url := dest_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(current_setting('app.settings.service_role_key', true), 'SERVICE_ROLE_KEY_HERE')
      ),
      body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
    );
  RETURN NEW;
END;
$function$
;
