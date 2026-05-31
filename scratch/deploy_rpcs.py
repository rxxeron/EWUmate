import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def deploy_rpcs():
    print("Connecting to Supabase PostgreSQL database to deploy RPCs...")
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        # 1. Deploy get_admin_dashboard_stats RPC
        print("Deploying public.get_admin_dashboard_stats() function...")
        cur.execute("""
            CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
            RETURNS jsonb SECURITY DEFINER AS $$
            DECLARE
              yesterday_iso TIMESTAMPTZ;
              last_7_days_iso TIMESTAMPTZ;
              last_14_days_iso TIMESTAMPTZ;
              
              users_count INT;
              active_users_24h INT;
              programs_count INT;
              notices_count INT;
              
              feedbacks_pending INT;
              feedbacks_in_progress INT;
              feedbacks_resolved INT;
              feedbacks_ignored INT;
              
              vault_pending INT;
              vault_removal INT;
              vault_approved INT;
              vault_rejected INT;
              vault_total INT;
              
              recent_users JSONB;
              active_users JSONB;
              
              active_sems JSONB;
              sem_stats JSONB := '{}'::jsonb;
              total_active_courses INT := 0;
              
              reg_trend JSONB;
              act_trend JSONB;
              
              result JSONB;
              
              -- variables for sem loops
              sem_record RECORD;
              current_code TEXT;
              next_code TEXT;
              table_name TEXT;
              c_sections INT;
              c_courses INT;
              n_sections INT;
              n_courses INT;
              single_sem_stats JSONB;
            BEGIN
              yesterday_iso := now() - INTERVAL '24 hours';
              last_7_days_iso := now() - INTERVAL '6 days';
              last_14_days_iso := now() - INTERVAL '13 days';

              -- Primary metrics counts
              SELECT count(*) INTO users_count FROM public.profiles;
              SELECT count(*) INTO active_users_24h FROM public.profiles WHERE last_active_at >= yesterday_iso;
              SELECT count(*) INTO programs_count FROM public.programs;
              SELECT count(*) INTO notices_count FROM public.notifications;

              -- Feedbacks counts
              SELECT count(*) INTO feedbacks_pending FROM public.feedbacks WHERE status = 'pending';
              SELECT count(*) INTO feedbacks_in_progress FROM public.feedbacks WHERE status = 'in_progress';
              SELECT count(*) INTO feedbacks_resolved FROM public.feedbacks WHERE status = 'resolved';
              SELECT count(*) INTO feedbacks_ignored FROM public.feedbacks WHERE status = 'ignored';

              -- Vault counts
              SELECT count(*) INTO vault_pending FROM public.study_materials WHERE status = 'pending';
              SELECT count(*) INTO vault_removal FROM public.study_materials WHERE status = 'removal_requested';
              SELECT count(*) INTO vault_approved FROM public.study_materials WHERE status = 'approved';
              SELECT count(*) INTO vault_rejected FROM public.study_materials WHERE status = 'rejected';
              SELECT count(*) INTO vault_total FROM public.study_materials;

              -- Recent/Active lists
              SELECT coalesce(jsonb_agg(r), '[]'::jsonb) INTO recent_users FROM (
                SELECT id, full_name, student_id, program_code, department_name, created_at, last_active_at, app_open_count 
                FROM public.profiles 
                ORDER BY created_at DESC LIMIT 5
              ) r;

              SELECT coalesce(jsonb_agg(a), '[]'::jsonb) INTO active_users FROM (
                SELECT id, full_name, student_id, last_active_at, app_open_count 
                FROM public.profiles 
                ORDER BY last_active_at DESC LIMIT 5
              ) a;

              -- Dynamic Course metrics for Active Semesters
              SELECT jsonb_agg(s) INTO active_sems FROM public.active_semester s;
              
              IF active_sems IS NOT NULL THEN
                FOR sem_record IN SELECT * FROM jsonb_to_recordset(active_sems) AS (
                  track TEXT, current_semester_code TEXT, next_semester_code TEXT, 
                  is_advising_open BOOLEAN, is_next_semester_open BOOLEAN
                ) LOOP
                  current_code := sem_record.current_semester_code;
                  next_code := sem_record.next_semester_code;
                  c_sections := 0;
                  c_courses := 0;
                  n_sections := 0;
                  n_courses := 0;

                  -- Current Semester Courses Stats
                  IF current_code IS NOT NULL AND current_code <> '' THEN
                    table_name := 'courses_' || lower(regexp_replace(current_code, '[\\s_]+', '', 'g'));
                    BEGIN
                      EXECUTE format('SELECT count(*) FROM public.%I', table_name) INTO c_sections;
                      EXECUTE format('SELECT count(distinct course_code) FROM public.%I', table_name) INTO c_courses;
                      total_active_courses := total_active_courses + c_courses;
                    EXCEPTION WHEN OTHERS THEN
                      c_sections := 0;
                      c_courses := 0;
                    END;
                  END IF;

                  -- Next Semester Courses Stats
                  IF next_code IS NOT NULL AND next_code <> '' THEN
                    table_name := 'courses_' || lower(regexp_replace(next_code, '[\\s_]+', '', 'g'));
                    BEGIN
                      EXECUTE format('SELECT count(*) FROM public.%I', table_name) INTO n_sections;
                      EXECUTE format('SELECT count(distinct course_code) FROM public.%I', table_name) INTO n_courses;
                    EXCEPTION WHEN OTHERS THEN
                      n_sections := 0;
                      n_courses := 0;
                    END;
                  END IF;

                  single_sem_stats := jsonb_build_object(
                    'current', current_code,
                    'next', next_code,
                    'current_courses', c_courses,
                    'current_sections', c_sections,
                    'next_courses', n_courses,
                    'next_sections', n_sections,
                    'is_advising_open', coalesce(sem_record.is_advising_open, false),
                    'is_next_semester_open', coalesce(sem_record.is_next_semester_open, false)
                  );

                  sem_stats := sem_stats || jsonb_build_object(sem_record.track, single_sem_stats);
                END LOOP;
              END IF;

              -- Growth Trend Data (Last 14 Days)
              SELECT coalesce(jsonb_agg(t), '[]'::jsonb) INTO reg_trend FROM (
                WITH date_series AS (
                  SELECT generate_series(
                    current_date - INTERVAL '13 days', 
                    current_date, 
                    '1 day'::interval
                  )::date AS d
                ),
                day_counts AS (
                  SELECT created_at::date AS c_date, count(*) AS cnt 
                  FROM public.profiles 
                  WHERE created_at >= last_14_days_iso
                  GROUP BY created_at::date
                ),
                growth_cumulative AS (
                  SELECT 
                    to_char(ds.d, 'Mon DD') AS date_label,
                    coalesce(dc.cnt, 0) AS count,
                    (users_count - (SELECT count(*) FROM public.profiles WHERE created_at >= last_14_days_iso)) 
                    + sum(coalesce(dc.cnt, 0)) OVER (ORDER BY ds.d) AS total
                  FROM date_series ds
                  LEFT JOIN day_counts dc ON ds.d = dc.c_date
                )
                SELECT date_label AS "date", count, total FROM growth_cumulative
              ) t;

              -- Activity Trend Data (Last 7 Days)
              SELECT coalesce(jsonb_agg(at_rows), '[]'::jsonb) INTO act_trend FROM (
                WITH date_series AS (
                  SELECT generate_series(
                    current_date - INTERVAL '6 days', 
                    current_date, 
                    '1 day'::interval
                  )::date AS d
                ),
                active_counts AS (
                  SELECT activity_date, dau 
                  FROM public.daily_active_users_metrics 
                  WHERE activity_date >= (current_date - INTERVAL '6 days')
                )
                SELECT 
                  to_char(ds.d, 'Mon DD') AS "date",
                  coalesce(ac.dau, 0) AS active
                FROM date_series ds
                LEFT JOIN active_counts ac ON ds.d = ac.activity_date
                ORDER BY ds.d ASC
              ) at_rows;

              -- Construct final single JSON result
              result := jsonb_build_object(
                'stats', jsonb_build_object(
                  'users', users_count,
                  'activeUsers24h', active_users_24h,
                  'programs', programs_count,
                  'courses', total_active_courses,
                  'notifications', notices_count,
                  'pendingFeedbacks', feedbacks_pending,
                  'inProgressFeedbacks', feedbacks_in_progress,
                  'resolvedFeedbacks', feedbacks_resolved,
                  'ignoredFeedbacks', feedbacks_ignored
                ),
                'vaultStats', jsonb_build_object(
                  'pending', vault_pending,
                  'removalRequested', vault_removal,
                  'approved', vault_approved,
                  'rejected', vault_rejected,
                  'total', vault_total
                ),
                'recentUsers', recent_users,
                'activeUsers', active_users,
                'semesterStats', sem_stats,
                'registrationTrend', reg_trend,
                'activityTrend', act_trend
              );

              RETURN result;
            END;
            $$ LANGUAGE plpgsql;
        """)

        # 2. Deploy get_admin_analytics_stats RPC
        print("Deploying public.get_admin_analytics_stats() function...")
        cur.execute("""
            CREATE OR REPLACE FUNCTION public.get_admin_analytics_stats(timeframe_days INT)
            RETURNS jsonb SECURITY DEFINER AS $$
            DECLARE
              total_users INT;
              completed_count INT;
              course_history_count INT;
              registered_only_count INT;
              
              start_date DATE;
              growth_trend JSONB;
              activity_trend JSONB;
              
              latest_dau INT := 0;
              latest_mau INT := 0;
              latest_yau INT := 0;
              peak_dau INT := 0;
              
              registered_in_range INT := 0;
              growth_rate NUMERIC;
              
              result JSONB;
            BEGIN
              start_date := current_date - timeframe_days;

              -- Onboarding funnel counts
              SELECT count(*) INTO total_users FROM public.profiles;
              SELECT count(*) INTO completed_count FROM public.profiles WHERE onboarding_status = 'completed';
              SELECT count(*) INTO course_history_count FROM public.profiles WHERE onboarding_status = 'course_history';
              registered_only_count := total_users - completed_count - course_history_count;
              IF registered_only_count < 0 THEN registered_only_count := 0; END IF;

              -- Growth Trend Data
              SELECT count(*) INTO registered_in_range FROM public.profiles WHERE created_at >= start_date;
              
              SELECT coalesce(jsonb_agg(t), '[]'::jsonb) INTO growth_trend FROM (
                WITH date_series AS (
                  SELECT generate_series(
                    start_date, 
                    current_date, 
                    '1 day'::interval
                  )::date AS d
                ),
                day_counts AS (
                  SELECT created_at::date AS c_date, count(*) AS cnt 
                  FROM public.profiles 
                  WHERE created_at >= start_date
                  GROUP BY created_at::date
                ),
                growth_cumulative AS (
                  SELECT 
                    to_char(ds.d, 'Mon DD') AS date_label,
                    coalesce(dc.cnt, 0) AS count,
                    (total_users - registered_in_range) + sum(coalesce(dc.cnt, 0)) OVER (ORDER BY ds.d) AS total
                  FROM date_series ds
                  LEFT JOIN day_counts dc ON ds.d = dc.c_date
                )
                SELECT date_label AS "date", count, total FROM growth_cumulative
              ) t;

              -- Activity Trend Data
              SELECT coalesce(jsonb_agg(at_rows), '[]'::jsonb) INTO activity_trend FROM (
                WITH date_series AS (
                  SELECT generate_series(
                    start_date, 
                    current_date, 
                    '1 day'::interval
                  )::date AS d
                ),
                active_counts AS (
                  SELECT activity_date, dau, mau, yau 
                  FROM public.daily_active_users_metrics 
                  WHERE activity_date >= start_date
                )
                SELECT 
                  to_char(ds.d, 'Mon DD') AS "date",
                  coalesce(ac.dau, 0) AS dau,
                  coalesce(ac.mau, 0) AS mau,
                  coalesce(ac.yau, 0) AS yau
                FROM date_series ds
                LEFT JOIN active_counts ac ON ds.d = ac.activity_date
                ORDER BY ds.d ASC
              ) at_rows;

              -- Latest metrics values
              SELECT coalesce(dau, 0), coalesce(mau, 0), coalesce(yau, 0) 
              INTO latest_dau, latest_mau, latest_yau
              FROM public.daily_active_users_metrics
              ORDER BY activity_date DESC LIMIT 1;

              -- Peak DAU
              SELECT max(dau) INTO peak_dau FROM public.daily_active_users_metrics WHERE activity_date >= start_date;
              IF peak_dau IS NULL THEN peak_dau := 0; END IF;

              -- Growth rate calculation
              IF total_users > 0 THEN
                growth_rate := round(((registered_in_range::numeric / total_users::numeric) * 100.0), 1);
              ELSE
                growth_rate := 0.0;
              END IF;

              -- Construct JSON object
              result := jsonb_build_object(
                'funnelData', jsonb_build_object(
                  'registered', registered_only_count,
                  'courseHistory', course_history_count,
                  'completed', completed_count,
                  'total', total_users
                ),
                'growthData', growth_trend,
                'activityData', activity_trend,
                'stats', jsonb_build_object(
                  'totalUsers', total_users,
                  'activeUsers', latest_dau,
                  'rollingMau', latest_mau,
                  'rollingYau', latest_yau,
                  'growthRate', growth_rate,
                  'peakActivity', peak_dau
                )
              );

              RETURN result;
            END;
            $$ LANGUAGE plpgsql;
        """)
        
        # Grant execute permissions to public/authenticated/service_role roles
        cur.execute("GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_stats() TO authenticated, service_role;")
        cur.execute("GRANT EXECUTE ON FUNCTION public.get_admin_analytics_stats(INT) TO authenticated, service_role;")
        
        conn.commit()
        print("\nRPC database migrations executed and committed successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"\n[ERROR] RPC deployment failed: {e}")
        raise e
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    deploy_rpcs()
