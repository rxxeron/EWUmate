DROP POLICY IF EXISTS "Public read active_semester" ON "active_semester";
-- Table: active_semester

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE active_semester ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read active_semester" ON "active_semester"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Anyone can view admin users list" ON "admin_users";
-- Table: admin_users

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view admin users list" ON "admin_users"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public Read Config" ON "app_config";
-- Table: app_config

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read Config" ON "app_config"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public read access for calendar" ON "calendar_spring2026";
-- Table: calendar_spring2026

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE calendar_spring2026 ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for calendar" ON "calendar_spring2026"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public read calendar" ON "calendar_spring2026";
-- Table: calendar_spring2026

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE calendar_spring2026 ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read calendar" ON "calendar_spring2026"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public read calendar bi" ON "calendar_spring2026_phrm_llb";
-- Table: calendar_spring2026_phrm_llb

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE calendar_spring2026_phrm_llb ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read calendar bi" ON "calendar_spring2026_phrm_llb"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users can insert their own completed courses" ON "completed_courses";
-- Table: completed_courses

-- Roles: ['public']

-- Command: INSERT

ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own completed courses" ON "completed_courses"

FOR INSERT

TO public

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can update their own completed courses" ON "completed_courses";
-- Table: completed_courses

-- Roles: ['public']

-- Command: UPDATE

ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can update their own completed courses" ON "completed_courses"

FOR UPDATE

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can view their own completed courses" ON "completed_courses";
-- Table: completed_courses

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own completed courses" ON "completed_courses"

FOR SELECT

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users manage own completed_courses" ON "completed_courses";
-- Table: completed_courses

-- Roles: ['public']

-- Command: ALL

ALTER TABLE completed_courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own completed_courses" ON "completed_courses"

FOR ALL

TO public

USING (((auth.uid())::text = (user_id)::text))

WITH CHECK (((auth.uid())::text = (user_id)::text))

;

DROP POLICY IF EXISTS "Admins can manage course metadata" ON "course_metadata";
-- Table: course_metadata

-- Roles: ['public']

-- Command: ALL

ALTER TABLE course_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage course metadata" ON "course_metadata"

FOR ALL

TO public

USING ((auth.uid() IN ( SELECT admin_users.user_id

   FROM admin_users)))

;

DROP POLICY IF EXISTS "Anyone can view course metadata" ON "course_metadata";
-- Table: course_metadata

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE course_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view course metadata" ON "course_metadata"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public Read course_metadata" ON "course_metadata";
-- Table: course_metadata

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE course_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read course_metadata" ON "course_metadata"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public read courses" ON "courses_spring2026";
-- Table: courses_spring2026

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE courses_spring2026 ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read courses" ON "courses_spring2026"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "public_read_summer2026" ON "courses_summer2026";
-- Table: courses_summer2026

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE courses_summer2026 ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_summer2026" ON "courses_summer2026"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users can manage their own enrollments" ON "enrollments";
-- Table: enrollments

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own enrollments" ON "enrollments"

FOR ALL

TO authenticated

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users sync own enrollments" ON "enrollments";
-- Table: enrollments

-- Roles: ['public']

-- Command: ALL

ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users sync own enrollments" ON "enrollments"

FOR ALL

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can delete own tokens" ON "fcm_tokens";
-- Table: fcm_tokens

-- Roles: ['public']

-- Command: DELETE

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can delete own tokens" ON "fcm_tokens"

FOR DELETE

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can update tokens on their device" ON "fcm_tokens";
-- Table: fcm_tokens

-- Roles: ['public']

-- Command: UPDATE

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can update tokens on their device" ON "fcm_tokens"

FOR UPDATE

TO public

USING (true)

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can view own tokens" ON "fcm_tokens";
-- Table: fcm_tokens

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tokens" ON "fcm_tokens"

FOR SELECT

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can insert their tokens" ON "fcm_tokens";
-- Table: fcm_tokens

-- Roles: ['public']

-- Command: INSERT

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their tokens" ON "fcm_tokens"

FOR INSERT

TO public

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "feedbacks";
-- Table: feedbacks

-- Roles: ['authenticated']

-- Command: INSERT

ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable insert for authenticated users only" ON "feedbacks"

FOR INSERT

TO authenticated

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Enable read access for all users" ON "feedbacks";
-- Table: feedbacks

-- Roles: ['authenticated']

