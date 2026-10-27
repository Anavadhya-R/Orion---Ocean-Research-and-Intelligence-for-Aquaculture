-- =============================================================================
-- ORION | Hive layer 4: SUMMARY tables for the React dashboard and Power BI   (branch: feature/sql-summaries)
--
-- Small, flat, final tables - one per dashboard view. Every table is exported to CSV by
-- scripts/export_summaries.sh (React reads the JSON copy, Power BI reads the CSV).
-- Conventions: *_usd = US dollars, *_pct = percent (0-100), yoy = 2024 vs 2023 (the data has only 2 years,
-- so growth exists for 2024 rows only; 2023 rows have NULL growth). ALL SOURCE DATA IS SYNTHETIC.
-- =============================================================================

USE orion;

-- Production, feed, mortality, money and growth by species and year
DROP TABLE IF EXISTS sum_production_by_species_year;
CREATE TABLE sum_production_by_species_year STORED AS ORC AS
WITH agg AS (
  SELECT species_id,
       common_name,
       scientific_name,
       species_group,
       aquaculture_potential,
       reporting_year,
       COUNT(*)                                                         AS production_records,
       COUNT(DISTINCT site_id)                                          AS active_sites,
       ROUND(SUM(production_tonnes), 2)                                 AS total_tonnes,
       ROUND(AVG(production_tonnes), 3)                                 AS avg_tonnes_per_record,
       ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
       ROUND(AVG(mortality_rate_percent), 2)                            AS avg_mortality_pct,
       ROUND(AVG(survival_rate_percent), 2)                             AS avg_survival_pct,
       ROUND(SUM(revenue_usd), 2)                                       AS total_revenue_usd,
       ROUND(SUM(operating_cost_usd), 2)                                AS total_cost_usd,
       ROUND(SUM(gross_profit_usd), 2)                                  AS gross_profit_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
       ROUND(SUM(revenue_usd) / NULLIF(SUM(production_tonnes), 0), 2)   AS revenue_per_tonne_usd
  FROM vw_production_enriched
  GROUP BY species_id, common_name, scientific_name, species_group, aquaculture_potential, reporting_year
)
SELECT a.*,
       p.total_tonnes AS prev_year_tonnes,
       CASE WHEN p.total_tonnes > 0 THEN ROUND((a.total_tonnes - p.total_tonnes) / p.total_tonnes * 100, 2) END AS tonnes_yoy_pct,
       CASE WHEN p.total_revenue_usd > 0 THEN ROUND((a.total_revenue_usd - p.total_revenue_usd) / p.total_revenue_usd * 100, 2) END AS revenue_yoy_pct,
       CASE WHEN p.gross_profit_usd > 0 THEN ROUND((a.gross_profit_usd - p.gross_profit_usd) / p.gross_profit_usd * 100, 2) END AS profit_yoy_pct
FROM agg a
LEFT JOIN agg p ON a.species_id = p.species_id AND p.reporting_year = a.reporting_year - 1;

-- By ocean basin and year
DROP TABLE IF EXISTS sum_production_by_basin_year;
CREATE TABLE sum_production_by_basin_year STORED AS ORC AS
WITH agg AS (
  SELECT ocean_basin,
       reporting_year,
       COUNT(*)                                                         AS production_records,
       COUNT(DISTINCT site_id)                                          AS active_sites,
       ROUND(SUM(production_tonnes), 2)                                 AS total_tonnes,
       ROUND(AVG(production_tonnes), 3)                                 AS avg_tonnes_per_record,
       ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
       ROUND(AVG(mortality_rate_percent), 2)                            AS avg_mortality_pct,
       ROUND(AVG(survival_rate_percent), 2)                             AS avg_survival_pct,
       ROUND(SUM(revenue_usd), 2)                                       AS total_revenue_usd,
       ROUND(SUM(operating_cost_usd), 2)                                AS total_cost_usd,
       ROUND(SUM(gross_profit_usd), 2)                                  AS gross_profit_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
       ROUND(SUM(revenue_usd) / NULLIF(SUM(production_tonnes), 0), 2)   AS revenue_per_tonne_usd
  FROM vw_production_enriched
  GROUP BY ocean_basin, reporting_year
)
SELECT a.*,
       p.total_tonnes AS prev_year_tonnes,
       CASE WHEN p.total_tonnes > 0 THEN ROUND((a.total_tonnes - p.total_tonnes) / p.total_tonnes * 100, 2) END AS tonnes_yoy_pct,
       CASE WHEN p.total_revenue_usd > 0 THEN ROUND((a.total_revenue_usd - p.total_revenue_usd) / p.total_revenue_usd * 100, 2) END AS revenue_yoy_pct,
       CASE WHEN p.gross_profit_usd > 0 THEN ROUND((a.gross_profit_usd - p.gross_profit_usd) / p.gross_profit_usd * 100, 2) END AS profit_yoy_pct
