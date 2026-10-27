-- =============================================================================
-- ORION | Hive layer 2: CLEAN tables (typed ORC)               (branch: feature/hive-analytics)
--
-- Reads raw_* (all STRING) -> typed ORC tables (the "cleaned aquaculture datasets").
-- Rules: empty string -> NULL, text trimmed, numbers/dates cast, booleans parsed with
--        LOWER(x) = 'true' (CAST(text AS BOOLEAN) is unreliable in Hive).
-- Partitioned: fish_production (reporting_year), finance_transactions (txn_year), ocean_conditions (obs_year).
-- Dropped: marine_species.image_url (100 % empty). Renamed: measurement_date -> obs_date,
--          transaction_date -> txn_date, observation_date -> obs_date.
-- =============================================================================

USE orion;
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

-- ------------------------------------------------------------------ species
DROP TABLE IF EXISTS marine_species;
CREATE TABLE marine_species STORED AS ORC AS
SELECT TRIM(species_id) AS species_id, TRIM(scientific_name) AS scientific_name, TRIM(common_name) AS common_name,
       TRIM(species_group) AS species_group, TRIM(habitat_type) AS habitat_type,
       CAST(trophic_level AS DOUBLE) AS trophic_level,
       CAST(min_temperature_c AS DOUBLE) AS min_temperature_c, CAST(max_temperature_c AS DOUBLE) AS max_temperature_c,
       CAST(min_salinity_psu AS DOUBLE) AS min_salinity_psu,    CAST(max_salinity_psu AS DOUBLE) AS max_salinity_psu,
       CAST(min_depth_m AS DOUBLE) AS min_depth_m,              CAST(max_depth_m AS DOUBLE) AS max_depth_m,
       TRIM(conservation_status) AS conservation_status, TRIM(aquaculture_potential) AS aquaculture_potential,
       TRIM(species_description) AS species_description, TRIM(data_origin) AS data_origin,
       TRIM(image_search_query) AS image_search_query
FROM raw_marine_species;

DROP TABLE IF EXISTS species_occurrences;
CREATE TABLE species_occurrences STORED AS ORC AS
SELECT TRIM(occurrence_id) AS occurrence_id, TRIM(species_id) AS species_id,
       CAST(latitude AS DOUBLE) AS latitude, CAST(longitude AS DOUBLE) AS longitude,
       CAST(observation_date AS DATE) AS obs_date, YEAR(CAST(observation_date AS DATE)) AS obs_year,
       CAST(depth_m AS DOUBLE) AS depth_m, CAST(water_temperature_c AS DOUBLE) AS water_temperature_c,
       CAST(salinity_psu AS DOUBLE) AS salinity_psu, CAST(dissolved_oxygen_mg_l AS DOUBLE) AS dissolved_oxygen_mg_l,
       TRIM(ocean_basin) AS ocean_basin, TRIM(location_name) AS location_name,
       TRIM(observation_source) AS observation_source, (LOWER(TRIM(is_synthetic)) = 'true') AS is_synthetic
FROM raw_species_occurrences;

-- -------------------------------------------------------------------- sites
DROP TABLE IF EXISTS aquaculture_sites;
CREATE TABLE aquaculture_sites STORED AS ORC AS
SELECT TRIM(site_id) AS site_id, TRIM(site_name) AS site_name,
       CAST(latitude AS DOUBLE) AS latitude, CAST(longitude AS DOUBLE) AS longitude,
       TRIM(country_or_region) AS country_or_region, TRIM(ocean_basin) AS ocean_basin, TRIM(site_type) AS site_type,
       CAST(farm_area_hectares AS DOUBLE) AS farm_area_hectares, CAST(water_depth_m AS DOUBLE) AS water_depth_m,
       CAST(average_temperature_c AS DOUBLE) AS average_temperature_c,
       CAST(average_salinity_psu AS DOUBLE) AS average_salinity_psu,
       CAST(average_dissolved_oxygen_mg_l AS DOUBLE) AS average_dissolved_oxygen_mg_l,
       CAST(water_quality_index AS DOUBLE) AS water_quality_index,
       CAST(infrastructure_access_score AS DOUBLE) AS infrastructure_access_score,
       CAST(environmental_risk_score AS DOUBLE) AS environmental_risk_score,
       CAST(estimated_production_capacity_tonnes_year AS DOUBLE) AS capacity_tonnes_year,
       TRIM(site_status) AS site_status, (LOWER(TRIM(is_synthetic)) = 'true') AS is_synthetic
FROM raw_aquaculture_sites;

