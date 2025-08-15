-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/03-indexes.sql
-- Database indexes for optimizing query performance
-- These indexes speed up foreign key lookups, status filters, and time-based queries
-- RELEVANT FILES: 02-tables.sql, 05-functions.sql

-- Foreign key relationship indexes
CREATE INDEX IF NOT EXISTS idx_campaigns_client_id ON public.campaigns(client_id);
CREATE INDEX IF NOT EXISTS idx_leads_campaign_id ON public.leads(campaign_id);
CREATE INDEX IF NOT EXISTS idx_messages_lead_id ON public.messages(lead_id);
CREATE INDEX IF NOT EXISTS idx_messages_campaign_id ON public.messages(campaign_id);

-- Status filtering indexes for common queries
CREATE INDEX IF NOT EXISTS idx_leads_status ON public.leads(status);
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(status);

-- Time-based query optimization
CREATE INDEX IF NOT EXISTS idx_messages_due ON public.messages(due);

-- Specialized indexes for message scheduling system
CREATE INDEX IF NOT EXISTS idx_messages_campaign_due ON public.messages(campaign_id, due) WHERE due IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_messages_due_date ON public.messages((DATE(due AT TIME ZONE 'Europe/Berlin'))) WHERE due IS NOT NULL;

-- Unique constraint to prevent duplicate leads
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_lead_per_campaign ON public.leads(campaign_id, email) WHERE email IS NOT NULL;

-- Add index comments for documentation
COMMENT ON INDEX idx_campaigns_client_id IS 'Speed up client-to-campaigns lookups';
COMMENT ON INDEX idx_leads_campaign_id IS 'Speed up campaign-to-leads lookups';
COMMENT ON INDEX idx_messages_lead_id IS 'Speed up lead-to-messages lookups';
COMMENT ON INDEX idx_messages_campaign_id IS 'Speed up campaign-to-messages lookups';
COMMENT ON INDEX idx_leads_status IS 'Optimize filtering leads by status';
COMMENT ON INDEX idx_messages_status IS 'Optimize filtering messages by status';
COMMENT ON INDEX idx_messages_due IS 'Optimize scheduling queries for due messages';
COMMENT ON INDEX idx_messages_campaign_due IS 'Optimize campaign-specific scheduling queries';
COMMENT ON INDEX idx_messages_due_date IS 'Optimize daily message capacity calculations';
COMMENT ON INDEX idx_unique_lead_per_campaign IS 'Prevent duplicate leads within a campaign';