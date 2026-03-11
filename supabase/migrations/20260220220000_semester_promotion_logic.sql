-- Migration: Semester Promotion Logic
-- Add current_semester_start_date to active_semester
ALTER TABLE active_semester ADD COLUMN IF NOT EXISTS current_semester_start_date DATE;
ALTER TABLE active_semester ADD COLUMN IF NOT EXISTS switch_date DATE;

-- Function to promote next semester to current
CREATE OR REPLACE FUNCTION promote_active_semester()
RETURNS void AS $$
BEGIN
    UPDATE active_semester
    SET 
        current_semester = next_semester,
        current_semester_code = next_semester_code,
        current_semester_start_date = upcoming_semester_start_date,
        next_semester = NULL,
        next_semester_code = NULL,
        upcoming_semester_start_date = NULL,
        switch_date = NULL,
        grade_submission_start = NULL,
        grade_submission_deadline = NULL,
        updated_at = NOW()
    WHERE next_semester_code IS NOT NULL 
      AND (switch_date IS NULL OR switch_date <= CURRENT_DATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update column comments
COMMENT ON COLUMN active_semester.current_semester_start_date IS 'First day of classes for the current semester';
COMMENT ON COLUMN active_semester.switch_date IS 'Date when the next_semester becomes current';
