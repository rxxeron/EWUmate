
-- ==========================================
-- SETUP ACADEMIC DOCUMENTS STORAGE BUCKET
-- ==========================================

-- 1. Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('academic_documents', 'academic_documents', false)
ON CONFLICT (id) DO NOTHING;

-- 2. Allow anon role to upload files to this bucket
-- (Used by the Admin Panel to ingest PDF/JSON data)
DROP POLICY IF EXISTS "Allow anon uploads to academic_documents" ON storage.objects;
CREATE POLICY "Allow anon uploads to academic_documents"
ON storage.objects FOR INSERT
TO anon
WITH CHECK (bucket_id = 'academic_documents');

-- 3. Allow anon role to update files (for upsert support)
DROP POLICY IF EXISTS "Allow anon updates to academic_documents" ON storage.objects;
CREATE POLICY "Allow anon updates to academic_documents"
ON storage.objects FOR UPDATE
TO anon
USING (bucket_id = 'academic_documents');

-- 4. Allow anon to read for verification if needed (optional)
DROP POLICY IF EXISTS "Allow anon reading academic_documents" ON storage.objects;
CREATE POLICY "Allow anon reading academic_documents"
ON storage.objects FOR SELECT
TO anon
USING (bucket_id = 'academic_documents');
