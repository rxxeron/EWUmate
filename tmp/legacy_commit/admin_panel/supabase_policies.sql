-- Create the admin_users table
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Turn on Row Level Security
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Allow read access for authenticated admins only
CREATE POLICY "Admins can view admin_users" ON public.admin_users
    FOR SELECT USING (auth.uid() IN (SELECT user_id FROM public.admin_users));

-- Create policy for active_semester table so only admins can modify it
ALTER TABLE public.active_semester ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active semester" ON public.active_semester
    FOR SELECT USING (true);

CREATE POLICY "Only admins can update active semester" ON public.active_semester
    FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.admin_users));
