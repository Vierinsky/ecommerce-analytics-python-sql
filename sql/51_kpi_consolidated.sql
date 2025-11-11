CREATE OR REPLACE VIEW analytics.vw_kpi_quarter_sp AS
WITH
rev AS (
    SELECT year, quarter, revenue_sp
    FROM analytics.vw_revenue_quarter_sp
),
revw AS (
    SELECT year, quarter, share_ge4 AS reviews_ge4_share
    FROM analytics.vw_reviews_share_quarter_sp
),
lt AS (
    SELECT year, quarter, lead_time_p90
    FROM analytics.vw_leadtime_p90_quarter_sp
),
ot AS (
    SELECT year, quarter, on_time_rate
    FROM analytics.vw_on_time_rate_quarter_sp
)
SELECT
    COALESCE(rev.year, revw.year, lt.year, ot.year) AS year,
    COALESCE(rev.quarter, revw.quarter, lt.quarter, ot.quarter) AS quarter,
    rev.revenue_sp,
    reviews_ge4_share,
    lt.lead_time_p90,
    ot.on_time_rate
FROM rev
FULL OUTER JOIN revw USING (year, quarter)
FULL OUTER JOIN lt USING (year, quarter)
FULL OUTER JOIN ot USING (year, quarter)
ORDER BY 1,2;

-- Test
SELECT * FROM analytics.vw_kpi_quarter_sp ORDER BY year, quarter;
