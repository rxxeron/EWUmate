-- ==========================================
-- EWUMATE SCHEMA MIGRATION: Recalculation RPC
-- ==========================================

-- 1. Function to recalculate results for ALL users
CREATE OR REPLACE FUNCTION public.recalculate_all_academic_results()
RETURNS void AS $$
BEGIN
    UPDATE public.academic_data SET semesters = semesters;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to recalculate results for a SPECIFIC user
CREATE OR REPLACE FUNCTION public.recalculate_user_results(target_user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.academic_data 
    SET semesters = semesters 
    WHERE user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
