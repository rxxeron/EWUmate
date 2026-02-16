-- ========================================
-- AUTOMATIC SEMESTER SWITCHING SETUP
-- ========================================
-- This sets up daily checks to automatically switch the current semester
-- based on the academic calendar's "University Reopens for..." date

-- Step 1: Create the switching function
CREATE OR REPLACE FUNCTION check_and_switch_semester()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  switching_config JSONB;
  next_semester TEXT;
  switch_date TIMESTAMPTZ;
  status TEXT;
  current_semester TEXT;
BEGIN
  -- Get semester switching configuration
  SELECT value INTO switching_config
  FROM config
  WHERE key = 'semester_switching';
  
  IF switching_config IS NULL THEN
    RAISE NOTICE 'No semester switching configuration found';
    RETURN;
  END IF;
  
  -- Extract values from config
  next_semester := switching_config->>'nextSemester';
  switch_date := (switching_config->>'switchDate')::TIMESTAMPTZ;
  status := switching_config->>'status';
  
  -- Check if switch is pending and date has passed
  IF status = 'pending' AND switch_date <= NOW() THEN
    -- Get current semester
    SELECT value::TEXT INTO current_semester
    FROM config
    WHERE key = 'currentSemester';
    
    -- Remove quotes from JSON string
    current_semester := TRIM(BOTH '"' FROM current_semester);
    
    RAISE NOTICE 'Switching semester from % to %', current_semester, next_semester;
    
    -- Update current semester
    UPDATE config
    SET value = to_jsonb(next_semester),
        updated_at = NOW()
    WHERE key = 'currentSemester';
    
    -- Mark switch as completed
    UPDATE config
    SET value = jsonb_set(
      value,
      '{status}',
      '"completed"'::jsonb
    ),
    value = jsonb_set(
      value,
      '{completedAt}',
      to_jsonb(NOW()::TEXT)
    ),
    updated_at = NOW()
    WHERE key = 'semester_switching';
    
    RAISE NOTICE '✅ Semester switched to %', next_semester;
  END IF;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_and_switch_semester() TO service_role;
GRANT EXECUTE ON FUNCTION check_and_switch_semester() TO anon;
GRANT EXECUTE ON FUNCTION check_and_switch_semester() TO authenticated;

-- ========================================
-- SETUP CRON JOB (Run in Supabase Dashboard)
-- ========================================
-- Go to Database → Cron Jobs → Create a new cron job:
-- Name: check-semester-switch
-- Schedule: 0 18 * * * (runs at 18:00 UTC = 00:00 Dhaka time)
-- Command: SELECT check_and_switch_semester();

-- OR run this if pg_cron is enabled:
-- SELECT cron.schedule(
--   'check-semester-switch',
--   '0 18 * * *',
--   $$SELECT check_and_switch_semester();$$
-- );

-- ========================================
-- TEST THE FUNCTION MANUALLY
-- ========================================
-- You can test the function anytime by running:
-- SELECT check_and_switch_semester();

-- ========================================
-- VERIFY SETUP
-- ========================================
-- Check current semester:
-- SELECT * FROM config WHERE key = 'currentSemester';

-- Check pending switch:
-- SELECT * FROM config WHERE key = 'semester_switching';
