# Data dictionary

## Table: core.fact_events

| Column           | Type            | Description                                                     | Example                            | Missing | Notes                                                   |
| ---------------- | --------------- | --------------------------------------------------------------- | ---------------------------------- | ------- | ------------------------------------------------------- |
| `event_id`       | `BIGSERIAL`     | Surrogate primary key of the row in the fact.                   | `1`                                | No      | **PK**, unique                                          |
| `order_id`       | `TEXT`          | Source order identifier (Olist).                                | `00010242fe8c5a6d1ba2dd792cb16214` | No      | ~32-char hex                                            |
| `order_item_id`  | `INT`           | Item index within the order.                                    | `1`                                | No      | With `order_id` defines the line                        |
| `price`          | `NUMERIC(12,2)` | Item price (GMV **without** freight).                           | `58.90`                            | No      | Used for Revenue                                        |
| `freight_value`  | `NUMERIC(12,2)` | Freight cost allocated to the item.                             | `13.29`                            | Yes     | Not used in Revenue                                     |
| `lead_time_days` | `NUMERIC(10,4)` | Days from payment approval to delivery: `delivered - approved`. | `7.5821`                           | Yes     | Can be fractional; negatives should be flagged/filtered |
| `on_time_flag`   | `SMALLINT`      | `1` if `delivered_date <= estimated_date`, else `0`.            | `1`                                | Yes     | Binary {0,1}, derived                                   |
| `calendar_sk`    | `INT`           | FK to `core.dim_calendar`.                                      | `345`                              | No      | **FK**                                                  |
| `customer_sk`    | `INT`           | FK to `core.dim_customer`.                                      | `24256`                            | No      | **FK**                                                  |
| `product_sk`     | `INT`           | FK to `core.dim_product`.                                       | `13096`                            | No      | **FK**                                                  |
| `seller_sk`      | `INT`           | FK to `core.dim_seller` (optional).                             | `NULL` / `123`                     | Yes     | **FK** optional (until seller dim is populated)         |
| `external_sk`    | `INT`           | FK to `core.dim_external` (optional: weather/holidays).         | `NULL` / `10`                      | Yes     | **FK** optional                                         |

### Suggested indexes & constraints

- UNIQUE (order_id, order_item_id)

- INDEX (calendar_sk), INDEX (customer_sk), INDEX (product_sk), INDEX (seller_sk)

- Checks: price >= 0, freight_value >= 0, lead_time_days IS NULL OR lead_time_days >= 0, on_time_flag IN (0,1)

## Table: core.dim_calendar

| Column        | Type       | Description                                 | Example      | Missing | Notes                         |
| ------------- | ---------- | ------------------------------------------- | ------------ | ------- | ----------------------------- |
| `calendar_sk` | `SERIAL`   | Surrogate primary key.                      | `345`        | No      | **PK**                        |
| `date`        | `DATE`     | **Delivered** date (daily grain).           | `2017-04-02` | No      | ISO `YYYY-MM-DD`              |
| `day_of_week` | `SMALLINT` | Day of week (your convention: 1–7 or 0–6).  | `1`          | No      | Document convention in README |
| `week`        | `SMALLINT` | ISO week of year.                           | `13`         | No      | 1–53                          |
| `month`       | `SMALLINT` | Month of year.                              | `4`          | No      | 1–12                          |
| `quarter`     | `SMALLINT` | Calendar quarter.                           | `2`          | No      | 1–4                           |
| `year`        | `INT`      | Calendar year.                              | `2018`       | No      | —                             |
| `is_holiday`  | `BOOLEAN`  | Whether the date is a holiday (if modeled). | `FALSE`      | Yes     | Optional mapping              |

Indexes: UNIQUE (date), INDEX (year, quarter)

## Table: core.dim_customer

| Column           | Type     | Description                            | Example                            | Missing | Notes              |
| ---------------- | -------- | -------------------------------------- | ---------------------------------- | ------- | ------------------ |
| `customer_sk`    | `SERIAL` | Surrogate primary key.                 | `24256`                            | No      | **PK**             |
| `customer_id`    | `TEXT`   | Source customer identifier (Olist).    | `06b8999e2fba1a1fbc88172c00ba8bc7` | No      | Unique             |
| `customer_city`  | `TEXT`   | Normalized customer city (lowercased). | `sao paulo`                        | No      | Used for SP filter |
| `customer_state` | `TEXT`   | State (UF, 2 letters).                 | `SP`                               | No      | —                  |

Indexes: UNIQUE (customer_id), INDEX (customer_city, customer_state)

## Table: core.dim_product