-- Command: SELECT

ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON "feedbacks"

FOR SELECT

TO authenticated

USING (true)

;

DROP POLICY IF EXISTS "Enable update for all users" ON "feedbacks";
-- Table: feedbacks

-- Roles: ['authenticated']

-- Command: UPDATE

ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable update for all users" ON "feedbacks"

FOR UPDATE

TO authenticated

USING (true)

;

DROP POLICY IF EXISTS "Admins can manage grade scale" ON "grade_scale";
-- Table: grade_scale

-- Roles: ['public']

-- Command: ALL

ALTER TABLE grade_scale ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage grade scale" ON "grade_scale"

FOR ALL

TO public

USING ((auth.uid() IN ( SELECT admin_users.user_id

   FROM admin_users)))

;

DROP POLICY IF EXISTS "Anyone can view grade scale" ON "grade_scale";
-- Table: grade_scale

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE grade_scale ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view grade scale" ON "grade_scale"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public Read grade_scale" ON "grade_scale";
-- Table: grade_scale

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE grade_scale ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read grade_scale" ON "grade_scale"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users read own or broadcast notifications" ON "notifications";
-- Table: notifications

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own or broadcast notifications" ON "notifications"

FOR SELECT

TO public

USING (((auth.uid() = user_id) OR (user_id IS NULL)))

;

DROP POLICY IF EXISTS "Users update own notifications" ON "notifications";
-- Table: notifications

-- Roles: ['public']

-- Command: UPDATE

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users update own notifications" ON "notifications"

FOR UPDATE

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Public Read Profiles" ON "profiles";
-- Table: profiles

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read Profiles" ON "profiles"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON "profiles";
-- Table: profiles

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone" ON "profiles"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users can manage their own profile" ON "profiles";
-- Table: profiles

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own profile" ON "profiles"

FOR ALL

TO authenticated

USING ((auth.uid() = id))

WITH CHECK ((auth.uid() = id))

;

DROP POLICY IF EXISTS "Users can sync own profile" ON "profiles";
-- Table: profiles

-- Roles: ['public']

-- Command: ALL

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can sync own profile" ON "profiles"

FOR ALL

TO public

USING ((auth.uid() = id))

WITH CHECK ((auth.uid() = id))

;

DROP POLICY IF EXISTS "Users sync own profile" ON "profiles";
-- Table: profiles

-- Roles: ['public']

-- Command: ALL

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users sync own profile" ON "profiles"

FOR ALL

TO public

USING ((auth.uid() = id))

;

DROP POLICY IF EXISTS "Public Read Programs" ON "programs";
-- Table: programs

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read Programs" ON "programs"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users can delete their own exceptions" ON "schedule_exceptions";
-- Table: schedule_exceptions

-- Roles: ['public']

-- Command: DELETE

ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can delete their own exceptions" ON "schedule_exceptions"

FOR DELETE

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can update their own exceptions" ON "schedule_exceptions";
-- Table: schedule_exceptions

-- Roles: ['public']

-- Command: UPDATE

ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can update their own exceptions" ON "schedule_exceptions"

FOR UPDATE

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can manage their own exceptions" ON "schedule_exceptions";
-- Table: schedule_exceptions

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own exceptions" ON "schedule_exceptions"

FOR ALL

TO authenticated

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can view their own exceptions" ON "schedule_exceptions";
-- Table: schedule_exceptions

-- Roles: ['authenticated']

-- Command: SELECT

ALTER TABLE schedule_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own exceptions" ON "schedule_exceptions"

FOR SELECT

TO authenticated

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users manage own schedule_generations" ON "schedule_generations";
-- Table: schedule_generations

-- Roles: ['public']

-- Command: ALL

ALTER TABLE schedule_generations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own schedule_generations" ON "schedule_generations"

FOR ALL

TO public

USING (((auth.uid())::text = user_id))

WITH CHECK (((auth.uid())::text = user_id))

;

DROP POLICY IF EXISTS "Admins can manage scholarship policies" ON "scholarship_policies";
-- Table: scholarship_policies

-- Roles: ['public']

-- Command: ALL

ALTER TABLE scholarship_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage scholarship policies" ON "scholarship_policies"

FOR ALL

TO public

USING ((auth.uid() IN ( SELECT admin_users.user_id

   FROM admin_users)))

;

