-- Ensure enrollments upsert target exists for app onboarding save flow
-- App uses ON CONFLICT (user_id, course_code, semester_code)

-- Deduplicate any existing rows before adding uniqueness
WITH ranked AS (
  SELECT
    ctid,
    row_number() OVER (
      PARTITION BY user_id, course_code, semester_code
      ORDER BY updated_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM public.enrollments
)
DELETE FROM public.enrollments e
USING ranked r
WHERE e.ctid = r.ctid
  AND r.rn > 1;

-- Create unique index used by ON CONFLICT
CREATE UNIQUE INDEX IF NOT EXISTS uq_enrollments_user_course_semester
  ON public.enrollments (user_id, course_code, semester_code);
