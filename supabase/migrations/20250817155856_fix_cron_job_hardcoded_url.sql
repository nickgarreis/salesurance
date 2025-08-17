-- Fix cron job to use hardcoded correct project URL instead of broken vault secrets
-- The current job uses vault secrets that point to wrong project (wnqqioudrzffadjonxpv)
-- This migration replaces it with hardcoded correct URL (ejlnibieoldtlaoymzvy)

-- Unschedule the broken cron job that uses vault secrets
SELECT cron.unschedule('send-scheduled-emails-fixed');

-- Create new cron job with hardcoded correct URL (no authentication needed)
SELECT cron.schedule(
    'send-scheduled-emails-direct',  -- New job name
    '*/5 * * * *',                   -- Every 5 minutes
    $$
    SELECT net.http_post(
        url := 'https://ejlnibieoldtlaoymzvy.supabase.co/functions/v1/send-email',
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := '{}'::jsonb
    ) as request_id;
    $$
);

-- Log the fix for debugging
DO $$
BEGIN
    RAISE NOTICE 'Fixed cron job to use correct project URL: ejlnibieoldtlaoymzvy';
    RAISE NOTICE 'Old broken job "send-scheduled-emails-fixed" has been unscheduled';
    RAISE NOTICE 'New working job "send-scheduled-emails-direct" created';
    RAISE NOTICE 'No vault secrets dependency - uses hardcoded URL';
END $$;