-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250813000014_add_email_tracking_columns.sql
-- Adds email tracking columns to messages table for Resend webhook integration
-- Stores Resend email ID and all email events (sent, delivered, opened, clicked, bounced, etc.) in JSONB
-- RELEVANT FILES: send-email/index.ts, resend-webhook/index.ts, messages table schema

-- Add resend_email_id column to store the Resend API email ID for webhook matching
ALTER TABLE messages ADD COLUMN resend_email_id TEXT;

-- Add email_events column to store all email tracking events in JSON format
-- This will contain events like sent, delivered, opened, clicked, bounced, complained, failed
ALTER TABLE messages ADD COLUMN email_events JSONB DEFAULT '{}';

-- Create index on resend_email_id for fast webhook lookups
CREATE INDEX IF NOT EXISTS idx_messages_resend_email_id ON messages(resend_email_id);

-- Create index on email_events for efficient event queries
CREATE INDEX IF NOT EXISTS idx_messages_email_events ON messages USING GIN (email_events);

-- Add comments to document the column purposes
COMMENT ON COLUMN messages.resend_email_id IS 'Resend API email ID returned from send request, used to match webhook events';
COMMENT ON COLUMN messages.email_events IS 'JSONB object storing email tracking events with timestamps (sent, delivered, opened, clicked, bounced, complained, failed)';