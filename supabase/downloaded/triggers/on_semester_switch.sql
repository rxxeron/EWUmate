CREATE TRIGGER on_semester_switch AFTER UPDATE ON public.active_semester FOR EACH ROW EXECUTE FUNCTION handle_semester_switch_sync();
