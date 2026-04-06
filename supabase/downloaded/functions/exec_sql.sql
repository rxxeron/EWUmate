CREATE OR REPLACE FUNCTION public.exec_sql(sql_query text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
            BEGIN
                EXECUTE sql_query;
            END;
            $function$
;
