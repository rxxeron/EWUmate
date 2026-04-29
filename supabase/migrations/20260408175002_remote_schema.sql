-- MASTER SCHEMA SYNC: 2026-04-08 17:50:02.565249
-- This file contains the consolidated production state.

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "supabase_vault";
CREATE EXTENSION IF NOT EXISTS "pg_graphql";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- 2. TABLES & COLUMNS

CREATE TABLE IF NOT EXISTS public."active_semester" (
  "track" USER-DEFINED NOT NULL,
  "current_semester_code" text,
  "next_semester_code" text,
  "classes_start_date" date,
  "advising_start_date" date,
  "advising_end_date" date,
  "final_exam_start" date,
  "final_exam_end" date,
  "grade_submission_start" date,
  "grade_submission_deadline" date,
  "semester_switch_date" date,
  "upcoming_classes_start_date" date,
  "updated_at" timestamp with time zone DEFAULT now(),
  "classes_end_date" date
);

CREATE TABLE IF NOT EXISTS public."admin_users" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid NOT NULL,
  "email" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public."app_config" (
  "key" text NOT NULL,
  "value" jsonb NOT NULL,
  "latest_version" text,
  "download_url" text
);

CREATE TABLE IF NOT EXISTS public."calendar_spring2026" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "event_date" date NOT NULL,
  "title" text NOT NULL,
  "type" text,
  "target_track" USER-DEFINED DEFAULT 'tri_semester'::academic_track,
  "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."calendar_spring2026_phrm_llb" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "event_date" date NOT NULL,
  "title" text NOT NULL,
  "type" text,
  "target_track" USER-DEFINED DEFAULT 'bi_semester'::academic_track,
  "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."completed_courses" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid,
  "course_code" text NOT NULL,
  "semester_code" text NOT NULL,
  "grade" text NOT NULL,
  "grade_point" numeric DEFAULT 0.0,
  "credits" numeric NOT NULL,
  "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."course_metadata" (
  "code" text NOT NULL,
  "name" text NOT NULL,
  "credit_val" numeric NOT NULL,
  "equivalent_code" text
);

CREATE TABLE IF NOT EXISTS public."courses_spring2026" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "course_code" text,
  "original_code" text,
  "section_number" text,
  "faculty_initials" text,
  "capacity" text,
  "schedule_data" jsonb,
  "course_name" text,
  "credit_val" numeric
);

CREATE TABLE IF NOT EXISTS public."courses_summer2026" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "course_code" text,
  "original_code" text,
  "section_number" text,
  "faculty_initials" text,
  "capacity" text,
  "schedule_data" jsonb,
  "course_name" text,
  "credit_val" numeric
);

CREATE TABLE IF NOT EXISTS public."enrollments" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid,
  "semester_code" text,
  "course_code" text,
  "section_id" uuid,
  "status" USER-DEFINED DEFAULT 'enrolled'::enrollment_status,
  "grade" text,
  "grade_points" numeric,
  "updated_at" timestamp with time zone DEFAULT now(),
  "section" text
);

CREATE TABLE IF NOT EXISTS public."fcm_tokens" (
  "token" text NOT NULL,
  "user_id" uuid,
  "platform" text,
  "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."feedbacks" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid,
  "message" text NOT NULL,
  "status" character varying(50) DEFAULT 'pending'::character varying,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."grade_scale" (
  "grade" text NOT NULL,
  "point" numeric NOT NULL,
  "min_score" numeric,
  "description" text,
  "policy" text DEFAULT 'modern'::text
);

CREATE TABLE IF NOT EXISTS public."notifications" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid,
  "type" USER-DEFINED DEFAULT 'system'::notification_type,
  "title" text NOT NULL,
  "body" text NOT NULL,
  "trigger_at" timestamp with time zone DEFAULT now(),
  "is_dispatched" boolean DEFAULT true,
  "is_read" boolean DEFAULT false,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now(),
  "alert_key" text
);

CREATE TABLE IF NOT EXISTS public."parsing_logs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "file_name" text NOT NULL,
  "file_type" text NOT NULL,
  "status" text DEFAULT 'processing'::text NOT NULL,
  "metrics" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."profiles" (
  "id" uuid NOT NULL,
  "student_id" text,
  "full_name" text NOT NULL,
  "nickname" text,
  "program_code" text,
  "admitted_semester" text,
  "cgpa" numeric DEFAULT 0.0,
  "total_credits_earned" numeric DEFAULT 0.0,
  "photo_url" text,
  "onboarding_status" text DEFAULT 'pending'::text,
  "updated_at" timestamp with time zone DEFAULT now(),
  "created_at" timestamp with time zone DEFAULT now(),
  "semester_type" text DEFAULT 'tri'::text,
  "department_name" text,
  "scholarship_status" text,
  "program_name" text,
  "track" text,
  "enrolled_sections" ARRAY DEFAULT '{}'::text[],
  "enrolled_sections_next" ARRAY DEFAULT '{}'::text[],
  "past_history" jsonb DEFAULT '[]'::jsonb,
  "enrolled_credits" numeric DEFAULT 0.0,
  "enrolled_credits_next" numeric DEFAULT 0.0,
  "total_courses_completed" integer DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public."programs" (
  "program_code" text NOT NULL,
  "name" text NOT NULL,
  "track" USER-DEFINED NOT NULL,
  "total_degree_credits" numeric DEFAULT 130 NOT NULL,
  "department_name" text
);

CREATE TABLE IF NOT EXISTS public."schedule_exceptions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "type" text NOT NULL,
  "date" date NOT NULL,
  "course_code" text NOT NULL,
  "course_name" text,
  "start_time" text,
  "end_time" text,
  "room" text,
  "metadata" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "faculty" text
);

CREATE TABLE IF NOT EXISTS public."schedule_generations" (
  "id" uuid NOT NULL,
  "user_id" text,
  "semester" text,
  "courses" jsonb,
  "filters" jsonb,
  "combinations" jsonb,
  "status" text,
  "count" integer,
  "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."scholarship_policies" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "department_code" text,
  "effective_from_semester" text,
  "effective_until_semester" text,
  "min_yearly_credits" numeric NOT NULL,
  "merit_cgpa_min" numeric NOT NULL,
  "deans_cgpa_min" numeric NOT NULL,
  "medha_cgpa_min" numeric NOT NULL,
  "merit_cgpa_max" numeric DEFAULT 4.00,
  "deans_cgpa_max" numeric,
  "medha_cgpa_max" numeric,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "degree_credits_required" numeric DEFAULT 130.0
);