FROM agg a
LEFT JOIN agg p ON a.ocean_basin = p.ocean_basin AND p.reporting_year = a.reporting_year - 1;

-- By country / region label and year (note: country_or_region mixes single countries ('Chile') and groups ('India/Bangladesh/Myanmar'))
DROP TABLE IF EXISTS sum_production_by_country_year;
CREATE TABLE sum_production_by_country_year STORED AS ORC AS
WITH agg AS (
  SELECT country_or_region,
       reporting_year,
       COUNT(*)                                                         AS production_records,
       COUNT(DISTINCT site_id)                                          AS active_sites,
       ROUND(SUM(production_tonnes), 2)                                 AS total_tonnes,
       ROUND(AVG(production_tonnes), 3)                                 AS avg_tonnes_per_record,
       ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
       ROUND(AVG(mortality_rate_percent), 2)                            AS avg_mortality_pct,
       ROUND(AVG(survival_rate_percent), 2)                             AS avg_survival_pct,
       ROUND(SUM(revenue_usd), 2)                                       AS total_revenue_usd,
       ROUND(SUM(operating_cost_usd), 2)                                AS total_cost_usd,
       ROUND(SUM(gross_profit_usd), 2)                                  AS gross_profit_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
       ROUND(SUM(revenue_usd) / NULLIF(SUM(production_tonnes), 0), 2)   AS revenue_per_tonne_usd
  FROM vw_production_enriched
  GROUP BY country_or_region, reporting_year
)
SELECT a.*,
       p.total_tonnes AS prev_year_tonnes,
       CASE WHEN p.total_tonnes > 0 THEN ROUND((a.total_tonnes - p.total_tonnes) / p.total_tonnes * 100, 2) END AS tonnes_yoy_pct,
       CASE WHEN p.total_revenue_usd > 0 THEN ROUND((a.total_revenue_usd - p.total_revenue_usd) / p.total_revenue_usd * 100, 2) END AS revenue_yoy_pct,
       CASE WHEN p.gross_profit_usd > 0 THEN ROUND((a.gross_profit_usd - p.gross_profit_usd) / p.gross_profit_usd * 100, 2) END AS profit_yoy_pct
FROM agg a
LEFT JOIN agg p ON a.country_or_region = p.country_or_region AND p.reporting_year = a.reporting_year - 1;

-- By farm type (marine_cage, earthen_pond, ...) and year
DROP TABLE IF EXISTS sum_production_by_site_type_year;
CREATE TABLE sum_production_by_site_type_year STORED AS ORC AS
WITH agg AS (
  SELECT site_type,
       reporting_year,
       COUNT(*)                                                         AS production_records,
       COUNT(DISTINCT site_id)                                          AS active_sites,
       ROUND(SUM(production_tonnes), 2)                                 AS total_tonnes,
       ROUND(AVG(production_tonnes), 3)                                 AS avg_tonnes_per_record,
       ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
       ROUND(AVG(mortality_rate_percent), 2)                            AS avg_mortality_pct,
       ROUND(AVG(survival_rate_percent), 2)                             AS avg_survival_pct,
       ROUND(SUM(revenue_usd), 2)                                       AS total_revenue_usd,
       ROUND(SUM(operating_cost_usd), 2)                                AS total_cost_usd,
       ROUND(SUM(gross_profit_usd), 2)                                  AS gross_profit_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
       ROUND(SUM(revenue_usd) / NULLIF(SUM(production_tonnes), 0), 2)   AS revenue_per_tonne_usd
  FROM vw_production_enriched
  GROUP BY site_type, reporting_year
)
SELECT a.*,
       p.total_tonnes AS prev_year_tonnes,
       CASE WHEN p.total_tonnes > 0 THEN ROUND((a.total_tonnes - p.total_tonnes) / p.total_tonnes * 100, 2) END AS tonnes_yoy_pct,
       CASE WHEN p.total_revenue_usd > 0 THEN ROUND((a.total_revenue_usd - p.total_revenue_usd) / p.total_revenue_usd * 100, 2) END AS revenue_yoy_pct,
       CASE WHEN p.gross_profit_usd > 0 THEN ROUND((a.gross_profit_usd - p.gross_profit_usd) / p.gross_profit_usd * 100, 2) END AS profit_yoy_pct
