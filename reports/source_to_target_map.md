# Source-to-Target map

### 1) core.fact_events (grain: one row per order item → (order_id, order_item_id))

| Target (table.column)                       | Source (file.column)                                                           | Transformation (concept)                                                                                    | Joins used in the ETL                            | Data quality rules                                | Notes                                 |
| ------------------------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------- | ------------------------------------- |
| `core.fact_events.event_id`                 | — (generated)                                                                  | Surrogate PK (auto‐increment)                                                                               | —                                                | Unique, not null                                  | Internal ID                           |
| `core.fact_events.order_id`                 | `orders.order_id`                                                              | Direct copy (degenerate)                                                                                    | `orders` ⟂ `order_items` on `order_id`           | Not null                                          | For traceability                      |
| `core.fact_events.order_item_id`            | `order_items.order_item_id`                                                    | Direct copy (degenerate)                                                                                    | `orders` ⟂ `order_items` on `order_id`           | Not null; unique with `order_id`                  | Defines the line within the order     |
| `core.fact_events.calendar_sk`              | `dim_calendar.calendar_sk`                                                     | **Lookup by reference date** → use `orders.order_delivered_customer_date`                                   | —                                                | Not null                                          | Delivered date defines quarter        |
| `core.fact_events.customer_sk`              | `dim_customer.customer_sk`                                                     | Lookup by `customers.customer_id`                                                                           | `orders.customer_id` → `customers.customer_id`   | Not null; FK must exist                           | SP filter lives in the dim            |
| `core.fact_events.product_sk`               | `dim_product.product_sk`                                                       | Lookup by `products.product_id`                                                                             | `order_items.product_id` → `products.product_id` | Not null; FK must exist                           | Enables category KPI                  |
| `core.fact_events.seller_sk` *(optional)*   | `dim_seller.seller_sk`                                                         | Lookup by `sellers.seller_id`                                                                               | `order_items.seller_id` → `sellers.seller_id`    | FK may be null if you drop seller dim             | Use if you’ll analyze sellers         |
| `core.fact_events.external_sk` *(optional)* | `dim_external.external_sk`                                                     | Lookup by **(date, city)** = (`orders.order_delivered_customer_date`, normalized `customers.customer_city`) | `orders` + `customers`                           | May be null                                       | Only if you load climate/holidays     |
| `core.fact_events.price`                    | `order_items.price`                                                            | Cast to numeric (BRL)                                                                                       | `orders` ⟂ `order_items` on `order_id`           | `>= 0`, not null                                  | Your revenue excludes freight         |
| `core.fact_events.freight_value`            | `order_items.freight_value`                                                    | Cast to numeric                                                                                             | Same as above                                    | `>= 0`                                            | Logistics analysis only               |
| `core.fact_events.lead_time_days`           | `orders.order_delivered_customer_date`, `orders.order_approved_at`             | Date diff in **days**: `delivered − approved`                                                               | —                                                | `>= 0`; both dates not null; delivered ≥ approved | For P50/P90 per quarter               |
| `core.fact_events.on_time_flag`             | `orders.order_delivered_customer_date`, `orders.order_estimated_delivery_date` | `1` if `delivered ≤ estimated`; `0` if `delivered > estimated`; **NULL** if `estimated` is null             | —                                                | —                                                 | Exclude NULL from on-time denominator |

**Olist file columns used here include:** order_id, order_item_id, product_id, seller_id, price, freight_value, order_approved_at, order_delivered_customer_date, order_estimated_delivery_date, customer_id, customer_city.

### 2) core.dim_calendar

