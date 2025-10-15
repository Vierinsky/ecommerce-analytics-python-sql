-- Orders (raw mirror)
CREATE TABLE IF NOT EXISTS staging.orders_raw(
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_approved_at TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    _ingested_at TIMESTAMP,
    _source_file TEXT,
    _row_md5 TEXT
);

-- Order items (raw mirror)
CREATE TABLE IF NOT EXISTS staging.order_items_raw(
    order_id TEXT,
    order_item_id INT,
    product_id TEXT,
    seller_id TEXT,
    price NUMERIC,
    freight_value NUMERIC,
    _ingested_at TIMESTAMP, 
    _source_file TEXT, 
    _row_md5 TEXT
);

-- Customers (raw mirror)
CREATE TABLE IF NOT EXISTS staging.customers_raw(
    customer_id TEXT,
    customer_city TEXT,
    customer_state TEXT,
    _ingested_at TIMESTAMP, 
    _source_file TEXT, 
    _row_md5 TEXT
);


-- Checking if tables were created
SELECT 'orders' AS tbl, COUNT(*) FROM staging.orders_raw
UNION ALL
SELECT 'order_items', COUNT(*) FROM staging.order_items_raw
UNION ALL
SELECT 'customers', COUNT(*) FROM staging.customers_raw;