CREATE TABLE IF NOT EXISTS public."semester_analytics" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid NOT NULL,
  "semester_code" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()),
  "updated_at" timestamp with time zone DEFAULT timezone('utc'::text, now()),
  "live_sgpa" numeric DEFAULT 0.00,
  "live_cgpa" numeric DEFAULT 0.00,
  "target" numeric DEFAULT 0.00,
  "required_credit" numeric DEFAULT 0.00,
  "completed_credit" numeric DEFAULT 0.00,
  "taken_in_this_sem" numeric DEFAULT 0.00,
  "credits_left" numeric DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS public."semester_course_marks" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid NOT NULL,
  "semester_code" text NOT NULL,
  "course_code" text NOT NULL,
  "course_name" text,
  "section" text,
  "quiz_strategy" text DEFAULT 'bestN'::text,
  "quiz_n" integer DEFAULT 2,
  "short_quiz_n" integer DEFAULT 2,
  "dist_mid" real DEFAULT 30.0,
  "dist_final" real DEFAULT 40.0,
  "dist_quiz" real DEFAULT 10.0,
  "dist_short_quiz" real,
  "dist_assignment" real,
  "dist_presentation" real,
  "dist_viva" real,
  "dist_attendance" real,
  "dist_lab" real,
  "obt_mid" real,
  "obt_final" real,
  "obt_assignment" real,
  "obt_presentation" real,
  "obt_viva" real,
  "obt_attendance" real,
  "obt_lab" real,
  "obt_quizzes" ARRAY DEFAULT '{}'::real[],
  "obt_short_quizzes" ARRAY DEFAULT '{}'::real[],
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()),
  "updated_at" timestamp with time zone DEFAULT timezone('utc'::text, now()),
  "grade_goal" text,
  "dist_term_paper" real,
  "dist_class_performance" real,
  "obt_term_paper" real,
  "obt_class_performance" real,
  "marks_data" jsonb,
  "dist_project" real,
  "obt_project" real,
  "dist_optional_1" double precision,
  "obt_optional_1" double precision,
  "dist_optional_2" double precision,
  "obt_optional_2" double precision,
  "dist_optional_3" double precision,
  "obt_optional_3" double precision
);

CREATE TABLE IF NOT EXISTS public."semester_course_stats" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "semester" text NOT NULL,
  "course_code" text NOT NULL,
  "marks_obtained" real DEFAULT 0.0,
  "total_possible" real DEFAULT 100.0,
  "grade_goal" text,
  "last_updated" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."semester_summaries" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid,
  "semester_code" text NOT NULL,
  "tgpa" numeric DEFAULT 0.0,
  "cgpa" numeric DEFAULT 0.0,
  "credits_earned" numeric DEFAULT 0.0,
  "total_credits_earned" numeric DEFAULT 0.0,
  "updated_at" timestamp with time zone DEFAULT now(),
  "courses" jsonb DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS public."semesters" (
  "code" text NOT NULL,
  "title" text NOT NULL,
  "is_active" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."tasks" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid,
  "title" text,
  "course_code" text,
  "course_name" text,
  "assign_date" timestamp with time zone,
  "due_date" timestamp with time zone,
  "submission_type" text,
  "type" text,
  "is_completed" boolean DEFAULT false,
  "is_missed" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now(),
  "semester_code" text,
  "track" text
);

CREATE TABLE IF NOT EXISTS public."user_drafts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "semester_code" text NOT NULL,
  "combination_data" jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."user_semester_states" (
  "user_id" uuid NOT NULL,
  "semester_code" text NOT NULL,
  "weekly_grid_cache" jsonb DEFAULT '{}'::jsonb,
  "progress_summary" jsonb DEFAULT '{}'::jsonb,
  "updated_at" timestamp with time zone DEFAULT now()
);

-- 3. FUNCTIONS

CREATE OR REPLACE FUNCTION public."trg_notify_schedule_sync"() RETURNS trigger AS $$

DECLARE
  payload JSONB;
BEGIN
  -- We always notify for the affected user
  payload := jsonb_build_object(
    'user_id', COALESCE(NEW.user_id, OLD.user_id)
  );

  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'
      ),
      body := payload
    );
  
  RETURN NULL;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."enable_rls_on_new_table"() RETURNS trigger AS $$
 
BEGIN 
  -- Silently do nothing. This fixes the public.public crash.
END; 

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."shift_enrollments_by_track"() RETURNS trigger AS $$

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

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."catch_graded_enrollment"() RETURNS trigger AS $$

DECLARE
    v_credits numeric;
    v_grade_point numeric;
BEGIN
    IF NEW.grade IS NOT NULL AND NEW.grade != '' AND NEW.grade != 'W' AND NEW.grade != 'I' THEN
        SELECT credit_val INTO v_credits FROM course_metadata WHERE code = NEW.course_code LIMIT 1;
        -- FIX: Call get_grade_point with TWO arguments!
        SELECT public.get_grade_point(NEW.semester_code, NEW.grade) INTO v_grade_point;
        
        INSERT INTO completed_courses (user_id, course_code, semester_code, grade, credits, grade_point)
        VALUES (NEW.user_id, NEW.course_code, NEW.semester_code, upper(trim(NEW.grade)), COALESCE(v_credits, 3.0), COALESCE(v_grade_point, 0.0))
        ON CONFLICT DO NOTHING;
        
        DELETE FROM enrollments WHERE id = NEW.id;
        RETURN NULL; 
    END IF;
    RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."update_timestamp"() RETURNS trigger AS $$

BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."promote_active_semester"() RETURNS trigger AS $$

BEGIN
    UPDATE active_semester 
    SET current_semester_code = next_semester_code,
        updated_at = now()
    WHERE next_semester_code IS NOT NULL AND next_semester_code <> '';
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."trigger_sync_schedule"() RETURNS trigger AS $$

DECLARE
  host_header text;
  dest_url text;
BEGIN
  -- 1. Get host from headers or fallback to your project URL
  BEGIN
    host_header := current_setting('request.headers', true)::json->>'host';
  EXCEPTION WHEN OTHERS THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co';
  END;

  IF host_header IS NULL THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co';
  END IF;

  dest_url := 'https://' || host_header || '/functions/v1/sync-schedule';

  -- 2. Trigger with Definitive Master Key Fallback (The fix!)
  PERFORM
    net.http_post(
      url := dest_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(
            current_setting('app.settings.service_role_key', true),
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'
        )
      ),
      body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
    );
  RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."trigger_track_sync"() RETURNS trigger AS $$

