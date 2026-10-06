-- Migration: Add course_metadata and courses_fall2026 Redis Sync Triggers

-- 1. Sync course_metadata to Redis
CREATE OR REPLACE FUNCTION public.fn_sync_course_metadata_to_redis()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_meta jsonb;
BEGIN
  SELECT jsonb_agg(to_jsonb(c)) INTO v_meta FROM public.course_metadata c;
  PERFORM public.upstash_redis_set('global:course_metadata', COALESCE(v_meta, '[]'::jsonb));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_course_metadata_to_redis ON public.course_metadata;
CREATE TRIGGER trg_sync_course_metadata_to_redis
AFTER INSERT OR UPDATE OR DELETE ON public.course_metadata
FOR EACH STATEMENT
EXECUTE FUNCTION public.fn_sync_course_metadata_to_redis();

-- 2. Sync courses_fall2026 to Redis
CREATE OR REPLACE FUNCTION public.fn_sync_courses_fall2026_to_redis()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_courses jsonb;
BEGIN
  SELECT jsonb_agg(to_jsonb(c)) INTO v_courses FROM public.courses_fall2026 c;
  PERFORM public.upstash_redis_set('global:courses:fall2026', COALESCE(v_courses, '[]'::jsonb));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_courses_fall2026_to_redis ON public.courses_fall2026;
CREATE TRIGGER trg_sync_courses_fall2026_to_redis
AFTER INSERT OR UPDATE OR DELETE ON public.courses_fall2026
FOR EACH STATEMENT
EXECUTE FUNCTION public.fn_sync_courses_fall2026_to_redis();
