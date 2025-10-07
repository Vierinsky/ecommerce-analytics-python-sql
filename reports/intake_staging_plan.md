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
- Missing values (Null) and Ranges:
- Valid Dates:
- Valid Order Status: Only `approved` order state.
- Valid City: Only `sao paulo` city.