DECLARE
  host_header text;
  dest_url text;
BEGIN
  -- 1. Try to get host from request headers (PostgREST)
  BEGIN
    host_header := current_setting('request.headers', true)::json->>'host';
  EXCEPTION WHEN OTHERS THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co'; -- Fallback
  END;

  IF host_header IS NULL THEN
    host_header := 'jwygjihrbwxhehijldiz.supabase.co';
  END IF;

  -- 1. Trigger sync-schedule
  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-schedule',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,
      body := jsonb_build_object('track', NEW.track)
    );

  -- 2. Trigger sync-semester-meta (new)
  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-semester-meta',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,
      body := jsonb_build_object('record', jsonb_build_object('track', NEW.track, 'current_semester_code', NEW.current_semester_code))
    );

  -- 3. Trigger sync-profile-cache (new)
  PERFORM
    net.http_post(
      url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-profile-cache',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6q"}'::jsonb,
      body := jsonb_build_object('track', NEW.track)
    );

  RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."trg_calculate_live_projection"() RETURNS trigger AS $$

DECLARE
  v_user_id UUID;
  v_semester_code TEXT;

  v_sem_credits NUMERIC := 0.0;
  v_sem_points NUMERIC := 0.0;
  v_live_sgpa NUMERIC := 0.0;

  v_past_cgpa NUMERIC := 0.0;
  v_past_earned NUMERIC := 0.0;
  v_live_cgpa NUMERIC := 0.0;
  
  v_program_code TEXT;
  v_total_required NUMERIC := 0.0;
  v_credits_left NUMERIC := 0.0;
BEGIN
  -- Determine the affected user and semester whether we are Inserting, Updating, or Deleting
  IF TG_OP = 'DELETE' THEN
    v_user_id := OLD.user_id;
    v_semester_code := OLD.semester_code;
  ELSE
    v_user_id := NEW.user_id;
    v_semester_code := NEW.semester_code;
  END IF;

  -- 1) Calculate Predicted SGPA (live_sgpa)
  SELECT
    COALESCE(SUM(cm.credit_val), 0),
    COALESCE(SUM(cm.credit_val * get_grade_point(v_semester_code, COALESCE(scm.grade_goal, 'A'))), 0)
  INTO v_sem_credits, v_sem_points
  FROM semester_course_marks scm
  LEFT JOIN course_metadata cm ON cm.code = scm.course_code
  WHERE scm.user_id = v_user_id AND scm.semester_code = v_semester_code;

  IF v_sem_credits > 0 THEN
     v_live_sgpa := (v_sem_points / v_sem_credits);
  ELSE
     v_live_sgpa := 0.0;
  END IF;

  -- 2) Predict CGPA (live_cgpa) & Get Past Earned
  SELECT
      COALESCE(cgpa, 0.0),
      COALESCE(total_credits_earned, 0.0),
      program_code
  INTO v_past_cgpa, v_past_earned, v_program_code
  FROM profiles
  WHERE id = v_user_id;

  IF (v_past_earned + v_sem_credits) > 0 THEN
      v_live_cgpa := ((v_past_cgpa * v_past_earned) + (v_live_sgpa * v_sem_credits)) / (v_past_earned + v_sem_credits);
  ELSE
      v_live_cgpa := v_past_cgpa;
  END IF;

  -- 3) Degree Credits & Credits Left
  -- Look up target credits from 'programs' table
  IF v_program_code IS NOT NULL THEN
     SELECT COALESCE(total_degree_credits, 130.0)
     INTO v_total_required
     FROM programs
     WHERE program_code = v_program_code;
  ELSE
     v_total_required := 130.0;
  END IF;

  -- Credits Left logic
  v_credits_left := v_total_required - v_past_earned;
  IF v_credits_left < 0 THEN
     v_credits_left := 0.0;
  END IF;

  -- 4) Upsert the dynamic prediction into the semester_analytics table
  INSERT INTO semester_analytics (
    user_id,
    semester_code,
    live_sgpa,
    live_cgpa,
    taken_in_this_sem,
    completed_credit,
    required_credit,
    credits_left,
    updated_at
  )
  VALUES (
    v_user_id,
    v_semester_code,
    v_live_sgpa,
    v_live_cgpa,
    v_sem_credits,
    v_past_earned,
    v_total_required,
    v_credits_left,
    now()
  )
  ON CONFLICT (user_id, semester_code) DO UPDATE SET
    live_sgpa = EXCLUDED.live_sgpa,
    live_cgpa = EXCLUDED.live_cgpa,
    taken_in_this_sem = EXCLUDED.taken_in_this_sem,
    completed_credit = EXCLUDED.completed_credit,
    required_credit = EXCLUDED.required_credit,
    credits_left = EXCLUDED.credits_left,
    updated_at = now();

  RETURN NULL;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."create_course_table"() RETURNS trigger AS $$

DECLARE
    v_table text := 'courses_' || p_semester_code;
    v_sql text;
BEGIN
    v_sql := format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            course_code text,
            original_code text,
            section_number text,
            faculty_initials text,
            capacity text,
            schedule_data jsonb,
            course_name text,
            credit_val numeric
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT SELECT ON TABLE public.%I TO anon, authenticated;
        GRANT ALL ON TABLE public.%I TO service_role;
    ', v_table, v_table, v_table, v_table);
    EXECUTE v_sql;
    
    BEGIN
        EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."create_calendar_table"() RETURNS trigger AS $$

DECLARE
    v_table text := 'calendar_' || p_semester_code;
    v_sql text;
BEGIN
    v_sql := format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id serial primary key,
            event_name text,
            start_date date,
            end_date date,
            event_type text,
            remarks text
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT SELECT ON TABLE public.%I TO anon, authenticated;
        GRANT ALL ON TABLE public.%I TO service_role;
    ', v_table, v_table, v_table, v_table);
    EXECUTE v_sql;

    BEGIN
        EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."create_exam_table"() RETURNS trigger AS $$

DECLARE
    v_table text := 'exams_' || p_semester_code;
    v_sql text;
