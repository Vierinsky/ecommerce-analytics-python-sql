# Data dictionary

## File Name: facts_event.csv

| Column | Type | Description | Example | Missing Values | Notes |
|---|---|---|---|---|---|
| event_id | integer | Unique event identifier | 1 | No | Primary key |
| order_id | string | Unique order identifier | b81ef226f3fe1789b1e8b2acac839d17 | No | Data source origin value |
| order_item_id | string | Unique item within an order identifier | 1 | No | - |
| price | float | Order's net price | 58.9 | No | Does not include freight |
| freight_value | float | Freight's cost | 19.93 | No | - |
| lead_time_days | integer | Delivered date - Approved date in days | 12 | No | - |
| on_time_flag | integer | 1 if delivered_date <= estimated_date, if not, then 0 | 0 | No | - |
| calendar_sk | integer | Unique calendar table row identifier | 3 | No | Foreign Key |
| customer_sk | integer | Unique customer table row identifier | 4 | No | Foreign Key |
| product_sk | integer | Unique product table row identifier | 1 | No | Foreign Key |
| seller_sk | integer | Unique seller table row identifier | 2 | No | Foreign Key |
| external_sk | integer | Unique external table row identifier | 10 | No | Foreign Key |

## File Name: dim_calendar.csv

| Column | Type | Description | Example | Missing Values | Notes |
|---|---|---|---|---|---|
| calendar_sk | integer | Row surrogate key | 3 | No | Primary key |
| date | date | Order delivered to customer date | 02/04/2017 | No | dd/mm/yyyy |
| day_of_week | string | Day of the week's name | Monday | No | - |
| week | integer | Number of the week | 52 | No | - |
| month | integer | Number of the month | 9 | No | - |
| quarter | integer | Number of the quarter | 3 | No | min: 1 max: 4 |
| year | integer | Date's year | 2018 | No | - |
| is_holiday | string | If the order's date was holiday | Yes | No | - |

## File Name: dim_customer.csv

| Column | Type | Description | Example | Missing Values | Notes |
|---|---|---|---|---|---|
| customer_sk | integer | Row surrogate key | 17 | No | Primary key |
| customer_id | string | Unique customer identifier | 06b8999e2fba1a1fbc88172c00ba8bc7 | No | Data source origin value |
| customer_city | string | customer's city | sao paulo | No | It should always be "sao paulo" |
| customer_state | string | customer's state | SP | No | It should always be "SP" |

## File Name: dim_product.csv

| Column | Type | Description | Example | Missing Values | Notes |
|---|---|---|---|---|---|
| product_sk | integer | Row surrogate key | 22 | No | Primary key |
| product_id | string | Unique product identifier | 4244733e06e7ecb4970a6e2683c13e61 | No | Data source origin value |
| product_category_name | string | Product's category name | perfumaria | No | Data source origin value |

## File Name: dim_seller.csv

| Column | Type | Description | Example | Missing Values | Notes |
|---|---|---|---|---|---|
| seller_sk | integer | Row surrogate key | 32 | No | Primary key |
| seller_id | string | Unique seller identifier | 48436dade18ac8b2bce089ec2a041202 | No | Data source origin value |
| seller_city | string | Seller's city | campinas | No | - |
| seller_state | string | Seller's state | RJ | No | - |

## File Name: dim_external.csv

| Column | Type | Description | Example | Missing Values | Notes |
|---|---|---|---|---|---|
| external_sk | integer | Row surrogate key | 28 | No | Primary key |
| date | date | Measurement's date | 02/04/2017 | No | dd/mm/yyyy |
| city | string | Measurement's city | sao paulo | No | It should always be "sao paulo"  |
| temp | string | day's mean temperature in Celsius | 28.5 | No | - |
| rain | string | If it rained | Yes | No | - |
| is_holiday | string | If the measurement date was holiday | Yes | No | - |

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

# API and External Data (Template; Needs to be completed)

## A) Overview

Purpose: enrich fact events with external context to support KPIs (on-time rate, seasonality, etc.).

Join logic (conceptual): (date + city) from your reference date (delivered_date) and normalized customer city.

Physical model: store only external_sk in core.fact_events; all attributes live in core.dim_external.

## B) Holidays (CSV / flat file)

Provider: <PROVIDER_NAME>
Acquisition method: manual download or scripted fetch (HTTPS).
File URL / ID: <HOLIDAYS_DATA_URL_OR_ID>
Update cadence: yearly (or whenever calendar changes).
Timezone: <TZ_NAME> (must match your dim_calendar assumptions)
Geographic scope: Brazil, filtered to São Paulo city ("sao paulo") or SP state ("SP") — pick one to be consistent with KPIs.

### B1) Raw schema (as received) (REPLACE IF NEEDED)

