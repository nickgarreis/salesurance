-- /Users/nick/NiCode GmbH/Salesurance/supabase/scripts/setup-vault-secrets.sql
-- Setup script for configuring Supabase Vault secrets for email cron job
-- Run this script after applying migrations to configure vault secrets for each project
-- RELEVANT FILES: 06-cron-jobs.sql, send-email edge function, client-config.md

-- Remove any existing vault secrets to avoid conflicts
DELETE FROM vault.secrets WHERE name IN ('project_url', 'service_role_key');

-- Store project-specific configuration in Supabase Vault for secure access
-- Replace the URL and service role key with actual values for each deployment
SELECT vault.create_secret('https://ejlnibieoldtlaoymzvy.supabase.co', 'project_url');
SELECT vault.create_secret('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqbG5pYmllb2xkdGxhb3ltenZ5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTI0MTAwOCwiZXhwIjoyMDcwODE3MDA4fQ.j0rGgZOfdzaCe1IlVFJ_2ylDaP2zhSAsKzaAa7WcgzE', 'service_role_key');

-- Verify secrets were created successfully
SELECT 
    name,
    created_at,
    CASE 
        WHEN name = 'project_url' THEN 'Configured (URL)'
        WHEN name = 'service_role_key' THEN 'Configured (JWT Token)'
        ELSE 'Unknown'
    END as description
FROM vault.secrets 
WHERE name IN ('project_url', 'service_role_key')
ORDER BY name;

-- Note: This script should be run via:
-- psql $DATABASE_URL -f supabase/scripts/setup-vault-secrets.sql
-- or through Supabase Dashboard SQL Editor