BEGIN
    v_sql := format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id serial primary key,
            course_code text,
            exam_date date,
            start_time time,
            end_time time,
            room text
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT SELECT ON TABLE public.%I TO anon, authenticated;
        GRANT ALL ON TABLE public.%I TO service_role;
    ', v_table, v_table, v_table, v_table);
    EXECUTE v_sql;

    BEGIN
        EXECUTE format('CREATE POLICY "public_read_%s" ON public.%I FOR SELECT USING (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."create_advising_table"() RETURNS trigger AS $$

DECLARE
    v_table text := 'advising_' || p_semester_code;
    v_sql text;
BEGIN
    v_sql := format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id serial primary key,
            student_id text,
            advised_courses jsonb,
            advising_time timestamp
        );
        ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;
        GRANT ALL ON TABLE public.%I TO anon, authenticated, service_role;
    ', v_table, v_table, v_table);
    EXECUTE v_sql;

    BEGIN
        EXECUTE format('CREATE POLICY "all_access_%s" ON public.%I FOR ALL USING (true) WITH CHECK (true);', p_semester_code, v_table);
    EXCEPTION WHEN duplicate_object THEN null; END;

    NOTIFY pgrst, 'reload schema';
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."master_academic_sync"() RETURNS trigger AS $$

DECLARE
    v_user_id uuid;
    v_rec record;
    
    -- Accumulators for CGPA
    v_cum_points numeric := 0.0;
    v_cum_credits numeric := 0.0;
    
    -- Variables for per-semester calculation
    v_sem_points numeric;
    v_sem_credits numeric;
    v_tgpa numeric;
    v_cgpa numeric;
BEGIN
    -- Determine the user being updated
    v_user_id := COALESCE(NEW.user_id, OLD.user_id);

    -- Reset accumulators
    v_cum_points := 0.0;
    v_cum_credits := 0.0;
    
    -- Iterate over the user's completed courses by chronological semester
    FOR v_rec IN 
        SELECT 
            semester_code,
            -- Sum credits and points ONLY if the grade is NOT an excluded grade (W, I, P, S, U, R)
            COALESCE(SUM(CASE WHEN upper(grade) NOT IN ('W', 'I', 'P', 'S', 'U', 'R') THEN credits ELSE 0 END), 0) AS term_credits,
            COALESCE(SUM(CASE WHEN upper(grade) NOT IN ('W', 'I', 'P', 'S', 'U', 'R') THEN credits * grade_point ELSE 0 END), 0) AS term_points,
            -- Aggregate all courses as JSON (for display in flutter app)
            jsonb_agg(
                jsonb_build_object(
                    'code', course_code, 
                    'grade', grade, 
                    'credits', credits, 
                    'grade_point', grade_point
                )
            ) AS courses
        FROM completed_courses
        WHERE user_id = v_user_id
        GROUP BY semester_code
        ORDER BY 
            (regexp_replace(semester_code, '[^0-9]', '', 'g'))::int ASC, -- Year integer
            CASE lower(regexp_replace(semester_code, '[0-9]', '', 'g'))  -- Season mapped to int
                WHEN 'spring' THEN 1
                WHEN 'summer' THEN 2
                WHEN 'fall'   THEN 3
                ELSE 4
            END ASC
    LOOP
        v_sem_credits := v_rec.term_credits;
        v_sem_points := v_rec.term_points;
        
        -- Calculate TGPA
        IF v_sem_credits > 0 THEN
            v_tgpa := ROUND(v_sem_points / v_sem_credits, 2);
        ELSE
            v_tgpa := 0.0;
        END IF;
        
        -- Advance cumulative sums
        v_cum_points := v_cum_points + v_sem_points;
        v_cum_credits := v_cum_credits + v_sem_credits;
        
        -- Calculate CGPA up to this chronologically encountered semester
        IF v_cum_credits > 0 THEN
            v_cgpa := ROUND(v_cum_points / v_cum_credits, 2);
        ELSE
            v_cgpa := 0.0;
        END IF;

        -- Upsert into semester_summaries
        INSERT INTO semester_summaries (
            user_id, 
            semester_code, 
            tgpa, 
            cgpa, 
            credits_earned, 
            total_credits_earned, 
            courses, 
            updated_at
        )
        VALUES (
            v_user_id, 
            v_rec.semester_code, 
            v_tgpa, 
            v_cgpa, 
            v_sem_credits, 
            v_cum_credits, 
            v_rec.courses, 
            NOW()
        )
        ON CONFLICT (user_id, semester_code) DO UPDATE SET
            tgpa = EXCLUDED.tgpa,
            cgpa = EXCLUDED.cgpa,
            credits_earned = EXCLUDED.credits_earned,
            total_credits_earned = EXCLUDED.total_credits_earned,
            courses = EXCLUDED.courses,
            updated_at = NOW();
    END LOOP;

    -- Clean up any semester summaries if all courses for that semester were deleted
    DELETE FROM semester_summaries 
    WHERE user_id = v_user_id 
      AND semester_code NOT IN (
          SELECT DISTINCT semester_code FROM completed_courses WHERE user_id = v_user_id
      );

    -- Final update to the user's master profile containing their overall CGPA
    UPDATE profiles
    SET cgpa = (CASE WHEN v_cum_credits > 0 THEN ROUND(v_cum_points / v_cum_credits, 2) ELSE 0 END),
        total_credits_earned = v_cum_credits,
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN COALESCE(NEW, OLD);
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."master_enrollment_sync"() RETURNS trigger AS $$

DECLARE
    v_user_id uuid;
    v_track text;
    v_current_sem text;
    v_next_sem text;
    v_current_sections uuid[];
    v_next_sections uuid[];
BEGIN
    v_user_id := COALESCE(NEW.user_id, OLD.user_id);

    SELECT track::text INTO v_track FROM profiles WHERE id = v_user_id;

    -- Fix: Cast track to text or cast v_track to academic_track
    SELECT current_semester_code, next_semester_code INTO v_current_sem, v_next_sem
    FROM active_semester WHERE track::text = v_track LIMIT 1;

    SELECT array_remove(array_agg(section_id), NULL) INTO v_current_sections
    FROM enrollments
    WHERE user_id = v_user_id AND semester_code = v_current_sem AND status = 'enrolled' AND (grade IS NULL OR grade = '');

    SELECT array_remove(array_agg(section_id), NULL) INTO v_next_sections
    FROM enrollments
    WHERE user_id = v_user_id AND semester_code = v_next_sem AND status = 'upcoming' AND (grade IS NULL OR grade = '');

    UPDATE profiles
    SET enrolled_sections = COALESCE(v_current_sections, '{}'::uuid[]),
        enrolled_sections_next = COALESCE(v_next_sections, '{}'::uuid[]),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN COALESCE(NEW, OLD);
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."sync_profile_enrolled_sections"() RETURNS trigger AS $$

