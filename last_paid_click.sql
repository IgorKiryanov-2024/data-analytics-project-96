WITH tab1 AS
  (SELECT DISTINCT ON (visitor_id) visitor_id,
                      visit_date,
                      SOURCE AS utm_source,
                                medium AS utm_medium,
                                campaign AS utm_campaign
   FROM sessions
   WHERE medium != 'organic'
   ORDER BY visitor_id,
            visit_date DESC)
SELECT t.visitor_id,
       t.visit_date,
       utm_source,
       utm_medium,
       utm_campaign,
       l.lead_id,
       l.created_at,
       l.amount,
       l.closing_reason,
       l.status_id
FROM tab1 t
LEFT JOIN leads l ON t.visitor_id = l.visitor_id
AND t.visit_date <= l.created_at
ORDER BY l.amount DESC NULLS LAST,
         t.visit_date,
         utm_source,
         utm_medium,
         utm_campaign
LIMIT 10;