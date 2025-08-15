-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000010_change_strategy_column_to_text_array.sql
-- Changes the strategy column in campaigns table from JSONB to TEXT[] for direct SQL storage
-- This allows users to store SQL strings directly as array elements instead of JSON objects
-- RELEVANT FILES: 20250813000007_add_strategy_column_to_campaigns.sql, 20250813000008_create_automated_message_scheduling_system.sql, campaigns table

-- Drop the existing JSONB strategy column and its index
DROP INDEX IF EXISTS idx_campaigns_strategy;
ALTER TABLE campaigns DROP COLUMN IF EXISTS strategy;

-- Add new TEXT[] strategy column for direct SQL string storage
-- Each array element will be a complete SQL INSERT statement
ALTER TABLE campaigns ADD COLUMN strategy TEXT[];

-- Create index on strategy column for better query performance with array operations
CREATE INDEX idx_campaigns_strategy ON campaigns USING GIN (strategy);

-- Add comment to document the expected structure of the strategy column
COMMENT ON COLUMN campaigns.strategy IS 'TEXT array containing SQL INSERT statements for automated message creation. Each element should be a complete SQL INSERT statement that creates a message. Example: ["INSERT INTO messages (...) VALUES (...)", "INSERT INTO messages (...) VALUES (...)"]';