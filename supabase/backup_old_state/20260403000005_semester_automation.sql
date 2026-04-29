-- 1. Execute Function that handles the actual switch and cleans up its own cron job
CREATE OR REPLACE FUNCTION public.execute_semester_switch(p_current_sem text, p_track text, p_job_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    lower_sem text := lower(p_current_sem);
    year int;
    next_semester_code text;
    future_semester_code text;
BEGIN
    -- Extract Year
    year := substring(lower_sem from '\d{4}')::int;
    
    -- Calculate paths
    IF p_track = 'bi_semester' THEN
        IF lower_sem LIKE '%spring%' THEN 
            next_semester_code := 'Fall' || year;
            future_semester_code := 'Spring' || (year + 1);
        ELSE 
            next_semester_code := 'Spring' || (year + 1);
            future_semester_code := 'Fall' || (year + 1);
        END IF;
    ELSE
        IF lower_sem LIKE '%spring%' THEN 
            next_semester_code := 'Summer' || year;
            future_semester_code := 'Fall' || year;
        ELSIF lower_sem LIKE '%summer%' THEN 
            next_semester_code := 'Fall' || year;
            future_semester_code := 'Spring' || (year + 1);
        ELSE 
            next_semester_code := 'Spring' || (year + 1);
            future_semester_code := 'Summer' || (year + 1);
        END IF;
    END IF;

    -- 1. Update Active Semester
    UPDATE public.active_semester 
    SET current_semester_code = next_semester_code,
        next_semester_code = future_semester_code,
        updated_at = now()
    WHERE track = p_track;

    -- 2. Shift Enrollments (Mark ongoing as completed for this track)
    PERFORM public.shift_enrollments_by_track(p_track, next_semester_code, 'completed');

    -- 3. Cleanup: Drop exact cron job so it doesn't fire next year
    PERFORM cron.unschedule(p_job_name);

END;
$$;


-- 2. Trigger Function that watches Calendar inserts and schedules the pg_cron
CREATE OR REPLACE FUNCTION public.fn_auto_schedule_semester_switch()
RETURNS TRIGGER AS $$
DECLARE
    cron_expr text;
    job_name text;
    event_day int;
    event_month int;
    v_track text;
    sem text;
BEGIN
    -- We only care when the critical calendar dates are inserted via the PDF parsing
    IF NEW.title ILIKE '%Classes Begin%' OR NEW.title ILIKE '%University Reopens%' OR NEW.title ILIKE '%Classes begin%' THEN
        
        -- Identify track based on table name dynamically (TG_TABLE_NAME)
        IF TG_TABLE_NAME LIKE '%_phrm_llb' THEN
            v_track := 'bi_semester';
        ELSE
            v_track := 'tri_semester';
        END IF;

        -- Extract base semester code, e.g. "spring2026" from "calendar_spring2026_phrm_llb"
        sem := replace(replace(TG_TABLE_NAME, 'calendar_', ''), '_phrm_llb', '');
        
        -- Get the Day and Month from event_date for the CRON string
        event_day := extract(day from NEW.event_date::date);
        event_month := extract(month from NEW.event_date::date);
        
        -- Build the ONCE-A-YEAR cron expression specifically for midnight
        -- format: MIN HOUR DAY MONTH *
        cron_expr := format('0 0 %s %s *', event_day, event_month);
        
        job_name := 'switch_' || v_track || '_' || sem;

        -- Unschedule existing job if it already exists (in case admin uploads PDF again)
        PERFORM cron.unschedule(job_name);

        -- Schedule the job cleanly
        -- It calls execute_semester_switch which will self-destruct the job afterwards
        PERFORM cron.schedule(job_name, cron_expr, 
            format('SELECT public.execute_semester_switch(%L, %L, %L);', sem, v_track, job_name)
        );

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
