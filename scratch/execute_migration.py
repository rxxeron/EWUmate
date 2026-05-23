import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def run_migration():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        print("Starting database migration...")
        
        # 1. Add same_course column to course_metadata
        print("Adding 'same_course' column to public.course_metadata...")
        cur.execute("""
            ALTER TABLE public.course_metadata 
            ADD COLUMN IF NOT EXISTS same_course TEXT REFERENCES public.course_metadata(code) ON DELETE SET NULL;
        """)
        
        # 2. Add parent_id column to study_materials
        print("Adding 'parent_id' column to public.study_materials...")
        cur.execute("""
            ALTER TABLE public.study_materials 
            ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.study_materials(id) ON DELETE CASCADE;
        """)
        
        # 3. Create delete trigger function
        print("Creating delete trigger function and binding trigger...")
        cur.execute("""
            CREATE OR REPLACE FUNCTION public.delete_linked_study_materials()
            RETURNS TRIGGER AS $$
            BEGIN
                -- Delete child rows if this was the parent
                DELETE FROM public.study_materials WHERE parent_id = OLD.id;
                
                -- Delete parent row if this was a child
                IF OLD.parent_id IS NOT NULL THEN
                    DELETE FROM public.study_materials WHERE id = OLD.parent_id;
                END IF;
                RETURN OLD;
            END;
            $$ LANGUAGE plpgsql SECURITY DEFINER;
        """)
        
        cur.execute("""
            DROP TRIGGER IF EXISTS trg_delete_linked_study_materials ON public.study_materials;
            CREATE TRIGGER trg_delete_linked_study_materials
            AFTER DELETE ON public.study_materials
            FOR EACH ROW
            EXECUTE FUNCTION public.delete_linked_study_materials();
        """)
        
        # 4. Create sync trigger function
        print("Creating sync trigger function and binding trigger...")
        cur.execute("""
            CREATE OR REPLACE FUNCTION public.sync_updates_study_materials()
            RETURNS TRIGGER AS $$
            BEGIN
                IF pg_trigger_depth() <= 1 THEN
                    -- Sync to parent if this is a child
                    IF NEW.parent_id IS NOT NULL THEN
                        UPDATE public.study_materials 
                        SET 
                            status = NEW.status,
                            faculty_initial = NEW.faculty_initial,
                            semester = NEW.semester,
                            file_type = NEW.file_type,
                            file_name = NEW.file_name
                        WHERE id = NEW.parent_id;
                    END IF;
                    
                    -- Sync to children if this is a parent
                    UPDATE public.study_materials 
                    SET 
                        status = NEW.status,
                        faculty_initial = NEW.faculty_initial,
                        semester = NEW.semester,
                        file_type = NEW.file_type,
                        file_name = NEW.file_name
                    WHERE parent_id = NEW.id;
                END IF;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql SECURITY DEFINER;
        """)
        
        cur.execute("""
            DROP TRIGGER IF EXISTS trg_sync_updates_study_materials ON public.study_materials;
            CREATE TRIGGER trg_sync_updates_study_materials
            AFTER UPDATE ON public.study_materials
            FOR EACH ROW
            EXECUTE FUNCTION public.sync_updates_study_materials();
        """)
        
        # 5. Mappings to establish
        equivalents = [
            ('CSE103', 'ICE103'),
            ('CSE106', 'ICE204'),
            ('CSE110', 'ICE107'),
            ('CSE207', 'ICE207'),
            ('CSE209', 'ICE109'),
            ('CSE246', 'ICE245'),
            ('CSE251', 'ICE213'),
            ('CSE302', 'ICE305'),
            ('CSE360', 'ICE469'),
            ('CSE432', 'ICE322'),
            ('CSE406', 'ICE485'),
            ('CSE475', 'ICE478')
        ]
        
        print("Establishing bidirectional course metadata mappings...")
        updated_count = 0
        for course_a, course_b in equivalents:
            # Let's verify if BOTH exist in the database first to avoid foreign key/referential errors
            cur.execute("SELECT code FROM public.course_metadata WHERE code IN (%s, %s);", (course_a, course_b))
            existing = [row[0] for row in cur.fetchall()]
            
            if len(existing) == 2:
                # Update Course A same_course -> Course B
                cur.execute("UPDATE public.course_metadata SET same_course = %s WHERE code = %s;", (course_b, course_a))
                # Update Course B same_course -> Course A
                cur.execute("UPDATE public.course_metadata SET same_course = %s WHERE code = %s;", (course_a, course_b))
                print(f"  Mapped equivalents: {course_a} <-> {course_b}")
                updated_count += 2
            else:
                missing = [c for c in [course_a, course_b] if c not in existing]
                print(f"  [SKIPPED] Cannot map {course_a} <-> {course_b} (missing from catalog: {', '.join(missing)})")
                
        # Commit transaction
        conn.commit()
        print(f"\nMigration committed successfully! {updated_count} course mappings established.")
        
    except Exception as e:
        conn.rollback()
        print(f"\n[ERROR] Migration failed and rolled back: {e}")
        raise e
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    run_migration()
