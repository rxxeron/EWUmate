-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Robust Scraper Log Trigger Function (Schedule Sync + Automated Snapshot)
CREATE OR REPLACE FUNCTION public.handle_scraper_log_trigger()
RETURNS TRIGGER AS $$
DECLARE
    r RECORD;
    vault_key TEXT;
    azure_key TEXT;
    normalized_log_semester TEXT;
    edge_url TEXT := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule';
    snapshot_url TEXT := 'https://ewumate-parser.azurewebsites.net/api/generate_snapshot';
BEGIN
    -- 1. Only act if the scraper finished successfully
    IF (NEW.status = 'completed' OR NEW.status = 'success') THEN
        
        -- 2. Normalize the semester from the log (e.g., 'Summer 2026' -> 'summer2026')
        normalized_log_semester := lower(regexp_replace(NEW.semester, '[\s\-_]+', '', 'g'));

        -- 3. Fetch Keys securely from the Vault
        SELECT decrypted_secret INTO vault_key 
        FROM vault.decrypted_secrets 
        WHERE name = 'SUPA_SERVICE_ROLE_KEY' 
        LIMIT 1;

        SELECT decrypted_secret INTO azure_key 
        FROM vault.decrypted_secrets 
        WHERE name = 'AZURE_FUNCTION_KEY' 
        LIMIT 1;

        -- 4. Find all matching tracks and trigger sync
        FOR r IN 
            SELECT track FROM public.active_semester 
            WHERE lower(regexp_replace(current_semester_code, '[\s\-_]+', '', 'g')) = normalized_log_semester
        LOOP
            IF vault_key IS NOT NULL THEN
                PERFORM net.http_post(
                    url := edge_url,
                    headers := jsonb_build_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || vault_key
                    ),
                    body := jsonb_build_object(
                        'track', r.track,
                        'triggered_by', 'automated_scraper_sync',
                        'log_id', NEW.id
                    )
                );
            END IF;
        END LOOP;

        -- 5. Trigger automated snapshot (Only once per log, regardless of tracks)
        -- This moves the snapshot logic out of the main scraper process to avoid timeouts
        IF azure_key IS NOT NULL THEN
            PERFORM net.http_post(
                url := snapshot_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'x-functions-key', azure_key
                ),
                body := jsonb_build_object(
                    'semester', NEW.semester,
                    'triggered_by', 'db_trigger_scraper_log'
                )
            );
        END IF;

    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply the trigger
DROP TRIGGER IF EXISTS on_scraper_log_completed ON public.scraper_logs;
CREATE TRIGGER on_scraper_log_completed
    AFTER INSERT OR UPDATE OF status ON public.scraper_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_scraper_log_trigger();
