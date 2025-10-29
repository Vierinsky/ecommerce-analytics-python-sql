WITH base AS (
    SELECT
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        o.customer_id,
        o.order_status,
        o.order_approved_at,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM staging.order_items_raw oi
    JOIN staging.orders_raw      o USING (order_id)
    WHERE o.order_status = 'delivered'
),

-- Date normalization
    -- Keeps all columns from base and adds delivered_date which is just the date part of the timestamp.
cal AS (
    SELECT
        b.*,
        DATE(b.order_delivered_customer_date) AS delivered_date
    FROM base b
),

-- Dimension lookups
joined AS (
    SELECT
        c.order_id,
        c.order_item_id,
        c.price,
        c.freight_value,
        c.order_approved_at,
        c.order_delivered_customer_date,
        c.order_estimated_delivery_date,
        dc.customer_sk,
        dp.product_sk,
        dcal.calendar_sk
    FROM cal c
    JOIN core.dim_customer dc ON dc.customer_id = c.customer_id
    JOIN core.dim_product dp ON dp.product_id = c.product_id
    JOIN core.dim_calendar dcal ON dcal.date = c.delivered_date
    -- JOIN core.dim_seller s ON s.seller_id = c.seller_id
)

-- SELECT * FROM joined LIMIT 20;


INSERT INTO core.facts_events (
    order_id,
    order_item_id,
    price,
    freight_value,
    lead_time_days,
    on_time_flag,
    calendar_sk,
    customer_sk,
    product_sk,
    -- seller_sk
    -- external_sk
)

-- Computing derived fields
SELECT 
    j.order_id,
    j.order_item_id,
    j.price,
    j.freight_value,

    -- lead time in days (approved -> delivered)
    CASE
        WHEN j.order_delivered_customer_date IS NOT NULL
        AND j.order_approved_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (j.order_delivered_customer_date - j.order_approved_at)) / 86400.0
        ELSE NULL 
    END AS lead_time_days,

    -- on-time: 1 if delivered <= estimated; 0 if delivered > estimated; NULL if there's no estimated or delivered
    CASE
        WHEN j.order_delivered_customer_date IS NULL OR j.order_estimated_delivery_date IS NULL THEN NULL
        WHEN j.order_delivered_customer_date <= j.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS on_time_flag,

    j.calendar_sk,
    j.customer_sk,
    j.product_sk
;