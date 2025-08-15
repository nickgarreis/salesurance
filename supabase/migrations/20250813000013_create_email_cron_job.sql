-- /Users/nick/Pokale Meier/supabase/migrations/20250813000013_create_email_cron_job.sql
-- Creates pg_cron job to automatically send scheduled emails every 5 minutes
-- Calls the send-email edge function to process messages with status='active' and due <= now
-- RELEVANT FILES: send-email edge function, messages table, pg_cron extension

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create cron job to run send-email function every 5 minutes
-- This job will make HTTP requests to the edge function endpoint
SELECT cron.schedule(
    'send-scheduled-emails',        -- Job name
    '*/5 * * * *',                  -- Every 5 minutes
    $$
    SELECT
      net.http_post(
        url := 'https://' || current_setting('app.settings.supabase_url') || '/functions/v1/send-email',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
        ),
        body := '{}'::jsonb
      ) as request_id;
    $$
);

-- Add helpful comment for documentation
COMMENT ON EXTENSION pg_cron IS 'PostgreSQL cron extension for scheduling automated tasks';

-- Log the creation of the cron job
DO $$
BEGIN
    RAISE NOTICE 'Created cron job "send-scheduled-emails" to run every 5 minutes';
    RAISE NOTICE 'The job will call the send-email edge function to process due messages';
END $$;