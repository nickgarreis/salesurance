-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000001_allow_null_messages_and_berlin_timezone.sql
-- Allows NULL messages in the messages table and sets Berlin timezone for all created_at columns
-- This migration fixes the NOT NULL constraint violation and ensures proper timezone handling
-- RELEVANT FILES: 20250812000001_create_initial_tables.sql, CLAUDE.md, render.yaml

-- Remove NOT NULL constraint from messages.message column
-- This allows messages to have NULL content when needed (e.g., draft messages)
ALTER TABLE messages ALTER COLUMN message DROP NOT NULL;

-- Update all created_at column defaults to use Berlin timezone
-- This ensures all timestamps are consistently in Berlin time instead of UTC

-- Update clients table created_at default
ALTER TABLE clients ALTER COLUMN created_at SET DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin');

-- Update campaigns table created_at default  
ALTER TABLE campaigns ALTER COLUMN created_at SET DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin');

-- Update leads table created_at default
ALTER TABLE leads ALTER COLUMN created_at SET DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin');

-- Update messages table created_at default
ALTER TABLE messages ALTER COLUMN created_at SET DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin');

-- Update the trigger function to use Berlin timezone for updated_at columns
-- This ensures updated_at timestamps are also in Berlin time
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Set updated_at to current Berlin time instead of UTC
    NEW.updated_at = NOW() AT TIME ZONE 'Europe/Berlin';
    RETURN NEW;
END;
$$ language 'plpgsql';