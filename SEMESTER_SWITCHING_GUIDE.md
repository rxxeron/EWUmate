# Automatic Semester Switching Setup

## 🎯 How It Works

### 1. **When Academic Calendar is Uploaded:**

Example: You upload `"Academic Calendar Spring 2026.pdf"`

**System Logic:**
- Current calendar semester: `Spring 2026`
- Expected **NEXT** semester: `Summer 2026`
- Scans calendar for: `"University Reopens for Summer 2026"`
- Found on date: `"May 12"`
- **Schedules switch:** May 12, 2026

**Semester Sequence:**
- Spring → Summer (same year)
- Summer → Fall (same year)  
- Fall → Spring (next year)

---

### 2. **Daily Automatic Check** (Midnight Dhaka Time)

**Cron job runs daily at 00:00 Dhaka (18:00 UTC):**
1. Checks `config.semester_switching` table
2. If `status = "pending"` AND `switchDate <= TODAY`
3. Updates `config.currentSemester` to next semester
4. Marks switch as `"completed"`

---

## 📋 Setup Instructions

### Step 1: Create Config Table

Run in **Supabase SQL Editor**:

```sql
-- Create config table
CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE config ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read access" ON config
  FOR SELECT USING (true);

-- Allow service role full access  
CREATE POLICY "Allow service role full access" ON config
  FOR ALL USING (auth.role() = 'service_role');

-- Insert default currentSemester
INSERT INTO config (key, value, updated_at)
VALUES ('currentSemester', '"Spring 2026"', NOW())
ON CONFLICT (key) DO NOTHING;
```

### Step 2: Create Semester Switching Functions

Run in **Supabase SQL Editor**:

```sql
-- Function to switch semester (executed once on scheduled date)
CREATE OR REPLACE FUNCTION switch_to_next_semester()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  switching_config JSONB;
  next_semester TEXT;
BEGIN
  SELECT value INTO switching_config FROM config WHERE key = 'semester_switching';
  
  IF switching_config IS NULL THEN RETURN; END IF;
  
  next_semester := switching_config->>'nextSemester';
  
  -- Update current semester
  UPDATE config SET value = to_jsonb(next_semester), updated_at = NOW()
  WHERE key = 'currentSemester';
  
  -- Mark switch as completed
  UPDATE config 
  SET value = jsonb_set(value, '{status}', '"completed"'::jsonb),
      updated_at = NOW()
  WHERE key = 'semester_switching';
  
  RAISE NOTICE 'Semester switched to: %', next_semester;
END;
$$;

-- Function to schedule the switch
CREATE OR REPLACE FUNCTION schedule_semester_switch(switch_date TIMESTAMPTZ, next_sem TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  job_name TEXT;
  cron_schedule TEXT;
BEGIN
  job_name := 'switch-to-' || REPLACE(LOWER(next_sem), ' ', '-');
  PERFORM cron.unschedule(job_name);
  cron_schedule := to_char(switch_date, 'MI HH24 DD MM') || ' *';
  PERFORM cron.schedule(job_name, cron_schedule, $$SELECT switch_to_next_semester();$$);
  RETURN 'Scheduled for ' || switch_date::TEXT;
END;
$$;

-- Trigger to auto-schedule when calendar is uploaded
CREATE OR REPLACE FUNCTION auto_schedule_semester_switch()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  next_semester TEXT;
  switch_date TIMESTAMPTZ;
BEGIN
  IF NEW.key = 'semester_switching' AND NEW.value->>'status' = 'scheduled' THEN
    next_semester := NEW.value->>'nextSemester';
    switch_date := (NEW.value->>'switchDate')::TIMESTAMPTZ;
    PERFORM schedule_semester_switch(switch_date, next_semester);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_schedule_semester_switch
  AFTER INSERT OR UPDATE ON config
  FOR EACH ROW
  EXECUTE FUNCTION auto_schedule_semester_switch();

GRANT EXECUTE ON FUNCTION switch_to_next_semester() TO service_role;
GRANT EXECUTE ON FUNCTION schedule_semester_switch(TIMESTAMPTZ, TEXT) TO service_role;
```

### Step 3: Enable pg_cron Extension

Run in **Supabase SQL Editor**:

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

**That's it!** No manual cron job setup needed - the system automatically schedules semester switches when you upload calendars.

---

## 🧪 Testing

### Manual Test Switch:

```sql
-- Manually trigger semester switch
SELECT switch_to_next_semester();

-- Check current semester
SELECT * FROM config WHERE key = 'currentSemester';
```

### Test Automatic Scheduling:

1. Go to **https://admin.rxxeron.me**
2. Upload: `"Academic Calendar Spring 2026.pdf"`
3. Make sure it contains: `"University Reopens for Summer 2026"` with a date
4. Check what got scheduled:

```sql
-- View scheduled cron jobs
SELECT * FROM cron.job;
-- You should see a job like: 'switch-to-summer-2026'

-- View the schedule config
SELECT * FROM config WHERE key = 'semester_switching';
```

5. For immediate testing, update the switch date to now:

```sql
-- Set switch date to 1 minute from now for testing
UPDATE config 
SET value = jsonb_set(
  value, 
  '{switchDate}', 
  to_jsonb((NOW() + INTERVAL '1 minute')::TEXT)
)
WHERE key = 'semester_switching';

-- This will trigger the auto_schedule trigger and reschedule the job
-- Wait 1 minute, then check:
SELECT * FROM config WHERE key = 'currentSemester';
-- Should be "Summer 2026"
```

---

## 📊 Database Schema

### config table structure:

| key | value | updated_at |
|-----|-------|------------|
| `currentSemester` | `"Spring 2026"` | 2026-02-15 |
| `semester_switching` | `{"nextSemester": "Summer 2026", "switchDate": "2026-05-12T00:00:00Z", "status": "pending", "identifiedAt": "2026-02-15T..."}` | 2026-02-15 |

---

## 🔄 Complete Flow Example

1. **Upload Calendar:** `Academic Calendar Spring 2026.pdf`
2. **System detects:** Current = Spring 2026, Next = Summer 2026
3. **System finds:** "University Reopens for Summer 2026" on "May 12"
4. **System saves config:**
   ```json
   {
     "nextSemester": "Summer 2026",
     "switchDate": "2026-05-12T00:00:00Z",
     "status": "scheduled"
   }
   ```
5. **Database trigger automatically:**
   - Creates cron job: `switch-to-summer-2026`
   - Scheduled for: May 12, 2026 at 00:00
   - Command: `SELECT switch_to_next_semester();`
6. **On May 12, 2026 at midnight:**
   - Cron job executes ONCE
   - Updates `currentSemester` to "Summer 2026"
   - Marks switch as `"completed"`
7. **Result:** All users now see Summer 2026 data! 🎉

**Key advantage:** No daily checks needed - the job runs exactly once on the scheduled date!

---

## ✅ Verification Commands

```sql
-- View all config
SELECT * FROM config;

-- View current semester
SELECT value FROM config WHERE key = 'currentSemester';

-- View pending switches
SELECT value FROM config WHERE key = 'semester_switching';

-- Test the switch function
SELECT check_and_switch_semester();

-- View cron jobs
SELECT * FROM cron.job;
```

---

## 🚀 You're All Set!

Your system now automatically switches semesters based on the academic calendar - just like your Firebase setup! 🎉
