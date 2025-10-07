# Layers and conventions

## Schemas

`staging` (Raw data landing) -> `core` (Cleaned and modeled data) -> `analytics`

## Conventions

- `snake_case`
- Dates in UTC
- Numbers with two decimal points

## Traceability

- Operative columns:
    `_ingested_at`, `_source_file`, `_row_md5`.

# Staging Tables

A staging table per Olist's original tables:

staging.orders_raw (orders)

staging.order_items_raw (order_items)

staging.customers_raw (customers)

staging.products_raw (products)

staging.reviews_raw (order_reviews)

(opcional) staging.sellers_raw (sellers)

staging.external_raw (Weather/Holidays: One row per (date, city))

Every table should have the following operative columns: _ingested_at TIMESTAMP, _source_file TEXT, _row_md5 TEXT.

Recommended load order: customers → orders → order_items → products → sellers → reviews → external.

## Idempotence During Staging

- Load data as **append-only** (Every data load adds new rows to `staging.`)

- Deduplication (dedup) by natural key and `_row_md5` (Hash of all, or the main, columns of the row.)

- Saving a manifest (file name + expected rows + checksum)

# Transformations When Loading to core.

## General Rules

- Type Cast: Dates to `DATE` datatype.
- Normalization: 
    * Strings: `TRIM/LOWER` (e.g.,“são paulo” or “São Paulo” -> “sao paulo”)
- Missing values (Null) and Ranges: (TODO)
- Valid Dates: dd/mm/yyyy format.
- Valid Order Status: Only `approved` order state.
- Valid City: Only `sao paulo` city.

## Dimensions

### core.dim_calendar

- Source: Dates from the "order_delivered_customer_date" column from the orders_raw table.

- Key: calendar_sk (surrogate).

- Attributes: date, day_of_week, week, month, quarter, year, is_holiday.

### core.dim_customer

- Source: customers_raw.

- Key: customer_sk. Natural attribute: customer_id.

- Attributes: clean city/state (city = sao paulo, state = SP).

### core.dim_product

- Source: products_raw.

- Key: product_sk. Natural attribute: product_id.

- Attributes: product_category_name (We'll consider a mapping table to translate portuguese categories).

### core.dim_seller (opcional)

- Source: sellers_raw.

- Key: seller_sk. Natural attribute: seller_id.

### core.dim_external (opcional)

- Source: external_raw.

- Natural (Conceptual) attribute: (date, city).

- Key: external_sk.

- Rules: Unique values differentiated by combinations of (date, city); Units (°C, mm).

## Facts

### core.fact_events

- Grain: 1 row = (order_id, order_item_id)

- Key: event_id (PK surrogate), order_id, order_item_id (degenerate), calendar_sk, customer_sk, product_sk, seller_sk, external_sk.

- Metrics: price, freight_value.

- Derivatives:

    * lead_time_days = `order_delivered_customer_date − `order_approved_at` (In days, >= 0).

    * on_time_flag = 1 if `order_delivered_customer_date` ≤ `order_estimated_delivery_date`, 0 if not, NULL if there's not estimated delivery date.

- Lookup keys

    * calendar_sk: From `order_delivered_customer_date` (reference date to define the quarter).

    * external_sk: Using normalized (delivered_date + customer_city).

# Automatic checks (Always after every load)

## Count and Duplicates

- Staging vs core: Expected rows ≈ Loaded rows (± tolerance)

- Unique Values fact: UNIQUE (order_id, order_item_id) (violation = ABORT).

- Unique Values dims: (customer_id, product_id, (date,city) in external) without duplicates (violation = ABORT).

## Dates and Temporal Logic

- `order_delivered_customer_date` >= `order_approved_at` (violations > 0 = ABORT/QUARANTINE).

- `order_estimated_delivery_date` Must be present for the calculation of on-time KPI (If is not existent, on_time_flag = NULL and exclude from calculation).

## Ranges / Types

- price >= 0, freight_value >= 0, lead_time_days >= 0 (violations = ABORT if > 0.1%).

- Not null dates in critical attributes (order_estimated_delivery_date to assigned quarter; If null → Exclude or Quarantine).

## Referential Integrity

- Every *_sk in fact table exist in its dim table (If Null = ABORT).

## Geography and Normalization

- % of rows with normalized city name = 100% (If < 100% → WARN/QUARANTINE According to threshold).

## Severity
- ABORT: Breaks KPI (Unique values, FK, Temporal Logic).

- WARN: Not critical, but it gets recorded (Null values in non critical attributes, small difference in counts).

- QUARANTINE: Moves problematic rows to staging._quarantine.

# Fail Rules

- Duplicados en la llave natural del grano → ABORT.

- FK faltantes (lookup a dims) → ABORT.

- Fechas invertidas (delivered < approved) → QUARANTINE si ≤ X filas, ABORT si > X.

- % nulos en fechas clave > umbral (define, ej. >0.5%) → ABORT.

- Rangos negativos en price/freight → ABORT.