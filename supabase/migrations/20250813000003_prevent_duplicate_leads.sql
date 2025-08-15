-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000003_prevent_duplicate_leads.sql
-- Adds function and trigger to prevent duplicate leads with same first_name, last_name, and campaign_id
-- This ensures data integrity by preventing insertion of leads that already exist in the same campaign
-- RELEVANT FILES: 20250812000001_create_initial_tables.sql, CLAUDE.md, workflows/xml-instructions/outreach_agent.xml

-- Create function to check for duplicate leads before insertion
-- This function will be called by a trigger to prevent duplicate entries
CREATE OR REPLACE FUNCTION prevent_duplicate_leads()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if a lead already exists with the same first_name, last_name, and campaign_id
    IF EXISTS (
        SELECT 1 FROM leads 
        WHERE first_name = NEW.first_name 
        AND last_name = NEW.last_name 
        AND campaign_id = NEW.campaign_id
    ) THEN
        -- If duplicate found, prevent insertion by returning NULL
        -- This effectively cancels the INSERT operation
        RETURN NULL;
    END IF;
    
    -- If no duplicate found, allow the insertion to proceed
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that executes the duplicate prevention function before each INSERT
-- This trigger will automatically check for duplicates on every new lead insertion
CREATE TRIGGER prevent_duplicate_leads_trigger
    BEFORE INSERT ON leads
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_leads();