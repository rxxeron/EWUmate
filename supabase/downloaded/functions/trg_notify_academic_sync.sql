CREATE OR REPLACE FUNCTION public.trg_notify_academic_sync()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        PERFORM
          net.http_post(
            url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-academic-stats',
            headers := jsonb_build_object(
              'Content-Type', 'application/json',
              'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'
            ),
            body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
          );
        RETURN NULL;
    END;
    $function$
;
