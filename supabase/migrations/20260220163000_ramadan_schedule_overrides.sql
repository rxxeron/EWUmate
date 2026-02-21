-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Ramadan Schedule Overrides
-- ==========================================

-- 1. Create the Overrides Table
CREATE TABLE IF NOT EXISTS public.schedule_overrides (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT false,
    original_start TEXT NOT NULL,
    original_end TEXT NOT NULL,
    new_start TEXT NOT NULL,
    new_end TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Note: We map exactly how the app caches times
-- Example: '08:30 AM', '10:00 AM' -> '09:00 AM', '10:20 AM'

-- Protect the table
ALTER TABLE public.schedule_overrides ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable read access for authenticated users to overrides" ON public.schedule_overrides;
CREATE POLICY "Enable read access for authenticated users to overrides"
    ON public.schedule_overrides FOR SELECT TO authenticated USING (true);


-- 2. Populate the table with the provided Ramadan layout
-- We default them to inactive. To enable, flip is_active = true
INSERT INTO public.schedule_overrides (name, original_start, original_end, new_start, new_end, is_active)
VALUES
    -- THEORY CLASSES
    ('Ramadan', '08:30 AM', '10:00 AM', '09:00 AM', '10:20 AM', false),
    ('Ramadan', '10:10 AM', '11:40 AM', '10:30 AM', '11:50 AM', false),
    ('Ramadan', '11:50 AM', '01:20 PM', '12:00 PM', '01:20 PM', false), -- '12:00 NOON' standardizes to '12:00 PM' generally
    ('Ramadan', '01:30 PM', '03:00 PM', '01:30 PM', '02:50 PM', false),
    ('Ramadan', '03:10 PM', '04:40 PM', '03:00 PM', '04:20 PM', false),
    ('Ramadan', '04:50 PM', '06:20 PM', '04:30 PM', '05:50 PM', false),
    
    -- LAB CLASSES (2 HOUR)
    ('Ramadan', '08:00 AM', '10:00 AM', '08:35 AM', '10:20 AM', false),
    ('Ramadan', '10:10 AM', '12:10 PM', '10:30 AM', '12:15 PM', false),
    ('Ramadan', '01:30 PM', '03:30 PM', '01:30 PM', '03:15 PM', false),
    ('Ramadan', '04:50 PM', '06:50 PM', '04:25 PM', '05:55 PM', false),
    
    -- LAB CLASSES (3 HOUR)
    ('Ramadan', '08:00 AM', '11:00 AM', '08:35 AM', '11:15 AM', false),
    ('Ramadan', '10:10 AM', '01:10 PM', '10:30 AM', '01:10 PM', false),
    ('Ramadan', '01:30 PM', '04:30 PM', '01:30 PM', '04:10 PM', false),
    ('Ramadan', '04:50 PM', '07:50 PM', '04:30 PM', '07:30 PM', false)
ON CONFLICT DO NOTHING;

-- 3. The Re-writer Trigger Function
CREATE OR REPLACE FUNCTION public.apply_schedule_overrides()
RETURNS trigger AS $$
DECLARE
    override_record record;
    day_key text;
    day_classes jsonb;
    class_idx int;
    class_obj jsonb;
    modified_template jsonb;
BEGIN
    -- If there's no weekly template, do nothing
    IF NEW.weekly_template IS NULL OR jsonb_typeof(NEW.weekly_template) != 'object' THEN
        RETURN NEW;
    END IF;

    -- Copy the incoming template
    modified_template := NEW.weekly_template;

    -- Loop through active overrides
    FOR override_record IN SELECT * FROM public.schedule_overrides WHERE is_active = true
    LOOP
        -- Loop through the Days (Sunday, Monday, etc.) in the JSON object
        FOR day_key IN SELECT jsonb_object_keys(modified_template)
        LOOP
            day_classes := modified_template->day_key;
            
            -- If the day has classes (is an array)
            IF jsonb_typeof(day_classes) = 'array' THEN
                
                -- Loop backward through the array so we can replace safely
                FOR class_idx IN REVERSE jsonb_array_length(day_classes)-1 .. 0
                LOOP
                    class_obj := day_classes->class_idx;
                    
                    -- If the class matches the original constraints precisely
                    IF (class_obj->>'startTime') = override_record.original_start AND 
                       (class_obj->>'endTime') = override_record.original_end THEN
                       
                       -- Mutate the JSON object with the new times
                       class_obj := jsonb_set(class_obj, '{startTime}', to_jsonb(override_record.new_start));
                       class_obj := jsonb_set(class_obj, '{endTime}', to_jsonb(override_record.new_end));
                       
                       -- Put the mutated class back into the array slot
                       day_classes := jsonb_set(day_classes, ARRAY[class_idx::text], class_obj);

                    END IF;
                END LOOP;
                
                -- Put the mutated array back into the day key
                modified_template := jsonb_set(modified_template, ARRAY[day_key], day_classes);
            END IF;
        END LOOP;
    END LOOP;

    -- Assign the fully processed JSON dict back to the row
    NEW.weekly_template := modified_template;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Attach Trigger to user_schedules Table
DROP TRIGGER IF EXISTS trigger_apply_schedule_overrides ON public.user_schedules;

CREATE TRIGGER trigger_apply_schedule_overrides
    BEFORE INSERT OR UPDATE OF weekly_template
    ON public.user_schedules
    FOR EACH ROW
    EXECUTE FUNCTION public.apply_schedule_overrides();
