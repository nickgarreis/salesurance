-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/05-triggers.sql
-- Database triggers for automatic timestamp updates and message scheduling
-- These triggers handle automated business logic when data changes occur
-- RELEVANT FILES: 02-tables.sql, 04-functions.sql

-- Triggers to automatically update the updated_at column when rows are modified

-- Client updated_at trigger
DROP TRIGGER IF EXISTS update_clients_updated_at ON public.clients;
CREATE TRIGGER update_clients_updated_at 
    BEFORE UPDATE ON public.clients
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Campaign updated_at trigger
DROP TRIGGER IF EXISTS update_campaigns_updated_at ON public.campaigns;
CREATE TRIGGER update_campaigns_updated_at 
    BEFORE UPDATE ON public.campaigns
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Lead updated_at trigger
DROP TRIGGER IF EXISTS update_leads_updated_at ON public.leads;
CREATE TRIGGER update_leads_updated_at 
    BEFORE UPDATE ON public.leads
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Message updated_at trigger
DROP TRIGGER IF EXISTS update_messages_updated_at ON public.messages;
CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON public.messages
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger to automatically create messages when lead status changes to 'processing'
-- This is the core automation trigger that executes campaign strategies
DROP TRIGGER IF EXISTS trigger_create_messages_on_processing ON public.leads;
CREATE TRIGGER trigger_create_messages_on_processing
    BEFORE UPDATE OF status ON public.leads
    FOR EACH ROW
    EXECUTE FUNCTION public.create_messages_on_processing_status();

-- Add trigger comments for documentation
COMMENT ON TRIGGER update_clients_updated_at ON public.clients IS 'Automatically updates updated_at timestamp when client record is modified';
COMMENT ON TRIGGER update_campaigns_updated_at ON public.campaigns IS 'Automatically updates updated_at timestamp when campaign record is modified';
COMMENT ON TRIGGER update_leads_updated_at ON public.leads IS 'Automatically updates updated_at timestamp when lead record is modified';
COMMENT ON TRIGGER update_messages_updated_at ON public.messages IS 'Automatically updates updated_at timestamp when message record is modified';
COMMENT ON TRIGGER trigger_create_messages_on_processing ON public.leads IS 'Creates scheduled messages automatically when lead status changes to processing';