DROP TABLE IF EXISTS habitat_suitability;
CREATE TABLE habitat_suitability STORED AS ORC AS
SELECT TRIM(habitat_id) AS habitat_id, CAST(latitude AS DOUBLE) AS latitude, CAST(longitude AS DOUBLE) AS longitude,
       TRIM(ocean_basin) AS ocean_basin, CAST(temperature_c AS DOUBLE) AS temperature_c,
       CAST(salinity_psu AS DOUBLE) AS salinity_psu, CAST(dissolved_oxygen_mg_l AS DOUBLE) AS dissolved_oxygen_mg_l,
       CAST(ph AS DOUBLE) AS ph, CAST(depth_m AS DOUBLE) AS depth_m, CAST(chlorophyll_a_mg_m3 AS DOUBLE) AS chlorophyll_a_mg_m3,
       CAST(wave_height_m AS DOUBLE) AS wave_height_m, CAST(water_quality_score AS DOUBLE) AS water_quality_score,
       CAST(environmental_risk_score AS DOUBLE) AS environmental_risk_score,
       TRIM(suitable_species_id) AS suitable_species_id, CAST(suitability_score AS DOUBLE) AS suitability_score,
       TRIM(suitability_class) AS suitability_class, CAST(cluster_id AS INT) AS cluster_id,
       (LOWER(TRIM(is_synthetic)) = 'true') AS is_synthetic
FROM raw_habitat_suitability;

DROP TABLE IF EXISTS species_environment_compat;
CREATE TABLE species_environment_compat STORED AS ORC AS
SELECT TRIM(compatibility_id) AS compatibility_id, TRIM(species_id) AS species_id, TRIM(habitat_id) AS habitat_id,
       CAST(temperature_compatibility_score AS DOUBLE) AS temperature_compatibility_score,
       CAST(salinity_compatibility_score AS DOUBLE) AS salinity_compatibility_score,
       CAST(oxygen_compatibility_score AS DOUBLE) AS oxygen_compatibility_score,
       CAST(depth_compatibility_score AS DOUBLE) AS depth_compatibility_score,
       CAST(overall_compatibility_score AS DOUBLE) AS overall_compatibility_score,
       TRIM(compatibility_class) AS compatibility_class, TRIM(explanation) AS explanation
FROM raw_species_environment_compat;

-- --------------------------------------------------------------- production
DROP TABLE IF EXISTS fish_production;
CREATE TABLE fish_production (
  production_id STRING, site_id STRING, species_id STRING, reporting_month INT,
  production_tonnes DOUBLE, feed_consumption_tonnes DOUBLE, feed_conversion_ratio DOUBLE,
  mortality_rate_percent DOUBLE, survival_rate_percent DOUBLE,
  operating_cost_usd DOUBLE, revenue_usd DOUBLE, data_origin STRING
)
PARTITIONED BY (reporting_year INT)
STORED AS ORC;

INSERT OVERWRITE TABLE fish_production PARTITION (reporting_year)
SELECT TRIM(production_id), TRIM(site_id), TRIM(species_id), CAST(reporting_month AS INT),
       CAST(production_tonnes AS DOUBLE), CAST(feed_consumption_tonnes AS DOUBLE), CAST(feed_conversion_ratio AS DOUBLE),
       CAST(mortality_rate_percent AS DOUBLE), CAST(survival_rate_percent AS DOUBLE),
       CAST(operating_cost_usd AS DOUBLE), CAST(revenue_usd AS DOUBLE), TRIM(data_origin),
       CAST(reporting_year AS INT)
FROM raw_fish_production
WHERE reporting_year RLIKE '^[0-9]{4}$';

DROP TABLE IF EXISTS finance_transactions;
CREATE TABLE finance_transactions (
  transaction_id STRING, site_id STRING, txn_date DATE, txn_month INT, transaction_type STRING,
  category STRING, description STRING, amount_usd DOUBLE, payment_method STRING,
  related_production_id STRING, is_simulated BOOLEAN
)
PARTITIONED BY (txn_year INT)
STORED AS ORC;

INSERT OVERWRITE TABLE finance_transactions PARTITION (txn_year)
SELECT TRIM(transaction_id), TRIM(site_id), CAST(transaction_date AS DATE), MONTH(CAST(transaction_date AS DATE)),
       TRIM(transaction_type), TRIM(category), TRIM(description), CAST(amount_usd AS DOUBLE), TRIM(payment_method),
       NULLIF(TRIM(related_production_id), ''), (LOWER(TRIM(is_simulated)) = 'true'),
       YEAR(CAST(transaction_date AS DATE))
FROM raw_finance_transactions;

DROP TABLE IF EXISTS resource_inventory;
CREATE TABLE resource_inventory STORED AS ORC AS
SELECT TRIM(resource_id) AS resource_id, TRIM(site_id) AS site_id, TRIM(resource_name) AS resource_name,
       TRIM(resource_category) AS resource_category, CAST(quantity_available AS DOUBLE) AS quantity_available,
       TRIM(unit) AS unit, CAST(reorder_threshold AS DOUBLE) AS reorder_threshold, CAST(unit_cost_usd AS DOUBLE) AS unit_cost_usd,
       TRIM(supplier_name) AS supplier_name, CAST(last_restock_date AS DATE) AS last_restock_date,
       TRIM(resource_status) AS resource_status
FROM raw_resource_inventory;

