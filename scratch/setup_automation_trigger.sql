-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Function that pulls the key from the vault and triggers the sync
CREATE OR REPLACE FUNCTION public.handle_scraper_log_trigger()
RETURNS TRIGGER AS $$
DECLARE
    target_track TEXT;
    edge_url TEXT := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule';
    vault_key TEXT;
BEGIN
    -- 1. Only act if the scraper finished successfully
    IF (NEW.status = 'completed' OR NEW.status = 'success') THEN
        
        -- 2. Fetch the Service Role Key securely from the Vault
        SELECT decrypted_secret INTO vault_key 
        FROM vault.decrypted_secrets 
        WHERE name = 'SUPA_SERVICE_ROLE_KEY' 
        LIMIT 1;

        -- 3. Check if this semester belongs to an active track (Tri/Bi)
        SELECT track INTO target_track 
        FROM active_semester 
        WHERE current_semester_code = NEW.semester_code 
        AND is_active = true
        LIMIT 1;

        -- 4. If everything aligns, trigger the bulk sync
        IF target_track IS NOT NULL AND vault_key IS NOT NULL THEN
            PERFORM net.http_post(
                url := edge_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || vault_key
                ),
                body := jsonb_build_object(
                    'track', target_track,
                    'triggered_by', 'scraper_log_auto_trigger'
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
