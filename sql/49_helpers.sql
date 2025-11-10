-- Quarter/date helper (delivered date → quarter)
CREATE OR REPLACE VIEW analytics.vw_orders_q_sp AS
SELECT
    o.order_id,
    o.customer_id,
    DATE(o.order_delivered_customer_date) AS delivered_date,
    dcal.calendar_sk,
    dcal.year,
    dcal.quarter,
    dcu.customer_city
FROM staging.orders_raw o
JOIN core.dim_customer dcu ON dcu.customer_id = o.customer_id
JOIN core.dim_calendar dcal ON dcal.date = DATE(o.order_delivered_customer_date)
WHERE o.order_status = 'delivered'
    AND dcu.customer_city = 'sao paulo';

/*
-- Dropped A/B Test


-- Deterministic hashing (customer → A/B)
CREATE OR REPLACE VIEW analytics.vw_customer_ab AS
SELECT
    dcu.customer_id,
    ( ( ('x' || substr(md5(dcu.customer_id), 1, 8))::bit(32)::int ) & 1 )::int AS group_id
FROM core.dim_customer dcu;


-- A/B assignment & order-level analysis views
DROP VIEW IF EXISTS analytics.vw_customer_ab CASCADE;

*/

-- Let's review which quarters we actually have
SELECT year, quarter, COUNT(*) AS orders_sp
FROM analytics.vw_ab_orders_sp
GROUP BY 1,2
ORDER BY 1,2;