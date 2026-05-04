import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def add_domain_restriction():
    try:
        conn = psycopg2.connect(conn_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("--- ADDING DOMAIN RESTRICTION TRIGGER TO auth.users ---")
        
        # 1. Create the validation function
        cur.execute("""
CREATE OR REPLACE FUNCTION public.validate_email_domain()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Only allow @std.ewubd.edu
  IF NEW.email NOT LIKE '%@std.ewubd.edu' THEN
    RAISE EXCEPTION 'Registration restricted to @std.ewubd.edu domain.';
  END IF;
  RETURN NEW;
END;
$function$;
        """)

        # 2. Add the trigger to auth.users (in the auth schema)
        # Note: We use a check to avoid duplicate trigger errors
        cur.execute("""
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_validate_email_domain') THEN
    CREATE TRIGGER trg_validate_email_domain
    BEFORE INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.validate_email_domain();
  END IF;
END $$;
        """)
        
        print("SUCCESS: Registration is now restricted to @std.ewubd.edu at the database level.")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    add_domain_restriction()
