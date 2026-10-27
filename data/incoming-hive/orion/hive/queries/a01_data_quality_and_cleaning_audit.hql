-- ORION | A01 Data quality + BEFORE/AFTER cleaning audit of ocean_conditions
USE orion;

-- 1. Row counts of every table
SELECT 'marine_species' AS tbl, COUNT(*) AS n FROM marine_species
UNION ALL SELECT 'species_occurrences', COUNT(*) FROM species_occurrences
UNION ALL SELECT 'aquaculture_sites', COUNT(*) FROM aquaculture_sites
UNION ALL SELECT 'habitat_suitability', COUNT(*) FROM habitat_suitability
UNION ALL SELECT 'species_environment_compat', COUNT(*) FROM species_environment_compat
UNION ALL SELECT 'fish_production', COUNT(*) FROM fish_production
UNION ALL SELECT 'finance_transactions', COUNT(*) FROM finance_transactions
UNION ALL SELECT 'resource_inventory', COUNT(*) FROM resource_inventory
UNION ALL SELECT 'dashboard_kpis', COUNT(*) FROM dashboard_kpis
UNION ALL SELECT 'ocean_conditions_raw', COUNT(*) FROM ocean_conditions_raw
UNION ALL SELECT 'ocean_conditions (cleaned)', COUNT(*) FROM ocean_conditions;

-- 2. Nulls per column BEFORE cleaning (raw) vs AFTER cleaning
SELECT 'raw' AS stage,
       SUM(CASE WHEN salinity_psu IS NULL THEN 1 ELSE 0 END)          AS null_salinity,
       SUM(CASE WHEN dissolved_oxygen_mg_l IS NULL THEN 1 ELSE 0 END) AS null_oxygen,
       SUM(CASE WHEN ph IS NULL THEN 1 ELSE 0 END)                    AS null_ph,
       SUM(CASE WHEN chlorophyll_a_mg_m3 IS NULL THEN 1 ELSE 0 END)   AS null_chlorophyll,
       SUM(CASE WHEN nitrate_umol_l IS NULL THEN 1 ELSE 0 END)        AS null_nitrate,
       SUM(CASE WHEN wave_height_m IS NULL THEN 1 ELSE 0 END)         AS null_wave,
       SUM(CASE WHEN current_speed_m_s IS NULL THEN 1 ELSE 0 END)     AS null_current
FROM ocean_conditions_raw
UNION ALL
SELECT 'cleaned',
       SUM(CASE WHEN salinity_psu IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN dissolved_oxygen_mg_l IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN ph IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN chlorophyll_a_mg_m3 IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN nitrate_umol_l IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN wave_height_m IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN current_speed_m_s IS NULL THEN 1 ELSE 0 END)
FROM ocean_conditions;

-- 3. How many cells did cleaning impute, per column, per ocean basin?
SELECT ocean_basin, COUNT(*) AS measurements,
       SUM(salinity_imputed) AS salinity, SUM(oxygen_imputed) AS oxygen, SUM(ph_imputed) AS ph,
       SUM(chlorophyll_imputed) AS chlorophyll, SUM(nitrate_imputed) AS nitrate,
       SUM(wave_imputed) AS wave, SUM(current_imputed) AS current_speed,
       SUM(salinity_imputed + oxygen_imputed + ph_imputed + chlorophyll_imputed + nitrate_imputed + wave_imputed + current_imputed) AS cells_imputed
FROM vw_ocean_imputation_audit
GROUP BY ocean_basin
ORDER BY cells_imputed DESC;

-- 4. Did cleaning change any value that was NOT null in raw?  (expect 0 in every column)
SELECT SUM(CASE WHEN r.ph IS NOT NULL AND r.ph <> c.ph THEN 1 ELSE 0 END)                         AS changed_ph,
       SUM(CASE WHEN r.salinity_psu IS NOT NULL AND r.salinity_psu <> c.salinity_psu THEN 1 ELSE 0 END) AS changed_salinity,
       SUM(CASE WHEN r.sea_surface_temperature_c <> c.sea_surface_temperature_c THEN 1 ELSE 0 END) AS changed_sst,
       SUM(CASE WHEN r.latitude <> c.latitude OR r.longitude <> c.longitude THEN 1 ELSE 0 END)     AS changed_coordinates
FROM ocean_conditions_raw r JOIN ocean_conditions c ON r.measurement_id = c.measurement_id;

-- 5. Effect of imputation on the averages (raw ignores nulls, cleaned includes the filled values)
SELECT 'raw' AS stage, ROUND(AVG(salinity_psu), 3) AS avg_salinity, ROUND(AVG(ph), 4) AS avg_ph,
       ROUND(AVG(dissolved_oxygen_mg_l), 3) AS avg_oxygen, ROUND(AVG(chlorophyll_a_mg_m3), 4) AS avg_chlorophyll
