-- Enable pg_cron extension for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create function to switch semester (called once on scheduled date)
CREATE OR REPLACE FUNCTION switch_to_next_semester()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  switching_config JSONB;
  next_semester TEXT;
BEGIN
  -- Get semester switching configuration
  SELECT value INTO switching_config
  FROM config
  WHERE key = 'semester_switching';
  
  IF switching_config IS NULL THEN
    RAISE NOTICE 'No semester switching configuration found';
    RETURN;
  END IF;
  
  -- Extract next semester
  next_semester := switching_config->>'nextSemester';
  
  IF next_semester IS NULL THEN
    RAISE NOTICE 'No next semester found in config';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Switching semester to: %', next_semester;
  
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
  
  RAISE NOTICE '✅ Semester switched to: %', next_semester;
END;
$$;

-- Function to schedule the semester switch (called after calendar upload)
CREATE OR REPLACE FUNCTION schedule_semester_switch(switch_date TIMESTAMPTZ, next_sem TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  job_name TEXT;
  cron_schedule TEXT;
BEGIN
  -- Generate unique job name
  job_name := 'switch-to-' || REPLACE(LOWER(next_sem), ' ', '-');
  
  -- Remove existing job with same name if exists
  PERFORM cron.unschedule(job_name);
  
  -- Extract datetime components for cron format: minute hour day month *
  -- Example: '12 0 12 5 *' for May 12 at 00:12 (midnight + 12 seconds offset)
  cron_schedule := to_char(switch_date, 'MI HH24 DD MM') || ' *';
  
  -- Schedule one-time job
  PERFORM cron.schedule(
    job_name,
    cron_schedule,
    $cmd$SELECT switch_to_next_semester();$cmd$
  );
  
  RETURN 'Scheduled semester switch to ' || next_sem || ' at ' || switch_date::TEXT;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION switch_to_next_semester() TO service_role;
GRANT EXECUTE ON FUNCTION schedule_semester_switch(TIMESTAMPTZ, TEXT) TO service_role;

-- Create trigger function to auto-schedule when config is updated
CREATE OR REPLACE FUNCTION auto_schedule_semester_switch()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  next_semester TEXT;
  switch_date TIMESTAMPTZ;
  status TEXT;
  result TEXT;
BEGIN
  -- Only proceed if this is the semester_switching config
  IF NEW.key = 'semester_switching' THEN
    next_semester := NEW.value->>'nextSemester';
    switch_date := (NEW.value->>'switchDate')::TIMESTAMPTZ;
    status := NEW.value->>'status';
    
    -- Only schedule if status is 'scheduled' and we have valid data
    IF status = 'scheduled' AND next_semester IS NOT NULL AND switch_date IS NOT NULL THEN
      -- Schedule the cron job
      result := schedule_semester_switch(switch_date, next_semester);
      RAISE NOTICE '%', result;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on config table
DROP TRIGGER IF EXISTS trigger_auto_schedule_semester_switch ON config;
CREATE TRIGGER trigger_auto_schedule_semester_switch
  AFTER INSERT OR UPDATE ON config
  FOR EACH ROW
  EXECUTE FUNCTION auto_schedule_semester_switch();

COMMENT ON FUNCTION switch_to_next_semester() IS 'Switches current semester to next semester (called on scheduled date)';
COMMENT ON FUNCTION schedule_semester_switch(TIMESTAMPTZ, TEXT) IS 'Schedules one-time cron job for semester switch';
COMMENT ON FUNCTION auto_schedule_semester_switch() IS 'Trigger function that auto-schedules semester switch when calendar is uploaded';
