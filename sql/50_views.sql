-- Revenue per quarter view
CREATE OR REPLACE VIEW analytics.vw_revenue_quarter AS
SELECT
    dcal.year,
    dcal.quarter,
    SUM(f.price) AS revenue
FROM core.fact_events f
JOIN core.dim_calendar dcal ON dcal.calendar_sk = f.calendar_sk
GROUP BY 1,2;

-- Revenue per quarter for sao paulo view
CREATE OR REPLACE VIEW analytics.vw_revenue_quarter_sp AS
SELECT
  dcal.year,
  dcal.quarter,
  SUM(f.price) AS revenue_sp
FROM core.fact_events f
JOIN core.dim_calendar dcal  ON dcal.calendar_sk  = f.calendar_sk
JOIN core.dim_customer dcu   ON dcu.customer_sk   = f.customer_sk
WHERE dcu.customer_city = 'sao paulo'  -- asumiendo normalizada en minúsculas
GROUP BY 1,2;
