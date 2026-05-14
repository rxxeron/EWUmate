-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Robust Scraper Log Trigger Function
CREATE OR REPLACE FUNCTION public.handle_scraper_log_trigger()
RETURNS TRIGGER AS $$
DECLARE
    r RECORD;
    vault_key TEXT;
    normalized_log_semester TEXT;
    edge_url TEXT := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule';
BEGIN
    -- 1. Only act if the scraper finished successfully
    IF (NEW.status = 'completed' OR NEW.status = 'success') THEN
        
        -- 2. Normalize the semester from the log (e.g., 'Summer 2026' -> 'summer2026')
        normalized_log_semester := lower(regexp_replace(NEW.semester, '[\s\-_]+', '', 'g'));

        -- 3. Fetch Service Key securely from the Vault
        SELECT decrypted_secret INTO vault_key 
        FROM vault.decrypted_secrets 
        WHERE name = 'SUPA_SERVICE_ROLE_KEY' 
        LIMIT 1;

        -- Exit early if no key found (safety)
        IF vault_key IS NULL THEN 
            RAISE WARNING 'handle_scraper_log_trigger: SUPA_SERVICE_ROLE_KEY not found in vault.';
            RETURN NEW; 
        END IF;

        -- 4. Find all matching tracks and trigger sync
        -- Option A: Only sync CURRENT semesters
        FOR r IN 
            SELECT track FROM public.active_semester 
            WHERE lower(regexp_replace(current_semester_code, '[\s\-_]+', '', 'g')) = normalized_log_semester
        LOOP
            RAISE NOTICE 'Triggering bulk sync for track: %', r.track;
            
            -- Fire the Edge Function for each matching track
            PERFORM net.http_post(
                url := edge_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || vault_key
                ),
                body := jsonb_build_object(
                    'track', r.track,
                    'triggered_by', 'automated_scraper_sync',
                    'log_id', NEW.id,
                    'semester_matched', NEW.semester
                )
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply the trigger to the scraper_logs table
DROP TRIGGER IF EXISTS on_scraper_log_completed ON public.scraper_logs;
CREATE TRIGGER on_scraper_log_completed
    AFTER INSERT OR UPDATE OF status ON public.scraper_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_scraper_log_trigger();
