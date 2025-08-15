-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000008_create_automated_message_scheduling_system.sql
-- Creates the complete automated message scheduling system with business hours and capacity constraints
-- This system automatically creates scheduled messages when leads change status to 'processing'
-- RELEVANT FILES: 20250813000007_add_strategy_column_to_campaigns.sql, 20250812000001_create_initial_tables.sql, leads table, messages table, campaigns table

-- Set timezone to Berlin for all scheduling calculations
SET timezone = 'Europe/Berlin';

-- Function to check if a given timestamp falls within business hours (Mon-Fri, 9AM-6PM Berlin time)
-- This function ensures all messages are only scheduled during working hours
CREATE OR REPLACE FUNCTION is_business_hours(check_time TIMESTAMPTZ)
RETURNS BOOLEAN AS $$
BEGIN
    -- Convert to Berlin timezone and check if it's Monday-Friday between 9 AM and 6 PM
    RETURN EXTRACT(DOW FROM check_time AT TIME ZONE 'Europe/Berlin') BETWEEN 1 AND 5 
           AND EXTRACT(HOUR FROM check_time AT TIME ZONE 'Europe/Berlin') BETWEEN 9 AND 17;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get the next business hour slot after a given timestamp
-- This function advances time to the next valid business hour if needed
CREATE OR REPLACE FUNCTION get_next_business_hour(from_time TIMESTAMPTZ)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    result_time TIMESTAMPTZ;
    day_of_week INTEGER;
    hour_of_day INTEGER;
BEGIN
    -- Start with the provided time in Berlin timezone
    result_time := from_time AT TIME ZONE 'Europe/Berlin' AT TIME ZONE 'Europe/Berlin';
    
    LOOP
        day_of_week := EXTRACT(DOW FROM result_time AT TIME ZONE 'Europe/Berlin');
        hour_of_day := EXTRACT(HOUR FROM result_time AT TIME ZONE 'Europe/Berlin');
        
        -- If it's Saturday (6) or Sunday (0), move to Monday 9 AM
        IF day_of_week = 6 OR day_of_week = 0 THEN
            result_time := DATE_TRUNC('week', result_time AT TIME ZONE 'Europe/Berlin') + INTERVAL '1 week' + INTERVAL '1 day' + INTERVAL '9 hours';
            result_time := result_time AT TIME ZONE 'Europe/Berlin';
        -- If it's before 9 AM on a weekday, move to 9 AM same day
        ELSIF hour_of_day < 9 THEN
            result_time := DATE_TRUNC('day', result_time AT TIME ZONE 'Europe/Berlin') + INTERVAL '9 hours';
            result_time := result_time AT TIME ZONE 'Europe/Berlin';
        -- If it's after 6 PM on a weekday, move to next day 9 AM
        ELSIF hour_of_day >= 18 THEN
            result_time := DATE_TRUNC('day', result_time AT TIME ZONE 'Europe/Berlin') + INTERVAL '1 day' + INTERVAL '9 hours';
            result_time := result_time AT TIME ZONE 'Europe/Berlin';
        -- If it's within business hours, we're good
        ELSE
            EXIT;
        END IF;
    END LOOP;
    
    RETURN result_time;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to check daily message capacity for a specific campaign on a given date
