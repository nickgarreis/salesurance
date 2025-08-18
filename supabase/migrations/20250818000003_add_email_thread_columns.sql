-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250818000003_add_email_thread_columns.sql
-- Add dedicated email_id and thread_id columns to messages table
-- Simple columns without indexes for clean, fast implementation
-- RELEVANT FILES: messages table schema

-- Add new dedicated columns
ALTER TABLE messages 
ADD COLUMN email_id TEXT,
ADD COLUMN thread_id TEXT;

-- Add documentation
COMMENT ON COLUMN messages.email_id IS 'Unique email identifier';
COMMENT ON COLUMN messages.thread_id IS 'Thread identifier for grouping messages';