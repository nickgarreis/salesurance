-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/01-extensions.sql
-- Defines all PostgreSQL extensions required by the database
-- These extensions provide UUID generation and cron job scheduling capabilities
-- RELEVANT FILES: 02-tables.sql, 05-functions.sql, 07-cron-jobs.sql

-- Enable UUID generation support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable cron job scheduling for automated tasks
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- Enable HTTP client for making API calls from database
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- Add documentation comments
COMMENT ON EXTENSION "uuid-ossp" IS 'Functions for generating universally unique identifiers (UUIDs)';
COMMENT ON EXTENSION pg_cron IS 'PostgreSQL cron extension for scheduling automated tasks';
COMMENT ON EXTENSION pg_net IS 'Async HTTP client for PostgreSQL';