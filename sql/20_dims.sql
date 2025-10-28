-- dim_calendar table
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

-- dim_customer table
CREATE TABLE IF NOT EXISTS core.dim_customer(
    customer_sk SERIAL PRIMARY KEY,
    customer_id TEXT UNIQUE NOT NULL,
    customer_city TEXT,
    customer_state TEXT
);

-- Normalization and populating of dim_customer table
INSERT INTO core.dim_customer (customer_id, customer_city, customer_state)
SELECT DISTINCT
    c.customer_id,
    TRIM(LOWER(c.customer_city)) AS customer_city,
    TRIM(UPPER(c.customer_state)) AS customer_state
FROM staging.customers_raw c
ON CONFLICT (customer_id) DO NOTHING;

-- core.dim_product table
CREATE TABLE IF NOT EXISTS core.dim_product(
    product_sk SERIAL PRIMARY KEY,
    product_id TEXT UNIQUE NOT NULL,
    product_category_name TEXT
);

-- populate core.dim_product table
INSERT INTO core.dim_product (product_id, product_category_name)
SELECT DISTINCT
    p.product_id,
    TRIM(LOWER(p.product_category_name_english)) AS product_category_name
FROM staging.products_raw p
ON CONFLICT (product_id) DO NOTHING;

-- Sanity checks
SELECT COUNT(*) FROM core.dim_calendar;
SELECT COUNT(*) FROM core.dim_customer;
SELECT COUNT(*) FROM core.dim_product;
SELECT * FROM core.dim_customer LIMIT 5;
SELECT * FROM core.dim_product LIMIT 5;
