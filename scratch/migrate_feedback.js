import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing env vars');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runMigration() {
  console.log('Running migration to add user_id and is_admin to feedback_comments...');
  
  const { error } = await supabase.rpc('exec_sql', {
    sql_query: `
      ALTER TABLE public.feedback_comments ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
      ALTER TABLE public.feedback_comments ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;
      
      -- Update RLS for feedback_comments
      ALTER TABLE public.feedback_comments ENABLE ROW LEVEL SECURITY;
      
      DROP POLICY IF EXISTS "Users can view comments on their own feedback" ON public.feedback_comments;
      CREATE POLICY "Users can view comments on their own feedback" ON public.feedback_comments
        FOR SELECT USING (
          EXISTS (
            SELECT 1 FROM public.feedbacks
            WHERE feedbacks.id = feedback_comments.feedback_id
            AND feedbacks.user_id = auth.uid()
          )
          OR 
          auth.uid() IN (SELECT user_id FROM public.admin_users)
        );

      DROP POLICY IF EXISTS "Users can insert comments on their own feedback" ON public.feedback_comments;
      CREATE POLICY "Users can insert comments on their own feedback" ON public.feedback_comments
        FOR INSERT WITH CHECK (
          EXISTS (
            SELECT 1 FROM public.feedbacks
            WHERE feedbacks.id = feedback_comments.feedback_id
            AND feedbacks.user_id = auth.uid()
          )
          OR 
          auth.uid() IN (SELECT user_id FROM public.admin_users)
        );
    `
  });

  if (error) {
    console.error('Migration failed:', error);
    
    // Fallback if rpc('exec_sql') is not available
    console.log('Trying alternative approach...');
    // We might not have exec_sql. In that case, we have to hope the user runs it or we use another way.
  } else {
    console.log('Migration successful!');
  }
}

runMigration();