DECLARE
    user_track text;
    active_sem text;
    enrolled_ids text[];
BEGIN
    SELECT track::text INTO user_track FROM profiles WHERE id = COALESCE(NEW.user_id, OLD.user_id);
    IF user_track IS NULL THEN
        user_track := 'tri_semester';
    END IF;

    SELECT initcap(replace(replace(lower(current_semester_code), ' ', ''), '_', ''))
    INTO active_sem
    FROM active_semester
    WHERE track::text = user_track;

    IF active_sem IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    EXECUTE format(
        'SELECT array_agg(DISTINCT %L || %L || e.course_code || %L || COALESCE(c.section_number, %L)) ' ||
        'FROM enrollments e ' ||
        'LEFT JOIN %I c ON e.course_code = c.course_code ' ||
        'WHERE e.user_id = %L AND initcap(replace(replace(lower(e.semester_code), %L, %L), %L, %L)) = %L',
        active_sem, '_', '_', 'N/A',
        'courses_' || lower(active_sem),
        COALESCE(NEW.user_id, OLD.user_id), ' ', '', '_', '', active_sem
    ) INTO enrolled_ids;

    UPDATE profiles
    SET enrolled_sections = COALESCE(enrolled_ids, '{}')
    WHERE id = COALESCE(NEW.user_id, OLD.user_id);

    RETURN COALESCE(NEW, OLD);
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."set_completed_course_details"() RETURNS trigger AS $$

DECLARE
    v_credits numeric;
BEGIN
    -- Fetch missing credits automatically
    IF NEW.credits IS NULL OR NEW.credits = 0 THEN
        SELECT credit_val INTO v_credits FROM course_metadata WHERE code = NEW.course_code LIMIT 1;
        NEW.credits := COALESCE(v_credits, 3.0);
    END IF;

    -- Calculate the exact grade point using the master function
    -- Overwrite it even if the client sends one, establishing database as the single source of truth
    IF NEW.grade IS NOT NULL AND NEW.grade != '' THEN
        NEW.grade := upper(trim(NEW.grade));
        NEW.grade_point := public.get_grade_point(NEW.semester_code, NEW.grade);
    END IF;

    RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."handle_enrollment_sync"() RETURNS trigger AS $$

DECLARE
  service_key TEXT := 'YOUR_SERVICE_ROLE_KEY'; -- Replace with your Service Role Key
  project_url TEXT := 'https://YOUR_PROJECT_ID.supabase.co'; -- Replace with your Project URL
BEGIN
  PERFORM
    net.http_post(
      url := project_url || '/functions/v1/sync-schedule',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_key
      ),
      body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
    );
  RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."trg_shift_enrollment"() RETURNS trigger AS $$

DECLARE
    v_credits numeric;
    v_gp numeric;
BEGIN
    -- Only shift if grade is updated from NULL to a value (or changed)
    -- AND NOT an ongoing/future placeholder (though usually they are NULL)
    IF NEW.grade IS NOT NULL AND (OLD.grade IS NULL OR OLD.grade != NEW.grade) THEN
        
        -- 1. Get Credits from course_metadata
        SELECT credit_val INTO v_credits FROM course_metadata WHERE code = NEW.course_code LIMIT 1;
        IF v_credits IS NULL THEN v_credits := 3.0; END IF; -- Default
        
        -- 2. Get Grade Point
        v_gp := get_grade_point(NEW.semester_code, NEW.grade);
        
        -- 3. Insert into completed_courses
        INSERT INTO completed_courses (user_id, course_code, semester_code, grade, credits, grade_point)
        VALUES (NEW.user_id, NEW.course_code, NEW.semester_code, NEW.grade, v_credits, v_gp)
        ON CONFLICT (user_id, course_code, semester_code) DO UPDATE 
        SET grade = EXCLUDED.grade, credits = EXCLUDED.credits, grade_point = EXCLUDED.grade_point;
        
        -- 4. Delete from enrollments
        DELETE FROM enrollments WHERE id = NEW.id;
        
        RETURN NULL; -- Row is deleted, so return NULL to signal completion of action
    END IF;
    
    RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."get_grade_point"() RETURNS trigger AS $$

DECLARE
    v_year int;
    v_season text;
    v_policy text;
    v_point numeric;
    v_clean_sem text;
    v_digit_str text;
BEGIN
    v_clean_sem := trim(p_semester_code);
    
    -- Extract year and season
    IF v_clean_sem LIKE '%_%' THEN
        v_year := COALESCE(NULLIF(split_part(v_clean_sem, '_', 2), ''), '0')::int;
        v_season := lower(split_part(v_clean_sem, '_', 1));
    ELSE
        -- Handle 'Spring2026' or similar
        -- Use \D to match non-digits
        v_digit_str := regexp_replace(v_clean_sem, '\D', '', 'g');
        
        IF v_digit_str IS NULL OR v_digit_str = '' THEN
            v_year := 0;
        ELSE
            v_year := v_digit_str::int;
        END IF;
        
        v_season := lower(regexp_replace(v_clean_sem, '[0-9]', '', 'g'));
    END IF;

    -- Determine Policy
    IF v_year = 0 THEN
        v_policy := 'modern'; 
    ELSIF v_year < 2023 THEN
        v_policy := 'legacy';
    ELSIF v_year = 2023 THEN
        IF v_season IN ('spring', 'summer') THEN
            v_policy := 'legacy';
        ELSE
            v_policy := 'modern';
        END IF;
    ELSE
        v_policy := 'modern';
    END IF;

    -- Fetch from grade_scale
    SELECT point INTO v_point FROM grade_scale WHERE grade = p_grade AND policy = v_policy LIMIT 1;
    
    RETURN COALESCE(v_point, 0.00);
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."handle_semester_switch_sync"() RETURNS trigger AS $$

DECLARE
  service_key TEXT := 'YOUR_SERVICE_ROLE_KEY';
  project_url TEXT := 'https://YOUR_PROJECT_ID.supabase.co';