| Target                                 | Source               | Transformation                                            | Joins         | Rules            | Notes                          |
| -------------------------------------- | -------------------- | --------------------------------------------------------- | ------------- | ---------------- | ------------------------------ |
| `dim_calendar.calendar_sk`             | — (generated)        | Surrogate PK                                              | —             | Unique, not null |                                |
| `dim_calendar.date`                    | — (generated series) | Daily date sequence from min(delivered) to max(delivered) | —             | Unique           | Keep one timezone consistently |
| `dim_calendar.day_of_week`             | `date`               | Derive name or index                                      | —             | —                |                                |
| `dim_calendar.week`                    | `date`               | ISO week number                                           | —             | —                |                                |
| `dim_calendar.month`                   | `date`               | Month number (1–12)                                       | —             | —                |                                |
| `dim_calendar.quarter`                 | `date`               | Quarter number (1–4)                                      | —             | —                | Used in YoY by quarter         |
| `dim_calendar.year`                    | `date`               | Year                                                      | —             | —                |                                |
| `dim_calendar.is_holiday` *(optional)* | external/holidays    | Map to 0/1                                                | Join via date | —                | If you load holidays           |


### 3) core.dim_customer

| Target                        | Source                     | Transformation                                     | Joins | Rules                      | Notes                           |
| ----------------------------- | -------------------------- | -------------------------------------------------- | ----- | -------------------------- | ------------------------------- |
| `dim_customer.customer_sk`    | — (generated)              | Surrogate PK                                       | —     | Unique, not null           |                                 |
| `dim_customer.customer_id`    | `customers.customer_id`    | Direct copy (natural ID)                           | —     | Unique (natural), not null | Traceability                    |
| `dim_customer.customer_city`  | `customers.customer_city`  | Normalize (trim, lower/title-case; remove accents) | —     | Not null                   | Your SP filter uses this        |
| `dim_customer.customer_state` | `customers.customer_state` | Normalize to `UPPER()`                             | —     | Can be null                | If you later switch to SP state |


### 4) core.dim_product

| Target                              | Source                           | Transformation                  | Joins | Rules                      | Notes                   |
| ----------------------------------- | -------------------------------- | ------------------------------- | ----- | -------------------------- | ----------------------- |
| `dim_product.product_sk`            | — (generated)                    | Surrogate PK                    | —     | Unique, not null           |                         |
| `dim_product.product_id`            | `products.product_id`            | Direct copy                     | —     | Unique (natural), not null |                         |
| `dim_product.product_category_name` | `products.product_category_name` | Normalize strings; map unknowns | —     | Can be null                | Drives Top-Category KPI |


### 5) core.dim_seller

| Target                    | Source                 | Transformation         | Joins | Rules                      | Notes |
| ------------------------- | ---------------------- | ---------------------- | ----- | -------------------------- | ----- |
| `dim_seller.seller_sk`    | — (generated)          | Surrogate PK           | —     | Unique, not null           |       |
| `dim_seller.seller_id`    | `sellers.seller_id`    | Direct copy            | —     | Unique (natural), not null |       |
| `dim_seller.seller_city`  | `sellers.seller_city`  | Normalize              | —     | Not null                   |       |
| `dim_seller.seller_state` | `sellers.seller_state` | Normalize to `UPPER()` | —     | Can be null                |       |

**Olist sellers** has seller_id, seller_city, seller_state.


### 6) core.dim_external

| Target                     | Source                       | Transformation                                    | Natural key    | Rules            | Notes          |
| -------------------------- | ---------------------------- | ------------------------------------------------- | -------------- | ---------------- | -------------- |
| `dim_external.external_sk` | — (generated)                | Surrogate PK                                      | —              | Unique, not null |                |
| `dim_external.date`        | external.date                | Parse to `date`                                   | `(date, city)` | Not null         |                |
| `dim_external.city`        | external.city                | Normalize exactly as `dim_customer.customer_city` | `(date, city)` | Not null         | Join stability |
| `dim_external.temp`        | external.temp\_avg           | Cast/round (°C)                                   | —              | Can be null      |                |
| `dim_external.rain`        | external.rain\_mm or boolean | Cast; mm or 0/1                                   | —              | Can be null      |                |
| `dim_external.is_holiday`  | external.is\_holiday         | Map to 0/1                                        | —              | Can be null      |                |

### 7) Review linkage (Needed for KPI #2)

We’ll compute the ≥4★ share by joining `orders` ↔ `order_reviews` at the order level, then aggregating per quarter/SP. We won't be storing review columns in the fact table.
