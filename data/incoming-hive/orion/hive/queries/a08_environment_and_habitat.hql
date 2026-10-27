-- ORION | A08 Ocean environment, habitat suitability and species compatibility
USE orion;

-- 1. Basin conditions (cleaned data) across the whole period
SELECT ocean_basin, SUM(measurements) AS measurements, ROUND(AVG(avg_sst_c), 2) AS sst_c, ROUND(AVG(avg_salinity_psu), 2) AS salinity,
       ROUND(AVG(avg_dissolved_oxygen_mg_l), 2) AS oxygen, ROUND(AVG(avg_ph), 3) AS ph, ROUND(AVG(avg_chlorophyll_mg_m3), 3) AS chlorophyll
FROM sum_ocean_basin_month
GROUP BY ocean_basin
ORDER BY sst_c DESC;

-- 2. Seasonal SST swing per basin (max - min of monthly averages)
SELECT ocean_basin, ROUND(MAX(avg_sst_c) - MIN(avg_sst_c), 2) AS sst_swing_c, ROUND(MIN(avg_sst_c), 2) AS coldest_month_c, ROUND(MAX(avg_sst_c), 2) AS warmest_month_c
FROM sum_ocean_basin_month
GROUP BY ocean_basin
ORDER BY sst_swing_c DESC;

-- 3. Year-on-year change in SST, pH and oxygen per basin (2024 vs 2022 baseline)
SELECT ocean_basin,
       ROUND(AVG(CASE WHEN obs_year = 2024 THEN avg_sst_c END) - AVG(CASE WHEN obs_year = 2022 THEN avg_sst_c END), 3) AS sst_change_c,
       ROUND(AVG(CASE WHEN obs_year = 2024 THEN avg_ph END) - AVG(CASE WHEN obs_year = 2022 THEN avg_ph END), 4)       AS ph_change,
       ROUND(AVG(CASE WHEN obs_year = 2024 THEN avg_dissolved_oxygen_mg_l END) - AVG(CASE WHEN obs_year = 2022 THEN avg_dissolved_oxygen_mg_l END), 3) AS oxygen_change
FROM sum_ocean_basin_month
GROUP BY ocean_basin
ORDER BY ocean_basin;

-- 4. Depth bands: how conditions change with depth
SELECT CASE WHEN depth_m < 50 THEN '0-50 m' WHEN depth_m < 200 THEN '50-200 m' WHEN depth_m < 1000 THEN '200-1000 m' ELSE '1000 m+' END AS depth_band,
       COUNT(*) AS measurements, ROUND(AVG(water_temperature_c), 2) AS avg_temp_c, ROUND(AVG(salinity_psu), 2) AS avg_salinity,
       ROUND(AVG(dissolved_oxygen_mg_l), 2) AS avg_oxygen
FROM ocean_conditions
GROUP BY CASE WHEN depth_m < 50 THEN '0-50 m' WHEN depth_m < 200 THEN '50-200 m' WHEN depth_m < 1000 THEN '200-1000 m' ELSE '1000 m+' END
ORDER BY depth_band;

-- 5. Basins with the highest share of high / very high suitability habitat
SELECT ocean_basin,
       SUM(habitat_cells) AS cells,
       ROUND(SUM(CASE WHEN suitability_class IN ('High', 'Very High') THEN pct_of_basin ELSE 0 END), 1) AS pct_high_or_very_high
FROM sum_habitat_by_basin
GROUP BY ocean_basin
ORDER BY pct_high_or_very_high DESC;

-- 6. Species that fit the most habitat cells (compatibility Excellent or Good)
SELECT c.species_id, m.common_name, m.species_group, COUNT(*) AS good_matches, ROUND(AVG(c.overall_compatibility_score), 1) AS avg_score
FROM species_environment_compat c
JOIN marine_species m ON c.species_id = m.species_id
WHERE c.compatibility_class IN ('Excellent', 'Good')
GROUP BY c.species_id, m.common_name, m.species_group
ORDER BY good_matches DESC
LIMIT 15;

-- 7. Which compatibility factor limits a match most often? (average sub-scores of Poor matches)
SELECT compatibility_class, COUNT(*) AS pairs,
       ROUND(AVG(temperature_compatibility_score), 1) AS temp, ROUND(AVG(salinity_compatibility_score), 1) AS salinity,
       ROUND(AVG(oxygen_compatibility_score), 1) AS oxygen, ROUND(AVG(depth_compatibility_score), 1) AS depth
FROM species_environment_compat
GROUP BY compatibility_class
ORDER BY pairs DESC;

-- 8. Where are the species observed? Occurrences per basin and species group
SELECT o.ocean_basin, m.species_group, COUNT(*) AS occurrences
FROM species_occurrences o JOIN marine_species m ON o.species_id = m.species_id
GROUP BY o.ocean_basin, m.species_group
ORDER BY o.ocean_basin, occurrences DESC;

-- 9. Habitat clusters (cluster_id from the ML step): profile of each cluster
SELECT cluster_id, COUNT(*) AS cells, ROUND(AVG(temperature_c), 2) AS temp_c, ROUND(AVG(salinity_psu), 2) AS salinity,
       ROUND(AVG(dissolved_oxygen_mg_l), 2) AS oxygen, ROUND(AVG(suitability_score), 1) AS suitability, ROUND(AVG(environmental_risk_score), 1) AS risk
FROM habitat_suitability
GROUP BY cluster_id
ORDER BY cluster_id;
