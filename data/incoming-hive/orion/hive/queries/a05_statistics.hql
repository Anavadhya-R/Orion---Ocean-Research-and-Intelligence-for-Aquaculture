-- ORION | A05 Descriptive statistics: totals, averages, spread, percentiles, correlations
USE orion;

-- 1. Headline totals
SELECT * FROM sum_overview_kpis;

-- 2. Distribution of monthly production per record: mean, spread, quartiles, extremes
SELECT COUNT(*) AS records,
       ROUND(AVG(production_tonnes), 2)                   AS mean_tonnes,
       ROUND(STDDEV_POP(production_tonnes), 2)            AS stddev_tonnes,
       ROUND(MIN(production_tonnes), 2)                   AS min_tonnes,
       ROUND(PERCENTILE_APPROX(production_tonnes, 0.25), 2) AS p25,
       ROUND(PERCENTILE_APPROX(production_tonnes, 0.50), 2) AS median,
       ROUND(PERCENTILE_APPROX(production_tonnes, 0.75), 2) AS p75,
       ROUND(PERCENTILE_APPROX(production_tonnes, 0.95), 2) AS p95,
       ROUND(MAX(production_tonnes), 2)                   AS max_tonnes
FROM fish_production;

-- 3. Same for the quality indicators
SELECT ROUND(AVG(feed_conversion_ratio), 3) AS mean_fcr, ROUND(PERCENTILE_APPROX(feed_conversion_ratio, 0.5), 3) AS median_fcr,
       ROUND(STDDEV_POP(feed_conversion_ratio), 3) AS sd_fcr,
       ROUND(AVG(mortality_rate_percent), 2) AS mean_mortality, ROUND(PERCENTILE_APPROX(mortality_rate_percent, 0.5), 2) AS median_mortality,
       ROUND(PERCENTILE_APPROX(mortality_rate_percent, 0.95), 2) AS p95_mortality
FROM fish_production;

-- 4. Correlations: what moves production, cost and mortality?
SELECT ROUND(CORR(production_tonnes, revenue_usd), 3)               AS corr_tonnes_revenue,
       ROUND(CORR(production_tonnes, operating_cost_usd), 3)        AS corr_tonnes_cost,
       ROUND(CORR(feed_conversion_ratio, mortality_rate_percent), 3) AS corr_fcr_mortality,
       ROUND(CORR(feed_conversion_ratio, operating_cost_usd / production_tonnes), 3) AS corr_fcr_unit_cost
FROM fish_production;

-- 5. Site-level drivers: do environment and size explain output? (one row per site)
SELECT ROUND(CORR(s.water_quality_index, p.tonnes), 3)        AS corr_waterquality_tonnes,
       ROUND(CORR(s.environmental_risk_score, p.tonnes), 3)   AS corr_envrisk_tonnes,
       ROUND(CORR(s.farm_area_hectares, p.tonnes), 3)         AS corr_area_tonnes,
       ROUND(CORR(s.infrastructure_access_score, p.margin), 3) AS corr_infrastructure_margin,
       ROUND(CORR(s.environmental_risk_score, p.mortality), 3) AS corr_envrisk_mortality
FROM aquaculture_sites s
JOIN (SELECT site_id, SUM(production_tonnes) AS tonnes, AVG(mortality_rate_percent) AS mortality,
             100.0 * SUM(revenue_usd - operating_cost_usd) / SUM(revenue_usd) AS margin
      FROM fish_production GROUP BY site_id) p ON s.site_id = p.site_id;

-- 6. Average site profile by farm type
SELECT site_type, COUNT(*) AS sites, ROUND(AVG(farm_area_hectares), 2) AS avg_hectares, ROUND(AVG(water_depth_m), 1) AS avg_depth_m,
       ROUND(AVG(water_quality_index), 1) AS avg_water_quality, ROUND(AVG(environmental_risk_score), 1) AS avg_env_risk,
       ROUND(AVG(capacity_tonnes_year), 0) AS avg_capacity_tonnes
FROM aquaculture_sites
GROUP BY site_type
ORDER BY sites DESC;

-- 7. Outliers: production records more than 3 standard deviations above their species mean
SELECT p.production_id, p.site_id, p.species_id, p.reporting_year, p.reporting_month, p.production_tonnes,
       ROUND(a.mean_t, 2) AS species_mean, ROUND((p.production_tonnes - a.mean_t) / a.sd_t, 1) AS z_score
FROM fish_production p
JOIN (SELECT species_id, AVG(production_tonnes) AS mean_t, STDDEV_POP(production_tonnes) AS sd_t
      FROM fish_production GROUP BY species_id) a ON p.species_id = a.species_id
WHERE a.sd_t > 0 AND (p.production_tonnes - a.mean_t) / a.sd_t > 3
ORDER BY z_score DESC
LIMIT 20;
