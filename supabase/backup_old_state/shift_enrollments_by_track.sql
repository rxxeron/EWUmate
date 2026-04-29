-- Track-Safe Enrollment Shift Function
-- Ensures that when we switch Tri-Semester, we don't accidentally switch Bi-Semester students
-- even if they share the same semester_code (e.g. Fall2026).

CREATE OR REPLACE FUNCTION shift_enrollments_by_track(
    p_track TEXT, 
    p_semester_code TEXT, 
    p_new_status TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE enrollments e
    SET status = p_new_status,
        grade = NULL
    FROM profiles p
    WHERE e.user_id = p.id
    AND p.track = p_track
    AND e.semester_code = p_semester_code
    AND e.status = 'upcoming';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