FROM agg a
LEFT JOIN agg p ON a.site_type = p.site_type AND p.reporting_year = a.reporting_year - 1;

-- Species group x ocean basin x year (heat-map of what is farmed where)
DROP TABLE IF EXISTS sum_production_by_species_group_basin;
CREATE TABLE sum_production_by_species_group_basin STORED AS ORC AS
WITH agg AS (
  SELECT species_group,
       ocean_basin,
       reporting_year,
       COUNT(*)                                                         AS production_records,
       COUNT(DISTINCT site_id)                                          AS active_sites,
       ROUND(SUM(production_tonnes), 2)                                 AS total_tonnes,
       ROUND(AVG(production_tonnes), 3)                                 AS avg_tonnes_per_record,
       ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
       ROUND(AVG(mortality_rate_percent), 2)                            AS avg_mortality_pct,
       ROUND(AVG(survival_rate_percent), 2)                             AS avg_survival_pct,
       ROUND(SUM(revenue_usd), 2)                                       AS total_revenue_usd,
       ROUND(SUM(operating_cost_usd), 2)                                AS total_cost_usd,
       ROUND(SUM(gross_profit_usd), 2)                                  AS gross_profit_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
       ROUND(SUM(revenue_usd) / NULLIF(SUM(production_tonnes), 0), 2)   AS revenue_per_tonne_usd
  FROM vw_production_enriched
  GROUP BY species_group, ocean_basin, reporting_year
)
SELECT a.*,
       p.total_tonnes AS prev_year_tonnes,
       CASE WHEN p.total_tonnes > 0 THEN ROUND((a.total_tonnes - p.total_tonnes) / p.total_tonnes * 100, 2) END AS tonnes_yoy_pct,
       CASE WHEN p.total_revenue_usd > 0 THEN ROUND((a.total_revenue_usd - p.total_revenue_usd) / p.total_revenue_usd * 100, 2) END AS revenue_yoy_pct,
       CASE WHEN p.gross_profit_usd > 0 THEN ROUND((a.gross_profit_usd - p.gross_profit_usd) / p.gross_profit_usd * 100, 2) END AS profit_yoy_pct
FROM agg a
LEFT JOIN agg p ON a.species_group = p.species_group AND a.ocean_basin = p.ocean_basin AND p.reporting_year = a.reporting_year - 1;

