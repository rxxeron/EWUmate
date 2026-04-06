-- Table: notifications
-- Roles: ['public']
-- Command: UPDATE
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users update own notifications" ON "notifications"
FOR UPDATE
TO public
USING ((auth.uid() = user_id))
;