BEGIN
  -- Only trigger if the current_semester_code actually changed
  IF (OLD.current_semester_code IS DISTINCT FROM NEW.current_semester_code) THEN
    PERFORM
      net.http_post(
        url := project_url || '/functions/v1/sync-semester-summary',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_key
        ),
        body := jsonb_build_object('track', NEW.track)
      );
  END IF;
  RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."calc_quiz_sum"() RETURNS trigger AS $$

DECLARE
  v_total numeric := 0;
BEGIN
  IF quizzes IS NULL OR array_length(quizzes, 1) IS NULL THEN
    RETURN 0.0;
  END IF;

  -- Default strategy is best N
  IF (strategy IS NULL OR strategy = 'bestN') AND n > 0 THEN
    SELECT COALESCE(SUM(val), 0.0) INTO v_total FROM (
      SELECT unnest(quizzes) AS val ORDER BY val DESC LIMIT n
    ) sub;
  ELSIF strategy = 'average' AND n > 0 THEN
    SELECT COALESCE(AVG(val), 0.0) * n INTO v_total FROM (
      SELECT unnest(quizzes) AS val ORDER BY val DESC LIMIT n
    ) sub;
  ELSE
    -- Fallback: sum all
    SELECT COALESCE(SUM(val), 0.0) INTO v_total FROM (
      SELECT unnest(quizzes) AS val
    ) sub;
  END IF;

  RETURN v_total;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."trg_notify_academic_sync"() RETURNS trigger AS $$

    BEGIN
        PERFORM
          net.http_post(
            url := 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-academic-stats',
            headers := jsonb_build_object(
              'Content-Type', 'application/json',
              'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'
            ),
            body := jsonb_build_object('user_id', COALESCE(NEW.user_id, OLD.user_id))
          );
        RETURN NULL;
    END;
    
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."exec_sql"() RETURNS trigger AS $$

            BEGIN
                EXECUTE sql_query;
            END;
            
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."sync_bulk_profile_enrollments"() RETURNS trigger AS $$

BEGIN
    WITH enrolled_agg AS (
        SELECT 
            e.user_id,
            array_agg(DISTINCT p_semester || '_' || e.course_code || '_N/A') as ids
        FROM enrollments e
        WHERE e.semester_code = p_semester
        AND (p_user_id IS NULL OR e.user_id = p_user_id)
        GROUP BY e.user_id
    )
    UPDATE profiles p
    SET enrolled_sections = COALESCE(ea.ids, '{}')
    FROM enrolled_agg ea
    WHERE p.id = ea.user_id
    AND p.track = p_track
    AND (p_user_id IS NULL OR p.id = p_user_id);
    
    -- Also clear for users with NO enrollments in the active semester
    IF p_user_id IS NULL THEN
        UPDATE profiles p
        SET enrolled_sections = '{}'
        WHERE p.track = p_track
        AND NOT EXISTS (
            SELECT 1 FROM enrollments e 
            WHERE e.user_id = p.id 
            AND e.semester_code = p_semester
        );
    ELSE
        UPDATE profiles p
        SET enrolled_sections = '{}'
        WHERE p.id = p_user_id
        AND NOT EXISTS (
            SELECT 1 FROM enrollments e 
            WHERE e.user_id = p.id 
            AND e.semester_code = p_semester
        );
    END IF;
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."normalize_course_code"() RETURNS trigger AS $$

BEGIN
    RETURN upper(regexp_replace(p_code, '\s+', '', 'g'));
END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION public."fn_auto_fix_course"() RETURNS trigger AS $$

BEGIN
    NEW.course_code := public.normalize_course_code(NEW.course_code);
    IF NEW.credit_val = 0 OR NEW.credit_val IS NULL THEN
        SELECT credit_val INTO NEW.credit_val FROM public.course_metadata WHERE code = NEW.course_code LIMIT 1;
    END IF;
    RETURN NEW;
END;

$$ LANGUAGE PLPGSQL;

-- 4. TRIGGERS
DROP TRIGGER IF EXISTS "on_semester_change" ON public."active_semester";
CREATE TRIGGER "on_semester_change" AFTER UPDATE ON public."active_semester" FOR EACH ROW EXECUTE FUNCTION trigger_track_sync();

DROP TRIGGER IF EXISTS "sync_profiles_updated" ON public."profiles";
CREATE TRIGGER "sync_profiles_updated" BEFORE UPDATE ON public."profiles" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "trg_course_details_calculator" ON public."completed_courses";
CREATE TRIGGER "trg_course_details_calculator" BEFORE INSERT ON public."completed_courses" FOR EACH ROW EXECUTE FUNCTION set_completed_course_details();

DROP TRIGGER IF EXISTS "trg_course_details_calculator" ON public."completed_courses";
CREATE TRIGGER "trg_course_details_calculator" BEFORE UPDATE ON public."completed_courses" FOR EACH ROW EXECUTE FUNCTION set_completed_course_details();

DROP TRIGGER IF EXISTS "projection_engine_trigger" ON public."semester_course_marks";
CREATE TRIGGER "projection_engine_trigger" AFTER INSERT ON public."semester_course_marks" FOR EACH ROW EXECUTE FUNCTION trg_calculate_live_projection();

DROP TRIGGER IF EXISTS "projection_engine_trigger" ON public."semester_course_marks";
CREATE TRIGGER "projection_engine_trigger" AFTER DELETE ON public."semester_course_marks" FOR EACH ROW EXECUTE FUNCTION trg_calculate_live_projection();

DROP TRIGGER IF EXISTS "projection_engine_trigger" ON public."semester_course_marks";
CREATE TRIGGER "projection_engine_trigger" AFTER UPDATE ON public."semester_course_marks" FOR EACH ROW EXECUTE FUNCTION trg_calculate_live_projection();

DROP TRIGGER IF EXISTS "sync_fcm_tokens_updated" ON public."fcm_tokens";
CREATE TRIGGER "sync_fcm_tokens_updated" BEFORE UPDATE ON public."fcm_tokens" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "sync_scholarship_policies_updated" ON public."scholarship_policies";
CREATE TRIGGER "sync_scholarship_policies_updated" BEFORE UPDATE ON public."scholarship_policies" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "on_semester_switch" ON public."active_semester";
CREATE TRIGGER "on_semester_switch" AFTER UPDATE ON public."active_semester" FOR EACH ROW EXECUTE FUNCTION handle_semester_switch_sync();

