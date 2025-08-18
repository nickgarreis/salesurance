-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250818000002_massive_cleanup.sql
-- Massive cleanup: Remove all email infrastructure (edge functions, cron jobs, columns, indexes)
-- Clears the way for simplified email_id and thread_id columns
-- RELEVANT FILES: messages table schema, cron jobs, edge functions

-- Drop all cron jobs
SELECT cron.unschedule('send-scheduled-emails-direct');

-- Drop the function used by cron job
DROP FUNCTION IF EXISTS get_due_messages();

-- Drop existing indexes that will conflict or are no longer needed
DROP INDEX IF EXISTS idx_messages_thread_id;
DROP INDEX IF EXISTS idx_messages_message_id;
DROP INDEX IF EXISTS idx_messages_email_events;
DROP INDEX IF EXISTS idx_messages_resend_email_id;

-- Drop email-related columns
ALTER TABLE messages 
DROP COLUMN IF EXISTS email_thread_data,
DROP COLUMN IF EXISTS email_events,
DROP COLUMN IF EXISTS resend_email_id;