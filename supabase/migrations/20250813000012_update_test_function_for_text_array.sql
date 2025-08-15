-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000012_update_test_function_for_text_array.sql
-- Updates the test functions to work with TEXT[] strategy format instead of JSONB
-- This ensures our test suite validates the new TEXT array-based strategy system
-- RELEVANT FILES: 20250813000011_update_trigger_for_text_array_strategy.sql, 20250813000010_change_strategy_column_to_text_array.sql, 20250813000009_test_automated_messaging_system.sql

-- Updated test function to validate the complete automated messaging system with TEXT[] strategy
CREATE OR REPLACE FUNCTION test_automated_messaging_system()
RETURNS TEXT AS $$
DECLARE
    test_client_id UUID;
    test_campaign_id UUID;
    test_lead_id UUID;
    message_count INTEGER;
    first_message_due TIMESTAMPTZ;
    second_message_due TIMESTAMPTZ;
    test_strategy TEXT[];
    result_text TEXT := '';
BEGIN
    -- Create test client
    INSERT INTO clients (name, status) 
    VALUES ('Test Client for Automated Messaging', 'active')
    RETURNING id INTO test_client_id;
    
    result_text := result_text || 'Created test client: ' || test_client_id || E'\n';
    
    -- Create test strategy with 3 message templates using TEXT array
    -- Each SQL uses $1-$5 parameters: $1=id, $2=lead_id, $3=campaign_id, $4=due, $5=timestamps
    test_strategy := ARRAY[
        'INSERT INTO messages (id, lead_id, campaign_id, status, channel, subject, message, sender, due, created_at, updated_at) VALUES ($1, $2, $3, ''scheduled'', ''email'', ''Welcome to our service'', ''Hi there! Welcome to our amazing service. We are excited to have you on board!'', ''sales@company.com'', $4, $5, $5)',
        'INSERT INTO messages (id, lead_id, campaign_id, status, channel, subject, message, sender, due, created_at, updated_at) VALUES ($1, $2, $3, ''scheduled'', ''email'', ''How are you finding our service?'', ''Hi! We wanted to check in and see how you are finding our service. Any questions so far?'', ''sales@company.com'', $4, $5, $5)',
        'INSERT INTO messages (id, lead_id, campaign_id, status, channel, subject, message, sender, due, created_at, updated_at) VALUES ($1, $2, $3, ''scheduled'', ''linkedin'', ''Connect on LinkedIn'', ''Hi! I would love to connect with you on LinkedIn to stay in touch!'', ''sales@company.com'', $4, $5, $5)'
    ];
    
    -- Create test campaign with strategy
    INSERT INTO campaigns (client_id, name, status, strategy) 
    VALUES (test_client_id, 'Test Automated Messaging Campaign', 'active', test_strategy)
    RETURNING id INTO test_campaign_id;
    
    result_text := result_text || 'Created test campaign with TEXT[] strategy: ' || test_campaign_id || E'\n';
    
    -- Create test lead (status = 'new' initially)
    INSERT INTO leads (campaign_id, first_name, last_name, job_title, email, status)
    VALUES (test_campaign_id, 'John', 'Doe', 'CEO', 'john.doe@example.com', 'new')
    RETURNING id INTO test_lead_id;
    
    result_text := result_text || 'Created test lead: ' || test_lead_id || E'\n';
    
    -- Verify no messages exist yet
    SELECT COUNT(*) INTO message_count
    FROM messages 
    WHERE lead_id = test_lead_id;
    
    IF message_count = 0 THEN
        result_text := result_text || 'PASS: No messages created initially' || E'\n';
    ELSE
        result_text := result_text || 'FAIL: ' || message_count || ' messages found before status change' || E'\n';
    END IF;
    
    -- Change lead status to 'processing' - this should trigger message creation
    UPDATE leads 
    SET status = 'processing' 
    WHERE id = test_lead_id;
    
    result_text := result_text || 'Updated lead status to processing' || E'\n';
    
    -- Check if messages were created
    SELECT COUNT(*) INTO message_count
    FROM messages 
    WHERE lead_id = test_lead_id AND campaign_id = test_campaign_id;
    
    IF message_count = 3 THEN
        result_text := result_text || 'PASS: 3 messages created successfully with TEXT[] strategy' || E'\n';
    ELSE
        result_text := result_text || 'FAIL: Expected 3 messages, found ' || message_count || E'\n';
    END IF;
    
    -- Verify message scheduling follows business hours
    SELECT MIN(due) INTO first_message_due
    FROM messages 
    WHERE lead_id = test_lead_id AND due IS NOT NULL;
    
    SELECT MAX(due) INTO second_message_due
    FROM messages 
    WHERE lead_id = test_lead_id AND due IS NOT NULL;
    
    -- Check if messages are scheduled in business hours
    IF is_business_hours(first_message_due) THEN
        result_text := result_text || 'PASS: First message scheduled in business hours: ' || first_message_due || E'\n';
    ELSE
        result_text := result_text || 'FAIL: First message not in business hours: ' || first_message_due || E'\n';
    END IF;
    
    -- Verify 24-hour interval between message sequences
    IF second_message_due >= first_message_due + INTERVAL '24 hours' THEN
        result_text := result_text || 'PASS: Messages have proper 24h+ interval' || E'\n';
    ELSE
        result_text := result_text || 'FAIL: Messages too close together. First: ' || first_message_due || ', Last: ' || second_message_due || E'\n';
    END IF;
    
    -- Verify all messages have required fields
    IF (SELECT COUNT(*) FROM messages WHERE lead_id = test_lead_id AND (subject IS NULL OR message IS NULL OR sender IS NULL)) = 0 THEN
        result_text := result_text || 'PASS: All messages have required fields populated' || E'\n';
    ELSE
        result_text := result_text || 'FAIL: Some messages missing required fields' || E'\n';
    END IF;
    
    -- Clean up test data
    DELETE FROM messages WHERE lead_id = test_lead_id;
    DELETE FROM leads WHERE id = test_lead_id;
    DELETE FROM campaigns WHERE id = test_campaign_id;
    DELETE FROM clients WHERE id = test_client_id;
    
    result_text := result_text || 'Test cleanup completed' || E'\n';
    result_text := result_text || E'\n=== AUTOMATED MESSAGING SYSTEM TEXT[] TEST COMPLETE ===';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Updated test function for campaign isolation with TEXT[] format
