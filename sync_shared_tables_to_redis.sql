-- Upstash Redis Set Helper & Triggers using pg_net (jsonb body)
CREATE OR REPLACE FUNCTION public.upstash_redis_set(key_name TEXT, json_val JSONB)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_url TEXT;
  v_token TEXT;
  v_req_id BIGINT;
BEGIN
  SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'UPSTASH_REDIS_URL' LIMIT 1;
  SELECT decrypted_secret INTO v_token FROM vault.decrypted_secrets WHERE name = 'UPSTASH_REDIS_TOKEN' LIMIT 1;

  IF v_url IS NULL OR v_token IS NULL THEN
    RAISE WARNING 'Upstash Redis credentials not found in vault';
    RETURN NULL;
  END IF;

  SELECT net.http_post(
    url := v_url || '/set/' || key_name,
    body := json_val,
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || v_token,
      'Content-Type', 'application/json'
    )
  ) INTO v_req_id;

  RETURN v_req_id;
END;
$$;

-- 1. active_semester
CREATE OR REPLACE FUNCTION public.fn_sync_active_semester_to_redis()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM public.upstash_redis_set(
    'global:active_semester:' || NEW.track::text,
    to_jsonb(NEW)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_active_semester_to_redis ON public.active_semester;
CREATE TRIGGER trg_sync_active_semester_to_redis
AFTER INSERT OR UPDATE ON public.active_semester
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_active_semester_to_redis();

-- 2. semesters
CREATE OR REPLACE FUNCTION public.fn_sync_semesters_to_redis()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_all_semesters jsonb;
BEGIN
  SELECT jsonb_agg(to_jsonb(s)) INTO v_all_semesters FROM public.semesters s;
  PERFORM public.upstash_redis_set('global:semesters', COALESCE(v_all_semesters, '[]'::jsonb));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_semesters_to_redis ON public.semesters;
CREATE TRIGGER trg_sync_semesters_to_redis
AFTER INSERT OR UPDATE OR DELETE ON public.semesters
FOR EACH STATEMENT
EXECUTE FUNCTION public.fn_sync_semesters_to_redis();

-- 3. calendar_fall2026
CREATE OR REPLACE FUNCTION public.fn_sync_calendar_fall2026_to_redis()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_cal jsonb;
BEGIN
  SELECT jsonb_agg(to_jsonb(c)) INTO v_cal FROM public.calendar_fall2026 c;
  PERFORM public.upstash_redis_set('global:calendar:fall2026', COALESCE(v_cal, '[]'::jsonb));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_calendar_fall2026_to_redis ON public.calendar_fall2026;
CREATE TRIGGER trg_sync_calendar_fall2026_to_redis
AFTER INSERT OR UPDATE OR DELETE ON public.calendar_fall2026
FOR EACH STATEMENT
EXECUTE FUNCTION public.fn_sync_calendar_fall2026_to_redis();

-- 4. calendar_fall2026_phrm_llb
CREATE OR REPLACE FUNCTION public.fn_sync_calendar_fall2026_phrm_to_redis()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_cal jsonb;
BEGIN
  SELECT jsonb_agg(to_jsonb(c)) INTO v_cal FROM public.calendar_fall2026_phrm_llb c;
  PERFORM public.upstash_redis_set('global:calendar:fall2026:phrm_llb', COALESCE(v_cal, '[]'::jsonb));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_calendar_fall2026_phrm_to_redis ON public.calendar_fall2026_phrm_llb;
CREATE TRIGGER trg_sync_calendar_fall2026_phrm_to_redis
AFTER INSERT OR UPDATE OR DELETE ON public.calendar_fall2026_phrm_llb
FOR EACH STATEMENT
EXECUTE FUNCTION public.fn_sync_calendar_fall2026_phrm_to_redis();
