-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000005_add_dsgvo_footer_to_campaigns.sql
-- Migration to add 'dsgvo_footer' column to campaigns table for GDPR compliance footer content
-- This column will store HTML-formatted footer content for GDPR/DSGVO compliance requirements
-- RELEVANT FILES: campaigns table schema, 20250813000001_create_initial_tables.sql, 20250813000004_rename_discovery_to_info_in_campaigns.sql

-- Add dsgvo_footer column to campaigns table with TEXT data type to support HTML content
ALTER TABLE campaigns ADD COLUMN dsgvo_footer TEXT;