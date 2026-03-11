-- Create a central configuration table for remote control
CREATE TABLE IF NOT EXISTS public.app_config (
    id SERIAL PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    is_enabled BOOLEAN DEFAULT true,
    config_value JSONB DEFAULT '{}'::jsonb,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookup by key
CREATE INDEX IF NOT EXISTS idx_app_config_key ON public.app_config (key);

-- Populate with initial/essential flags
INSERT INTO public.app_config (key, is_enabled, config_value, description) VALUES
('maintenance_mode', true, '{"message": "System is under maintenance. Please try again later."}'::jsonb, 'Blocks app access with a custom maintenance message'),
('emergency_notice', false, '{"title": "Urgent Update", "message": "Example notice content", "type": "info"}'::jsonb, 'Shows a high-priority banner on the student dashboard'),
('scholarship_projection', true, '{}'::jsonb, 'Enables/Disables the AI-powered scholarship projection in Semester Summary'),
('attendance_module', true, '{}'::jsonb, 'Toggle for the Attendance tracking feature'),
('course_browser_module', true, '{}'::jsonb, 'Toggle for the Course Browser/History feature'),
('min_version', true, '{"android": "1.0.0", "ios": "1.0.0"}'::jsonb, 'Minimum supported app version before forcing update')
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Allow public read access (for the app)
CREATE POLICY "Allow public read-only access to app_config" 
ON public.app_config FOR SELECT 
TO anon, authenticated 
USING (true);

-- Allow service role full access
CREATE POLICY "Allow service_role full access to app_config" 
ON public.app_config FOR ALL 
TO service_role 
USING (true);
