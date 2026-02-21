-- Add upcoming_semester_start_date to active_semester
ALTER TABLE active_semester ADD COLUMN IF NOT EXISTS upcoming_semester_start_date DATE;

-- Update column comments for clarity
COMMENT ON COLUMN active_semester.upcoming_semester_start_date IS 'First day of classes for the next_semester_code';
COMMENT ON COLUMN active_semester.grade_submission_start IS 'When results entry becomes available to users';
COMMENT ON COLUMN active_semester.grade_submission_deadline IS 'When the app forces results entry and transitions profile';
