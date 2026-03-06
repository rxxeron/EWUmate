-- Enable RLS on specific semester tables that were flagged by the Supabase Linter
ALTER TABLE IF EXISTS public.courses_spring2026 ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public."courses_Spring2026" ENABLE ROW LEVEL SECURITY;

-- Apply public read security policy to these tables (like the main courses table)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_class WHERE relname = 'courses_spring2026' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
        DROP POLICY IF EXISTS "Public read courses_spring2026" ON public.courses_spring2026;
        CREATE POLICY "Public read courses_spring2026" ON public.courses_spring2026 FOR SELECT TO public USING (true);
    END IF;
    
    IF EXISTS (SELECT FROM pg_class WHERE relname = 'courses_Spring2026' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
        DROP POLICY IF EXISTS "Public read courses_Spring2026" ON public."courses_Spring2026";
        CREATE POLICY "Public read courses_Spring2026" ON public."courses_Spring2026" FOR SELECT TO public USING (true);
    END IF;
END $$;
