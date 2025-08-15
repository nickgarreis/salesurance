// /Users/nick/NiCode GmbH/Salesurance/supabase/functions/receive-emails/index.ts
// Webhook edge function to receive incoming email replies via Resend webhook
// Finds lead by email address and creates response message, updates lead status to 'responded'
// RELEVANT FILES: messages table schema, leads table, send-email/index.ts, campaigns table

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Create Supabase client with service role key for database operations
const supabase = createClient(supabaseUrl, supabaseServiceKey)

Deno.serve(async (req) => {
  try {
    // Only accept POST requests for webhooks
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    console.log('Received incoming email webhook')
    
    // Parse the webhook payload from Resend
    const payload = await req.json()
    console.log('Webhook payload:', JSON.stringify(payload, null, 2))

    // Extract email data from Resend webhook format
    // Resend webhook typically includes: from, to, subject, html, text, etc.
    const senderEmail = payload.from || payload.sender?.email
    const subject = payload.subject || 'Re: Your message'
    const messageBody = payload.html || payload.text || 'Email received'

    if (!senderEmail) {
      console.error('No sender email found in webhook payload')
      return new Response(JSON.stringify({ error: 'No sender email provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    console.log(`Processing incoming email from: ${senderEmail}`)

    // Find the lead by email address
    const { data: lead, error: leadError } = await supabase
      .from('leads')
      .select('id, campaign_id, email, first_name, last_name, status')
      .eq('email', senderEmail)
      .single()

    if (leadError || !lead) {
      console.error('Lead not found for email:', senderEmail, leadError)
      return new Response(JSON.stringify({ 
        error: 'Lead not found',
        email: senderEmail 
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    console.log(`Found lead: ${lead.first_name} ${lead.last_name} (ID: ${lead.id})`)

    // Create new message record for the received email
    const { data: newMessage, error: messageError } = await supabase
      .from('messages')
      .insert({
        lead_id: lead.id,
        campaign_id: lead.campaign_id,
        status: 'respond',
        channel: 'email',
        subject: subject,
        message: messageBody,
        sender: 'lead',
        sent_at: new Date().toISOString()
      })
      .select()
      .single()

    if (messageError) {
      console.error('Error creating message record:', messageError)
      return new Response(JSON.stringify({ 
        error: 'Failed to create message record',
        details: messageError.message 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Update lead status to 'responded' if it's not already
    if (lead.status !== 'responded') {
      const { error: statusUpdateError } = await supabase
        .from('leads')
        .update({ status: 'responded' })
        .eq('id', lead.id)

      if (statusUpdateError) {
        console.error('Error updating lead status:', statusUpdateError)
        // Don't fail the entire operation, just log the error
      } else {
        console.log(`Updated lead ${lead.id} status to 'responded'`)
      }
    }

    console.log(`Successfully processed incoming email from ${senderEmail}`)
    
    return new Response(JSON.stringify({
      message: 'Email received and processed successfully',
      lead_id: lead.id,
      message_id: newMessage.id,
      sender_email: senderEmail
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Unexpected error in receive-emails function:', error)
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      details: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})