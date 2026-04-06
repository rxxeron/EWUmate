CREATE TRIGGER trg_sync_profile_enrollments AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION sync_profile_enrolled_sections();
