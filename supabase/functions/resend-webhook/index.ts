// /Users/nick/Pokale Meier/supabase/functions/resend-webhook/index.ts
// Webhook handler for Resend email events (sent, delivered, opened, clicked, bounced, etc.)
// Updates messages table with email tracking data using JSONB email_events column
// RELEVANT FILES: send-email/index.ts, messages table schema, 20250813000014_add_email_tracking_columns.sql

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createHmac } from 'node:crypto'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const resendWebhookSecret = Deno.env.get('RESEND_WEBHOOK_SECRET')

// Create Supabase client with service role key for database operations
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// Supported Resend webhook event types
const SUPPORTED_EVENTS = [
  'email.sent',
  'email.delivered', 
  'email.bounced',
  'email.opened',
  'email.clicked',
  'email.complained',
  'email.delivery_delayed',
  'email.failed',
  'email.unsubscribed'
] as const

type SupportedEvent = typeof SUPPORTED_EVENTS[number]

// Verify webhook signature for security
function verifyWebhookSignature(payload: string, signature: string, secret: string): boolean {
  if (!secret || !signature) {
    console.warn('Missing webhook secret or signature - skipping verification')
    return true // Allow during development, but log warning
  }
  
  const expectedSignature = createHmac('sha256', secret)
    .update(payload)
    .digest('hex')
  
  // Resend sends signature in format "sha256=<hash>"
  const providedSignature = signature.replace('sha256=', '')
  
  return expectedSignature === providedSignature
}

// Extract event type from full event name (e.g., 'email.opened' -> 'opened')
function getEventKey(eventType: string): string {
  return eventType.includes('.') ? eventType.split('.')[1] : eventType
}

// Build event data object based on event type
function buildEventData(eventType: SupportedEvent, webhookData: any): any {
  const baseEvent = { timestamp: webhookData.created_at }
  
  switch (eventType) {
    case 'email.clicked':
      return {
        ...baseEvent,
        link: webhookData.data.click?.link,
        user_agent: webhookData.data.click?.userAgent,
        ip_address: webhookData.data.click?.ipAddress
      }
    
    case 'email.bounced':
      return {
        ...baseEvent,
        type: webhookData.data.bounce?.type,
        sub_type: webhookData.data.bounce?.subType, 
        message: webhookData.data.bounce?.message
      }
    
    case 'email.failed':
      return {
        ...baseEvent,
        reason: webhookData.data.failed?.reason
      }
    
    default:
      return baseEvent
  }
}

Deno.serve(async (req) => {
  try {
    // Only accept POST requests
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const body = await req.text()
    const signature = req.headers.get('resend-signature') || req.headers.get('signature')
    
    console.log('Received webhook request', { 
      signature: signature ? 'present' : 'missing',
      bodyLength: body.length 
    })

    // Verify webhook signature if secret is configured
    if (resendWebhookSecret && signature) {
      if (!verifyWebhookSignature(body, signature, resendWebhookSecret)) {
        console.error('Invalid webhook signature')
        return new Response(JSON.stringify({ error: 'Invalid signature' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        })
      }
    }

    const webhookData = JSON.parse(body)
    const eventType = webhookData.type as SupportedEvent

    console.log('Processing webhook event', { 
      type: eventType, 
      email_id: webhookData.data?.email_id 
    })

    // Validate event type
    if (!SUPPORTED_EVENTS.includes(eventType)) {
      console.log(`Unsupported event type: ${eventType}`)
      return new Response(JSON.stringify({ message: 'Event type not supported' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Extract email ID from webhook data
    const emailId = webhookData.data?.email_id
    if (!emailId) {
      console.error('No email_id found in webhook data')
      return new Response(JSON.stringify({ error: 'Missing email_id' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Find message by resend_email_id and include thread data for logging
    const { data: message, error: findError } = await supabase
      .from('messages')
      .select('id, email_events, email_thread_data, lead_id, campaign_id')
      .eq('resend_email_id', emailId)
      .single()

    if (findError) {
      console.error(`Message not found for email_id ${emailId}:`, findError)
      return new Response(JSON.stringify({ error: 'Message not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Handle unsubscribe events with special business logic
    if (eventType === 'email.unsubscribed') {
      console.log(`Processing unsubscribe event for campaign ${message.campaign_id}`)
      
      // Get lead information to find company_website
      const { data: lead, error: leadError } = await supabase
        .from('leads')
        .select('company_website')
        .eq('id', message.lead_id)
        .single()
      
      if (leadError || !lead) {
        console.error(`Failed to find lead for message ${message.id}:`, leadError)
        return new Response(JSON.stringify({ error: 'Lead not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        })
      }
      
      // Update all leads in this campaign with the same company_website to 'unsubscribed'
      const { data: updatedLeads, error: updateLeadsError } = await supabase
        .from('leads')
        .update({ status: 'unsubscribed' })
        .eq('campaign_id', message.campaign_id)
        .eq('company_website', lead.company_website)
        .select('id, email, first_name, last_name')
      
      if (updateLeadsError) {
        console.error('Error updating leads to unsubscribed:', updateLeadsError)
        return new Response(JSON.stringify({ error: 'Failed to update leads' }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        })
      }
      
      // Cancel all pending messages for these unsubscribed leads
      if (updatedLeads && updatedLeads.length > 0) {
        const leadIds = updatedLeads.map(lead => lead.id)
        
        const { error: cancelError } = await supabase
          .from('messages')
          .update({ status: 'cancelled' })
          .in('lead_id', leadIds)
          .eq('status', 'active')
        
        if (cancelError) {
          console.error('Error cancelling pending messages:', cancelError)
          // Don't fail the unsubscribe, just log the error
        } else {
          console.log(`Cancelled pending messages for ${leadIds.length} unsubscribed leads`)
        }
      }
      
      const unsubscribeCount = updatedLeads?.length || 0
      console.log(`Successfully unsubscribed ${unsubscribeCount} leads from campaign ${message.campaign_id}`)
    }

    // Build event data for this specific event type
    const eventKey = getEventKey(eventType)
    const eventData = buildEventData(eventType, webhookData)
    
    // Merge new event into existing email_events JSON
    const updatedEvents = {
      ...message.email_events,
      [eventKey]: eventData
    }

    // Update message with new event data
    const { error: updateError } = await supabase
      .from('messages')
      .update({ 
        email_events: updatedEvents,
        updated_at: new Date().toISOString()
      })
      .eq('id', message.id)

    if (updateError) {
      console.error(`Failed to update message ${message.id}:`, updateError)
      return new Response(JSON.stringify({ error: 'Database update failed' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Log thread information for debugging and analytics
    const threadInfo = message.email_thread_data ? {
      thread_id: message.email_thread_data.thread_id,
      message_id: message.email_thread_data.message_id,
      is_follow_up: !!message.email_thread_data.parent_message_id
    } : null

    console.log(`Successfully processed ${eventType} event for message ${message.id}`, {
      thread_info: threadInfo,
      lead_id: message.lead_id,
      campaign_id: message.campaign_id
    })
    
    return new Response(JSON.stringify({ 
      message: 'Webhook processed successfully',
      event_type: eventType,
      message_id: message.id,
      thread_id: threadInfo?.thread_id
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Unexpected error in resend-webhook function:', error)
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      details: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})