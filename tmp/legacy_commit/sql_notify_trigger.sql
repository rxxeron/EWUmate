-- Function to invoke the sync Edge Function
-- This requires the Supabase HTTP extension or similar, 
-- but a more standard way in Supabase is via a Webhook.
-- However, we can also use a simple PL/pgSQL function if the net extension is enabled.

CREATE OR REPLACE FUNCTION trg_notify_sync() 
RETURNS TRIGGER AS $$
BEGIN
    -- This uses the standard Supabase Hook pattern (if configured in Dashboard)
    -- Or we can just log it/emit a notification.
    -- For now, I will assume the Edge Function should be called.
    
    PERFORM
      net.http_post(
        url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-academic-stats',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
        ),
        body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
      );
      
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply Trigger to completed_courses
DROP TRIGGER IF EXISTS completed_courses_sync_trigger ON completed_courses;
CREATE TRIGGER completed_courses_sync_trigger
AFTER INSERT OR DELETE OR UPDATE ON completed_courses
FOR EACH ROW
EXECUTE FUNCTION trg_notify_sync();
