-- Creating core.facts_events table
CREATE TABLE IF NOT EXISTS core.facts_events(
    event_id BIGSERIAL PRIMARY KEY,
    order_id TEXT,
    order_item_id INT,
    price NUMERIC,
    freight_value NUMERIC(12,2),
    lead_time_days SMALLINT,
    on_time_flag INT,
    calendar_sk INT,
    customer_sk INT,
    product_sk INT,
    seller_sk INT,
    external_sk INT,

    CONSTRAINT uq_fact_order_item UNIQUE (order_id, order_item_id),
    CONSTRAINT fk_fact_calendar FOREIGN KEY (calendar_sk) REFERENCES core.dim_calendar (calendar_sk),
    CONSTRAINT fk_fact_customer FOREIGN KEY (customer_sk) REFERENCES core.dim_customer (customer_sk),
    CONSTRAINT fk_fact_product FOREIGN KEY (product_sk) REFERENCES core.dim_product (product_sk)
    -- CONSTRAINT fk_fact_seller FOREIGN KEY (seller_sk) REFERENCES core.dim_seller (seller_sk)
    -- CONSTRAINT  FOREIGN KEY (external_sk) REFERENCES  ()
);