| Column                  | Type     | Description                                | Example                            | Missing | Notes                                 |
| ----------------------- | -------- | ------------------------------------------ | ---------------------------------- | ------- | ------------------------------------- |
| `product_sk`            | `SERIAL` | Surrogate primary key.                     | `13096`                            | No      | **PK**                                |
| `product_id`            | `TEXT`   | Source product identifier (Olist).         | `4244733e06e7ecb4970a6e2683c13e61` | No      | Unique                                |
| `product_category_name` | `TEXT`   | Product category name (Olist, normalized). | `perfumaria`                       | Yes     | `LOWER(TRIM())`; may be NULL in Olist |

Indexes: UNIQUE (product_id), INDEX (product_category_name)

## (Optional) Table: core.dim_seller

| Column         | Type     | Description                       | Example                            | Missing | Notes  |
| -------------- | -------- | --------------------------------- | ---------------------------------- | ------- | ------ |
| `seller_sk`    | `SERIAL` | Surrogate primary key.            | `123`                              | No      | **PK** |
| `seller_id`    | `TEXT`   | Source seller identifier (Olist). | `48436dade18ac8b2bce089ec2a041202` | No      | Unique |
| `seller_city`  | `TEXT`   | Seller city (normalized).         | `campinas`                         | Yes     | —      |
| `seller_state` | `TEXT`   | Seller state (UF).                | `RJ`                               | Yes     | —      |

Indexes: UNIQUE (seller_id), INDEX (seller_city, seller_state)

## (Optional) Table: core.dim_external (weather/holidays)

| Column        | Type           | Description                    | Example      | Missing | Notes              |
| ------------- | -------------- | ------------------------------ | ------------ | ------- | ------------------ |
| `external_sk` | `SERIAL`       | Surrogate primary key.         | `10`         | No      | **PK**             |
| `date`        | `DATE`         | Measurement date.              | `2017-04-02` | No      | Join key with city |
| `city`        | `TEXT`         | Measurement city (normalized). | `sao paulo`  | No      | Lowercased         |
| `temp`        | `NUMERIC(6,2)` | Daily mean temperature (°C).   | `28.50`      | Yes     | —                  |
| `rain`        | `BOOLEAN`      | Whether it rained.             | `TRUE`       | Yes     | —                  |
| `is_holiday`  | `BOOLEAN`      | Whether the date is a holiday. | `FALSE`      | Yes     | —                  |

Index: UNIQUE (date, city)

## Main analytic views (read-only)

| View                                        | Grain / Scope                      | Key fields                                             | Notes                          |
| ------------------------------------------- | ---------------------------------- | ------------------------------------------------------ | ------------------------------ |
| `analytics.vw_revenue_quarter_sp`           | Quarter · São Paulo                | `year`, `quarter`, `revenue_sp`                        | `SUM(price)` (no freight)      |
| `analytics.vw_reviews_share_quarter_sp`     | Quarter · São Paulo                | `year`, `quarter`, `share_ge4`                         | `AVG(review_score >= 4)`       |
| `analytics.vw_leadtime_p90_quarter_sp`      | Quarter · São Paulo                | `year`, `quarter`, `lead_time_p90`                     | `PERCENTILE_CONT(0.9)`         |
| `analytics.vw_on_time_rate_quarter_sp`      | Quarter · São Paulo                | `year`, `quarter`, `on_time_rate`                      | `AVG(on_time_flag)`            |
| `analytics.vw_kpi_quarter_sp`               | Quarter · São Paulo (consolidated) | `year`, `quarter`, KPI fields                          | FULL OUTER JOIN of KPI views   |
| `analytics.vw_promise_vs_ontime_quarter_sp` | Quarter · São Paulo                | `p50_promise_days`, `p90_promise_days`, `on_time_rate` | ETA vs On-time                 |
| `analytics.vw_late_orders_cat_quarter_sp`   | Quarter · São Paulo · category     | `n_orders`, `late_rate`, `late_orders`                 | Base for contribution analysis |
| `analytics.vw_delta_late_orders_cat_sp`     | Quarter · São Paulo · category     | `delta_late_orders`, previous/current rates & volumes  | Q vs Q-1 driver ranking        |

## Normalization & data quality conventions

- Text normalization: LOWER(TRIM()) for city/category names.

- Dates: ISO YYYY-MM-DD.

- Booleans: use BOOLEAN in dimensions; in fact use {0,1} for on_time_flag.

- NULL policy: avoid NULLs in surrogate keys (*_sk); allow NULLs in derived metrics if inputs are missing (e.g., lead_time_days).

- QA rules:

    - Reject or flag rows where order_delivered_customer_date < order_approved_at.

    - Keep price >= 0, freight_value >= 0.

    - Ensure uniqueness of (order_id, order_item_id) in the fact.
