-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000007_add_strategy_column_to_campaigns.sql
-- Migration to add 'strategy' column to campaigns table for storing message template SQLs
-- This column will store JSONB array of SQL templates that define the messages to be created automatically
-- RELEVANT FILES: 20250812000001_create_initial_tables.sql, campaigns table schema, leads table schema, messages table schema

-- Add strategy column to campaigns table with JSONB data type to support flexible message template storage
-- Each campaign can have a variable number of message templates stored as SQL strings
ALTER TABLE campaigns ADD COLUMN strategy JSONB;

-- Add index on strategy column for better query performance when processing lead status changes
CREATE INDEX idx_campaigns_strategy ON campaigns USING GIN (strategy);

-- Add comment to document the expected structure of the strategy column
COMMENT ON COLUMN campaigns.strategy IS 'JSONB array containing SQL templates for automated message creation. Each template should be a valid SQL string that can reference campaign_id and lead_id variables.';