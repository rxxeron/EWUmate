DROP POLICY IF EXISTS public_read_summer2026 ON courses_summer2026;
CREATE POLICY public_read_summer2026 ON courses_summer2026 FOR SELECT TO anon, authenticated USING (true);
