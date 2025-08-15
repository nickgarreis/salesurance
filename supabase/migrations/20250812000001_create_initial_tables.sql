-- /Users/nick/agentic_marketing_system/supabase/migrations/20250812000001_create_initial_tables.sql
-- Creates the core tables for the agentic marketing system
-- This migration establishes the foundational data model for clients, campaigns, leads, and messages
-- RELEVANT FILES: CLAUDE.md, render.yaml, requirements.txt

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create clients table
-- Stores client information and their current status
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create campaigns table
-- Links to clients and stores campaign-specific information
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create leads table
-- Stores prospect information and their research results for each campaign
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create messages table
-- Tracks all outreach messages sent to leads across different channels
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'draft',
    channel TEXT NOT NULL, -- email, linkedin, phone, etc.
    subject TEXT,
    message TEXT NOT NULL,
    sender TEXT NOT NULL,
    due TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_campaigns_client_id ON campaigns(client_id);
CREATE INDEX idx_leads_campaign_id ON leads(campaign_id);
CREATE INDEX idx_messages_lead_id ON messages(lead_id);
CREATE INDEX idx_messages_campaign_id ON messages(campaign_id);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_due ON messages(due);

-- Create updated_at trigger function
-- This function automatically updates the updated_at column when a row is modified
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all tables
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();