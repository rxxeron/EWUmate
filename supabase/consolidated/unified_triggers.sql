-- Unified Triggers Strategy
-- Consolidates timestamp management and cross-table synchronization

-- 1. Optimized Timestamp Handler
CREATE OR REPLACE FUNCTION public.trg_set_timestamp()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Applying Timestamp Trigger to All Relevant Tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at' 
          AND table_schema = 'public'
          AND table_name NOT LIKE 'pg_%'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_timestamp_on_%I ON public.%I', t, t);
        EXECUTE format('CREATE TRIGGER trg_set_timestamp_on_%I BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.trg_set_timestamp()', t, t);
    END LOOP;
END;
$$;

-- 3. Core Enrollment Trigger
DROP TRIGGER IF EXISTS trg_enrollment_sync ON public.enrollments;
CREATE TRIGGER trg_enrollment_sync
AFTER INSERT OR UPDATE OR DELETE ON public.enrollments
FOR EACH ROW EXECUTE FUNCTION public.fn_sync_enrollments();

-- 4. Semester Switch Trigger
CREATE OR REPLACE FUNCTION public.fn_on_semester_switch()
RETURNS trigger AS $$
BEGIN
    -- This would trigger a bulk sync when the active semester is changed
    PERFORM public.sync_all_profiles(NEW.track::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_on_semester_switch ON public.active_semester;
CREATE TRIGGER trg_on_semester_switch
AFTER UPDATE OF current_semester_code ON public.active_semester
FOR EACH ROW EXECUTE FUNCTION public.fn_on_semester_switch();
