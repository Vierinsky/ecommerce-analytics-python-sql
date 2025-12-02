<!-- 
Una frase explicando para que sirve cada paquete (En inglés):

    pandas, numpy, matplotlib, scipy, SQLAlchemy, psycopg2-binary, python-dotenv, requests

Incluye estas secciones (bullets, sin detalles técnicos):

    * Resumen: “Proyecto e-commerce (Olist) con Python+SQL. KPIs YoY y A/B.”

    * Stack: Python, PostgreSQL, (Docker si elegiste A), notebooks.

    * Qué aprenderás: ingestión, limpieza, KPIs, visualización, pruebas estadísticas.

    * Progreso: “Fase 0 completada. En curso: Fase 1 (repo + entorno).”

    * KPIs (en texto): lista los 5 que definiste (sin fórmulas). -->

# E-commerce Analytics (Python + SQL + Power BI) — Olist Dataset (Brazil)

End-to-end analytics project using Python, PostgreSQL, and Power BI on the Olist Brazilian E-commerce dataset.

- **Focus**: São Paulo city, orders with delivered status only, Year quarters come from delivered_date.
- **Goal**: To build a small analytic warehouse, compute KPIs, and publish an executive dashboard to analyze and explain business insights.

## Tech stack

* Python 3.11 (pandas, SQLAlchemy, python-dotenv)

* PostgreSQL (Docker)

* SQL (DDL, staging → dims/facts → analytic views)

* Power BI (4 pages: KPIs, Trends, Delivery, Summary)

## Repository structure
```
.
├─ sql/
│  ├─ 00_schemas.sql               # schemas (staging, core, analytics)
│  ├─ 10_staging.sql               # staging tables (orders_raw, order_items_raw, reviews_raw, ...)
│  ├─ 20_core_model.sql            # core.dim_* and core.fact_events (DDL)
│  ├─ 30_constraints_indexes.sql   # PK/FK, indexes
│  ├─ 50_views.sql                 # KPI views (revenue, reviews, lead time P90, on-time, category share)
│  ├─ 51_kpi_consolidated.sql      # analytics.vw_kpi_quarter_sp (quarter-level)
│  └─ 52_drivers_views.sql         # drivers (late orders by category; delta vs previous quarter)
│
<!-- Review and Correct this section -->
├─ scripts/
│  ├─ load_orders.py               # minimal CSV loader (sample_orders.csv → staging.orders_raw)
│  └─ [other loaders].py           # optional loaders (order_items, reviews, sellers…)
│
├─ data/                           # This folder contains the source of raw data used for this project. 
│                                  # Won't be uploaded to the online repository
│
├─ notebooks/
│  └─ EDA.ipynb                    # quick EDA / sanity checks (optional)
│
<!-- Review and Correct this section -->
├─ reports/
│  ├─ insights.md                  # Page 4 text (executive notes)
│  └─ ab_design.md                 # (removed from scope; left here if needed for reference)
│
├─ docker-compose.yml              # Postgres service
├─ .env                            # DB credentials (never commit secrets)
└─ Dashboard.pbix       # Power BI report (pages 1–4)
```
