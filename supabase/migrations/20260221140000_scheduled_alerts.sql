-- Migration: Create scheduled_alerts table for cloud scheduling
CREATE TABLE IF NOT EXISTS scheduled_alerts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    trigger_at TIMESTAMP WITH TIME ZONE NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL, -- e.g., 'class_reminder', 'task_3d', 'daily_summary'
    alert_key TEXT NOT NULL, -- deduplication key: e.g., 'class_45m:CSE101:2026-02-21'
    metadata JSONB DEFAULT '{}'::jsonb,
    
    is_dispatched BOOLEAN DEFAULT FALSE,
    dispatched_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_alerts_trigger_dispatch ON scheduled_alerts (trigger_at) WHERE is_dispatched = FALSE;
CREATE INDEX IF NOT EXISTS idx_alerts_user_key ON scheduled_alerts (user_id, alert_key);

-- RLS
ALTER TABLE scheduled_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own scheduled alerts" ON scheduled_alerts FOR SELECT USING (auth.uid() = user_id);