| Column (raw)   | Type                | Description                        |
| -------------- | ------------------- | ---------------------------------- |
| `date`         | string (YYYY-MM-DD) | Holiday date                       |
| `holiday_name` | string              | Name                               |
| `city`         | string              | City (may be blank if national)    |
| `state`        | string              | State code (e.g., SP)              |
| `scope`        | string              | `national` / `state` / `municipal` |

### B2) Normalization rules

Parse date to date.

City normalization: trim, lowercase, remove accents → sao paulo.

is_holiday: 1 if holiday applies to national or to your selected area (city or state), else 0.

### B3) Load → core.dim_external (S→T)

| Target (table.column)      | Source (raw)                   | Transformation                                  |
| -------------------------- | ------------------------------ | ----------------------------------------------- |
| `dim_external.external_sk` | —                              | Surrogate key (auto)                            |
| `dim_external.date`        | `date`                         | Parse to `date`                                 |
| `dim_external.city`        | `city` or fallback from config | Normalize to match `dim_customer.customer_city` |
| `dim_external.is_holiday`  | `scope`,`state`,`city`         | Map to 1/0 given your SP scope                  |
| `dim_external.temp`        | —                              | NULL (not provided)                             |
| `dim_external.rain`        | —                              | NULL (not provided)                             |

### B4) DQ & acceptance

(date, city) must be unique in dim_external.

date not null.

If city holidays are absent for your target city, generate rows with is_holiday = 0 for all dates in your range so joins don’t fail (gap filling).

Missing city in source → default to your project scope (e.g., "sao paulo"), but keep is_holiday=0 unless rule triggers.

### B5) Operational notes

Versioning: save raw file under /data/external/holidays/<YYYY>/holidays_raw.csv.

Lineage: record provider, file_sha256, ingested_at.

Failure policy: if the file is missing, proceed with is_holiday=0 for all dates (log a warning).

## C) Weather (API / JSON)

Provider: <WEATHER_PROVIDER_NAME>
Base URL: <API_BASE_URL> (e.g., https://api.<provider>.com/v1/historical)
Auth: header Authorization: Bearer <API_KEY> or ?apikey=<API_KEY>
Rate limits: <N>/min (throttle via backoff)
Billing: <PLAN_NAME> (track monthly credits)

### C1) Request spec (daily aggregates)

Endpoint: <API_BASE_URL>/daily

Params:

city: "sao paulo" (normalized to match dim_customer)

country or state: "BR" / "SP" (if required)

start_date: <MIN_DELIVERED_DATE>

end_date: <MAX_DELIVERED_DATE>

units: metric

Windowing: request in chunks (e.g., 31 days per call) to respect rate limits.

### C2) Response schema 

| Field (raw)  | Type                | Example      | Notes                         |
| ------------ | ------------------- | ------------ | ----------------------------- |
| `date`       | string (YYYY-MM-DD) | `2017-01-02` | Daily reference               |
| `city`       | string              | `São Paulo`  | Normalize to `sao paulo`      |
| `temp_avg`   | float (°C)          | `24.3`       | Daily mean                    |
| `precip_mm`  | float (mm)          | `0.0`        | Daily precipitation           |
| `is_holiday` | bool/int            | `0/1`        | Optional (if provider offers) |

### C3) Normalization rules

Parse date → date.

Normalize city → sao paulo to match dim_customer.customer_city.

Ensure units: °C, mm.

If fields are missing, set to NULL.

### C4) Load → core.dim_external (S→T)

| Target (table.column)      | Source (API field) | Transformation                    |
| -------------------------- | ------------------ | --------------------------------- |
| `dim_external.external_sk` | —                  | Surrogate key (auto)              |
| `dim_external.date`        | `date`             | Parse to date                     |
| `dim_external.city`        | `city`             | Normalize (trim, lower, deaccent) |
| `dim_external.temp`        | `temp_avg`         | Round to 1 decimal (optional)     |
| `dim_external.rain`        | `precip_mm`        | Keep mm; NULL if missing          |
| `dim_external.is_holiday`  | `<if provided>`    | Map true/false → 1/0; else NULL   |

### C5) DQ & acceptance

(date, city) unique.

date not null.

temp in range [-10, 55] (Brazil plausible), rain ≥ 0.

Any record outside range → set NULL and add to anomaly log.

### C6) Operational notes

Storage: persist raw JSON per day in /data/external/weather/YYYY/MM/DD.json (or parquet).

Retries: exponential backoff, 3 attempts per day chunk.

Reproducibility: freeze responses (no re-fetch unless --refresh flag is set).

Failure policy: if API down, skip refresh and keep last good snapshot; set external_sk = NULL for missing days (downstream analyses should tolerate it).