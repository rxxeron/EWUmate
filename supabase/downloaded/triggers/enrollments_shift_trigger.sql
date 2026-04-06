CREATE TRIGGER enrollments_shift_trigger AFTER UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION trg_shift_enrollment();
