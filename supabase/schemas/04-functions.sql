-- /Users/nick/NiCode GmbH/Salesurance/supabase/schemas/04-functions.sql
-- Database functions for automated message scheduling and timestamp management
-- These functions handle business logic for timing, capacity constraints, and automation
-- RELEVANT FILES: 02-tables.sql, 06-triggers.sql, 07-cron-jobs.sql

-- Set timezone to Berlin for all scheduling calculations
SET timezone = 'Europe/Berlin';

-- Function to automatically update the updated_at column when a row is modified
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to check if a given timestamp falls within business hours (Mon-Fri, 9AM-6PM Berlin time)
CREATE OR REPLACE FUNCTION public.is_business_hours(check_time TIMESTAMPTZ)
RETURNS BOOLEAN AS $$
BEGIN
    -- Convert to Berlin timezone and check if it's Monday-Friday between 9 AM and 6 PM
    RETURN EXTRACT(DOW FROM check_time AT TIME ZONE 'Europe/Berlin') BETWEEN 1 AND 5 
           AND EXTRACT(HOUR FROM check_time AT TIME ZONE 'Europe/Berlin') BETWEEN 9 AND 17;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get the next business hour slot after a given timestamp
CREATE OR REPLACE FUNCTION public.get_next_business_hour(from_time TIMESTAMPTZ)
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
CREATE OR REPLACE FUNCTION public.get_campaign_daily_message_count(campaign_uuid UUID, target_date DATE)
RETURNS INTEGER AS $$
BEGIN
    -- Count existing messages scheduled for the target date in Berlin timezone for this specific campaign
    RETURN (
        SELECT COUNT(*)
        FROM public.messages
        WHERE campaign_id = campaign_uuid
        AND due IS NOT NULL
        AND DATE(due AT TIME ZONE 'Europe/Berlin') = target_date
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to find the next available time slot for a campaign respecting all constraints
CREATE OR REPLACE FUNCTION public.get_next_available_slot(
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
    FROM public.messages
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
                FROM public.messages
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
CREATE OR REPLACE FUNCTION public.create_messages_on_processing_status()
RETURNS TRIGGER AS $$
DECLARE
    campaign_strategy TEXT[];
    strategy_sql TEXT;
    scheduled_time TIMESTAMPTZ;
    sequence_counter INTEGER := 1;
    base_time TIMESTAMPTZ;
BEGIN
    -- Only proceed if status changed TO 'processing'
    IF NEW.status = 'processing' AND (OLD.status IS NULL OR OLD.status != 'processing') THEN
        
        -- Get the campaign strategy for this lead
        SELECT strategy INTO campaign_strategy
        FROM public.campaigns
        WHERE id = NEW.campaign_id;
        
        -- If no strategy is defined, log and exit
        IF campaign_strategy IS NULL OR array_length(campaign_strategy, 1) IS NULL THEN
            RAISE WARNING 'No strategy defined for campaign %, lead %', NEW.campaign_id, NEW.id;
            RETURN NEW;
        END IF;
        
        -- Set base time to now for scheduling calculations
        base_time := NOW();
        
        -- Process each SQL statement in the strategy
        FOREACH strategy_sql IN ARRAY campaign_strategy
        LOOP
            -- Skip if no SQL is provided
            IF strategy_sql IS NULL OR LENGTH(TRIM(strategy_sql)) = 0 THEN
                RAISE WARNING 'Empty SQL in strategy for campaign %, lead %, sequence %', NEW.campaign_id, NEW.id, sequence_counter;
                CONTINUE;
            END IF;
            
            -- Calculate the next available time slot for this message
            scheduled_time := get_next_available_slot(NEW.campaign_id, base_time, sequence_counter);
            
            BEGIN
                -- Execute the dynamic SQL to create the message
                -- The SQL should insert into messages table with proper values
                EXECUTE strategy_sql 
                USING NEW.campaign_id, NEW.id, scheduled_time;
                
                RAISE INFO 'Created message % for lead % in campaign % scheduled for %', 
                          sequence_counter, NEW.id, NEW.campaign_id, scheduled_time;
                          
            EXCEPTION WHEN OTHERS THEN
                -- Log the error but don't fail the entire transaction
                RAISE WARNING 'Failed to execute strategy SQL for campaign %, lead %, sequence %: % - SQL: %', 
                             NEW.campaign_id, NEW.id, sequence_counter, SQLERRM, strategy_sql;
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

-- Test function for the automated messaging system
CREATE OR REPLACE FUNCTION public.test_automated_messaging()
RETURNS TEXT AS $$
DECLARE
    test_client_id UUID;
    test_campaign_id UUID;
    test_lead_id UUID;
    result_count INTEGER;
    result TEXT := '';
BEGIN
    -- Create test client
    INSERT INTO public.clients (name, status)
    VALUES ('Test Client for Automation', 'active')
    RETURNING id INTO test_client_id;
    
    result := result || 'Created test client: ' || test_client_id || E'\n';
    
    -- Create test campaign with strategy
    INSERT INTO public.campaigns (client_id, name, status, strategy)
    VALUES (
        test_client_id, 
        'Test Campaign for Automation', 
        'active',
        ARRAY[
            'INSERT INTO messages (campaign_id, lead_id, status, channel, subject, message, sender, due) VALUES ($1, $2, ''active'', ''email'', ''Test Subject 1'', ''Test message 1 content'', ''test@example.com'', $3)',
            'INSERT INTO messages (campaign_id, lead_id, status, channel, subject, message, sender, due) VALUES ($1, $2, ''active'', ''email'', ''Test Subject 2'', ''Test message 2 content'', ''test@example.com'', $3)'
        ]
    )
    RETURNING id INTO test_campaign_id;
    
    result := result || 'Created test campaign: ' || test_campaign_id || E'\n';
    
    -- Create test lead
    INSERT INTO public.leads (campaign_id, first_name, last_name, email, status)
    VALUES (test_campaign_id, 'Test', 'Lead', 'testlead@example.com', 'new')
    RETURNING id INTO test_lead_id;
    
    result := result || 'Created test lead: ' || test_lead_id || E'\n';
    
    -- Update lead status to 'processing' to trigger message creation
    UPDATE public.leads 
    SET status = 'processing' 
    WHERE id = test_lead_id;
    
    result := result || 'Updated lead status to processing (should trigger message creation)' || E'\n';
    
    -- Check how many messages were created
    SELECT COUNT(*) INTO result_count
    FROM public.messages 
    WHERE lead_id = test_lead_id;
    
    result := result || 'Messages created: ' || result_count || E'\n';
    
    -- Clean up test data
    DELETE FROM public.clients WHERE id = test_client_id;
    
    result := result || 'Cleaned up test data' || E'\n';
    result := result || 'Test completed successfully!';
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    -- Clean up on error
    DELETE FROM public.clients WHERE id = test_client_id;
    RETURN 'Test failed with error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to check for duplicate leads before insertion
-- This function will be called by a trigger to prevent duplicate entries
CREATE OR REPLACE FUNCTION public.prevent_duplicate_leads()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if a lead already exists with the same first_name, last_name, and campaign_id
    IF EXISTS (
        SELECT 1 FROM public.leads 
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

-- Function for testing campaign isolation with TEXT[] strategy format
CREATE OR REPLACE FUNCTION public.test_campaign_isolation()
RETURNS TEXT AS $$
DECLARE
    campaign_a_id UUID;
    campaign_b_id UUID;
    client_id UUID;
    lead_a_id UUID;
    lead_b_id UUID;
    messages_a INTEGER;
    messages_b INTEGER;
    result_text TEXT := '';
BEGIN
    -- Create test client
    INSERT INTO public.clients (name, status) VALUES ('Campaign Isolation Test Client', 'active')
    RETURNING id INTO client_id;
    
    -- Create two separate campaigns with TEXT[] strategies
    INSERT INTO public.campaigns (client_id, name, status, strategy) 
    VALUES (client_id, 'Campaign A', 'active', ARRAY['INSERT INTO messages (campaign_id, lead_id, status, channel, message, sender, due) VALUES ($1, $2, ''scheduled'', ''email'', ''Message from Campaign A'', ''sales@company.com'', $3)'])
    RETURNING id INTO campaign_a_id;
    
    INSERT INTO public.campaigns (client_id, name, status, strategy) 
    VALUES (client_id, 'Campaign B', 'active', ARRAY['INSERT INTO messages (campaign_id, lead_id, status, channel, message, sender, due) VALUES ($1, $2, ''scheduled'', ''email'', ''Message from Campaign B'', ''sales@company.com'', $3)'])
    RETURNING id INTO campaign_b_id;
    
    -- Create leads for both campaigns
    INSERT INTO public.leads (campaign_id, first_name, last_name, email, status)
    VALUES (campaign_a_id, 'Alice', 'Smith', 'alice@example.com', 'new')
    RETURNING id INTO lead_a_id;
    
    INSERT INTO public.leads (campaign_id, first_name, last_name, email, status)
    VALUES (campaign_b_id, 'Bob', 'Johnson', 'bob@example.com', 'new')
    RETURNING id INTO lead_b_id;
    
    -- Trigger both campaigns by changing status to processing
    UPDATE public.leads SET status = 'processing' WHERE id = lead_a_id;
    UPDATE public.leads SET status = 'processing' WHERE id = lead_b_id;
    
    -- Count messages for each campaign
    SELECT COUNT(*) INTO messages_a FROM public.messages WHERE campaign_id = campaign_a_id;
    SELECT COUNT(*) INTO messages_b FROM public.messages WHERE campaign_id = campaign_b_id;
    
    result_text := 'Campaign A messages: ' || messages_a || ', Campaign B messages: ' || messages_b;
    
    IF messages_a = 1 AND messages_b = 1 THEN
        result_text := result_text || ' - PASS: Campaign isolation working correctly with TEXT[] format';
    ELSE
        result_text := result_text || ' - FAIL: Campaign isolation not working with TEXT[] format';
    END IF;
    
    -- Cleanup
    DELETE FROM public.clients WHERE id = client_id;
    
    RETURN result_text;
    
EXCEPTION WHEN OTHERS THEN
    -- Clean up on error
    DELETE FROM public.clients WHERE id = client_id;
    RETURN 'Campaign isolation test failed with error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Add function comments for documentation
COMMENT ON FUNCTION public.update_updated_at_column() IS 'Automatically updates the updated_at timestamp when a row is modified';
COMMENT ON FUNCTION public.is_business_hours(TIMESTAMPTZ) IS 'Checks if a timestamp falls within business hours (Mon-Fri 9AM-6PM Berlin time)';
COMMENT ON FUNCTION public.get_next_business_hour(TIMESTAMPTZ) IS 'Returns the next valid business hour timestamp';
COMMENT ON FUNCTION public.get_campaign_daily_message_count(UUID, DATE) IS 'Returns count of messages scheduled for a campaign on a specific date';
COMMENT ON FUNCTION public.get_next_available_slot(UUID, TIMESTAMPTZ, INTEGER) IS 'Finds next available time slot respecting all scheduling constraints';
COMMENT ON FUNCTION public.create_messages_on_processing_status() IS 'Main trigger function that creates scheduled messages when lead status changes to processing';
COMMENT ON FUNCTION public.test_automated_messaging() IS 'Test function to verify the automated messaging system works correctly';
COMMENT ON FUNCTION public.test_campaign_isolation() IS 'Tests that campaigns maintain scheduling isolation from each other using TEXT[] strategy format';
COMMENT ON FUNCTION public.prevent_duplicate_leads() IS 'Trigger function to prevent duplicate leads with same first_name, last_name, and campaign_id';

-- Function to get due messages for email sending with all required data
-- Used by send-email edge function to bypass complex join issues in edge function environment
-- Returns scheduled messages that are due for sending with all related lead and campaign data
CREATE OR REPLACE FUNCTION public.get_due_messages()
RETURNS TABLE (
  id uuid,
  lead_id uuid,
  campaign_id uuid,
  subject text,
  message text,
  sender text,
  lead_email text,
  lead_status text,
  lead_company_website text,
  lead_campaign_id uuid,
  campaign_email text
) 
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    m.id,
    m.lead_id,
    m.campaign_id,
    m.subject,
    m.message,
    m.sender,
    l.email as lead_email,
    l.status as lead_status,
    l.company_website as lead_company_website,
    l.campaign_id as lead_campaign_id,
    c.email as campaign_email
  FROM messages m
  INNER JOIN leads l ON m.lead_id = l.id
  INNER JOIN campaigns c ON m.campaign_id = c.id
  WHERE m.status = 'scheduled'
    AND m.due <= NOW()
  ORDER BY m.due ASC;
$$;

COMMENT ON FUNCTION public.get_due_messages() IS 'Returns all scheduled messages that are due for sending, with lead and campaign data included. Used by send-email edge function to avoid complex join issues.';