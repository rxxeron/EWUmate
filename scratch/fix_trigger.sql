-- Fix normalization logic to be robust against spaces and casing
CREATE OR REPLACE FUNCTION public.handle_scraper_log_trigger()
RETURNS TRIGGER AS $$
DECLARE
    found_track TEXT;
    vault_key TEXT;
    edge_url TEXT := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule';
BEGIN
    -- Only fire on success
    IF (NEW.status = 'completed' OR NEW.status = 'success') THEN
        
        -- Normalize both sides by removing spaces, underscores, hyphens and lowercasing
        SELECT track INTO found_track 
        FROM public.active_semester 
        WHERE lower(replace(replace(replace(current_semester_code, ' ', ''), '_', ''), '-', '')) 
            = lower(replace(replace(replace(NEW.semester, ' ', ''), '_', ''), '-', ''))
        LIMIT 1;

        IF found_track IS NOT NULL THEN
            -- Fetch service key from Vault
            SELECT decrypted_secret INTO vault_key 
            FROM vault.decrypted_secrets 
            WHERE name = 'SUPA_SERVICE_ROLE_KEY' 
            LIMIT 1;

            IF vault_key IS NOT NULL THEN
                PERFORM net.http_post(
                    url := edge_url,
                    headers := jsonb_build_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || vault_key
                    ),
                    body := jsonb_build_object(
                        'semester', NEW.semester,
                        'triggered_by', 'db_trigger_scraper_log',
                        'log_id', NEW.id
                    )
                );
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
