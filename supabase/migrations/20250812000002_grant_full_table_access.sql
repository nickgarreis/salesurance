-- /Users/nick/agentic_marketing_system/supabase/migrations/20250812000002_grant_full_table_access.sql
-- Grants full access permissions to all users and service roles for the core tables
-- This allows unrestricted read/write access to clients, campaigns, leads, and messages tables
-- RELEVANT FILES: 20250812000001_create_initial_tables.sql, CLAUDE.md

-- Enable Row Level Security on all tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create policies that allow full access for all authenticated users and service roles
-- These policies grant SELECT, INSERT, UPDATE, DELETE permissions to everyone

-- Clients table - full access for all
CREATE POLICY "Allow full access to clients" ON clients
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

-- Campaigns table - full access for all
CREATE POLICY "Allow full access to campaigns" ON campaigns
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

-- Leads table - full access for all
CREATE POLICY "Allow full access to leads" ON leads
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

-- Messages table - full access for all
CREATE POLICY "Allow full access to messages" ON messages
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

-- Grant usage on the schema to all roles
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;

-- Grant all privileges on the tables to all roles
GRANT ALL PRIVILEGES ON clients TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON campaigns TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON leads TO authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON messages TO authenticated, anon, service_role;

-- Grant usage and select on sequences (for UUID generation)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;