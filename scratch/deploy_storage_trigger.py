import pg8000.dbapi

def main():
    print("Connecting to Supabase PostgreSQL database...")
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    cursor = conn.cursor()

    # 1. Deploy Trigger Function
    print("Deploying trigger function 'update_drive_account_used_bytes'...")
    function_sql = """
    CREATE OR REPLACE FUNCTION public.update_drive_account_used_bytes()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $function$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            -- Add the file size to the drive account's used_bytes
            IF NEW.drive_account_id IS NOT NULL THEN
                UPDATE public.drive_accounts
                SET used_bytes = COALESCE(used_bytes, 0) + NEW.file_size_bytes
                WHERE id = NEW.drive_account_id;
            END IF;
            
        ELSIF (TG_OP = 'DELETE') THEN
            -- Subtract the file size from the drive account's used_bytes
            IF OLD.drive_account_id IS NOT NULL THEN
                UPDATE public.drive_accounts
                SET used_bytes = GREATEST(0, COALESCE(used_bytes, 0) - OLD.file_size_bytes)
                WHERE id = OLD.drive_account_id;
            END IF;
            
        ELSIF (TG_OP = 'UPDATE') THEN
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
        RETURN COALESCE(NEW, OLD);
    END;
    $function$;
    """
    cursor.execute(function_sql)
    print("Function deployed successfully!")

    # 2. Recreate Trigger
    print("Binding trigger 'trg_update_drive_account_used_bytes' to 'study_materials' table...")
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

    # 3. Perform a one-time backfill/sync for ALL drive accounts
    print("Performing one-time storage backfill/sync for all drive accounts...")
    backfill_sql = """
    -- Reset used_bytes to 0 first
    UPDATE public.drive_accounts SET used_bytes = 0;

    -- Backfill from existing study_materials
    WITH storage_sums AS (
        SELECT drive_account_id, SUM(file_size_bytes) as total_size
        FROM public.study_materials
        WHERE drive_account_id IS NOT NULL
        GROUP BY drive_account_id
    )
    UPDATE public.drive_accounts da
    SET used_bytes = s.total_size
    FROM storage_sums s
    WHERE da.id = s.drive_account_id;
    """
    cursor.execute(backfill_sql)
    conn.commit()
    print("One-time storage backfill completed successfully!")

    cursor.close()
    conn.close()
    print("Database sync and deployment successful!")

if __name__ == "__main__":
    main()
