-- /Users/nick/NiCode GmbH/Salesurance/supabase/migrations/20250815000001_update_existing_campaign_emails.sql
-- Updates existing campaign email addresses from old Pokale Meier email to new Salesurance email
-- This migration ensures all existing campaigns use the correct sender email address
-- RELEVANT FILES: campaigns table schema, 20250813000017_add_email_column_to_campaigns.sql

-- Update existing campaigns that still have the old email address
UPDATE campaigns 
SET email = 'marian@salesurance.co' 
WHERE email = 'l.eissner@pokal-meier.de';

-- Add comment to log the update
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % campaigns from old Pokale Meier email to new Salesurance email', updated_count;
    RAISE NOTICE 'All campaigns now use: marian@salesurance.co';
END $$;