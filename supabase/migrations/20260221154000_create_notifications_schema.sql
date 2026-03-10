-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'system',
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create scheduled_alerts table for Azure to process
CREATE TABLE IF NOT EXISTS public.scheduled_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    trigger_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_dispatched BOOLEAN DEFAULT FALSE,
    dispatched_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_alerts ENABLE ROW LEVEL SECURITY;

-- Create Policies (Safely)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'notifications' AND policyname = 'Users can manage own notifications'
    ) THEN
        CREATE POLICY "Users can manage own notifications" 
        ON public.notifications FOR ALL 
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scheduled_alerts' AND policyname = 'Users can manage own scheduled_alerts'
    ) THEN
        CREATE POLICY "Users can manage own scheduled_alerts" 
        ON public.scheduled_alerts FOR ALL 
        USING (auth.uid() = user_id);
    END IF;
END
$$;

-- Enable Supabase Realtime for notifications (Safely)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
    END IF;
END
$$;
