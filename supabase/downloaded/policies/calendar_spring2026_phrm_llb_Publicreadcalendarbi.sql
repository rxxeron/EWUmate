-- Table: calendar_spring2026_phrm_llb
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE calendar_spring2026_phrm_llb ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read calendar bi" ON "calendar_spring2026_phrm_llb"
FOR SELECT
TO public
USING (true)
;
