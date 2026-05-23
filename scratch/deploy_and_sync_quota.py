import psycopg2
from psycopg2 import extras

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def main():
    try:
        print("Connecting to Supabase PostgreSQL database...")
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor(cursor_factory=extras.RealDictCursor)

        # 1. Deploy Trigger Function with SECURITY DEFINER and parent_id check
        print("\nDeploying trigger function 'update_drive_account_used_bytes' with SECURITY DEFINER...")
        function_sql = """
        CREATE OR REPLACE FUNCTION public.update_drive_account_used_bytes()
        RETURNS TRIGGER
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path TO 'public'
        AS $function$
        BEGIN
            IF (TG_OP = 'INSERT') THEN
                -- Add the file size to the drive account's used_bytes ONLY if it is a primary record (parent_id IS NULL)
                IF NEW.drive_account_id IS NOT NULL AND NEW.parent_id IS NULL THEN
                    UPDATE public.drive_accounts
                    SET used_bytes = COALESCE(used_bytes, 0) + NEW.file_size_bytes
                    WHERE id = NEW.drive_account_id;
                END IF;
                
            ELSIF (TG_OP = 'DELETE') THEN
                -- Subtract the file size from the drive account's used_bytes ONLY if it was a primary record (parent_id IS NULL)
                IF OLD.drive_account_id IS NOT NULL AND OLD.parent_id IS NULL THEN
                    UPDATE public.drive_accounts
                    SET used_bytes = GREATEST(0, COALESCE(used_bytes, 0) - OLD.file_size_bytes)
                    WHERE id = OLD.drive_account_id;
                END IF;
                
            ELSIF (TG_OP = 'UPDATE') THEN
                -- If parent_id status changed:
                -- 1. Was primary, now is a peer/child (e.g. parent_id was set)
                IF OLD.parent_id IS NULL AND NEW.parent_id IS NOT NULL THEN
                    IF OLD.drive_account_id IS NOT NULL THEN
                        UPDATE public.drive_accounts
                        SET used_bytes = GREATEST(0, COALESCE(used_bytes, 0) - OLD.file_size_bytes)
                        WHERE id = OLD.drive_account_id;
                    END IF;
                -- 2. Was a peer/child, now is a primary (e.g. parent_id cleared)
                ELSIF OLD.parent_id IS NOT NULL AND NEW.parent_id IS NULL THEN
                    IF NEW.drive_account_id IS NOT NULL THEN
                        UPDATE public.drive_accounts
                        SET used_bytes = COALESCE(used_bytes, 0) + NEW.file_size_bytes
                        WHERE id = NEW.drive_account_id;
                    END IF;
                -- 3. Remained a primary record:
                ELSIF OLD.parent_id IS NULL AND NEW.parent_id IS NULL THEN
                    -- If drive_account_id changed, transfer the size
                    IF OLD.drive_account_id IS DISTINCT FROM NEW.drive_account_id THEN
                        IF OLD.drive_account_id IS NOT NULL THEN
                            UPDATE public.drive_accounts
                            SET used_bytes = GREATEST(0, COALESCE(used_bytes, 0) - OLD.file_size_bytes)
                            WHERE id = OLD.drive_account_id;
                        END IF;
                        IF NEW.drive_account_id IS NOT NULL THEN
                            UPDATE public.drive_accounts
                            SET used_bytes = COALESCE(used_bytes, 0) + NEW.file_size_bytes
                            WHERE id = NEW.drive_account_id;
                        END IF;
                    -- If size changed but account remained the same
                    ELSIF OLD.file_size_bytes IS DISTINCT FROM NEW.file_size_bytes AND NEW.drive_account_id IS NOT NULL THEN
                        UPDATE public.drive_accounts
                        SET used_bytes = GREATEST(0, COALESCE(used_bytes, 0) - OLD.file_size_bytes + NEW.file_size_bytes)
                        WHERE id = NEW.drive_account_id;
                    END IF;
                END IF;
            END IF;
            RETURN COALESCE(NEW, OLD);
        END;
        $function$;
        """
        cursor.execute(function_sql)
        print("Function deployed successfully!")

        # 2. Re-bind Trigger
        print("\nBinding trigger 'trg_update_drive_account_used_bytes' to 'study_materials' table...")
        trigger_sql = """
        DROP TRIGGER IF EXISTS trg_update_drive_account_used_bytes ON public.study_materials;
        CREATE TRIGGER trg_update_drive_account_used_bytes
        AFTER INSERT OR UPDATE OR DELETE
        ON public.study_materials
        FOR EACH ROW
        EXECUTE FUNCTION update_drive_account_used_bytes();
        """
        cursor.execute(trigger_sql)
        print("Trigger bound successfully!")

        # 3. Perform a precise one-time backfill/sync for ALL drive accounts (primary only)
        print("\nPerforming storage backfill/sync for all drive accounts (parent_id IS NULL only)...")
        backfill_sql = """
        -- Reset used_bytes to 0 first
        UPDATE public.drive_accounts SET used_bytes = 0;

        -- Backfill from existing study_materials (primary records only)
        WITH storage_sums AS (
            SELECT drive_account_id, SUM(file_size_bytes) as total_size
            FROM public.study_materials
            WHERE drive_account_id IS NOT NULL AND parent_id IS NULL
            GROUP BY drive_account_id
        )
        UPDATE public.drive_accounts da
        SET used_bytes = s.total_size
        FROM storage_sums s
        WHERE da.id = s.drive_account_id;
        """
        cursor.execute(backfill_sql)
        conn.commit()
        print("Storage backfill completed successfully!")

        # 4. Display the current DB state for drive accounts
        print("\n--- NEW DRIVE ACCOUNTS STORAGE STATE ---")
        cursor.execute("SELECT id, email, total_capacity_bytes, used_bytes, is_active FROM drive_accounts ORDER BY email ASC;")
        accounts = cursor.fetchall()
        for a in accounts:
            used_mb = a['used_bytes'] / (1024 * 1024)
            cap_mb = a['total_capacity_bytes'] / (1024 * 1024)
            print(f"Account: {a['email']}")
            print(f"  ID: {a['id']}")
            print(f"  Used Space: {used_mb:.2f} MB / {cap_mb:.2f} MB ({a['used_bytes']} bytes)")
            print(f"  Active: {a['is_active']}")
            print("-" * 50)

        cursor.close()
        conn.close()
        print("\nAll database changes completed successfully!")
    except Exception as e:
        print(f"Error during deployment: {e}")

if __name__ == "__main__":
    main()
