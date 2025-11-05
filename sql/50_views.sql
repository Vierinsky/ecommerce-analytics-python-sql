-- Revenue per quarter view
CREATE OR REPLACE VIEW analytics.vw_revenue_quarter AS
SELECT
    dcal.year,
    dcal.quarter,
    SUM(f.price) AS revenue
FROM core.fact_events f
JOIN core.dim_calendar dcal ON dcal.calendar_sk = f.calendar_sk
GROUP BY 1,2;

-- KPI Views

-- Revenue (GMV without freight) — per quarter (SP)
CREATE OR REPLACE VIEW analytics.vw_revenue_quarter_sp AS
SELECT
  dcal.year,
  dcal.quarter,
  SUM(f.price) AS revenue_sp
FROM core.fact_events f
JOIN core.dim_calendar dcal  ON dcal.calendar_sk  = f.calendar_sk
JOIN core.dim_customer dcu   ON dcu.customer_sk   = f.customer_sk
WHERE dcu.customer_city = 'sao paulo' 
GROUP BY 1,2;

-- Share of reviews ≥ 4★ — per quarter (SP)
CREATE OR REPLACE VIEW analytics.vw_reviews_share_quarter_sp AS
WITH reviews AS (
    SELECT
    r.order_id,
    r.review_score
    FROM staging.reviews_raw r
),
orders_q AS (
    SELECT o.order_id, o.year, o.quarter
    FROM analytics.vw_orders_q_sp o
)
SELECT
    o.year,
    o.quarter,
    AVG(CASE WHEN r.review_score >= 4 THEN 1.0 ELSE 0.0 END) as share_ge4
FROM orders_q o
JOIN reviews r USING (order_id)
GROUP BY 1,2;

-- Lead time P90 (days) — per quarter (SP)
CREATE OR REPLACE VIEW analytics.vw_leadtime_p90_quarter_sp AS
SELECT
    dcal.year,
    dcal.quarter,
    percentile_cont(0.9) WITHIN GROUP (ORDER BY f.lead_time_days) AS lead_time_p90
FROM core.fact_events f
JOIN core.dim_calendar dcal ON dcal.calendar_sk = f.calendar_sk
JOIN core.dim_customer dcu ON dcu.customer_sk = f.customer_sk
WHERE dcu.customer_city = 'sao paulo'
    AND f.lead_time_days IS NOT NULL
GROUP BY 1,2;

-- On-time rate (% delivered ≤ estimated) — per quarter (SP)
CREATE OR REPLACE VIEW analytics.vw_on_time_rate_quarter_sp AS
SELECT
    dcal.year,
    dcal.quarter,
    AVG(CASE WHEN f.on_time_flag = 1 THEN 1.0
            WHEN f.on_time_flag = 0 THEN 0.0
            ELSE NULL END) AS on_time_flag
FROM core.fact_events f
JOIN core.dim_calendar dcal ON dcal.calendar_sk = f.calendar_sk
JOIN core.dim_customer dcu ON dcu.customer_sk = f.customer_sk
WHERE dcu.customer_city = 'sao paulo'
GROUP BY 1,2;

-- Top category share — “frozen at Q_{t−4}” (SP)
CREATE OR REPLACE VIEW analytics.vw_category_share_quarter_sp AS
SELECT
    dcal.year,
    dcal.quarter,
    dp.product_category_name AS category,
    SUM(f.price) AS revenue_cat,
    SUM(SUM(f.price)) OVER (PARTITION BY dcal.year, dcal.quarter) AS revenue_total,
    (SUM(f.price) / NULLIF(SUM(SUM(f.price)) OVER (PARTITION BY dcal.year, dcal.quarter),0)) AS share_cat
FROM core.fact_events f
JOIN core.dim_calendar dcal ON dcal.calendar_sk = f.calendar_sk
JOIN core.dim_customer dcu ON dcu.customer_sk = f.customer_sk
JOIN core.dim_product dp ON dp.product_sk = f.product_sk
WHERE dcu.customer_city = 'sao paulo'
GROUP BY 1,2,3;

-- A/B “analysis-ready” view (order-level, SP, with group)
    -- This aggregates order revenue (sum of items) and attaches the group
    -- RUN ME
CREATE OR REPLACE VIEW analytics.vw_ab_orders_sp AS
WITH order_rev AS (
    SELECT
    f.order_id,
    SUM(f.price) AS order_revenue,
    MIN(dcal.year) AS year,
    MIN(dcal.quarter) AS quarter,
    MIN(dcu.customer_id) AS customer_id
    FROM core.fact_events f
    JOIN core.dim_calendar dcal ON dcal.calendar_sk = f.calendar_sk
    JOIN core.dim_customer dcu  ON dcu.customer_sk  = f.customer_sk
    WHERE dcu.customer_city = 'sao paulo'
    GROUP BY f.order_id
)
SELECT
    o.order_id,
    o.order_revenue,
    o.year, o.quarter,
    o.customer_id,
    cab.group_id
FROM order_rev o
JOIN analytics.vw_customer_ab cab ON cab.customer_id = o.customer_id;

-- Quick check
SELECT * FROM analytics.vw_revenue_quarter_sp GROUP BY year, quarter, revenue_sp ORDER BY year ASC;
-- SELECT * FROM analytics.vw_revenue_quarter_sp LIMIT 5;
-- SELECT * FROM analytics.vw_reviews_share_quarter_sp LIMIT 5;
-- SELECT * FROM analytics.vw_on_time_rate_quarter_sp LIMIT 5;
-- SELECT * FROM analytics.vw_leadtime_p90_quarter_sp LIMIT 5;
-- SELECT * FROM analytics.vw_category_share_quarter_sp LIMIT 5;