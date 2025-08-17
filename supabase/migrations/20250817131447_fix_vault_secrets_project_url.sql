-- Fix vault secrets to point to correct project
-- The previous migration had wrong project URL (wnqqioudrzffadjonxpv) instead of correct one (ejlnibieoldtlaoymzvy)
-- This caused the cron job to call edge functions on wrong project

-- Update project URL to correct project
UPDATE vault.secrets 
SET secret = 'https://ejlnibieoldtlaoymzvy.supabase.co'
WHERE name = 'project_url';

-- Update service role key with actual key from Supabase dashboard
UPDATE vault.secrets 
SET secret = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqbG5pYmllb2xkdGxhb3ltenZ5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTI0MTAwOCwiZXhwIjoyMDcwODE3MDA4fQ.j0rGgZOfdzaCe1IlVFJ_2ylDaP2zhSAsKzaAa7WcgzE'
WHERE name = 'service_role_key';

-- Log the update for debugging
DO $$
BEGIN
    RAISE NOTICE 'Updated vault secrets to correct project: ejlnibieoldtlaoymzvy';
    RAISE NOTICE 'Previous incorrect project was: wnqqioudrzffadjonxpv';
    RAISE NOTICE 'Service role key updated with actual key from dashboard';
    RAISE NOTICE 'Cron job will now call correct edge function URL';
END $$;