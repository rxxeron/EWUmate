CREATE TRIGGER tr_auto_fix_summer BEFORE INSERT OR UPDATE ON public.courses_summer2026 FOR EACH ROW EXECUTE FUNCTION fn_auto_fix_course();
