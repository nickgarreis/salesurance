-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/06-cron-jobs.sql
-- PostgreSQL cron jobs for automated email sending and system maintenance
-- These jobs run on a schedule to process pending messages and maintain system health
-- RELEVANT FILES: 01-extensions.sql, 02-tables.sql, edge functions/send-email

-- Schedule cron job to automatically send scheduled emails every 5 minutes
-- This job calls the send-email edge function to process messages with status='scheduled' and due <= now
-- Prerequisites: Vault secrets 'project_url' and 'service_role_key' must be configured (see setup script)

-- Ensure clean state by unscheduling if exists (for idempotency)
-- Use conditional logic to avoid errors if job doesn't exist
DO $$
BEGIN
    PERFORM cron.unschedule('send-scheduled-emails-fixed');
EXCEPTION WHEN others THEN
    -- Job doesn't exist, continue
    NULL;
END
$$;

SELECT cron.schedule(
    'send-scheduled-emails-fixed',  -- Job name (matches migration 20250813000015)
    '*/5 * * * *',                  -- Every 5 minutes
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

-- Add helpful comment for documentation
COMMENT ON EXTENSION pg_cron IS 'PostgreSQL cron extension for scheduling automated tasks';

-- Note about cron job configuration:
-- The job makes HTTP requests to the edge function endpoint using Supabase Vault for secure credential storage
-- Vault secrets 'project_url' and 'service_role_key' are automatically configured with correct values
-- Edge function handles the actual email sending logic using Resend API
-- For new deployments: Update vault secrets with project-specific values before applying schema