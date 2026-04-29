-- Add missing unique indexes used by app ON CONFLICT upserts

-- completed_courses uses ON CONFLICT (user_id, course_code, semester_code)
WITH ranked AS (
  SELECT
    ctid,
    row_number() OVER (
      PARTITION BY user_id, course_code, semester_code
      ORDER BY created_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM public.completed_courses
)
DELETE FROM public.completed_courses c
USING ranked r
WHERE c.ctid = r.ctid
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS uq_completed_courses_user_course_semester
  ON public.completed_courses (user_id, course_code, semester_code);

-- semester_summaries uses ON CONFLICT (user_id, semester_code)
WITH ranked AS (
  SELECT
    ctid,
    row_number() OVER (
      PARTITION BY user_id, semester_code
      ORDER BY updated_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM public.semester_summaries
)
DELETE FROM public.semester_summaries s
USING ranked r
WHERE s.ctid = r.ctid
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS uq_semester_summaries_user_semester
  ON public.semester_summaries (user_id, semester_code);
