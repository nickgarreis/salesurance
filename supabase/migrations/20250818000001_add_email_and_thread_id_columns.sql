-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250818000001_add_email_and_thread_id_columns.sql
-- Adds dedicated emailId and threadId columns to the messages table
-- These columns provide direct access to email and thread identifiers without JSONB extraction
-- RELEVANT FILES: messages table schema, send-email/index.ts, resend-webhook/index.ts

-- Add emailId column to store unique email identifier
ALTER TABLE messages 
ADD COLUMN email_id TEXT;

-- Add threadId column for email thread tracking  
ALTER TABLE messages 
ADD COLUMN thread_id TEXT;

-- Create indexes for performance on new columns
CREATE INDEX idx_messages_email_id ON messages(email_id);
CREATE INDEX idx_messages_thread_id ON messages(thread_id);

-- Add comments for documentation
COMMENT ON COLUMN messages.email_id IS 'Unique email identifier';
COMMENT ON COLUMN messages.thread_id IS 'Thread identifier for grouping related messages';