-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250813000017_add_email_column_to_campaigns.sql
-- Adds email column to campaigns table to store the sender email address for each campaign
-- This fixes the issue where messages.sender contained names instead of email addresses
-- RELEVANT FILES: send-email/index.ts, campaigns table schema, messages table schema

-- Add email column to campaigns table with default email address
-- Using the configured email from MCP config as the default value
ALTER TABLE campaigns ADD COLUMN email TEXT NOT NULL DEFAULT 'marian@salesurance.co';

-- Create index on email column for better query performance when joining campaigns
CREATE INDEX IF NOT EXISTS idx_campaigns_email ON campaigns(email);

-- Add comment to document the column purpose
COMMENT ON COLUMN campaigns.email IS 'Sender email address used for all outreach messages in this campaign. Must be a valid email format for Resend API compliance.';

-- Log the creation of the new column
DO $$
BEGIN
    RAISE NOTICE 'Added email column to campaigns table with default sender email';
    RAISE NOTICE 'This column will be used by send-email edge function instead of messages.sender';
    RAISE NOTICE 'All existing campaigns now have the default email: marian@salesurance.co';
END $$;