-- ORION | A06 Site performance and capacity
USE orion;

-- 1. Top 20 sites by profit
SELECT site_id, site_name, ocean_basin, site_type, total_tonnes, gross_profit_usd, profit_margin_pct, capacity_utilisation_pct
FROM sum_site_performance
ORDER BY gross_profit_usd DESC
LIMIT 20;

-- 2. Best site in each basin (rank 1 by profit)
SELECT ocean_basin, site_name, site_type, gross_profit_usd, profit_margin_pct
FROM sum_site_performance
WHERE profit_rank_in_basin = 1
ORDER BY gross_profit_usd DESC;

-- 3. Loss-making sites over the whole period
SELECT site_id, site_name, country_or_region, site_type, total_revenue_usd, total_cost_usd, gross_profit_usd, profit_margin_pct
FROM sum_site_performance
WHERE gross_profit_usd < 0
ORDER BY gross_profit_usd;

-- 4. Capacity utilisation bands (annualised output vs stated capacity)
SELECT CASE WHEN capacity_utilisation_pct < 50 THEN '1: <50%' WHEN capacity_utilisation_pct < 80 THEN '2: 50-80%'
            WHEN capacity_utilisation_pct < 100 THEN '3: 80-100%' ELSE '4: over capacity' END AS utilisation_band,
       COUNT(*) AS sites, ROUND(AVG(profit_margin_pct), 2) AS avg_margin_pct
FROM sum_site_performance
GROUP BY CASE WHEN capacity_utilisation_pct < 50 THEN '1: <50%' WHEN capacity_utilisation_pct < 80 THEN '2: 50-80%'
              WHEN capacity_utilisation_pct < 100 THEN '3: 80-100%' ELSE '4: over capacity' END
ORDER BY utilisation_band;

-- 5. Risky sites: high environmental risk AND high mortality
SELECT sp.site_id, sp.site_name, sp.ocean_basin, s.environmental_risk_score, sp.avg_mortality_pct, sp.feed_conversion_ratio, sp.gross_profit_usd
FROM sum_site_performance sp
JOIN aquaculture_sites s ON sp.site_id = s.site_id
WHERE s.environmental_risk_score >= 40 AND sp.avg_mortality_pct >= 6
ORDER BY sp.avg_mortality_pct DESC
LIMIT 20;

-- 6. Sites with the best habitat fit for what they farm: join sites to the habitat cell at the same coordinates
SELECT s.site_id, s.site_name, h.suitability_class, h.suitability_score, h.suitable_species_id, sp.common_name AS best_species
FROM aquaculture_sites s
JOIN habitat_suitability h ON s.latitude = h.latitude AND s.longitude = h.longitude
LEFT JOIN marine_species sp ON h.suitable_species_id = sp.species_id
ORDER BY h.suitability_score DESC
LIMIT 20;
