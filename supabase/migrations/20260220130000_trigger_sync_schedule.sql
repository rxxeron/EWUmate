-- Create the function to call the edge function using pg_net
CREATE OR REPLACE FUNCTION trigger_sync_schedule()
RETURNS TRIGGER AS $$
DECLARE
  v_url text;
  v_auth_header text;
  v_body jsonb;
BEGIN

  -- Create JSON payload
  v_body := jsonb_build_object(
    'type', TG_OP,
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'record', row_to_json(NEW),
    'old_record', row_to_json(OLD)
  );

  -- Fetch the edge function URL from config or use local Kong gateway URL as fallback
  v_url := (SELECT value->>'sync_schedule_url' FROM config WHERE key = 'edge_functions');
  IF v_url IS NULL THEN
    v_url := 'http://kong:8000/functions/v1/sync-schedule'; -- Default local supabase docker net
  END IF;

  -- Fetch Anon or Service Role key to pass to the edge function
  v_auth_header := 'Bearer ' || COALESCE((SELECT value->>'anon_key' FROM config WHERE key = 'edge_functions'), 'YOUR_ANON_KEY');

  -- Make asynchronous web request using pg_net extension
  BEGIN
    PERFORM net.http_post(
      url := v_url,
      body := v_body,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      )
    );
  EXCEPTION WHEN others THEN
    -- Ignore network errors, so as not to block profile updates
    RAISE LOG 'Error calling sync-schedule edge function: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS trigger_sync_schedule_on_enrolled_sections ON public.profiles;

-- Create the trigger on profiles table
CREATE TRIGGER trigger_sync_schedule_on_enrolled_sections
AFTER UPDATE OF enrolled_sections ON public.profiles
FOR EACH ROW
WHEN (OLD.enrolled_sections IS DISTINCT FROM NEW.enrolled_sections)
EXECUTE FUNCTION trigger_sync_schedule();
