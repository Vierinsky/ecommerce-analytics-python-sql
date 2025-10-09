TODO: Set START_DATE / END_DATE and lock MDE = +2% before power analysis & stopping rules.

# 1) Objective and Context

“Adding a free-shipping threshold banner for São Paulo to raise average order revenue this quarter.”

# 2) Primary Metric

Name: Average order revenue (GMV without freight), currency = BRL

Definition: sum of `price` per order_id (across items), then mean across orders in the quarter

Window: by quarter, assigned by `order_delivered_customer_date`

Scope: sao paulo (city)

Primary = mean revenue/order (currency = BRL, freight excluded), quarter-level, sao paulo city.

# 3) Randomization Unit and assignment

Unit: customer_id

Assignment: group = hash(customer_id) % 2 → A (control), B (banner) 50/50

Rationale: avoids the same customer seeing both variants; stable over time

Unit = customer; deterministic hashing 50/50.

# 4) Eligibility and Exposure Rules

- Include: orders with order_status = delivered, sao paulo (city), within [start_date, end_date]

- Exclude: invalid dates (delivered < approved), missing delivered_date

- Exposure rule: customer hashed to B is considered exposed (in this offline project we’ll simulate exposure via hashing)

# 5) Hypotheses

- Math: H0:μB−μA = 0 vs H1:μB−μA > 0

- Plain English: “The banner increases average order revenue.”

# 6) Testing conventions

- Alpha: 0.05

- Power: 0.80

- Baseline (TODO: fill after pre-analysis): average revenue/order = ___ BRL

- MDE (target uplift): +__% relative (TODO: Let's pick something realistic: 1–3% is common for banners)

- Stat test: Welch’s t-test (means, unequal variances)

- Effect reported: absolute Δ BRL and % relative; Cohen’s d

- Robustness: Mann-Whitney + report median (to check outlier sensitivity)

# 7) Guardrails

Pick 2–3:

- On-time rate (pp) must not decrease

- Lead time P90 (days) must not increase

- Cancellation/return rate (pp) must not increase

Ship only if primary passes and guardrails don’t worsen.

# 8) Variance reduction (optional)

- CUPED (Covariate-Adjusted): Yes/No. If Yes, covariate = customer’s pre-period revenue/order

- Stratification: Yes/No. If Yes, strata = weekday or category

(If you’re new, it’s fine to set both to No for the first pass.)

# 9) Sanity checks (pre-treatment balance)

Compare A vs B on pre-period metrics (before start_date):

- #orders/customer, revenue/order, category mix, SP share
→ If imbalanced, note it and keep the plan (hashing should be fine).

# 10) Window & stopping

- Design: fixed horizon

- Stop when: N per group (from power analysis using the pre-period baseline/variance) is reached.

- Interim looks: None (no alpha-spending in v1)

# 11) Data hygiene

- Unique (order_id, order_item_id) in fact; aggregate to order for the metric

- Exclude rows with `order_delivered_customer_date < order_approved_at`

- Revenue excludes freight (`price` only)

- Sensitivity: winsorize revenue at P99.9 for robustness check only; Primary result uses raw data.

# 12) Reporting outline

1) Setup (unit, dates, N)

2) Descriptives (mean/median & distribution snapshot per group)

3) Test results (statistic, p-value, 95% CI, effect size)

4) Guardrails (all pass/fail)

5) Robustness (Mann-Whitney / median)

6) Decision (ship / hold / collect more data)

7) Risks & next steps

# Bonus: Quick decision nudges (so you can fill blanks fast)

- MDE: pick +2% if you want a realistic target for a banner.

- SP scope: choose city (consistent with your earlier KPIs) and state the exact column (customer_city == "sao paulo" normalized).

- Dates: pick a continuous quarter in the data (e.g., Q2 of a year in Olist’s range).