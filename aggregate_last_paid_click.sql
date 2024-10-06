with tab1 as (
     select distinct on (visitor_id)
        visitor_id,
        visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign as utm_campaign
    from
        sessions
    where
        medium != 'organic'
    order by
        visitor_id asc,
        visit_date desc
),

tab2 as (
    select
        t.visitor_id,
        t.visit_date,
        t.utm_source,
        t.utm_medium,
        t.utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    from
        tab1 as t
    left join leads as l
        on
            t.visitor_id = l.visitor_id
            and t.visit_date <= l.created_at
    order by
        l.amount desc nulls last,
        t.visit_date asc,
        t.utm_source asc,
        t.utm_medium asc,
        t.utm_campaign asc
),

tab3 as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        date(visit_date) as visit_date,
        count(visitor_id) as visitors_count,
        count(nullif(created_at, null)) as leads_count,
        count(
            case when status_id = 142 then visitor_id end
        ) as purchases_count,
        sum(
            case when status_id = 142 then amount else 0 end
        ) as revenue
    from
        tab2
    group by
        utm_source,
        utm_medium,
        utm_campaign,
        date(visit_date)
),

tab4 as (
    select
        date(campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from
        ya_ads
    group by
        date(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
    union all
    select
        date(campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from
        vk_ads
    group by
        date(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
)

select
    t3.visit_date,
    t3.visitors_count,
    t3.utm_source,
    t3.utm_medium,
    t3.utm_campaign,
    t4.total_cost,
    t3.leads_count,
    t3.purchases_count,
    t3.revenue
from
    tab3 as t3
left join tab4 as t4
    on
        t3.visit_date = t4.visit_date
        and t3.utm_source = t4.utm_source
        and t3.utm_medium = t4.utm_medium
        and t3.utm_campaign = t4.utm_campaign
order by
    t3.revenue desc nulls last,
    t3.visit_date asc,
    t3.visitors_count desc,
    t3.utm_source asc,
    t3.utm_medium asc
limit 15;
