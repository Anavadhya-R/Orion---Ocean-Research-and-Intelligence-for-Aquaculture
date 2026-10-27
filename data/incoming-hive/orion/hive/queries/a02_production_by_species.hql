-- ORION | A02 Production by species
USE orion;

-- 1. Top 15 species by total tonnes, with share of total and profit
SELECT tonnes_rank, common_name, species_group, aquaculture_potential, sites_farming, total_tonnes, pct_of_total_tonnes,
       total_revenue_usd, gross_profit_usd, profit_margin_pct, feed_conversion_ratio, avg_mortality_pct
FROM sum_species_ranking
WHERE tonnes_rank <= 15
ORDER BY tonnes_rank;

-- 2. Species group totals per year with growth (2024 vs 2023)
SELECT species_group, reporting_year, SUM(total_tonnes) AS tonnes, SUM(total_revenue_usd) AS revenue_usd,
       SUM(gross_profit_usd) AS profit_usd
FROM sum_production_by_species_year
GROUP BY species_group, reporting_year
ORDER BY species_group, reporting_year;

SELECT g.species_group,
       ROUND(SUM(CASE WHEN g.reporting_year = 2023 THEN g.total_tonnes END), 1) AS tonnes_2023,
       ROUND(SUM(CASE WHEN g.reporting_year = 2024 THEN g.total_tonnes END), 1) AS tonnes_2024,
       ROUND((SUM(CASE WHEN g.reporting_year = 2024 THEN g.total_tonnes END)
            / SUM(CASE WHEN g.reporting_year = 2023 THEN g.total_tonnes END) - 1) * 100, 2) AS growth_pct
FROM sum_production_by_species_year g
GROUP BY g.species_group
HAVING SUM(CASE WHEN g.reporting_year = 2023 THEN g.total_tonnes END) > 0
ORDER BY growth_pct DESC;

-- 3. Fastest growing / shrinking species (2024 vs 2023, species with >= 500 t in 2023)
SELECT common_name, species_group, prev_year_tonnes AS tonnes_2023, total_tonnes AS tonnes_2024, tonnes_yoy_pct
FROM sum_production_by_species_year
WHERE reporting_year = 2024 AND prev_year_tonnes >= 500
ORDER BY tonnes_yoy_pct DESC
LIMIT 15;

-- 4. Most and least profitable species by margin (min 1,000 t)
SELECT common_name, species_group, total_tonnes, gross_profit_usd, profit_margin_pct, margin_rank
FROM sum_species_ranking
WHERE total_tonnes >= 1000
ORDER BY profit_margin_pct DESC
LIMIT 15;

-- 5. Feed efficiency: best (lowest) feed conversion ratio among FED species with >= 500 t
--    (algae and filter-feeding molluscs use no feed: FCR = 0 and they are excluded here, not "perfect")
SELECT common_name, species_group, total_tonnes, feed_conversion_ratio, avg_mortality_pct
FROM sum_species_ranking
WHERE total_tonnes >= 500 AND feed_conversion_ratio > 0
ORDER BY feed_conversion_ratio
LIMIT 15;

-- 6. Does the catalogue's "aquaculture_potential" label predict real output? (simulated judgement vs simulated production)
SELECT aquaculture_potential, COUNT(*) AS species_farmed, ROUND(SUM(total_tonnes), 0) AS tonnes,
       ROUND(AVG(profit_margin_pct), 2) AS avg_margin_pct, ROUND(AVG(avg_mortality_pct), 2) AS avg_mortality_pct
FROM sum_species_ranking
GROUP BY aquaculture_potential
ORDER BY tonnes DESC;

-- 7. Catalogue species that are never farmed (opportunity list): high potential but no production record
SELECT m.species_id, m.common_name, m.species_group, m.aquaculture_potential
FROM marine_species m
LEFT JOIN (SELECT DISTINCT species_id FROM fish_production) f ON m.species_id = f.species_id
WHERE f.species_id IS NULL AND m.aquaculture_potential IN ('High', 'Medium')
ORDER BY m.aquaculture_potential, m.common_name;

-- 8. Conservation status of farmed species (IUCN-style code, approximate)
SELECT m.conservation_status, COUNT(DISTINCT p.species_id) AS species_farmed, ROUND(SUM(p.production_tonnes), 0) AS tonnes
FROM fish_production p JOIN marine_species m ON p.species_id = m.species_id
GROUP BY m.conservation_status
ORDER BY tonnes DESC;
