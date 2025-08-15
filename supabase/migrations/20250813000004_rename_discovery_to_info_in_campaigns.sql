-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000004_rename_discovery_to_info_in_campaigns.sql
-- Migration to rename the 'discovery' column to 'info' in the campaigns table
-- This provides a clearer, more generic name for storing campaign information
-- RELEVANT FILES: 20250813000002_add_discovery_column_to_campaigns.sql, campaigns table schema

-- Rename the discovery column to info in the campaigns table
ALTER TABLE campaigns RENAME COLUMN discovery TO info;