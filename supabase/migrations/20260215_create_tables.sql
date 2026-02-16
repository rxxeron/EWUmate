-- Create tables for Spring 2026 semester
-- These will be created dynamically based on semester name

-- Courses table
CREATE TABLE IF NOT EXISTS courses_Spring2026 (
  doc_id TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  section TEXT,
  course_name TEXT,
  credits INTEGER DEFAULT 0,
  capacity TEXT,
  type TEXT,
  semester TEXT,
  sessions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Calendar table
CREATE TABLE IF NOT EXISTS calendar_Spring2026 (
  doc_id TEXT PRIMARY KEY,
  date TEXT,
  day TEXT,
  event TEXT,
  type TEXT,
  semester TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exams table
CREATE TABLE IF NOT EXISTS exams_Spring2026 (
  doc_id TEXT PRIMARY KEY,
  class_days TEXT,
  last_class_date TEXT,
  exam_day TEXT,
  exam_date TEXT,
  semester TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Config table (if not exists)
CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Advising schedules
CREATE TABLE IF NOT EXISTS advising_schedules (
  semester_id TEXT PRIMARY KEY,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Advising schedule slots
CREATE TABLE IF NOT EXISTS advising_schedule_slots (
  slot_id TEXT PRIMARY KEY,
  semester_id TEXT,
  display_time TEXT,
  start_time TEXT,
  end_time TEXT,
  min_credits INTEGER DEFAULT 0,
  max_credits INTEGER DEFAULT 999,
  schedule_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE courses_Spring2026 ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_Spring2026 ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams_Spring2026 ENABLE ROW LEVEL SECURITY;
ALTER TABLE config ENABLE ROW LEVEL SECURITY;
ALTER TABLE advising_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE advising_schedule_slots ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Allow public read" ON courses_Spring2026 FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON calendar_Spring2026 FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON exams_Spring2026 FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON config FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON advising_schedules FOR SELECT USING (true);
CREATE POLICY "Allow public read" ON advising_schedule_slots FOR SELECT USING (true);

-- Create policies for service role full access
CREATE POLICY "Allow service role full access" ON courses_Spring2026 
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow service role full access" ON calendar_Spring2026 
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow service role full access" ON exams_Spring2026 
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow service role full access" ON config 
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow service role full access" ON advising_schedules 
  FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow service role full access" ON advising_schedule_slots 
  FOR ALL USING (auth.role() = 'service_role');

-- Insert default current semester
INSERT INTO config (key, value, updated_at)
VALUES ('currentSemester', '"Spring 2026"', NOW())
ON CONFLICT (key) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_courses_code ON courses_Spring2026(code);
CREATE INDEX IF NOT EXISTS idx_courses_section ON courses_Spring2026(section);
CREATE INDEX IF NOT EXISTS idx_calendar_date ON calendar_Spring2026(date);
CREATE INDEX IF NOT EXISTS idx_exams_class_days ON exams_Spring2026(class_days);
CREATE INDEX IF NOT EXISTS idx_advising_slots_semester ON advising_schedule_slots(semester_id);
