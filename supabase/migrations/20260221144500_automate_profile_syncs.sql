-- Create a unified function to trigger multiple edge functions
CREATE OR REPLACE FUNCTION trigger_profile_syncs()
RETURNS TRIGGER AS $$
DECLARE
  v_base_url text;
  v_auth_header text;
  v_body jsonb;
BEGIN

  -- Create JSON payload for edge functions
  v_body := jsonb_build_object(
    'type', TG_OP,
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'user_id', NEW.id,
    'record', row_to_json(NEW),
    'old_record', row_to_json(OLD)
  );

  -- Fetch Auth header from active_semester metadata or use a fallback
  -- In this environment, we rely on pg_net being able to reach the functions
  v_auth_header := 'Bearer ' || COALESCE((SELECT value->>'service_role_key' FROM config WHERE key = 'edge_functions'), 'YOUR_SERVICE_ROLE_KEY');

  -- 1. Trigger sync-schedule
  BEGIN
    PERFORM net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule',
      body := v_body,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      )
    );
  EXCEPTION WHEN others THEN
    RAISE LOG 'Error calling sync-schedule: %', SQLERRM;
  END;

  -- 2. Trigger match-exams
  BEGIN
    PERFORM net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/match-exams',
      body := v_body,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      )
    );
  EXCEPTION WHEN others THEN
    RAISE LOG 'Error calling match-exams: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger
DROP TRIGGER IF EXISTS trigger_sync_schedule_on_enrolled_sections ON public.profiles;

-- Create the new unified trigger on profiles table
-- Triggers on INSERT (Registration) and UPDATE of enrolled_sections (Advising/Manual)
CREATE TRIGGER trigger_profile_syncs_on_change
AFTER INSERT OR UPDATE OF enrolled_sections ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION trigger_profile_syncs();
