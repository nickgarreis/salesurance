-- /Users/nick/Pokale Meier/supabase/migrations/20250813000014_fix_email_cron_job.sql
-- Fixes the email cron job by removing broken configuration and using proper Supabase Vault approach
-- Unschedules the old broken job and creates a new working one with proper HTTP calls
-- RELEVANT FILES: send-email edge function, messages table, pg_cron extension, pg_net extension

-- First, unschedule the broken cron job if it exists
SELECT cron.unschedule('send-scheduled-emails');

-- Enable pg_net extension for HTTP requests (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Store project URL and service role key securely in Supabase Vault
-- Note: Replace these values with your actual project details
SELECT vault.create_secret('https://wnqqioudrzffadjonxpv.supabase.co', 'project_url');
SELECT vault.create_secret('SERVICE_ROLE_KEY', 'service_role_key');

-- Create the new working cron job using official Supabase best practices
SELECT cron.schedule(
    'send-scheduled-emails-fixed',    -- New job name to avoid conflicts
    '*/5 * * * *',                    -- Every 5 minutes
    $$
    SELECT
      net.http_post(
        url := (
          SELECT decrypted_secret 
          FROM vault.decrypted_secrets 
          WHERE name = 'project_url'
        ) || '/functions/v1/send-email',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret 
            FROM vault.decrypted_secrets 
            WHERE name = 'service_role_key'
          )
        ),
        body := '{}'::jsonb
      ) as request_id;
    $$
);

-- Add helpful comments for documentation
COMMENT ON EXTENSION pg_net IS 'PostgreSQL HTTP client for making HTTP requests from database';

-- Log the creation of the new cron job
DO $$
BEGIN
    RAISE NOTICE 'Fixed cron job created: "send-scheduled-emails-fixed" will run every 5 minutes';
    RAISE NOTICE 'Old broken job "send-scheduled-emails" has been unscheduled';
    RAISE NOTICE 'The job uses Supabase Vault for secure credential storage';
    RAISE NOTICE 'IMPORTANT: Replace SERVICE_ROLE_KEY with actual service role key!';
    RAISE NOTICE 'Migration follows official Supabase best practices for scheduling edge functions';
END $$;