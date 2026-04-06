CREATE TRIGGER sync_fcm_tokens_updated BEFORE UPDATE ON public.fcm_tokens FOR EACH ROW EXECUTE FUNCTION update_timestamp();
