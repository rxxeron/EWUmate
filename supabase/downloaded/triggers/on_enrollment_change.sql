CREATE TRIGGER on_enrollment_change AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION trigger_sync_schedule();
