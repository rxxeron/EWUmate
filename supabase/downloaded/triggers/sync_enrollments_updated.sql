CREATE TRIGGER sync_enrollments_updated BEFORE UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION update_timestamp();
