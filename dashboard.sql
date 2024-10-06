--все расчеты делаем по модели атрибуции Last Paid Click
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
        count(created_at) as leads_count,
        count(visitor_id) filter (where status_id = 142) as purchases_count,
        sum(amount) filter (where status_id = 142) as revenue
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
    t3.utm_medium asc;
--Сколько у нас пользователей заходят на сайт?
--Какие каналы их приводят на сайт?
--Сколько лидов к нам приходят?
select
    t5.utm_source,
    to_char(t5.visit_date, 'WW') as visit_week,
    sum(t5.visitors_count) as visitors_count,
    sum(t5.leads_count) as leads_count
from
    tab5 as t5
group by t5.utm_source, visit_week;
--Какая конверсия из клика в лид? А из лида в оплату?
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
        count(created_at) as leads_count,
        count(visitor_id) filter (where status_id = 142) as purchases_count,
        sum(amount) filter (where status_id = 142) as revenue
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
),

tab5 as (
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
),

tab6 as (
    select
        t5.utm_source,
        sum(t5.visitors_count) as visitors_count,
        sum(t5.leads_count) as leads_count,
        sum(t5.purchases_count) as purchases_count
    from
        tab5 as t5
    where t5.leads_count > 0 and t5.purchases_count > 0
    group by t5.utm_source
)

select
    utm_source,
    visitors_count,
    leads_count,
    purchases_count,
    round((leads_count::numeric / visitors_count::numeric) * 100.0, 2)
    as convers_click,
    round((purchases_count::numeric / leads_count::numeric) * 100.0, 2)
    as convers_lead
from tab6;
--cpu = total_cost / visitors_count
--cpl = total_cost / leads_count
--cppu = total_cost / purchases_count
--roi = (revenue - total_cost) / total_cost * 100%
select
    coalesce(t5.utm_source) as utm_source,
    sum(t5.total_cost) as total_cost,
    sum(t5.leads_count) as leads_count,
    sum(t5.purchases_count) as purchases_count,
    sum(t5.visitors_count) as visitors_count,
    sum(t5.revenue) as revenue,
    round(sum(t5.total_cost) / sum(t5.visitors_count), 2) as cpu,
    round(sum(t5.total_cost) / sum(t5.leads_count), 2) as cpl,
    round(sum(t5.total_cost) / sum(t5.purchases_count), 2) as cppu,
    round(
        ((sum(t5.revenue) - sum(t5.total_cost)) / sum(t5.total_cost)) * 100.0, 2
    ) as roi
from
    tab5 as t5
where t5.utm_source in ('yandex', 'vk')
group by t5.utm_source
order by total_cost desc nulls last;
-- считаем дни с момента перехода по рекламе
with tab1 as (
    select distinct on (visitor_id)
        visitor_id,
        visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign as utm_campaign
    from sessions
    where medium != 'organic'
    order by
        visitor_id asc,
        visit_date desc
),

tab2 as (
    select
        t.visitor_id,
        t.visit_date,
        l.created_at,
        (date(l.created_at) - date(t.visit_date)) as difference
    from tab1 as t
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
)

select avg(difference) from tab2;
