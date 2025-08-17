set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_due_messages()
 RETURNS TABLE(id uuid, lead_id uuid, campaign_id uuid, subject text, message text, sender text, lead_email text, lead_status text, lead_company_website text, lead_campaign_id uuid, campaign_email text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;


