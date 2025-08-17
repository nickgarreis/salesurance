-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/02-tables.sql
-- Complete table definitions for the agentic marketing system
-- This file contains all table structures with their columns, defaults, and constraints
-- RELEVANT FILES: 01-extensions.sql, 03-indexes.sql, 05-functions.sql, 06-triggers.sql

-- Set timezone for proper timestamp handling
SET timezone = 'Europe/Berlin';

-- Clients table: Stores client information and their current status
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Campaigns table: Links to clients and stores campaign-specific information
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    info JSONB, -- Discovery/info field for campaign details
    dsgvo_footer TEXT, -- GDPR footer text for emails
    auth TEXT, -- Authentication/authorization details
    strategy TEXT[], -- Array of SQL statements for automated message creation
    email TEXT NOT NULL DEFAULT 'marian@salesurance.co' -- Sender email address
);

-- Leads table: Stores prospect information and research results for each campaign
CREATE TABLE IF NOT EXISTS public.leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    job_title TEXT,
    status TEXT NOT NULL DEFAULT 'new',
    email TEXT,
    phone TEXT,
    linkedin TEXT,
    company TEXT,
    company_website TEXT,
    company_linkedin TEXT,
    research_results JSONB, -- Stores structured research data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table: Tracks all outreach messages sent to leads across different channels
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'draft',
    channel TEXT NOT NULL, -- email, linkedin, phone, etc.
    subject TEXT,
    message TEXT,
    sender TEXT NOT NULL,
    due TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() AT TIME ZONE 'Europe/Berlin'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resend_email_id TEXT, -- Resend API email ID for webhook matching
    email_events JSONB DEFAULT '{}', -- Email tracking events (sent, delivered, opened, clicked, etc.)
    email_thread_data JSONB -- Threading data: message_id, parent_message_id, thread_id, references
);

-- Add table comments for documentation
COMMENT ON TABLE public.clients IS 'Stores client information and their current status';
COMMENT ON TABLE public.campaigns IS 'Campaign management with strategy and configuration';
COMMENT ON TABLE public.leads IS 'Lead/prospect information with research data';
COMMENT ON TABLE public.messages IS 'Outreach message tracking across all channels';

-- Add column comments for important fields
COMMENT ON COLUMN public.campaigns.strategy IS 'TEXT array containing SQL INSERT statements for automated message creation';
COMMENT ON COLUMN public.campaigns.email IS 'Sender email address used for all outreach messages in this campaign';
COMMENT ON COLUMN public.messages.resend_email_id IS 'Resend API email ID returned from send request, used to match webhook events';
COMMENT ON COLUMN public.messages.email_events IS 'JSONB object storing email tracking events with timestamps';
COMMENT ON COLUMN public.messages.email_thread_data IS 'JSONB containing threading data: message_id, parent_message_id, thread_id, references';

-- Enable Row Level Security on all tables
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Row Level Security Policies
-- Allow full access for all authenticated roles (adjust for your security requirements)
CREATE POLICY "Allow full access to clients" ON clients
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow full access to campaigns" ON campaigns
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow full access to leads" ON leads
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow full access to messages" ON messages
    FOR ALL
    TO authenticated, anon, service_role
    USING (true)
    WITH CHECK (true);

-- Grant full access to authenticated and service role (adjust as needed for your security requirements)
GRANT ALL ON public.clients TO authenticated, service_role;
GRANT ALL ON public.campaigns TO authenticated, service_role;
GRANT ALL ON public.leads TO authenticated, service_role;
GRANT ALL ON public.messages TO authenticated, service_role;