-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250813000016_add_email_threading_support.sql
-- Migration to add email threading support with Message-ID tracking and thread management
-- Enables follow-up emails in the same conversation thread using proper email headers
-- RELEVANT FILES: messages table schema, send-email/index.ts, resend-webhook/index.ts

-- Add email_thread_data column to store all threading information in JSONB format
-- This consolidates message_id, parent_message_id, thread_id, and references into one column
ALTER TABLE messages ADD COLUMN email_thread_data JSONB;

-- Create index on thread_id for fast thread lookups
-- This enables efficient querying of all messages in a conversation thread
CREATE INDEX IF NOT EXISTS idx_messages_thread_id ON messages USING GIN ((email_thread_data->'thread_id'));

-- Create index on message_id for fast parent message lookups
-- This enables efficient lookup when creating follow-up emails
CREATE INDEX IF NOT EXISTS idx_messages_message_id ON messages USING GIN ((email_thread_data->'message_id'));

-- Add comment explaining the JSONB structure for future developers
COMMENT ON COLUMN messages.email_thread_data IS 'JSONB containing threading data: {"message_id": "RFC Message-ID", "parent_message_id": "parent Message-ID", "thread_id": "conversation thread identifier", "references": ["array of referenced message IDs"]}';