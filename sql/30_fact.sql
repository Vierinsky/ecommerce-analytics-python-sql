-- Creating core.facts_events table
CREATE TABLE IF NOT EXISTS core.facts_events(
    event_id BIGSERIAL PRIMARY KEY,
    order_id TEXT,
    order_item_id INT,
    price NUMERIC,
    freight_value NUMERIC,
    lead_time_days SMALLINT,
    on_time_flag INT,
    calendar_sk INT,
    customer_sk INT,
    product_sk INT,
    seller_sk INT,
    external_sk INT,

    CONSTRAINT 
);

-- 
INSERT INTO core.facts_events ();