DROP POLICY IF EXISTS "Anyone can view scholarship policies" ON "scholarship_policies";
-- Table: scholarship_policies

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE scholarship_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view scholarship policies" ON "scholarship_policies"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Public Read Policies" ON "scholarship_policies";
-- Table: scholarship_policies

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE scholarship_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read Policies" ON scholarship_policies

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users can manage their own analytics" ON "semester_analytics";
-- Table: semester_analytics

-- Roles: ['public']

-- Command: ALL

ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own analytics" ON "semester_analytics"

FOR ALL

TO public

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can read own analytics" ON "semester_analytics";
-- Table: semester_analytics

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own analytics" ON "semester_analytics"

FOR SELECT

TO public

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can read their own analytics" ON "semester_analytics";
-- Table: semester_analytics

-- Roles: ['authenticated']

-- Command: SELECT

ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own analytics" ON "semester_analytics"

FOR SELECT

TO authenticated

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can insert/update own analytics" ON "semester_analytics";
-- Table: semester_analytics

-- Roles: ['public']

-- Command: ALL

ALTER TABLE semester_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert/update own analytics" ON "semester_analytics"

FOR ALL

TO public

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can manage their own marks" ON "semester_course_marks";
-- Table: semester_course_marks

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE semester_course_marks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own marks" ON "semester_course_marks"

FOR ALL

TO authenticated

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can manage their own stats" ON "semester_course_stats";
-- Table: semester_course_stats

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE semester_course_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own stats" ON "semester_course_stats"

FOR ALL

TO authenticated

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Service role full access summaries" ON "semester_summaries";
-- Table: semester_summaries

-- Roles: ['service_role']

-- Command: ALL

ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access summaries" ON "semester_summaries"

FOR ALL

TO service_role

USING (true)

WITH CHECK (true)

;

DROP POLICY IF EXISTS "Users can view own summaries" ON "semester_summaries";
-- Table: semester_summaries

-- Roles: ['authenticated']

-- Command: SELECT

ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own summaries" ON "semester_summaries"

FOR SELECT

TO authenticated

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can manage their own summaries" ON "semester_summaries";
-- Table: semester_summaries

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own summaries" ON "semester_summaries"

FOR ALL

TO authenticated

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can read their own summaries" ON "semester_summaries";
-- Table: semester_summaries

-- Roles: ['authenticated']

-- Command: SELECT

ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own summaries" ON "semester_summaries"

FOR SELECT

TO authenticated

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can view their own summaries" ON "semester_summaries";
-- Table: semester_summaries

-- Roles: ['authenticated']

-- Command: SELECT

ALTER TABLE semester_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own summaries" ON "semester_summaries"

FOR SELECT

TO authenticated

USING ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Public Read Semesters" ON "semesters";
-- Table: semesters

-- Roles: ['public']

-- Command: SELECT

ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public Read Semesters" ON "semesters"

FOR SELECT

TO public

USING (true)

;

DROP POLICY IF EXISTS "Users can manage own tasks" ON "tasks";
-- Table: tasks

-- Roles: ['public']

-- Command: ALL

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own tasks" ON "tasks"

FOR ALL

TO public

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users manage own user_drafts" ON "user_drafts";
-- Table: user_drafts

-- Roles: ['public']

-- Command: ALL

ALTER TABLE user_drafts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own user_drafts" ON "user_drafts"

FOR ALL

TO public

USING (((auth.uid())::text = (user_id)::text))

WITH CHECK (((auth.uid())::text = (user_id)::text))

;

DROP POLICY IF EXISTS "Users can manage their own states" ON "user_semester_states";
-- Table: user_semester_states

-- Roles: ['authenticated']

-- Command: ALL

ALTER TABLE user_semester_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own states" ON "user_semester_states"

FOR ALL

TO authenticated

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users can manage own states" ON "user_semester_states";
-- Table: user_semester_states

-- Roles: ['public']

-- Command: ALL

ALTER TABLE user_semester_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own states" ON "user_semester_states"

FOR ALL

TO public

USING ((auth.uid() = user_id))

WITH CHECK ((auth.uid() = user_id))

;

DROP POLICY IF EXISTS "Users sync own states" ON "user_semester_states";
-- Table: user_semester_states

-- Roles: ['public']

-- Command: ALL

ALTER TABLE user_semester_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users sync own states" ON "user_semester_states"

FOR ALL

TO public

USING ((auth.uid() = user_id))

;

