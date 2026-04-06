-- Table: notifications
-- Roles: ['public']
-- Command: SELECT
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own or broadcast notifications" ON "notifications"
FOR SELECT
TO public
USING (((auth.uid() = user_id) OR (user_id IS NULL)))
;
