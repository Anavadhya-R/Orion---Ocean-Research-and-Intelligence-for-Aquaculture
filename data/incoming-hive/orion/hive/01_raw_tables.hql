-- =============================================================================
-- ORION | Hive layer 1: RAW (landing) tables                  (branch: feature/hive-analytics)
--
-- One EXTERNAL table per CSV produced by data/prepare_csv.py, read from /user/orion/raw/<table>/.
--   * OpenCSVSerde handles quoted text containing commas (species_description, explanation)
--   * every column is STRING: typing and cleaning happen in 02_clean_tables.hql; raw is never edited
--   * ocean_conditions_raw = data BEFORE cleaning, ocean_conditions_cleaned = AFTER cleaning (from cleaneddata.zip)
-- Run:  hive -f hive/01_raw_tables.hql
-- =============================================================================

USE orion;

DROP TABLE IF EXISTS raw_marine_species;
CREATE EXTERNAL TABLE raw_marine_species (
  `species_id` STRING,
  `scientific_name` STRING,
  `common_name` STRING,
  `species_group` STRING,
  `habitat_type` STRING,
  `trophic_level` STRING,
  `min_temperature_c` STRING,
  `max_temperature_c` STRING,
  `min_salinity_psu` STRING,
  `max_salinity_psu` STRING,
  `min_depth_m` STRING,
  `max_depth_m` STRING,
  `conservation_status` STRING,
  `aquaculture_potential` STRING,
  `species_description` STRING,
  `image_url` STRING,
  `data_origin` STRING,
  `image_search_query` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/marine_species'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_species_occurrences;
CREATE EXTERNAL TABLE raw_species_occurrences (
  `occurrence_id` STRING,
  `species_id` STRING,
  `latitude` STRING,
  `longitude` STRING,
  `observation_date` STRING,
  `depth_m` STRING,
  `water_temperature_c` STRING,
  `salinity_psu` STRING,
  `dissolved_oxygen_mg_l` STRING,
  `ocean_basin` STRING,
  `location_name` STRING,
  `observation_source` STRING,
  `is_synthetic` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/species_occurrences'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_aquaculture_sites;
CREATE EXTERNAL TABLE raw_aquaculture_sites (
  `site_id` STRING,
  `site_name` STRING,
  `latitude` STRING,
  `longitude` STRING,
  `country_or_region` STRING,
  `ocean_basin` STRING,
  `site_type` STRING,
  `farm_area_hectares` STRING,
  `water_depth_m` STRING,
  `average_temperature_c` STRING,
  `average_salinity_psu` STRING,
  `average_dissolved_oxygen_mg_l` STRING,
  `water_quality_index` STRING,
  `infrastructure_access_score` STRING,
  `environmental_risk_score` STRING,
  `estimated_production_capacity_tonnes_year` STRING,
  `site_status` STRING,
  `is_synthetic` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/aquaculture_sites'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_habitat_suitability;
CREATE EXTERNAL TABLE raw_habitat_suitability (
  `habitat_id` STRING,
  `latitude` STRING,
  `longitude` STRING,
  `ocean_basin` STRING,
  `temperature_c` STRING,
  `salinity_psu` STRING,
  `dissolved_oxygen_mg_l` STRING,
  `ph` STRING,
  `depth_m` STRING,
  `chlorophyll_a_mg_m3` STRING,
  `wave_height_m` STRING,
  `water_quality_score` STRING,
  `environmental_risk_score` STRING,
  `suitable_species_id` STRING,
  `suitability_score` STRING,
  `suitability_class` STRING,
  `cluster_id` STRING,
  `is_synthetic` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/habitat_suitability'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_species_environment_compat;
CREATE EXTERNAL TABLE raw_species_environment_compat (
  `compatibility_id` STRING,
  `species_id` STRING,
  `habitat_id` STRING,
  `temperature_compatibility_score` STRING,
  `salinity_compatibility_score` STRING,
  `oxygen_compatibility_score` STRING,
  `depth_compatibility_score` STRING,
  `overall_compatibility_score` STRING,
  `compatibility_class` STRING,
  `explanation` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/species_environment_compat'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_fish_production;
CREATE EXTERNAL TABLE raw_fish_production (
  `production_id` STRING,
  `site_id` STRING,
  `species_id` STRING,
  `reporting_year` STRING,
  `reporting_month` STRING,
  `production_tonnes` STRING,
  `feed_consumption_tonnes` STRING,
  `feed_conversion_ratio` STRING,
  `mortality_rate_percent` STRING,
  `survival_rate_percent` STRING,
  `operating_cost_usd` STRING,
  `revenue_usd` STRING,
  `data_origin` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/fish_production'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_finance_transactions;
CREATE EXTERNAL TABLE raw_finance_transactions (
  `transaction_id` STRING,
  `site_id` STRING,
  `transaction_date` STRING,
  `transaction_type` STRING,
  `category` STRING,
  `description` STRING,
  `amount_usd` STRING,
  `payment_method` STRING,
  `related_production_id` STRING,
  `is_simulated` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/finance_transactions'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_resource_inventory;
CREATE EXTERNAL TABLE raw_resource_inventory (
  `resource_id` STRING,
  `site_id` STRING,
  `resource_name` STRING,
  `resource_category` STRING,
  `quantity_available` STRING,
  `unit` STRING,
  `reorder_threshold` STRING,
  `unit_cost_usd` STRING,
  `supplier_name` STRING,
  `last_restock_date` STRING,
  `resource_status` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/resource_inventory'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_dashboard_kpis;
CREATE EXTERNAL TABLE raw_dashboard_kpis (
  `kpi_id` STRING,
  `period_start` STRING,
  `period_end` STRING,
  `site_id` STRING,
  `total_production_tonnes` STRING,
  `total_revenue_usd` STRING,
  `total_expenses_usd` STRING,
  `net_profit_usd` STRING,
  `average_mortality_rate_percent` STRING,
  `average_water_quality_score` STRING,
  `average_habitat_suitability_score` STRING,
  `low_inventory_item_count` STRING,
  `active_site_count` STRING,
  `data_origin` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/dashboard_kpis'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_ocean_conditions_raw;
CREATE EXTERNAL TABLE raw_ocean_conditions_raw (
  `measurement_id` STRING,
  `latitude` STRING,
  `longitude` STRING,
  `measurement_date` STRING,
  `ocean_basin` STRING,
  `depth_m` STRING,
  `sea_surface_temperature_c` STRING,
  `water_temperature_c` STRING,
  `salinity_psu` STRING,
  `dissolved_oxygen_mg_l` STRING,
  `ph` STRING,
  `chlorophyll_a_mg_m3` STRING,
  `nitrate_umol_l` STRING,
  `wave_height_m` STRING,
  `current_speed_m_s` STRING,
  `is_synthetic` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/ocean_conditions_raw'
TBLPROPERTIES ('skip.header.line.count' = '1');

DROP TABLE IF EXISTS raw_ocean_conditions_cleaned;
CREATE EXTERNAL TABLE raw_ocean_conditions_cleaned (
  `measurement_id` STRING,
  `latitude` STRING,
  `longitude` STRING,
  `measurement_date` STRING,
  `ocean_basin` STRING,
  `depth_m` STRING,
  `sea_surface_temperature_c` STRING,
  `water_temperature_c` STRING,
  `salinity_psu` STRING,
  `dissolved_oxygen_mg_l` STRING,
  `ph` STRING,
  `chlorophyll_a_mg_m3` STRING,
  `nitrate_umol_l` STRING,
  `wave_height_m` STRING,
  `current_speed_m_s` STRING,
  `is_synthetic` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',', 'quoteChar' = '"', 'escapeChar' = '\\')
STORED AS TEXTFILE
LOCATION '/user/orion/raw/ocean_conditions_cleaned'
TBLPROPERTIES ('skip.header.line.count' = '1');
