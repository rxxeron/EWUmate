-- Allow public (anon) to update active_semester
-- This is needed for the Admin Panel to save manual overrides
CREATE POLICY "Public update active_semester" ON public.active_semester 
  FOR UPDATE TO public USING (true) WITH CHECK (true);