-- Monthly time series with month-on-month and year-on-year growth
DROP TABLE IF EXISTS sum_production_monthly;
CREATE TABLE sum_production_monthly STORED AS ORC AS
WITH m AS (
  SELECT reporting_year, reporting_month, year_month,
       COUNT(*)                                                         AS production_records,
       COUNT(DISTINCT site_id)                                          AS active_sites,
       ROUND(SUM(production_tonnes), 2)                                 AS total_tonnes,
       ROUND(AVG(production_tonnes), 3)                                 AS avg_tonnes_per_record,
       ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
       ROUND(AVG(mortality_rate_percent), 2)                            AS avg_mortality_pct,
       ROUND(AVG(survival_rate_percent), 2)                             AS avg_survival_pct,
       ROUND(SUM(revenue_usd), 2)                                       AS total_revenue_usd,
       ROUND(SUM(operating_cost_usd), 2)                                AS total_cost_usd,
       ROUND(SUM(gross_profit_usd), 2)                                  AS gross_profit_usd,
       ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
       ROUND(SUM(revenue_usd) / NULLIF(SUM(production_tonnes), 0), 2)   AS revenue_per_tonne_usd
  FROM vw_production_enriched
  GROUP BY reporting_year, reporting_month, year_month
)
SELECT a.*,
       p.total_tonnes AS prev_month_tonnes,
       CASE WHEN p.total_tonnes > 0 THEN ROUND((a.total_tonnes - p.total_tonnes) / p.total_tonnes * 100, 2) END AS tonnes_mom_pct,
       y.total_tonnes AS same_month_last_year_tonnes,
       CASE WHEN y.total_tonnes > 0 THEN ROUND((a.total_tonnes - y.total_tonnes) / y.total_tonnes * 100, 2) END AS tonnes_yoy_pct,
       ROUND(AVG(a.total_tonnes) OVER (ORDER BY a.year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS tonnes_3m_moving_avg
FROM m a
LEFT JOIN m p ON p.year_month = CASE WHEN a.reporting_month = 1 THEN (a.reporting_year - 1) * 100 + 12 ELSE a.year_month - 1 END
LEFT JOIN m y ON y.year_month = a.year_month - 100;

-- Site scorecard: output, capacity use, money, quality; ranked inside the ocean basin
DROP TABLE IF EXISTS sum_site_performance;
CREATE TABLE sum_site_performance STORED AS ORC AS
WITH s AS (
  SELECT site_id, site_name, country_or_region, ocean_basin, site_type, site_status, capacity_tonnes_year,
         COUNT(DISTINCT year_month) AS months_reported,
         COUNT(DISTINCT species_id) AS species_farmed,
         ROUND(SUM(production_tonnes), 2) AS total_tonnes,
         ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
         ROUND(AVG(mortality_rate_percent), 2) AS avg_mortality_pct,
         ROUND(SUM(revenue_usd), 2) AS total_revenue_usd,
         ROUND(SUM(operating_cost_usd), 2) AS total_cost_usd,
         ROUND(SUM(gross_profit_usd), 2) AS gross_profit_usd
  FROM vw_production_enriched
  GROUP BY site_id, site_name, country_or_region, ocean_basin, site_type, site_status, capacity_tonnes_year
)
SELECT s.*,
       ROUND(100.0 * s.gross_profit_usd / NULLIF(s.total_revenue_usd, 0), 2) AS profit_margin_pct,
       -- annualised output as % of the site's stated yearly capacity (>100 = reported above capacity)
       ROUND(100.0 * (s.total_tonnes / s.months_reported * 12) / NULLIF(s.capacity_tonnes_year, 0), 1) AS capacity_utilisation_pct,
       RANK() OVER (PARTITION BY s.ocean_basin ORDER BY s.gross_profit_usd DESC) AS profit_rank_in_basin,
       RANK() OVER (ORDER BY s.total_tonnes DESC) AS tonnes_rank_global
FROM s;

-- Species league table over the whole period (2023-2024)
DROP TABLE IF EXISTS sum_species_ranking;
CREATE TABLE sum_species_ranking STORED AS ORC AS
WITH s AS (
  SELECT species_id, common_name, species_group, aquaculture_potential,
         COUNT(DISTINCT site_id) AS sites_farming,
         COUNT(DISTINCT ocean_basin) AS basins,
         ROUND(SUM(production_tonnes), 2) AS total_tonnes,
         ROUND(SUM(revenue_usd), 2) AS total_revenue_usd,
         ROUND(SUM(gross_profit_usd), 2) AS gross_profit_usd,
         ROUND(100.0 * SUM(gross_profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS profit_margin_pct,
         ROUND(SUM(feed_consumption_tonnes) / NULLIF(SUM(production_tonnes), 0), 3) AS feed_conversion_ratio,
         ROUND(AVG(mortality_rate_percent), 2) AS avg_mortality_pct
  FROM vw_production_enriched
  GROUP BY species_id, common_name, species_group, aquaculture_potential
)
SELECT s.*,
       RANK() OVER (ORDER BY total_tonnes DESC)      AS tonnes_rank,
       RANK() OVER (ORDER BY gross_profit_usd DESC)  AS profit_rank,
       RANK() OVER (ORDER BY profit_margin_pct DESC) AS margin_rank,
       ROUND(100.0 * total_tonnes / SUM(total_tonnes) OVER (), 2) AS pct_of_total_tonnes
FROM s;

-- Ocean conditions (cleaned) by basin, year and month - drives the environment charts
DROP TABLE IF EXISTS sum_ocean_basin_month;
CREATE TABLE sum_ocean_basin_month STORED AS ORC AS
SELECT ocean_basin, obs_year, obs_month,
       COUNT(*)                                  AS measurements,
       ROUND(AVG(sea_surface_temperature_c), 2)  AS avg_sst_c,
       ROUND(AVG(water_temperature_c), 2)        AS avg_water_temp_c,
       ROUND(AVG(salinity_psu), 2)               AS avg_salinity_psu,
       ROUND(AVG(dissolved_oxygen_mg_l), 2)      AS avg_dissolved_oxygen_mg_l,
       ROUND(AVG(ph), 3)                         AS avg_ph,
       ROUND(AVG(chlorophyll_a_mg_m3), 3)        AS avg_chlorophyll_mg_m3,
       ROUND(AVG(nitrate_umol_l), 2)             AS avg_nitrate_umol_l,
       ROUND(AVG(wave_height_m), 2)              AS avg_wave_height_m,
       ROUND(AVG(current_speed_m_s), 3)          AS avg_current_speed_m_s
FROM ocean_conditions
GROUP BY ocean_basin, obs_year, obs_month;

-- Habitat suitability by basin and class
DROP TABLE IF EXISTS sum_habitat_by_basin;
CREATE TABLE sum_habitat_by_basin STORED AS ORC AS
SELECT ocean_basin, suitability_class,
       COUNT(*)                                  AS habitat_cells,
       ROUND(AVG(suitability_score), 2)          AS avg_suitability_score,
       ROUND(AVG(water_quality_score), 2)        AS avg_water_quality_score,
       ROUND(AVG(environmental_risk_score), 2)   AS avg_env_risk_score,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY ocean_basin), 1) AS pct_of_basin
FROM habitat_suitability
GROUP BY ocean_basin, suitability_class;

-- Money in/out by month and category
DROP TABLE IF EXISTS sum_finance_monthly;
CREATE TABLE sum_finance_monthly STORED AS ORC AS
SELECT txn_year, txn_month, txn_year * 100 + txn_month AS year_month, transaction_type, category,
       COUNT(*) AS transactions, ROUND(SUM(amount_usd), 2) AS total_usd
FROM finance_transactions
GROUP BY txn_year, txn_month, transaction_type, category;

-- Inventory health by site basin and resource category
DROP TABLE IF EXISTS sum_inventory_status;
CREATE TABLE sum_inventory_status STORED AS ORC AS
SELECT s.ocean_basin, r.resource_category, r.resource_status,
       COUNT(*) AS items,
       ROUND(SUM(r.quantity_available * r.unit_cost_usd), 2) AS stock_value_usd,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY s.ocean_basin, r.resource_category), 1) AS pct_of_category
