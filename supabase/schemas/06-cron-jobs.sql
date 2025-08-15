-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/06-cron-jobs.sql
-- PostgreSQL cron jobs for automated email sending and system maintenance
-- These jobs run on a schedule to process pending messages and maintain system health
-- RELEVANT FILES: 01-extensions.sql, 02-tables.sql, edge functions/send-email

-- Schedule cron job to automatically send scheduled emails every 5 minutes
-- This job calls the send-email edge function to process messages with status='active' and due <= now
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

-- Note about cron job configuration:
-- The job makes HTTP requests to the edge function endpoint
-- Requires proper Supabase project URL and service role key configuration
-- Edge function handles the actual email sending logic using Resend API