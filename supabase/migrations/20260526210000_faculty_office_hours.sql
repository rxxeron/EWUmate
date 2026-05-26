-- 1. Add purpose column to drive_accounts to isolate pools
ALTER TABLE public.drive_accounts 
ADD COLUMN IF NOT EXISTS purpose TEXT NOT NULL DEFAULT 'study_vault';

-- 2. Seed the dedicated Office Hours Google Drive account
INSERT INTO public.drive_accounts (
    id,
    email,
    folder_id,
    service_account_json,
    total_capacity_bytes,
    used_bytes,
    is_active,
    purpose,
    created_at
) VALUES (
    '9b79728b-d8c9-4bfa-b807-46e43dd13d7e',
    'rhrakiubulh00@gmail.com',
    '15jxYYViGaJV18gAOmbO2ibheru4VdzlL',
    '{"client_id": "324713627379-m6s7efnft1tcsvmukrsrp64itn2nn6oq.apps.googleusercontent.com", "client_secret": "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", "refresh_token": "1//0gk8VALbOLYOpCgYIARAAGBASNwF-L9Ir3D0gCjxc1vgXaPcyVjwfEDnt2pp8502sWhwfklsDHVLW7fsk8y07nhMZanSRgH3C8Ss"}',
    16106127360,
    0,
    true,
    'office_hours',
    '2026-05-26 15:37:06.379146+00'
) ON CONFLICT (id) DO UPDATE 
SET purpose = 'office_hours',
    folder_id = EXCLUDED.folder_id,
    service_account_json = EXCLUDED.service_account_json,
    is_active = true;

-- 3. Create the Faculty Office Hours table
CREATE TABLE IF NOT EXISTS public.faculty_office_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_initials TEXT NOT NULL,         -- Match with faculty_master(short_name)
    day TEXT NOT NULL,                      -- e.g., 'Sunday', 'Monday'
    start_time TEXT NOT NULL,               -- e.g., '10:00 AM'
    end_time TEXT NOT NULL,                 -- e.g., '11:30 AM'
    drive_account_id UUID REFERENCES public.drive_accounts(id) ON DELETE SET NULL,
    drive_file_id TEXT NOT NULL,            -- Google Drive File ID
    file_name TEXT NOT NULL,                -- Proof file name
    submitted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexing for fast retrieval
CREATE INDEX IF NOT EXISTS idx_foh_faculty ON public.faculty_office_hours(faculty_initials);
CREATE INDEX IF NOT EXISTS idx_foh_status ON public.faculty_office_hours(status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.faculty_office_hours ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view approved office hours" 
ON public.faculty_office_hours FOR SELECT 
USING (status = 'approved' OR auth.uid() = submitted_by);

CREATE POLICY "Authenticated users can submit office hours" 
ON public.faculty_office_hours FOR INSERT 
WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = submitted_by);

CREATE POLICY "Users can delete their own pending submissions" 
ON public.faculty_office_hours FOR DELETE 
USING (auth.uid() = submitted_by AND status = 'pending');

-- 4. Grant privileges to standard Supabase client roles
GRANT SELECT, INSERT, UPDATE, DELETE ON public.faculty_office_hours TO authenticated;
GRANT SELECT ON public.faculty_office_hours TO anon;
GRANT ALL PRIVILEGES ON public.faculty_office_hours TO service_role;
GRANT ALL PRIVILEGES ON public.faculty_office_hours TO postgres;