CREATE OR REPLACE FUNCTION test_campaign_isolation()
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
    INSERT INTO clients (name, status) VALUES ('Campaign Isolation Test Client', 'active')
    RETURNING id INTO client_id;
    
    -- Create two separate campaigns with TEXT[] strategies
    INSERT INTO campaigns (client_id, name, status, strategy) 
    VALUES (client_id, 'Campaign A', 'active', ARRAY['INSERT INTO messages (id, lead_id, campaign_id, status, channel, message, sender, due, created_at, updated_at) VALUES ($1, $2, $3, ''scheduled'', ''email'', ''Message from Campaign A'', ''sales@company.com'', $4, $5, $5)'])
    RETURNING id INTO campaign_a_id;
    
    INSERT INTO campaigns (client_id, name, status, strategy) 
    VALUES (client_id, 'Campaign B', 'active', ARRAY['INSERT INTO messages (id, lead_id, campaign_id, status, channel, message, sender, due, created_at, updated_at) VALUES ($1, $2, $3, ''scheduled'', ''email'', ''Message from Campaign B'', ''sales@company.com'', $4, $5, $5)'])
    RETURNING id INTO campaign_b_id;
    
    -- Create leads for both campaigns
    INSERT INTO leads (campaign_id, first_name, last_name, email, status)
    VALUES (campaign_a_id, 'Alice', 'Smith', 'alice@example.com', 'new')
    RETURNING id INTO lead_a_id;
    
    INSERT INTO leads (campaign_id, first_name, last_name, email, status)
    VALUES (campaign_b_id, 'Bob', 'Johnson', 'bob@example.com', 'new')
    RETURNING id INTO lead_b_id;
    
    -- Trigger both campaigns by changing status to processing
    UPDATE leads SET status = 'processing' WHERE id = lead_a_id;
    UPDATE leads SET status = 'processing' WHERE id = lead_b_id;
    
    -- Count messages for each campaign
    SELECT COUNT(*) INTO messages_a FROM messages WHERE campaign_id = campaign_a_id;
    SELECT COUNT(*) INTO messages_b FROM messages WHERE campaign_id = campaign_b_id;
    
    result_text := 'Campaign A messages: ' || messages_a || ', Campaign B messages: ' || messages_b;
    
    IF messages_a = 1 AND messages_b = 1 THEN
        result_text := result_text || ' - PASS: Campaign isolation working correctly with TEXT[] format';
    ELSE
        result_text := result_text || ' - FAIL: Campaign isolation not working with TEXT[] format';
    END IF;
    
    -- Cleanup
    DELETE FROM messages WHERE campaign_id IN (campaign_a_id, campaign_b_id);
    DELETE FROM leads WHERE id IN (lead_a_id, lead_b_id);
    DELETE FROM campaigns WHERE id IN (campaign_a_id, campaign_b_id);
    DELETE FROM clients WHERE id = client_id;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Run the updated tests
DO $$
DECLARE
    test_results TEXT;
BEGIN
    SELECT test_automated_messaging_system() INTO test_results;
    RAISE INFO 'TEXT Array Automated Messaging Test Results: %', test_results;
END
$$;

-- Update comments for documentation
COMMENT ON FUNCTION test_automated_messaging_system() IS 'Comprehensive test function for automated message scheduling system using TEXT[] strategy format';
COMMENT ON FUNCTION test_campaign_isolation() IS 'Tests that campaigns maintain scheduling isolation from each other using TEXT[] strategy format';