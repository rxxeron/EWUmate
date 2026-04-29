-- Full Database Schema (Tables and Columns)

CREATE TABLE "active_semester" (
  "track" academic_track NOT NULL,
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
  "classes_end_date" date,
  PRIMARY KEY (track)
);

CREATE TABLE "admin_users" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" uuid NOT NULL,
  "email" text NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (id)
);

CREATE TABLE "app_config" (
  "key" text NOT NULL,
  "value" jsonb NOT NULL,
  "latest_version" text,
  "download_url" text,
  PRIMARY KEY (key)
);

CREATE TABLE "calendar_spring2026" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "event_date" date NOT NULL,
  "title" text NOT NULL,
  "type" text,
  "target_track" academic_track DEFAULT 'tri_semester'::academic_track,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "calendar_spring2026_phrm_llb" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "event_date" date NOT NULL,
  "title" text NOT NULL,
  "type" text,
  "target_track" academic_track DEFAULT 'bi_semester'::academic_track,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "completed_courses" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" uuid,
  "course_code" text NOT NULL,
  "semester_code" text NOT NULL,
  "grade" text NOT NULL,
  "grade_point" numeric DEFAULT 0.0,
  "credits" numeric NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "course_metadata" (
  "code" text NOT NULL,
  "name" text NOT NULL,
  "credit_val" numeric NOT NULL,
  "equivalent_code" text,
  PRIMARY KEY (code)
);

CREATE TABLE "courses_spring2026" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "course_code" text,
  "original_code" text,
  "section_number" text,
  "faculty_initials" text,
  "capacity" text,
  "schedule_data" jsonb,
  "created_at" timestamp with time zone DEFAULT now(),
  "course_name" text,
  "credit_val" numeric,
  PRIMARY KEY (id)
);

CREATE TABLE "courses_summer2026" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "course_code" text,
  "original_code" text,
  "section_number" text,
  "faculty_initials" text,
  "capacity" text,
  "schedule_data" jsonb,
  "course_name" text,
  "credit_val" numeric,
  PRIMARY KEY (id)
);

CREATE TABLE "enrollments" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" uuid,
  "semester_code" text,
  "course_code" text,
  "section_id" uuid,
  "status" enrollment_status DEFAULT 'enrolled'::enrollment_status,
  "grade" text,
  "grade_points" numeric,
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "fcm_tokens" (
  "token" text NOT NULL,
  "user_id" uuid,
  "platform" text,
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (token)
);

CREATE TABLE "feedbacks" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid,
  "message" text NOT NULL,
  "status" character varying(50) DEFAULT 'pending'::character varying,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "grade_scale" (
  "grade" text NOT NULL,
  "point" numeric NOT NULL,
  "min_score" numeric,
  "description" text,
  "policy" text DEFAULT 'modern'::text,
  PRIMARY KEY (grade)
);

CREATE TABLE "notifications" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" uuid,
  "type" notification_type DEFAULT 'system'::notification_type,
  "title" text NOT NULL,
  "body" text NOT NULL,
  "trigger_at" timestamp with time zone DEFAULT now(),
  "is_dispatched" boolean DEFAULT true,
  "is_read" boolean DEFAULT false,
  "payload" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now(),
  "alert_key" text,
  PRIMARY KEY (id)
);

CREATE TABLE "profiles" (
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
  "enrolled_sections" text[] DEFAULT '{}'::text[],
  "enrolled_sections_next" text[] DEFAULT '{}'::text[],
  "past_history" jsonb DEFAULT '[]'::jsonb,
  "enrolled_credits" numeric DEFAULT 0.0,
  "enrolled_credits_next" numeric DEFAULT 0.0,
  "total_courses_completed" integer DEFAULT 0,
  PRIMARY KEY (id)
);

CREATE TABLE "programs" (
  "program_code" text NOT NULL,
  "name" text NOT NULL,
  "track" academic_track NOT NULL,
  "total_degree_credits" numeric NOT NULL DEFAULT 130,
  "department_name" text,
  PRIMARY KEY (program_code)
);

CREATE TABLE "schedule_exceptions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
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
  "faculty" text,
  PRIMARY KEY (id)
);

CREATE TABLE "schedule_generations" (
  "id" uuid NOT NULL,
  "user_id" text,
  "semester" text,
  "courses" jsonb,
  "filters" jsonb,
  "combinations" jsonb,
  "status" text,
  "count" integer,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "scholarship_policies" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
  PRIMARY KEY (id)
);

CREATE TABLE "semester_analytics" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
  "credits_left" numeric DEFAULT 0.00,
  PRIMARY KEY (id)
);

CREATE TABLE "semester_course_marks" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
  "obt_quizzes" float4[] DEFAULT '{}'::real[],
  "obt_short_quizzes" float4[] DEFAULT '{}'::real[],
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
  PRIMARY KEY (id)
);

CREATE TABLE "semester_course_stats" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "semester" text NOT NULL,
  "course_code" text NOT NULL,
  "marks_obtained" real DEFAULT 0.0,
  "total_possible" real DEFAULT 100.0,
  "grade_goal" text,
  "last_updated" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "semester_summaries" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid,
  "semester_code" text NOT NULL,
  "tgpa" numeric DEFAULT 0.0,
  "cgpa" numeric DEFAULT 0.0,
  "credits_earned" numeric DEFAULT 0.0,
  "total_credits_earned" numeric DEFAULT 0.0,
  "updated_at" timestamp with time zone DEFAULT now(),
  "courses" jsonb DEFAULT '[]'::jsonb,
  PRIMARY KEY (id)
);

CREATE TABLE "semesters" (
  "code" text NOT NULL,
  "title" text NOT NULL,
  "is_active" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (code)
);

CREATE TABLE "tasks" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
  "track" text,
  PRIMARY KEY (id)
);

CREATE TABLE "user_drafts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "semester_code" text NOT NULL,
  "combination_data" jsonb NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);

CREATE TABLE "user_semester_states" (
  "user_id" uuid NOT NULL,
  "semester_code" text NOT NULL,
  "weekly_grid_cache" jsonb DEFAULT '{}'::jsonb,
  "progress_summary" jsonb DEFAULT '{}'::jsonb,
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY (user_id, semester_code)
);