FROM ocean_conditions_raw
UNION ALL
SELECT 'cleaned', ROUND(AVG(salinity_psu), 3), ROUND(AVG(ph), 4), ROUND(AVG(dissolved_oxygen_mg_l), 3), ROUND(AVG(chlorophyll_a_mg_m3), 4)
FROM ocean_conditions;

-- 6. Foreign-key integrity (all counts should be 0)
SELECT 'production -> sites' AS check_name, COUNT(*) AS orphan_rows FROM fish_production f LEFT JOIN aquaculture_sites s ON f.site_id = s.site_id WHERE s.site_id IS NULL
UNION ALL SELECT 'production -> species', COUNT(*) FROM fish_production f LEFT JOIN marine_species m ON f.species_id = m.species_id WHERE m.species_id IS NULL
UNION ALL SELECT 'finance -> sites', COUNT(*) FROM finance_transactions t LEFT JOIN aquaculture_sites s ON t.site_id = s.site_id WHERE s.site_id IS NULL
UNION ALL SELECT 'finance -> production', COUNT(*) FROM finance_transactions t LEFT JOIN fish_production f ON t.related_production_id = f.production_id WHERE f.production_id IS NULL
UNION ALL SELECT 'habitat -> species', COUNT(*) FROM habitat_suitability h LEFT JOIN marine_species m ON h.suitable_species_id = m.species_id WHERE m.species_id IS NULL
UNION ALL SELECT 'compat -> habitat', COUNT(*) FROM species_environment_compat c LEFT JOIN habitat_suitability h ON c.habitat_id = h.habitat_id WHERE h.habitat_id IS NULL
UNION ALL SELECT 'inventory -> sites', COUNT(*) FROM resource_inventory r LEFT JOIN aquaculture_sites s ON r.site_id = s.site_id WHERE s.site_id IS NULL;

-- 7. Business-rule checks on production (all should be 0 except rows_loss_making, which is informational)
SELECT SUM(CASE WHEN ABS(survival_rate_percent + mortality_rate_percent - 100) > 0.01 THEN 1 ELSE 0 END) AS survival_mortality_not_100,
       SUM(CASE WHEN production_tonnes <= 0 THEN 1 ELSE 0 END)                                           AS non_positive_production,
       SUM(CASE WHEN revenue_usd < operating_cost_usd THEN 1 ELSE 0 END)                                 AS rows_loss_making,
       COUNT(*)                                                                                          AS rows_total
FROM fish_production;

-- 8. Sites that report production vs. site status (only Operational sites should produce)
SELECT s.site_status, COUNT(DISTINCT s.site_id) AS sites, COUNT(DISTINCT f.site_id) AS sites_with_production
FROM aquaculture_sites s LEFT JOIN fish_production f ON s.site_id = f.site_id
GROUP BY s.site_status ORDER BY sites DESC;

-- 9. Money reconciliation: production revenue/cost vs finance ledger (differences should be ~0)
SELECT ROUND(MAX(p.revenue) - SUM(CASE WHEN t.transaction_type = 'income'  THEN t.amount_usd ELSE 0 END), 2) AS revenue_diff_usd,
       ROUND(MAX(p.cost)    - SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount_usd ELSE 0 END), 2) AS cost_diff_usd
FROM finance_transactions t
CROSS JOIN (SELECT SUM(revenue_usd) AS revenue, SUM(operating_cost_usd) AS cost FROM fish_production) p;

-- 10. KPI table: site rows + company-wide 'ALL' rows at two grains. Every grain/scope slice must equal the production total.
SELECT k.kpi_grain, k.kpi_scope, COUNT(*) AS rows_, ROUND(SUM(k.total_production_tonnes), 2) AS tonnes,
       ROUND(MAX(p.t), 2) AS production_table_tonnes
FROM dashboard_kpis k
CROSS JOIN (SELECT SUM(production_tonnes) AS t FROM fish_production) p
GROUP BY k.kpi_grain, k.kpi_scope
ORDER BY k.kpi_grain, k.kpi_scope;

-- 11. Synthetic flags: every record should be marked synthetic
SELECT 'ocean_conditions' AS tbl, SUM(CASE WHEN is_synthetic THEN 0 ELSE 1 END) AS not_flagged FROM ocean_conditions
UNION ALL SELECT 'aquaculture_sites', SUM(CASE WHEN is_synthetic THEN 0 ELSE 1 END) FROM aquaculture_sites
UNION ALL SELECT 'habitat_suitability', SUM(CASE WHEN is_synthetic THEN 0 ELSE 1 END) FROM habitat_suitability
UNION ALL SELECT 'species_occurrences', SUM(CASE WHEN is_synthetic THEN 0 ELSE 1 END) FROM species_occurrences;
