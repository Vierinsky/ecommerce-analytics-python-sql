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
