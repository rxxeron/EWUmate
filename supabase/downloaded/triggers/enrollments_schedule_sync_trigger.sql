CREATE TRIGGER enrollments_schedule_sync_trigger AFTER INSERT OR DELETE OR UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION trg_notify_schedule_sync();
