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
