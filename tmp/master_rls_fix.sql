-- MASTER RLS FIX FOR ADMIN PANEL
-- This script grants ALL permissions to users in the admin_users table for all core metadata and dynamic tables.

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin() 
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (auth.uid() IN (SELECT user_id FROM admin_users));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Define a macro-like procedure to apply admin policies to a table
CREATE OR REPLACE PROCEDURE apply_admin_policy(target_table TEXT)
AS $$
BEGIN
  -- Enable RLS just in case
  EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', target_table);
  
  -- Drop existing manage policy if it exists to avoid conflicts
  EXECUTE format('DROP POLICY IF EXISTS "Admins can manage %s" ON %I', target_table, target_table);
  EXECUTE format('DROP POLICY IF EXISTS "Admins manage %s" ON %I', target_table, target_table);
  
  -- Create the manage policy
  EXECUTE format('CREATE POLICY "Admins manage %s" ON %I FOR ALL TO public USING (is_admin()) WITH CHECK (is_admin())', target_table, target_table);
  
  RAISE NOTICE 'Applied manage policy to %', target_table;
END;
$$ LANGUAGE plpgsql;

-- Apply to all relevant tables
DO $$
DECLARE
    t TEXT;
    tables_to_fix TEXT[] := ARRAY[
        'active_semester',
        'semesters',
        'programs',
        'app_config',
        'course_metadata',
        'scholarship_policies',
        'grade_scale',
        'courses_spring2026',
        'courses_summer2026',
        'calendar_spring2026',
        'calendar_spring2026_phrm_llb',
        'calendar_summer2026',
        'notifications',
        'feedbacks'
    ];
BEGIN
    FOREACH t IN ARRAY tables_to_fix LOOP
        -- Check if table exists before applying
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t) THEN
            CALL apply_admin_policy(t);
        END IF;
    END LOOP;
END $$;