-- This ensures we don't exceed 20 messages per day per campaign while maintaining 20-minute intervals
CREATE OR REPLACE FUNCTION get_campaign_daily_message_count(campaign_uuid UUID, target_date DATE)
RETURNS INTEGER AS $$
BEGIN
    -- Count existing messages scheduled for the target date in Berlin timezone for this specific campaign
    RETURN (
        SELECT COUNT(*)
        FROM messages
        WHERE campaign_id = campaign_uuid
        AND due IS NOT NULL
        AND DATE(due AT TIME ZONE 'Europe/Berlin') = target_date
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to find the next available time slot for a campaign respecting all constraints
-- This function ensures 20-minute intervals between messages, 24h intervals between message sequences, and business hours
CREATE OR REPLACE FUNCTION get_next_available_slot(
    campaign_uuid UUID, 
    preferred_time TIMESTAMPTZ,
    sequence_number INTEGER DEFAULT 1
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    candidate_time TIMESTAMPTZ;
    daily_count INTEGER;
    target_date DATE;
    last_message_time TIMESTAMPTZ;
    min_interval INTERVAL;
BEGIN
    -- Set minimum interval: 24 hours for sequence gaps, 20 minutes for same-day messages
    IF sequence_number = 1 THEN
        min_interval := INTERVAL '20 minutes';
    ELSE
        min_interval := INTERVAL '24 hours';
    END IF;
    
    -- Start with preferred time, but ensure it's in business hours
    candidate_time := get_next_business_hour(preferred_time);
    
    -- Get the last scheduled message time for this campaign to maintain proper intervals
    SELECT MAX(due) INTO last_message_time
    FROM messages
    WHERE campaign_id = campaign_uuid AND due IS NOT NULL;
    
    -- If there's a last message, ensure we maintain the minimum interval
    IF last_message_time IS NOT NULL THEN
        candidate_time := GREATEST(candidate_time, last_message_time + min_interval);
        candidate_time := get_next_business_hour(candidate_time);
    END IF;
    
    -- Find a slot that respects all constraints
    LOOP
        target_date := DATE(candidate_time AT TIME ZONE 'Europe/Berlin');
        daily_count := get_campaign_daily_message_count(campaign_uuid, target_date);
        
        -- Check if we have capacity for this day (max 20 messages per day per campaign)
        IF daily_count < 20 THEN
            -- Check if there's a conflict with existing messages (20-minute buffer)
            IF NOT EXISTS (
                SELECT 1
                FROM messages
                WHERE campaign_id = campaign_uuid
                AND due IS NOT NULL
                AND ABS(EXTRACT(EPOCH FROM (due - candidate_time))) < 1200  -- 20 minutes in seconds
            ) THEN
                -- Found a valid slot
                RETURN candidate_time;
            END IF;
        END IF;
        
        -- Move to next 20-minute slot
        candidate_time := candidate_time + INTERVAL '20 minutes';
        candidate_time := get_next_business_hour(candidate_time);
    END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

-- Main function that creates messages when a lead status changes to 'processing'
-- This function executes the campaign strategy and schedules all messages with proper timing
CREATE OR REPLACE FUNCTION create_messages_on_processing_status()
RETURNS TRIGGER AS $$
DECLARE
    campaign_strategy JSONB;
    strategy_item JSONB;
    message_sql TEXT;
    scheduled_time TIMESTAMPTZ;
    sequence_counter INTEGER := 1;
    base_time TIMESTAMPTZ;
BEGIN
    -- Only proceed if status changed TO 'processing'
    IF NEW.status = 'processing' AND (OLD.status IS NULL OR OLD.status != 'processing') THEN
        
        -- Get the campaign strategy for this lead
        SELECT strategy INTO campaign_strategy
        FROM campaigns
        WHERE id = NEW.campaign_id;
        
        -- If no strategy is defined, log and exit
        IF campaign_strategy IS NULL OR jsonb_array_length(campaign_strategy) = 0 THEN
            RAISE WARNING 'No strategy defined for campaign %, lead %', NEW.campaign_id, NEW.id;
            RETURN NEW;
        END IF;
        
        -- Set base time to now for scheduling calculations
        base_time := NOW();
        
        -- Process each message template in the strategy
        FOR strategy_item IN SELECT * FROM jsonb_array_elements(campaign_strategy)
        LOOP
            -- Extract the SQL from the strategy item
            message_sql := strategy_item->>'sql';
            
            -- Skip if no SQL is provided
            IF message_sql IS NULL OR LENGTH(TRIM(message_sql)) = 0 THEN
                RAISE WARNING 'Empty SQL in strategy for campaign %, lead %, sequence %', NEW.campaign_id, NEW.id, sequence_counter;
                CONTINUE;
            END IF;
            
            -- Calculate the next available time slot for this message
            scheduled_time := get_next_available_slot(NEW.campaign_id, base_time, sequence_counter);
            
            BEGIN
                -- Execute the dynamic SQL to create the message
                -- The SQL should insert into messages table with proper values
                EXECUTE message_sql 
                USING NEW.campaign_id, NEW.id, scheduled_time;
                
                RAISE INFO 'Created message % for lead % in campaign % scheduled for %', 
                          sequence_counter, NEW.id, NEW.campaign_id, scheduled_time;
                          
            EXCEPTION WHEN OTHERS THEN
                -- Log the error but don't fail the entire transaction
                RAISE WARNING 'Failed to execute strategy SQL for campaign %, lead %, sequence %: % - SQL: %', 
                             NEW.campaign_id, NEW.id, sequence_counter, SQLERRM, message_sql;
            END;
            
            -- Increment sequence counter and update base time for next message
            sequence_counter := sequence_counter + 1;
            base_time := scheduled_time;
        END LOOP;
        
        RAISE INFO 'Completed message creation for lead % in campaign %. Created % messages.', 
                  NEW.id, NEW.campaign_id, sequence_counter - 1;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger that fires when lead status changes
-- This trigger automatically invokes the message creation process
DROP TRIGGER IF EXISTS trigger_create_messages_on_processing ON leads;
CREATE TRIGGER trigger_create_messages_on_processing
    BEFORE UPDATE OF status ON leads
    FOR EACH ROW
    EXECUTE FUNCTION create_messages_on_processing_status();

-- Add helpful comments for documentation
COMMENT ON FUNCTION is_business_hours(TIMESTAMPTZ) IS 'Checks if a timestamp falls within business hours (Mon-Fri 9AM-6PM Berlin time)';
COMMENT ON FUNCTION get_next_business_hour(TIMESTAMPTZ) IS 'Returns the next valid business hour timestamp';
COMMENT ON FUNCTION get_campaign_daily_message_count(UUID, DATE) IS 'Returns count of messages scheduled for a campaign on a specific date';
COMMENT ON FUNCTION get_next_available_slot(UUID, TIMESTAMPTZ, INTEGER) IS 'Finds next available time slot respecting all scheduling constraints';
COMMENT ON FUNCTION create_messages_on_processing_status() IS 'Main trigger function that creates scheduled messages when lead status changes to processing';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_campaign_due ON messages(campaign_id, due) WHERE due IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_messages_due_date ON messages((DATE(due AT TIME ZONE 'Europe/Berlin'))) WHERE due IS NOT NULL;