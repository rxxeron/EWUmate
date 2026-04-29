-- Function to purge notifications when a class is cancelled
CREATE OR REPLACE FUNCTION purge_cancelled_alerts()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.type = 'cancel') THEN
        -- Delete pending alerts for this user, course, and date
        -- Alert keys are formatted as: c_{m}m:{courseCode}:{dateStr}
        DELETE FROM public.scheduled_alerts
        WHERE user_id = NEW.user_id
          AND is_dispatched = false
          AND alert_key LIKE 'c_%m:' || NEW.course_code || ':' || NEW.date || '%';
          
        RAISE NOTICE 'Purged alerts for user % course % on %', NEW.user_id, NEW.course_code, NEW.date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to run on every insert into schedule_exceptions
DROP TRIGGER IF EXISTS tr_purge_cancelled_alerts ON public.schedule_exceptions;
CREATE TRIGGER tr_purge_cancelled_alerts
AFTER INSERT ON public.schedule_exceptions
FOR EACH ROW
EXECUTE FUNCTION purge_cancelled_alerts();
