CREATE TRIGGER on_semester_change AFTER UPDATE OF current_semester_code ON public.active_semester FOR EACH ROW EXECUTE FUNCTION trigger_track_sync();
