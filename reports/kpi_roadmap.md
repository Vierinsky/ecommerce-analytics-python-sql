# 1) Revenue (price without freight) — Relative YoY

- Source: core.fact_events (price) + core.dim_calendar + core.dim_customer

- Scope: sao paulo city (customer_city normalized)

- Level: Quarter

- Base metric: Revenue_Q = SUM(price) of rows delivered during the quarter.

- KPI calculation: (Revenue_Qt−Revenue_Qt−4)/Revenue_Qt−4

- Output: quarter, revenue_present, revenue_base, yoy_%

- Caveats: exclude freight; check out outliers of price=0

## Pivot Table (to check in Python):

- Rows: Quarter

- Columns: (opcional) canal / categoría

- Values: SUM(price), YoY%

# 2) Share de reviews ≥4★ — Change in Percentage Points (pp)

- Source: core.fact_events (for scope = sao paulo and delivered) + staging.reviews_raw + calendar

- Scope: sao paulo

- Level: Quarter

- Base metric:

    * Numerator = COUNT(reviews ≥4★)

    * Denominator = COUNT(total reviews) 

    * share_Q = Numerator / Denominator × 100

- KPI calculation: pp = share_{Q_t} − share_{Q_{t−4}}

- Output: quarter, share_present_%, share_base_%, delta_pp

- Caveats: lag between delivery and review; we'll define a window (TODO)

## Pivot Table (to check in Python):

- Rows: Quarter

- Columns: (optional) Product category

- Values: % reviews ≥4★, Δ pp YoY

# 3) Lead time (delivered − approved) — P90 y Variation

- Source: core.fact_events (lead_time_days) + calendar + customer

- Scope: sao paulo

- Level: Quarter

- Base metric: P90(lead_time_days) per quarter

- KPI calculation: P90_Qt​−P90_Qt−4

- Output: quarter, p90_actual_days, p90_base_days, delta (In days)

- Caveats: Exclude rows with invalid dates; Optional: Check P99 to check outliers. 

## Pivot Table (to check in Python):

- Rows: Quarter

- Columns: (optional) Product category

- Values: P50, P90 (Show both for context)

# 4) On-time rate (delivered ≤ estimated) — pp

- Source: core.fact_events (on_time_flag), calendar, customer

- Scope: sao paulo

- Level: Quarter

- Base metric: 
    - Denominator: row with estimated delivery date not null.

    - on_time_rate_Q = AVG(on_time_flag) × 100

- KPI calculation: pp = rate_{Q_t} − rate_{Q_{t−4}}

- Output: quarter, ontime_%, base_%, Δ pp, cobertura (n con estimated)

- Caveats: 

## Pivot Table (to check in Python):

- Rows: 

- Columns:

- Values:

# 5) 

- Source:

- Scope: 

- Level: 

- Base metric: 

- KPI calculation: 

- Output: 

- Caveats: 

## Pivot Table (to check in Python):

- Rows: 

- Columns:

- Values: