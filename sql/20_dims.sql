CREATE TABLE IF NOT EXISTS core.dim_calendar (
    calendar_sk SERIAL PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    day_of_week SMALLINT,
    week SMALLINT,
    month SMALLINT,
    quarter SMALLINT,
    year SMALLINT
);

-- Populate from the delivered_date range in staging.orders_raw
WITH bounds AS(
    SELECT
        DATE(MIN(order_delivered_customer_date)) AS dmin,
        DATE(MAX(order_delivered_customer_date)) AS dmax
    FROM staging.orders_raw
),
series AS (
    SELECT generate_series(dmin, dmax, interval '1day')::date AS date
    FROM bounds
)
INSERT INTO core.dim_calendar (date, day_of_week, week, month, quarter, year)
SELECT
    date,
    EXTRACT(DOW FROM date)::int,
    EXTRACT(WEEK FROM date)::int,
    EXTRACT(MONTH FROM date)::int,
    EXTRACT(QUARTER FROM date)::int,
    EXTRACT(YEAR FROM date)::int
FROM series
ON CONFLICT (date) DO NOTHING;