-- The source table mixes THREE kinds of rows: site x month (KPI-M-S...), site x year (KPI-Y-S...) and
-- company-wide totals with site_id = 'ALL' (KPI-M-ALL..., KPI-Y-ALL...). Summing everything counts each tonne 4 times.
-- kpi_grain = monthly | yearly, kpi_scope = site | all  -> ALWAYS filter on both (views below do it for you).
DROP TABLE IF EXISTS dashboard_kpis;
CREATE TABLE dashboard_kpis STORED AS ORC AS
SELECT TRIM(kpi_id) AS kpi_id,
       CASE WHEN kpi_id LIKE 'KPI-M-%' THEN 'monthly' WHEN kpi_id LIKE 'KPI-Y-%' THEN 'yearly' ELSE 'other' END AS kpi_grain,
       CASE WHEN TRIM(site_id) = 'ALL' THEN 'all' ELSE 'site' END AS kpi_scope,
       CAST(period_start AS DATE) AS period_start, CAST(period_end AS DATE) AS period_end, TRIM(site_id) AS site_id,
       CAST(total_production_tonnes AS DOUBLE) AS total_production_tonnes,
       CAST(total_revenue_usd AS DOUBLE) AS total_revenue_usd, CAST(total_expenses_usd AS DOUBLE) AS total_expenses_usd,
       CAST(net_profit_usd AS DOUBLE) AS net_profit_usd,
       CAST(average_mortality_rate_percent AS DOUBLE) AS average_mortality_rate_percent,
       CAST(average_water_quality_score AS DOUBLE) AS average_water_quality_score,
       CAST(average_habitat_suitability_score AS DOUBLE) AS average_habitat_suitability_score,
       CAST(low_inventory_item_count AS INT) AS low_inventory_item_count,
       CAST(active_site_count AS INT) AS active_site_count, TRIM(data_origin) AS data_origin
FROM raw_dashboard_kpis;

-- ------------------------------------------------------------ ocean conditions
-- BEFORE cleaning (nulls kept) - used only for the cleaning audit
DROP TABLE IF EXISTS ocean_conditions_raw;
CREATE TABLE ocean_conditions_raw STORED AS ORC AS
SELECT TRIM(measurement_id) AS measurement_id, CAST(latitude AS DOUBLE) AS latitude, CAST(longitude AS DOUBLE) AS longitude,
       CAST(measurement_date AS DATE) AS obs_date, TRIM(ocean_basin) AS ocean_basin, CAST(depth_m AS DOUBLE) AS depth_m,
       CAST(sea_surface_temperature_c AS DOUBLE) AS sea_surface_temperature_c, CAST(water_temperature_c AS DOUBLE) AS water_temperature_c,
       CAST(salinity_psu AS DOUBLE) AS salinity_psu, CAST(dissolved_oxygen_mg_l AS DOUBLE) AS dissolved_oxygen_mg_l,
       CAST(ph AS DOUBLE) AS ph, CAST(chlorophyll_a_mg_m3 AS DOUBLE) AS chlorophyll_a_mg_m3,
       CAST(nitrate_umol_l AS DOUBLE) AS nitrate_umol_l, CAST(wave_height_m AS DOUBLE) AS wave_height_m,
       CAST(current_speed_m_s AS DOUBLE) AS current_speed_m_s
FROM raw_ocean_conditions_raw;

-- AFTER cleaning (nulls imputed) - the table used by all analysis
DROP TABLE IF EXISTS ocean_conditions;
CREATE TABLE ocean_conditions (
  measurement_id STRING, latitude DOUBLE, longitude DOUBLE, obs_date DATE, obs_month INT, ocean_basin STRING, depth_m DOUBLE,
  sea_surface_temperature_c DOUBLE, water_temperature_c DOUBLE, salinity_psu DOUBLE, dissolved_oxygen_mg_l DOUBLE,
  ph DOUBLE, chlorophyll_a_mg_m3 DOUBLE, nitrate_umol_l DOUBLE, wave_height_m DOUBLE, current_speed_m_s DOUBLE,
  is_synthetic BOOLEAN
)
PARTITIONED BY (obs_year INT)
STORED AS ORC;

INSERT OVERWRITE TABLE ocean_conditions PARTITION (obs_year)
SELECT TRIM(measurement_id), CAST(latitude AS DOUBLE), CAST(longitude AS DOUBLE), CAST(measurement_date AS DATE),
       MONTH(CAST(measurement_date AS DATE)), TRIM(ocean_basin), CAST(depth_m AS DOUBLE),
       CAST(sea_surface_temperature_c AS DOUBLE), CAST(water_temperature_c AS DOUBLE), CAST(salinity_psu AS DOUBLE),
       CAST(dissolved_oxygen_mg_l AS DOUBLE), CAST(ph AS DOUBLE), CAST(chlorophyll_a_mg_m3 AS DOUBLE),
       CAST(nitrate_umol_l AS DOUBLE), CAST(wave_height_m AS DOUBLE), CAST(current_speed_m_s AS DOUBLE),
       (LOWER(TRIM(is_synthetic)) = 'true'), YEAR(CAST(measurement_date AS DATE))
FROM raw_ocean_conditions_cleaned;

ANALYZE TABLE fish_production PARTITION (reporting_year) COMPUTE STATISTICS;
ANALYZE TABLE finance_transactions PARTITION (txn_year) COMPUTE STATISTICS;
ANALYZE TABLE ocean_conditions PARTITION (obs_year) COMPUTE STATISTICS;
