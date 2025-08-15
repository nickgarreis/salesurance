-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000006_add_auth_to_campaigns.sql
-- Migration to add 'auth' column to campaigns table for authentication/authorization data
-- This column will store authentication credentials or configuration for the campaign
-- RELEVANT FILES: campaigns table schema, 20250813000001_create_initial_tables.sql, 20250813000005_add_dsgvo_footer_to_campaigns.sql

-- Add auth column to campaigns table with TEXT data type to support various auth formats
ALTER TABLE campaigns ADD COLUMN auth TEXT;