DROP TRIGGER IF EXISTS "trg_master_enrollment_sync" ON public."enrollments";
CREATE TRIGGER "trg_master_enrollment_sync" AFTER INSERT ON public."enrollments" FOR EACH ROW EXECUTE FUNCTION master_enrollment_sync();

DROP TRIGGER IF EXISTS "trg_master_enrollment_sync" ON public."enrollments";
CREATE TRIGGER "trg_master_enrollment_sync" AFTER DELETE ON public."enrollments" FOR EACH ROW EXECUTE FUNCTION master_enrollment_sync();

DROP TRIGGER IF EXISTS "trg_master_enrollment_sync" ON public."enrollments";
CREATE TRIGGER "trg_master_enrollment_sync" AFTER UPDATE ON public."enrollments" FOR EACH ROW EXECUTE FUNCTION master_enrollment_sync();

DROP TRIGGER IF EXISTS "trg_catch_graded_enrollment" ON public."enrollments";
CREATE TRIGGER "trg_catch_graded_enrollment" BEFORE UPDATE ON public."enrollments" FOR EACH ROW EXECUTE FUNCTION catch_graded_enrollment();

DROP TRIGGER IF EXISTS "trg_master_academic_sync" ON public."completed_courses";
CREATE TRIGGER "trg_master_academic_sync" AFTER INSERT ON public."completed_courses" FOR EACH ROW EXECUTE FUNCTION master_academic_sync();

DROP TRIGGER IF EXISTS "trg_master_academic_sync" ON public."completed_courses";
CREATE TRIGGER "trg_master_academic_sync" AFTER DELETE ON public."completed_courses" FOR EACH ROW EXECUTE FUNCTION master_academic_sync();

DROP TRIGGER IF EXISTS "trg_master_academic_sync" ON public."completed_courses";
CREATE TRIGGER "trg_master_academic_sync" AFTER UPDATE ON public."completed_courses" FOR EACH ROW EXECUTE FUNCTION master_academic_sync();


-- 5. RLS POLICIES
ALTER TABLE public."schedule_exceptions" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can update their own exceptions" ON public."schedule_exceptions";
CREATE POLICY "Users can update their own exceptions" ON public."schedule_exceptions" FOR UPDATE TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."schedule_exceptions" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can delete their own exceptions" ON public."schedule_exceptions";
CREATE POLICY "Users can delete their own exceptions" ON public."schedule_exceptions" FOR DELETE TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."user_semester_states" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own states" ON public."user_semester_states";
CREATE POLICY "Users can manage their own states" ON public."user_semester_states" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."semester_analytics" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read their own analytics" ON public."semester_analytics";
CREATE POLICY "Users can read their own analytics" ON public."semester_analytics" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public."profiles";
CREATE POLICY "Users can manage their own profile" ON public."profiles" FOR ALL TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));

ALTER TABLE public."calendar_spring2026" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read access for calendar" ON public."calendar_spring2026";
CREATE POLICY "Public read access for calendar" ON public."calendar_spring2026" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."admin_users" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view admin users list" ON public."admin_users";
CREATE POLICY "Anyone can view admin users list" ON public."admin_users" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."scholarship_policies" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Policies" ON public."scholarship_policies";
CREATE POLICY "Public Read Policies" ON public."scholarship_policies" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."semester_analytics" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own analytics" ON public."semester_analytics";
CREATE POLICY "Users can manage their own analytics" ON public."semester_analytics" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."semester_course_stats" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own stats" ON public."semester_course_stats";
CREATE POLICY "Users can manage their own stats" ON public."semester_course_stats" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."enrollments" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own enrollments" ON public."enrollments";
CREATE POLICY "Users can manage their own enrollments" ON public."enrollments" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."feedbacks" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public."feedbacks";
CREATE POLICY "Enable insert for authenticated users only" ON public."feedbacks" FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."feedbacks" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for all users" ON public."feedbacks";
CREATE POLICY "Enable read access for all users" ON public."feedbacks" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."feedbacks" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable update for all users" ON public."feedbacks";
CREATE POLICY "Enable update for all users" ON public."feedbacks" FOR UPDATE TO authenticated USING (true);

ALTER TABLE public."schedule_generations" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own schedule_generations" ON public."schedule_generations";
CREATE POLICY "Users manage own schedule_generations" ON public."schedule_generations" FOR ALL TO authenticated USING (((auth.uid())::text = user_id)) WITH CHECK (((auth.uid())::text = user_id));

ALTER TABLE public."user_drafts" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own user_drafts" ON public."user_drafts";
CREATE POLICY "Users manage own user_drafts" ON public."user_drafts" FOR ALL TO authenticated USING (((auth.uid())::text = (user_id)::text)) WITH CHECK (((auth.uid())::text = (user_id)::text));

ALTER TABLE public."semester_summaries" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own summaries" ON public."semester_summaries";
CREATE POLICY "Users can view own summaries" ON public."semester_summaries" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."semester_analytics" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own analytics" ON public."semester_analytics";
CREATE POLICY "Users can read own analytics" ON public."semester_analytics" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."semester_analytics" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can insert/update own analytics" ON public."semester_analytics";
CREATE POLICY "Users can insert/update own analytics" ON public."semester_analytics" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."active_semester" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read active_semester" ON public."active_semester";
CREATE POLICY "Public read active_semester" ON public."active_semester" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."calendar_spring2026" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read calendar" ON public."calendar_spring2026";
CREATE POLICY "Public read calendar" ON public."calendar_spring2026" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."calendar_spring2026_phrm_llb" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read calendar bi" ON public."calendar_spring2026_phrm_llb";
CREATE POLICY "Public read calendar bi" ON public."calendar_spring2026_phrm_llb" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."tasks" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own tasks" ON public."tasks";
CREATE POLICY "Users can manage own tasks" ON public."tasks" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."user_semester_states" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own states" ON public."user_semester_states";
CREATE POLICY "Users can manage own states" ON public."user_semester_states" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public."profiles";
CREATE POLICY "Public profiles are viewable by everyone" ON public."profiles" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can sync own profile" ON public."profiles";
CREATE POLICY "Users can sync own profile" ON public."profiles" FOR ALL TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));