FROM resource_inventory r
LEFT JOIN aquaculture_sites s ON r.site_id = s.site_id
GROUP BY s.ocean_basin, r.resource_category, r.resource_status;

-- Headline numbers (long format: metric / value / unit) for the dashboard KPI cards
DROP TABLE IF EXISTS sum_overview_kpis;
CREATE TABLE sum_overview_kpis STORED AS ORC AS
SELECT 'total_production_tonnes' AS metric, ROUND(SUM(production_tonnes), 2) AS metric_value, 'tonnes' AS unit FROM fish_production
UNION ALL SELECT 'total_revenue_usd', ROUND(SUM(revenue_usd), 2), 'USD' FROM fish_production
UNION ALL SELECT 'total_operating_cost_usd', ROUND(SUM(operating_cost_usd), 2), 'USD' FROM fish_production
UNION ALL SELECT 'gross_profit_usd', ROUND(SUM(revenue_usd - operating_cost_usd), 2), 'USD' FROM fish_production
UNION ALL SELECT 'profit_margin_pct', ROUND(100.0 * SUM(revenue_usd - operating_cost_usd) / SUM(revenue_usd), 2), '%' FROM fish_production
UNION ALL SELECT 'feed_conversion_ratio', ROUND(SUM(feed_consumption_tonnes) / SUM(production_tonnes), 3), 'ratio' FROM fish_production
UNION ALL SELECT 'avg_mortality_pct', ROUND(AVG(mortality_rate_percent), 2), '%' FROM fish_production
UNION ALL SELECT 'sites_total', COUNT(*), 'sites' FROM aquaculture_sites
UNION ALL SELECT 'sites_operational', SUM(CASE WHEN site_status = 'Operational' THEN 1 ELSE 0 END), 'sites' FROM aquaculture_sites
UNION ALL SELECT 'sites_producing', COUNT(DISTINCT site_id), 'sites' FROM fish_production
UNION ALL SELECT 'species_catalogue', COUNT(*), 'species' FROM marine_species
UNION ALL SELECT 'species_farmed', COUNT(DISTINCT species_id), 'species' FROM fish_production
UNION ALL SELECT 'low_or_out_of_stock_items', SUM(CASE WHEN resource_status <> 'In_Stock' THEN 1 ELSE 0 END), 'items' FROM resource_inventory
UNION ALL SELECT 'high_suitability_cells_pct', ROUND(100.0 * SUM(CASE WHEN suitability_class IN ('High', 'Very High') THEN 1 ELSE 0 END) / COUNT(*), 1), '%' FROM habitat_suitability;
