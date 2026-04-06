DROP TRIGGER IF EXISTS "completed_courses_sync_trigger" ON "completed_courses";
CREATE TRIGGER "completed_courses_sync_trigger" AFTER INSERT OR DELETE OR UPDATE ON public.completed_courses FOR EACH ROW EXECUTE FUNCTION trg_notify_academic_sync();

DROP TRIGGER IF EXISTS "enrollments_schedule_sync_trigger" ON "enrollments";
CREATE TRIGGER "enrollments_schedule_sync_trigger" AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION trg_notify_schedule_sync();

DROP TRIGGER IF EXISTS "enrollments_shift_trigger" ON "enrollments";
CREATE TRIGGER "enrollments_shift_trigger" AFTER UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION trg_shift_enrollment();

DROP TRIGGER IF EXISTS "on_semester_change" ON "active_semester";
CREATE TRIGGER "on_semester_change" AFTER UPDATE OF current_semester_code ON public.active_semester FOR EACH ROW EXECUTE FUNCTION trigger_track_sync();

DROP TRIGGER IF EXISTS "on_semester_switch" ON "active_semester";
CREATE TRIGGER "on_semester_switch" AFTER UPDATE ON public.active_semester FOR EACH ROW EXECUTE FUNCTION handle_semester_switch_sync();

DROP TRIGGER IF EXISTS "sync_enrollments_updated" ON "enrollments";
CREATE TRIGGER "sync_enrollments_updated" BEFORE UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "sync_fcm_tokens_updated" ON "fcm_tokens";
CREATE TRIGGER "sync_fcm_tokens_updated" BEFORE UPDATE ON public.fcm_tokens FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "sync_profiles_updated" ON "profiles";
CREATE TRIGGER "sync_profiles_updated" BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "sync_scholarship_policies_updated" ON "scholarship_policies";
CREATE TRIGGER "sync_scholarship_policies_updated" BEFORE UPDATE ON public.scholarship_policies FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "tr_auto_fix_summer" ON "courses_summer2026";
CREATE TRIGGER "tr_auto_fix_summer" BEFORE INSERT OR UPDATE ON public.courses_summer2026 FOR EACH ROW EXECUTE FUNCTION fn_auto_fix_course();

DROP TRIGGER IF EXISTS "trg_sync_profile_enrollments" ON "enrollments";
CREATE TRIGGER "trg_sync_profile_enrollments" AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION sync_profile_enrolled_sections();