ALTER TABLE public."app_config" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Config" ON public."app_config";
CREATE POLICY "Public Read Config" ON public."app_config" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."programs" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Programs" ON public."programs";
CREATE POLICY "Public Read Programs" ON public."programs" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."semesters" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Semesters" ON public."semesters";
CREATE POLICY "Public Read Semesters" ON public."semesters" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."semester_summaries" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access summaries" ON public."semester_summaries";
CREATE POLICY "Service role full access summaries" ON public."semester_summaries" FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public."semester_summaries" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own summaries" ON public."semester_summaries";
CREATE POLICY "Users can manage their own summaries" ON public."semester_summaries" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Profiles" ON public."profiles";
CREATE POLICY "Public Read Profiles" ON public."profiles" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users sync own profile" ON public."profiles";
CREATE POLICY "Users sync own profile" ON public."profiles" FOR ALL TO authenticated USING ((auth.uid() = id));

ALTER TABLE public."enrollments" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users sync own enrollments" ON public."enrollments";
CREATE POLICY "Users sync own enrollments" ON public."enrollments" FOR ALL TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."user_semester_states" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users sync own states" ON public."user_semester_states";
CREATE POLICY "Users sync own states" ON public."user_semester_states" FOR ALL TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."notifications" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own or broadcast notifications" ON public."notifications";
CREATE POLICY "Users read own or broadcast notifications" ON public."notifications" FOR SELECT TO authenticated USING (((auth.uid() = user_id) OR (user_id IS NULL)));

ALTER TABLE public."semester_summaries" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own summaries" ON public."semester_summaries";
CREATE POLICY "Users can view their own summaries" ON public."semester_summaries" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."schedule_exceptions" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own exceptions" ON public."schedule_exceptions";
CREATE POLICY "Users can view their own exceptions" ON public."schedule_exceptions" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."notifications" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users update own notifications" ON public."notifications";
CREATE POLICY "Users update own notifications" ON public."notifications" FOR UPDATE TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."semester_course_marks" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own marks" ON public."semester_course_marks";
CREATE POLICY "Users can manage their own marks" ON public."semester_course_marks" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."schedule_exceptions" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own exceptions" ON public."schedule_exceptions";
CREATE POLICY "Users can manage their own exceptions" ON public."schedule_exceptions" FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."semester_summaries" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read their own summaries" ON public."semester_summaries";
CREATE POLICY "Users can read their own summaries" ON public."semester_summaries" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."completed_courses" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own completed courses" ON public."completed_courses";
CREATE POLICY "Users can view their own completed courses" ON public."completed_courses" FOR SELECT TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."completed_courses" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can insert their own completed courses" ON public."completed_courses";
CREATE POLICY "Users can insert their own completed courses" ON public."completed_courses" FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

ALTER TABLE public."completed_courses" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can update their own completed courses" ON public."completed_courses";
CREATE POLICY "Users can update their own completed courses" ON public."completed_courses" FOR UPDATE TO authenticated USING ((auth.uid() = user_id));

ALTER TABLE public."course_metadata" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read course_metadata" ON public."course_metadata";
CREATE POLICY "Public Read course_metadata" ON public."course_metadata" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."grade_scale" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read grade_scale" ON public."grade_scale";
CREATE POLICY "Public Read grade_scale" ON public."grade_scale" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."completed_courses" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own completed_courses" ON public."completed_courses";
CREATE POLICY "Users manage own completed_courses" ON public."completed_courses" FOR ALL TO authenticated USING (((auth.uid())::text = (user_id)::text)) WITH CHECK (((auth.uid())::text = (user_id)::text));

ALTER TABLE public."course_metadata" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage course metadata" ON public."course_metadata";
CREATE POLICY "Admins can manage course metadata" ON public."course_metadata" FOR ALL TO authenticated USING ((auth.uid() IN ( SELECT admin_users.user_id
   FROM admin_users)));

ALTER TABLE public."course_metadata" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view course metadata" ON public."course_metadata";
CREATE POLICY "Anyone can view course metadata" ON public."course_metadata" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."scholarship_policies" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage scholarship policies" ON public."scholarship_policies";
CREATE POLICY "Admins can manage scholarship policies" ON public."scholarship_policies" FOR ALL TO authenticated USING ((auth.uid() IN ( SELECT admin_users.user_id
   FROM admin_users)));

ALTER TABLE public."scholarship_policies" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view scholarship policies" ON public."scholarship_policies";
CREATE POLICY "Anyone can view scholarship policies" ON public."scholarship_policies" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."grade_scale" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage grade scale" ON public."grade_scale";
CREATE POLICY "Admins can manage grade scale" ON public."grade_scale" FOR ALL TO authenticated USING ((auth.uid() IN ( SELECT admin_users.user_id
   FROM admin_users)));

ALTER TABLE public."grade_scale" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view grade scale" ON public."grade_scale";
CREATE POLICY "Anyone can view grade scale" ON public."grade_scale" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."parsing_logs" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Access" ON public."parsing_logs";
CREATE POLICY "Public Read Access" ON public."parsing_logs" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."parsing_logs" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service Role Write Access" ON public."parsing_logs";
CREATE POLICY "Service Role Write Access" ON public."parsing_logs" FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public."courses_summer2026" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_read_summer2026" ON public."courses_summer2026";
CREATE POLICY "public_read_summer2026" ON public."courses_summer2026" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."calendar_spring2026" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_read_spring2026" ON public."calendar_spring2026";
CREATE POLICY "public_read_spring2026" ON public."calendar_spring2026" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."courses_spring2026" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_read_spring2026" ON public."courses_spring2026";
CREATE POLICY "public_read_spring2026" ON public."courses_spring2026" FOR SELECT TO authenticated USING (true);

ALTER TABLE public."fcm_tokens" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated token management" ON public."fcm_tokens";
CREATE POLICY "Allow authenticated token management" ON public."fcm_tokens" FOR ALL TO authenticated USING (true) WITH CHECK ((auth.uid() = user_id));


-- 6. CRON JOBS
SELECT cron.schedule('invoke-alert-scheduler', '0 14 * * *', '
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-scheduler',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    ');
SELECT cron.schedule('invoke-semester-switch-bot', '0 0 * * *', '
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-semester-meta',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,
          body:='{}'::jsonb
      ) AS request_id;
    ');
SELECT cron.schedule('invoke-alert-dispatcher', '*/5 * * * *', '
    SELECT
      net.http_post(
          url:='https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-dispatcher',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"}'::jsonb,        
          body:='{}'::jsonb
      ) AS request_id;
    ');
