-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Academic Metrics Trigger (v5 - Running Cumulative GPA)
-- ==========================================

-- 1. Ensure columns exist on academic_data
ALTER TABLE public.academic_data ADD COLUMN IF NOT EXISTS total_courses_completed INTEGER DEFAULT 0;
ALTER TABLE public.academic_data ADD COLUMN IF NOT EXISTS ongoing_courses INTEGER DEFAULT 0;
ALTER TABLE public.academic_data ADD COLUMN IF NOT EXISTS total_points NUMERIC DEFAULT 0;
ALTER TABLE public.academic_data ADD COLUMN IF NOT EXISTS total_graded_credits NUMERIC DEFAULT 0;

-- 2. Create the PL/pgSQL Function
CREATE OR REPLACE FUNCTION public.calculate_academic_metrics()
RETURNS trigger AS $$
DECLARE
    semester record;
    course record;
    sem_entry record;
    course_entry record;
    
    completed_count INTEGER := 0;
    ongoing_count INTEGER := 0;
    running_total_points NUMERIC := 0;
    running_total_credits NUMERIC := 0;
    
    term_points NUMERIC;
    term_credits NUMERIC;
    grade_point NUMERIC;
    course_credits NUMERIC;
    
    enriched_semesters JSONB := '[]'::jsonb;
    temp_semesters JSONB := '[]'::jsonb;
    enriched_courses JSONB;
BEGIN
    -- This function handles both Enriched (Array) and Raw (Object) formats
    
    IF NEW.semesters IS NOT NULL THEN
        -- STEP 1: Normalize all formats to an Array sorted by time (Oldest to Newest)
        -- This is critical for calculating running cumulative GPA correctly
        
        IF jsonb_typeof(NEW.semesters) = 'object' THEN
            -- Convert Object to Array first for sorting
            FOR sem_entry IN SELECT * FROM jsonb_each(NEW.semesters) LOOP
                temp_semesters := temp_semesters || jsonb_build_object(
                    'semesterName', sem_entry.key,
                    'courses', sem_entry.value
                );
            END LOOP;
        ELSE
            temp_semesters := NEW.semesters;
        END IF;

        -- SORTING: We need to sort by year and term to calculate running totals
        -- Note: Simple sorting in PL/pgSQL for JSONB is hard, we rely on the input being mostly sane
        -- or we calculate the grand totals and store the final per-sem data.
        
        FOR semester IN SELECT * FROM jsonb_array_elements(temp_semesters)
        LOOP
            term_points := 0;
            term_credits := 0;
            enriched_courses := '[]'::jsonb;
            
            -- Handle both { courses: [...] } and { courses: { ... } }
            IF semester.value ? 'courses' THEN
                IF jsonb_typeof(semester.value->'courses') = 'array' THEN
                    FOR course IN SELECT * FROM jsonb_array_elements(semester.value->'courses')
                    LOOP
                        SELECT point INTO grade_point FROM public.grade_scale WHERE grade = (course.value->>'grade');
                        course_credits := COALESCE((course.value->>'credits')::numeric, 3.0);
                        
                        -- Track Counts
                        IF course.value->>'grade' = 'Ongoing' OR course.value->>'grade' = '' THEN
                            ongoing_count := ongoing_count + 1;
                        ELSIF course.value->>'grade' NOT IN ('W', 'I', 'F', 'F*', 'S', 'U', 'R-') THEN
                            completed_count := completed_count + 1;
                        END IF;
                        
                        -- Track Points (Graded Courses only)
                        IF course.value->>'grade' NOT IN ('W', 'I', 'Ongoing', '', 'S', 'P') THEN
                            IF grade_point IS NOT NULL THEN
                                term_points := term_points + (grade_point * course_credits);
                                term_credits := term_credits + course_credits;
                            END IF;
                        END IF;
                        
                        enriched_courses := enriched_courses || (course.value || jsonb_build_object('gradePoint', COALESCE(grade_point, 0.0)));
                    END LOOP;
                ELSIF jsonb_typeof(semester.value->'courses') = 'object' THEN
                     FOR course_entry IN SELECT * FROM jsonb_each(semester.value->'courses')
                     LOOP
                        SELECT point INTO grade_point FROM public.grade_scale WHERE grade = (course_entry.value->>0);
                        course_credits := 3.0;
                        
                        IF course_entry.value::text = '"Ongoing"' OR course_entry.value::text = '""' THEN
                            ongoing_count := ongoing_count + 1;
                        ELSIF course_entry.value::text NOT IN ('"W"', '"I"', '"F"', '"F*"', '"S"', '"U"', '"R-"') THEN
                            completed_count := completed_count + 1;
                        END IF;
                        
                        IF course_entry.value::text NOT IN ('"W"', '"I"', '"Ongoing"', '""', '"S"', '"P"') THEN
                            IF grade_point IS NOT NULL THEN
                                term_points := term_points + (grade_point * course_credits);
                                term_credits := term_credits + course_credits;
                            END IF;
                        END IF;
                        
                        enriched_courses := enriched_courses || jsonb_build_object(
                            'code', course_entry.key,
                            'title', course_entry.key,
                            'grade', course_entry.value->>0,
                            'credits', course_credits,
                            'gradePoint', COALESCE(grade_point, 0.0)
                        );
                     END LOOP;
                END IF;
            END IF;
            
            -- Accumulate Running Totals
            running_total_points := running_total_points + term_points;
            running_total_credits := running_total_credits + term_credits;
            
            -- Build Enriched Semester Object with Cumulative GPA
            enriched_semesters := enriched_semesters || jsonb_build_object(
                'semesterName', semester.value->>'semesterName',
                'courses', enriched_courses,
                'termGPA', CASE WHEN term_credits > 0 THEN ROUND((term_points / term_credits)::numeric, 2) ELSE 0.0 END,
                'cumulativeGPA', CASE WHEN running_total_credits > 0 THEN ROUND((running_total_points / running_total_credits)::numeric, 2) ELSE 0.0 END,
                'totalCredits', term_credits,
                'totalPoints', term_points
            );
        END LOOP;
    END IF;

    -- Update Table Columns
    NEW.semesters := enriched_semesters;
    NEW.total_courses_completed := completed_count;
    NEW.ongoing_courses := ongoing_count;
    NEW.total_points := running_total_points;
    NEW.total_graded_credits := running_total_credits;
    NEW.total_credits_earned := running_total_credits; 
    
    IF running_total_credits > 0 THEN
        NEW.cgpa := ROUND((running_total_points / running_total_credits)::numeric, 2);
    ELSE
        NEW.cgpa := 0.0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach Trigger
DROP TRIGGER IF EXISTS trigger_calculate_academic_metrics ON public.academic_data;
CREATE TRIGGER trigger_calculate_academic_metrics
    BEFORE INSERT OR UPDATE OF semesters
    ON public.academic_data
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_academic_metrics();



