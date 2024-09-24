with tab1 as (select distinct on (visitor_id)
visitor_id,
visit_date,
source as utm_source,
medium as utm_medium,
campaign as utm_campaign
from sessions 
where medium != 'organic'
order by visitor_id, visit_date desc)
select 
t.visitor_id,
t.visit_date,
utm_source,
utm_medium,
utm_campaign,
l.lead_id,
l.created_at,
l.amount,
l.closing_reason,
l.status_id
from tab1 t
left join leads l on t.visitor_id = l.visitor_id
and  t.visit_date <= l.created_at
order by l.amount desc nulls last, t.visit_date, utm_source, utm_medium, utm_campaign
limit 10;