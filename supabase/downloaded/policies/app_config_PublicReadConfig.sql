-- Table: app_config
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read Config" ON "app_config"
FOR SELECT
TO public
USING (true)
;
