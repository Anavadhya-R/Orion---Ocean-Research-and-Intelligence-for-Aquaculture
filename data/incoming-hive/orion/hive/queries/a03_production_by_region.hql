-- ORION | A03 Production by region (ocean basin, country/region label, farm type)
USE orion;

-- 1. Basin totals and growth
SELECT ocean_basin, reporting_year, active_sites, total_tonnes, total_revenue_usd, gross_profit_usd, profit_margin_pct,
       tonnes_yoy_pct, revenue_yoy_pct
FROM sum_production_by_basin_year
ORDER BY ocean_basin, reporting_year;

-- 2. Share of world output per basin (both years combined)
SELECT ocean_basin, ROUND(SUM(total_tonnes), 1) AS tonnes,
       ROUND(100.0 * SUM(total_tonnes) / SUM(SUM(total_tonnes)) OVER (), 2) AS pct_of_world
FROM sum_production_by_basin_year
GROUP BY ocean_basin
ORDER BY tonnes DESC;

-- 3. Top 10 countries/regions in 2024 with growth
SELECT country_or_region, active_sites, total_tonnes, tonnes_yoy_pct, gross_profit_usd, profit_margin_pct,
       RANK() OVER (ORDER BY total_tonnes DESC) AS rnk
FROM sum_production_by_country_year
WHERE reporting_year = 2024
ORDER BY total_tonnes DESC
LIMIT 10;

-- 4. Countries/regions with the highest profit margin (2024, >= 5 producing sites)
SELECT country_or_region, active_sites, total_tonnes, profit_margin_pct, feed_conversion_ratio, avg_mortality_pct
FROM sum_production_by_country_year
WHERE reporting_year = 2024 AND active_sites >= 5
ORDER BY profit_margin_pct DESC
LIMIT 10;

-- 5. Farm type performance by year
SELECT site_type, reporting_year, active_sites, total_tonnes, ROUND(total_tonnes / active_sites, 1) AS tonnes_per_site,
       profit_margin_pct, feed_conversion_ratio, avg_mortality_pct, tonnes_yoy_pct
FROM sum_production_by_site_type_year
ORDER BY site_type, reporting_year;

-- 6. What is farmed where: species group x basin (2024), share inside each basin
SELECT ocean_basin, species_group, total_tonnes,
       ROUND(100.0 * total_tonnes / SUM(total_tonnes) OVER (PARTITION BY ocean_basin), 1) AS pct_of_basin
FROM sum_production_by_species_group_basin
WHERE reporting_year = 2024
ORDER BY ocean_basin, total_tonnes DESC;

-- 7. Site status mix by basin (supply pipeline: Planned / Under_Construction / Fallow / Suspended)
SELECT ocean_basin, site_status, COUNT(*) AS sites, ROUND(SUM(capacity_tonnes_year), 0) AS capacity_tonnes_year
FROM aquaculture_sites
GROUP BY ocean_basin, site_status
ORDER BY ocean_basin, sites DESC;

-- 8. Unused capacity: capacity of non-operational sites as % of basin capacity
SELECT ocean_basin,
       ROUND(SUM(capacity_tonnes_year), 0) AS total_capacity,
       ROUND(100.0 * SUM(CASE WHEN site_status <> 'Operational' THEN capacity_tonnes_year ELSE 0 END) / SUM(capacity_tonnes_year), 1) AS pct_capacity_not_operational
FROM aquaculture_sites
GROUP BY ocean_basin
ORDER BY pct_capacity_not_operational DESC;
