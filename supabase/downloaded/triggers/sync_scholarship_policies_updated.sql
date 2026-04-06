CREATE TRIGGER sync_scholarship_policies_updated BEFORE UPDATE ON public.scholarship_policies FOR EACH ROW EXECUTE FUNCTION update_timestamp();
