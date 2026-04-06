CREATE TRIGGER completed_courses_sync_trigger AFTER INSERT OR DELETE OR UPDATE ON public.completed_courses FOR EACH ROW EXECUTE FUNCTION trg_notify_academic_sync();
