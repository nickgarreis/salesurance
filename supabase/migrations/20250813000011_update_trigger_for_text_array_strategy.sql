-- /Users/nick/agentic_marketing_system/supabase/migrations/20250813000011_update_trigger_for_text_array_strategy.sql
-- Updates the automated message creation trigger to work with TEXT[] strategy column instead of JSONB
-- This simplifies the SQL parsing and allows direct execution of SQL strings from the array
-- RELEVANT FILES: 20250813000010_change_strategy_column_to_text_array.sql, 20250813000008_create_automated_message_scheduling_system.sql, leads table, messages table

-- Updated main function that creates messages when a lead status changes to 'processing'
-- This function now processes TEXT[] strategy instead of JSONB
CREATE OR REPLACE FUNCTION create_messages_on_processing_status()
RETURNS TRIGGER AS $$
DECLARE
    campaign_strategy TEXT[];
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
        IF campaign_strategy IS NULL OR array_length(campaign_strategy, 1) = 0 THEN
            RAISE WARNING 'No strategy defined for campaign %, lead %', NEW.campaign_id, NEW.id;
            RETURN NEW;
        END IF;
        
        -- Set base time to now for scheduling calculations
        base_time := NOW();
        
        -- Process each SQL statement in the strategy array
        FOR i IN 1..array_length(campaign_strategy, 1)
        LOOP
            -- Get the SQL statement from the array
            message_sql := campaign_strategy[i];
            
            -- Skip if no SQL is provided or it's empty
            IF message_sql IS NULL OR LENGTH(TRIM(message_sql)) = 0 THEN
                RAISE WARNING 'Empty SQL in strategy for campaign %, lead %, sequence %', NEW.campaign_id, NEW.id, sequence_counter;
                CONTINUE;
            END IF;
            
            -- Calculate the next available time slot for this message
            scheduled_time := get_next_available_slot(NEW.campaign_id, base_time, sequence_counter);
            
            BEGIN
                -- Execute the dynamic SQL to create the message
                -- The SQL should use $1, $2, $3, $4, $5 placeholders for:
                -- $1 = message ID (generated UUID)
                -- $2 = lead ID  
                -- $3 = campaign ID
                -- $4 = due timestamp
                -- $5 = current timestamp (for created_at and updated_at)
                EXECUTE message_sql 
                USING uuid_generate_v4(), NEW.id, NEW.campaign_id, scheduled_time, NOW();
                
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

-- Update the comment for the function
COMMENT ON FUNCTION create_messages_on_processing_status() IS 'Main trigger function that creates scheduled messages when lead status changes to processing. Now supports TEXT[] strategy format for direct SQL execution.';