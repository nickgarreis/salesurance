-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000002_add_discovery_column_to_campaigns.sql
-- Adds discovery column to campaigns table to store structured discovery data
-- This column will store JSONB data containing research findings and insights about the campaign target
-- RELEVANT FILES: 20250812000001_create_initial_tables.sql, 20250813000001_allow_null_messages_and_berlin_timezone.sql, CLAUDE.md

-- Add discovery column to campaigns table
-- This will store structured discovery data as JSONB for flexible querying and storage
ALTER TABLE campaigns ADD COLUMN discovery JSONB;