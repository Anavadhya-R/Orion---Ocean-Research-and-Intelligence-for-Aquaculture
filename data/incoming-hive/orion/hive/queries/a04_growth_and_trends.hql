-- ORION | A04 Time series and growth rates (data covers Jan 2023 - Dec 2024)
USE orion;

-- 1. Monthly series with month-on-month, year-on-year growth and 3-month moving average
SELECT year_month, total_tonnes, tonnes_mom_pct, tonnes_yoy_pct, tonnes_3m_moving_avg, total_revenue_usd, gross_profit_usd
FROM sum_production_monthly
ORDER BY year_month;

-- 2. Year totals and growth
SELECT reporting_year, ROUND(SUM(total_tonnes), 1) AS tonnes, ROUND(SUM(total_revenue_usd), 0) AS revenue_usd,
       ROUND(SUM(gross_profit_usd), 0) AS profit_usd
FROM sum_production_monthly
GROUP BY reporting_year
ORDER BY reporting_year;

SELECT ROUND((SUM(CASE WHEN reporting_year = 2024 THEN total_tonnes END) / SUM(CASE WHEN reporting_year = 2023 THEN total_tonnes END) - 1) * 100, 2) AS tonnes_growth_pct,
       ROUND((SUM(CASE WHEN reporting_year = 2024 THEN total_revenue_usd END) / SUM(CASE WHEN reporting_year = 2023 THEN total_revenue_usd END) - 1) * 100, 2) AS revenue_growth_pct,
       ROUND((SUM(CASE WHEN reporting_year = 2024 THEN gross_profit_usd END) / SUM(CASE WHEN reporting_year = 2023 THEN gross_profit_usd END) - 1) * 100, 2) AS profit_growth_pct
FROM sum_production_monthly;

-- 3. Seasonality: average share of annual production by calendar month
SELECT reporting_month,
       ROUND(AVG(100.0 * total_tonnes / yr.year_total), 2) AS avg_pct_of_year,
       ROUND(AVG(total_tonnes), 1) AS avg_monthly_tonnes
FROM sum_production_monthly m
JOIN (SELECT reporting_year AS y, SUM(total_tonnes) AS year_total FROM sum_production_monthly GROUP BY reporting_year) yr
  ON m.reporting_year = yr.y
GROUP BY reporting_month
ORDER BY reporting_month;

-- 4. Ramp-up check: producing sites per month (new sites coming online explain growth, not yield)
SELECT year_month, active_sites, total_tonnes, ROUND(total_tonnes / active_sites, 2) AS tonnes_per_active_site
FROM sum_production_monthly
ORDER BY year_month;

-- 5. Growth decomposition 2024 vs 2023: more sites, or more output per site?
SELECT ROUND((a24.sites / a23.sites - 1) * 100, 2)                     AS site_growth_pct,
       ROUND((a24.per_site / a23.per_site - 1) * 100, 2)              AS tonnes_per_site_growth_pct,
       ROUND((a24.tonnes / a23.tonnes - 1) * 100, 2)                  AS total_tonnes_growth_pct
FROM (SELECT COUNT(DISTINCT site_id) AS sites, SUM(production_tonnes) AS tonnes,
             SUM(production_tonnes) / COUNT(DISTINCT site_id) AS per_site
      FROM fish_production WHERE reporting_year = 2023) a23
CROSS JOIN
     (SELECT COUNT(DISTINCT site_id) AS sites, SUM(production_tonnes) AS tonnes,
             SUM(production_tonnes) / COUNT(DISTINCT site_id) AS per_site
      FROM fish_production WHERE reporting_year = 2024) a24;

-- 6. Quarterly view for the executive summary
SELECT reporting_year, CAST(CEIL(reporting_month / 3.0) AS INT) AS quarter,
       ROUND(SUM(total_tonnes), 1) AS tonnes, ROUND(SUM(total_revenue_usd), 0) AS revenue_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / SUM(total_revenue_usd), 2) AS margin_pct
FROM sum_production_monthly
GROUP BY reporting_year, CAST(CEIL(reporting_month / 3.0) AS INT)
ORDER BY reporting_year, quarter;
