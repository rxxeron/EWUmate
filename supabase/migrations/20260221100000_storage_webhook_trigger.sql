-- ==========================================
-- STORAGE WEBHOOK: Auto-trigger Azure Function on file uploads
-- ==========================================
-- This trigger fires whenever a file is INSERT-ed or UPDATE-d in storage.objects
-- and sends the event payload to the Azure Function webhook endpoint via pg_net.

-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION notify_azure_on_storage_change()
RETURNS TRIGGER AS $$
DECLARE
  v_url text;
  v_body jsonb;
BEGIN
  -- Build JSON payload matching what ewumate_webhook expects
  v_body := jsonb_build_object(
    'type', TG_OP,
    'record', jsonb_build_object(
      'id', NEW.id,
      'name', NEW.name,
      'bucket_id', NEW.bucket_id,
      'owner', NEW.owner,
      'created_at', NEW.created_at,
      'updated_at', NEW.updated_at,
      'metadata', NEW.metadata
    )
  );

  -- Only fire for our 'academic_documents' bucket (skip profile_images, avatars, etc.)
  IF NEW.bucket_id != 'academic_documents' THEN
    RETURN NEW;
  END IF;

  -- Azure Function webhook URL
  -- The function key is stored in a config table for security
  v_url := COALESCE(
    (SELECT value->>'azure_webhook_url' FROM config WHERE key = 'edge_functions'),
    'https://ewumate-parser.azurewebsites.net/api/webhooks/storage'
  );

  -- Fire-and-forget HTTP POST via pg_net
  BEGIN
    PERFORM net.http_post(
      url := v_url,
      body := v_body,
      headers := '{"Content-Type": "application/json"}'::jsonb
    );
  EXCEPTION WHEN others THEN
    -- Don't block storage operations if the webhook fails
    RAISE LOG 'Azure webhook call failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Drop existing trigger if any
DROP TRIGGER IF EXISTS trigger_azure_storage_webhook ON storage.objects;

-- 3. Create trigger on INSERT and UPDATE
CREATE TRIGGER trigger_azure_storage_webhook
AFTER INSERT OR UPDATE ON storage.objects
FOR EACH ROW
EXECUTE FUNCTION notify_azure_on_storage_change();
