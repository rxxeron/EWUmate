-- Safe Security & Performance Migration
-- 1. Secure faculty_assignments with RLS and proper policies
ALTER TABLE public.faculty_assignments ENABLE ROW LEVEL SECURITY;

-- Allow everyone (anon + authenticated) to read faculty assignments
DROP POLICY IF EXISTS "Public read faculty_assignments" ON public.faculty_assignments;
CREATE POLICY "Public read faculty_assignments"
ON public.faculty_assignments
FOR SELECT
TO public
USING (true);

-- Allow authenticated users (students syncing portal) to insert/upsert faculty assignments
DROP POLICY IF EXISTS "Authenticated users can insert faculty_assignments" ON public.faculty_assignments;
CREATE POLICY "Authenticated users can insert faculty_assignments"
ON public.faculty_assignments
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update faculty_assignments" ON public.faculty_assignments;
CREATE POLICY "Authenticated users can update faculty_assignments"
ON public.faculty_assignments
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow service_role / master admin full access
DROP POLICY IF EXISTS "Service role full access on faculty_assignments" ON public.faculty_assignments;
CREATE POLICY "Service role full access on faculty_assignments"
ON public.faculty_assignments
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 2. Revoke anon/public execution on internal triggers & redis helper
REVOKE EXECUTE ON FUNCTION public.upstash_redis_set(text, jsonb) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.fn_sync_active_semester_to_redis() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.fn_sync_semesters_to_redis() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.fn_sync_calendar_fall2026_to_redis() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.fn_sync_calendar_fall2026_phrm_to_redis() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.fn_sync_course_metadata_to_redis() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.fn_sync_courses_fall2026_to_redis() FROM anon, authenticated, public;

-- Grant execution to postgres and service_role for internal use
GRANT EXECUTE ON FUNCTION public.upstash_redis_set(text, jsonb) TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.fn_sync_active_semester_to_redis() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.fn_sync_semesters_to_redis() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.fn_sync_calendar_fall2026_to_redis() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.fn_sync_calendar_fall2026_phrm_to_redis() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.fn_sync_course_metadata_to_redis() TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.fn_sync_courses_fall2026_to_redis() TO postgres, service_role;
