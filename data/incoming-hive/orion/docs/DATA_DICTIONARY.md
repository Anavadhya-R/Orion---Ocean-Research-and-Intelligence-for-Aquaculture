# ORION - Hive data dictionary

Database `orion`. **All data is synthetic/simulated** (every table carries an `is_synthetic` / `data_origin` flag or `SIMULATED` label).
Raw tables `raw_*` mirror the CSV files with every column as STRING and are not repeated here.
Machine-readable copy: `data_dictionary_hive.csv` (import into Power BI as a documentation table).


## `marine_species`  _(clean table)_
Species catalogue: tolerances, group, aquaculture potential (simulated, approximate)

| Column | Type | Unit | Description |
|---|---|---|---|
| `species_id` | STRING |  | Unique species key (SP###) |
| `scientific_name` | STRING |  | Latin binomial (real taxon; ranges approximate) |
| `common_name` | STRING |  | English common name |
| `species_group` | STRING |  | Taxonomic/functional group |
| `habitat_type` | STRING |  | coastal / reef / estuary / pelagic / deep_sea / polar |
| `trophic_level` | DOUBLE |  | Approximate trophic level |
| `min_temperature_c` | DOUBLE | degC | Lower tolerated water temperature (approximate) |
| `max_temperature_c` | DOUBLE | degC | Upper tolerated water temperature (approximate) |
| `min_salinity_psu` | DOUBLE | PSU | Lower tolerated salinity |
| `max_salinity_psu` | DOUBLE | PSU | Upper tolerated salinity |
| `min_depth_m` | DOUBLE | m | Shallowest typical depth |
| `max_depth_m` | DOUBLE | m | Deepest typical depth |
| `conservation_status` | STRING |  | IUCN-style code (LC NT VU EN CR DD NE); approximate, verify before citing |
| `aquaculture_potential` | STRING |  | Not_suitable / Low / Medium / High (simulated judgement) |
| `species_description` | STRING |  | Auto-generated short description |
| `data_origin` | STRING |  | Provenance label (all simulated / approximate) |
| `image_search_query` | STRING |  | Query to find a photo manually |

## `species_occurrences`  _(clean table)_
Simulated sighting points for the map

| Column | Type | Unit | Description |
|---|---|---|---|
| `occurrence_id` | STRING |  | Unique occurrence key |
| `species_id` | STRING |  | Unique species key (SP###) |
| `latitude` | DOUBLE | degrees | WGS84 latitude, decimal degrees (-90..90) |
| `longitude` | DOUBLE | degrees | WGS84 longitude, decimal degrees (-180..180) |
| `obs_date` | DATE |  | Simulated observation date (ISO) |
| `depth_m` | DOUBLE | m | Depth below surface |
| `water_temperature_c` | DOUBLE | degC | Water temperature at the stated depth |
| `salinity_psu` | DOUBLE | PSU | Practical salinity |
| `dissolved_oxygen_mg_l` | DOUBLE | mg/L | Dissolved oxygen concentration |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `location_name` | STRING |  | Simulation region name |
| `observation_source` | STRING |  | SIMULATED_* source label |
| `is_synthetic` | BOOLEAN |  | Always true: record is simulated |
| `obs_year` | INT |  | Partition column / derived: year of obs_date |

## `aquaculture_sites`  _(clean table)_
1,000 simulated farms: location, type, status, capacity, quality/risk scores

| Column | Type | Unit | Description |
|---|---|---|---|
| `site_id` | STRING |  | Unique site key (S####); 'ALL' in dashboard_kpis portfolio rows |
| `site_name` | STRING |  | Simulated site name (prefixed SIM) |
| `latitude` | DOUBLE | degrees | WGS84 latitude, decimal degrees (-90..90) |
| `longitude` | DOUBLE | degrees | WGS84 longitude, decimal degrees (-180..180) |
| `country_or_region` | STRING |  | Country/region label of the simulation region |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `site_type` | STRING |  | marine_cage / earthen_pond / longline_raft / land_based_ras / onshore_raceway |
| `farm_area_hectares` | DOUBLE | ha | Simulated farm area |
| `water_depth_m` | DOUBLE | m | Local water depth at site |
| `average_temperature_c` | DOUBLE | degC | Annual mean temperature at culture depth |
| `average_salinity_psu` | DOUBLE | PSU | Annual mean salinity |
| `average_dissolved_oxygen_mg_l` | DOUBLE | mg/L | Annual mean DO |
| `water_quality_index` | DOUBLE | 0-100 | 0-100 water-quality score (same formula as habitat water_quality_score) |
| `infrastructure_access_score` | DOUBLE | 0-100 | 0-100 simulated infrastructure access |
| `environmental_risk_score` | DOUBLE | 0-100 | 0-100 risk score (higher = riskier) |
| `capacity_tonnes_year` | DOUBLE | tonnes/year | Simulated annual capacity |
| `site_status` | STRING |  | Operational / Planned / Under_Construction / Fallow / Suspended |
| `is_synthetic` | BOOLEAN |  | Always true: record is simulated |

## `habitat_suitability`  _(clean table)_
Candidate habitat cells with best-fit species, suitability score/class and ML cluster

| Column | Type | Unit | Description |
|---|---|---|---|
| `habitat_id` | STRING |  | Unique habitat-point key (H#####); H00001-H01000 coincide with sites S0001-S1000 |
| `latitude` | DOUBLE | degrees | WGS84 latitude, decimal degrees (-90..90) |
| `longitude` | DOUBLE | degrees | WGS84 longitude, decimal degrees (-180..180) |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `temperature_c` | DOUBLE | degC | Annual mean temperature at depth_m |
| `salinity_psu` | DOUBLE | PSU | Practical salinity |
| `dissolved_oxygen_mg_l` | DOUBLE | mg/L | Dissolved oxygen concentration |
| `ph` | DOUBLE | pH units | pH (total scale, approximate) |
| `depth_m` | DOUBLE | m | Depth below surface |
| `chlorophyll_a_mg_m3` | DOUBLE | mg/m3 | Chlorophyll-a concentration |
| `wave_height_m` | DOUBLE | m | Significant wave height (surface condition) |
| `water_quality_score` | DOUBLE | 0-100 | 0-100 water-quality score |
| `environmental_risk_score` | DOUBLE | 0-100 | 0-100 risk score (higher = riskier) |
| `suitable_species_id` | STRING |  | Best-matching aquaculture-capable species |
| `suitability_score` | DOUBLE | 0-100 | 0-100 habitat suitability (simulated formula, not validated) |
| `suitability_class` | STRING |  | Low / Moderate / High / Very High |
| `cluster_id` | INT |  | K-means cluster (0 = coldest) |
| `is_synthetic` | BOOLEAN |  | Always true: record is simulated |

## `species_environment_compat`  _(clean table)_
Species x habitat compatibility sub-scores

| Column | Type | Unit | Description |
|---|---|---|---|
| `compatibility_id` | STRING |  | Unique compatibility key |
| `species_id` | STRING |  | Unique species key (SP###) |
| `habitat_id` | STRING |  | Unique habitat-point key (H#####); H00001-H01000 coincide with sites S0001-S1000 |
| `temperature_compatibility_score` | DOUBLE | 0-100 | 0-100 temperature fit |
| `salinity_compatibility_score` | DOUBLE | 0-100 | 0-100 salinity fit |
| `oxygen_compatibility_score` | DOUBLE | 0-100 | 0-100 oxygen fit (vs species minimum DO requirement) |
| `depth_compatibility_score` | DOUBLE | 0-100 | 0-100 depth fit |
| `overall_compatibility_score` | DOUBLE | 0-100 | Weighted 0-100 fit |
| `compatibility_class` | STRING |  | Excellent / Good / Fair / Poor |
| `explanation` | STRING |  | Plain-text breakdown of the score |

## `fish_production`  _(clean table)_
FACT: monthly production, feed, mortality, cost, revenue per site x species (partition: reporting_year)

| Column | Type | Unit | Description |
|---|---|---|---|
| `production_id` | STRING |  | Unique production record key |
| `site_id` | STRING |  | Unique site key (S####); 'ALL' in dashboard_kpis portfolio rows |
| `species_id` | STRING |  | Unique species key (SP###) |
| `reporting_year` | INT |  | Calendar year |
| `reporting_month` | INT |  | Calendar month 1-12 |
| `production_tonnes` | DOUBLE | tonnes | Harvested tonnes in the month |
| `feed_consumption_tonnes` | DOUBLE | tonnes | Feed used (0 for non-fed species) |
| `feed_conversion_ratio` | DOUBLE |  | Feed / production (0 for non-fed species) |
| `mortality_rate_percent` | DOUBLE | % | Monthly mortality |
| `survival_rate_percent` | DOUBLE | % | 100 - mortality_rate_percent (monthly) |
| `operating_cost_usd` | DOUBLE | USD | Sum of linked expense transactions |
| `revenue_usd` | DOUBLE | USD | Linked 'Fish sales' income |
| `data_origin` | STRING |  | Provenance label (all simulated / approximate) |

## `finance_transactions`  _(clean table)_
FACT: income/expense ledger (partition: txn_year)

| Column | Type | Unit | Description |
|---|---|---|---|
| `transaction_id` | STRING |  | Unique transaction key |
| `site_id` | STRING |  | Unique site key (S####); 'ALL' in dashboard_kpis portfolio rows |
| `txn_date` | DATE |  | Transaction date (ISO) |
| `transaction_type` | STRING |  | income / expense |
| `category` | STRING |  | Fish sales / Feed / Labour / Energy / Maintenance / Equipment / Transport / Other operating costs |
| `description` | STRING |  | Text description (SIMULATED) |
| `amount_usd` | DOUBLE | USD | Positive amount in USD; sign given by transaction_type |
| `payment_method` | STRING |  | Payment method |
| `related_production_id` | STRING |  | Production record this transaction belongs to |
| `is_simulated` | BOOLEAN |  | Always true |
| `txn_month` | INT |  | Month number 1-12 of txn_date |
| `txn_year` | INT |  | Partition column: year of txn_date |

## `resource_inventory`  _(clean table)_
Stock on hand per site and resource

| Column | Type | Unit | Description |
|---|---|---|---|
| `resource_id` | STRING |  | Unique inventory item key |
| `site_id` | STRING |  | Unique site key (S####); 'ALL' in dashboard_kpis portfolio rows |
| `resource_name` | STRING |  | Item name |
| `resource_category` | STRING |  | Feed / Seed stock / Equipment / Water-quality testing supplies / Medicines / Maintenance materials |
| `quantity_available` | DOUBLE |  | Quantity on hand at 2024-12-31 |
| `unit` | STRING |  | Unit of quantity |
| `reorder_threshold` | DOUBLE |  | Reorder level (same unit) |
| `unit_cost_usd` | DOUBLE | USD | Cost per unit |
| `supplier_name` | STRING |  | Fictional supplier |
| `last_restock_date` | DATE |  | Last restock (ISO) |
| `resource_status` | STRING |  | In_Stock / Low_Stock (qty<=threshold) / Out_of_Stock (qty=0) |

## `dashboard_kpis`  _(clean table)_
Pre-aggregated KPIs: site x month, site x year and company-wide 'ALL' rows

| Column | Type | Unit | Description |
|---|---|---|---|
| `kpi_id` | STRING |  | Unique KPI row key; KPI-M = month, KPI-Y = year |
| `period_start` | DATE |  | Period start (ISO) |
| `period_end` | DATE |  | Period end (ISO) |
| `site_id` | STRING |  | Unique site key (S####); 'ALL' in dashboard_kpis portfolio rows |
| `total_production_tonnes` | DOUBLE | tonnes | Sum of production_tonnes |
| `total_revenue_usd` | DOUBLE | USD | Sum of income transactions |
| `total_expenses_usd` | DOUBLE | USD | Sum of expense transactions |
| `net_profit_usd` | DOUBLE | USD | revenue - expenses |
| `average_mortality_rate_percent` | DOUBLE | % | Mean mortality over production records in period |
| `average_water_quality_score` | DOUBLE | 0-100 | Mean water_quality_index of active sites |
| `average_habitat_suitability_score` | DOUBLE | 0-100 | Mean suitability_score of habitat points at active sites |
| `low_inventory_item_count` | INT |  | Low/Out-of-stock items at 2024-12-31 snapshot (repeated for every period) |
| `active_site_count` | INT |  | Sites with production in period |
| `data_origin` | STRING |  | Provenance label (all simulated / approximate) |
| `kpi_grain` | STRING |  | monthly / yearly, derived from kpi_id (KPI-M-* / KPI-Y-*) |
| `kpi_scope` | STRING |  | site / all - 'all' = company-wide row (site_id = 'ALL'); never add site and all rows together |

## `ocean_conditions`  _(clean table)_
Ocean measurements AFTER cleaning (nulls imputed) (partition: obs_year)

| Column | Type | Unit | Description |
|---|---|---|---|
| `measurement_id` | STRING |  | Unique measurement key |
| `latitude` | DOUBLE | degrees | WGS84 latitude, decimal degrees (-90..90) |
| `longitude` | DOUBLE | degrees | WGS84 longitude, decimal degrees (-180..180) |
| `obs_date` | DATE |  | Simulated measurement date (ISO) |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `depth_m` | DOUBLE | m | Depth below surface |
| `sea_surface_temperature_c` | DOUBLE | degC | Surface temperature at the location/date |
| `water_temperature_c` | DOUBLE | degC | Water temperature at the stated depth |
| `salinity_psu` | DOUBLE | PSU | Practical salinity |
| `dissolved_oxygen_mg_l` | DOUBLE | mg/L | Dissolved oxygen concentration |
| `ph` | DOUBLE | pH units | pH (total scale, approximate) |
| `chlorophyll_a_mg_m3` | DOUBLE | mg/m3 | Chlorophyll-a concentration |
| `nitrate_umol_l` | DOUBLE | umol/L | Nitrate concentration |
| `wave_height_m` | DOUBLE | m | Significant wave height (surface condition) |
| `current_speed_m_s` | DOUBLE | m/s | Current speed at depth |
| `is_synthetic` | BOOLEAN |  | Always true: record is simulated |
| `obs_month` | INT |  | Month number 1-12 of obs_date |
| `obs_year` | INT |  | Partition column / derived: year of obs_date |

## `ocean_conditions_raw`  _(clean table)_
Ocean measurements BEFORE cleaning (nulls kept) - audit only

| Column | Type | Unit | Description |
|---|---|---|---|
| `measurement_id` | STRING |  | Unique measurement key |
| `latitude` | DOUBLE | degrees | WGS84 latitude, decimal degrees (-90..90) |
| `longitude` | DOUBLE | degrees | WGS84 longitude, decimal degrees (-180..180) |
| `obs_date` | DATE |  | Simulated measurement date (ISO) |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `depth_m` | DOUBLE | m | Depth below surface |
| `sea_surface_temperature_c` | DOUBLE | degC | Surface temperature at the location/date |
| `water_temperature_c` | DOUBLE | degC | Water temperature at the stated depth |
| `salinity_psu` | DOUBLE | PSU | Practical salinity |
| `dissolved_oxygen_mg_l` | DOUBLE | mg/L | Dissolved oxygen concentration |
| `ph` | DOUBLE | pH units | pH (total scale, approximate) |
| `chlorophyll_a_mg_m3` | DOUBLE | mg/m3 | Chlorophyll-a concentration |
| `nitrate_umol_l` | DOUBLE | umol/L | Nitrate concentration |
| `wave_height_m` | DOUBLE | m | Significant wave height (surface condition) |
| `current_speed_m_s` | DOUBLE | m/s | Current speed at depth |
| `is_synthetic` | BOOLEAN |  | Always true: record is simulated |

## `sum_finance_monthly`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `txn_year` | INT |  | Calendar year of the transactions |
| `txn_month` | INT |  | Month number 1-12 |
| `year_month` | INT |  | YYYYMM integer, e.g. 202403 |
| `transaction_type` | STRING |  | income / expense |
| `category` | STRING |  | Fish sales / Feed / Labour / Energy / Maintenance / Equipment / Transport / Other operating costs |
| `transactions` | BIGINT | count | Number of transactions |
| `total_usd` | DOUBLE | USD | SUM(amount_usd) |

## `sum_habitat_by_basin`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `suitability_class` | STRING |  | Low / Moderate / High / Very High |
| `habitat_cells` | BIGINT | count | Habitat cells in the group |
| `avg_suitability_score` | DOUBLE | 0-100 | Mean suitability_score |
| `avg_water_quality_score` | DOUBLE | 0-100 | Mean water_quality_score |
| `avg_env_risk_score` | DOUBLE | 0-100 | Mean environmental_risk_score |
| `pct_of_basin` | DOUBLE | % | Share of the basin's rows (habitat cells) |

## `sum_inventory_status`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `resource_category` | STRING |  | Feed / Seed stock / Equipment / Water-quality testing supplies / Medicines / Maintenance materials |
| `resource_status` | STRING |  | In_Stock / Low_Stock (qty<=threshold) / Out_of_Stock (qty=0) |
| `items` | BIGINT | count | Inventory items |
| `stock_value_usd` | DOUBLE | USD | SUM(quantity_available x unit_cost_usd) |
| `pct_of_category` | DOUBLE | % | Share of items in the same basin + category |

## `sum_ocean_basin_month`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `obs_year` | INT |  | Calendar year of the measurements |
| `obs_month` | INT |  | Month number 1-12 |
| `measurements` | BIGINT | count | Number of ocean measurements averaged |
| `avg_sst_c` | DOUBLE | degC | Mean sea-surface temperature |
| `avg_water_temp_c` | DOUBLE | degC | Mean water temperature |
| `avg_salinity_psu` | DOUBLE | PSU | Mean salinity |
| `avg_dissolved_oxygen_mg_l` | DOUBLE | mg/L | Mean dissolved oxygen |
| `avg_ph` | DOUBLE | pH | Mean pH |
| `avg_chlorophyll_mg_m3` | DOUBLE | mg/m3 | Mean chlorophyll-a |
| `avg_nitrate_umol_l` | DOUBLE | umol/L | Mean nitrate |
| `avg_wave_height_m` | DOUBLE | m | Mean wave height |
| `avg_current_speed_m_s` | DOUBLE | m/s | Mean current speed |

## `sum_overview_kpis`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `metric` | STRING |  | KPI name |
| `metric_value` | DOUBLE |  | KPI value |
| `unit` | STRING |  | Unit of metric_value |

## `sum_production_by_basin_year`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `reporting_year` | INT |  | Calendar year |
| `production_records` | BIGINT | count | Number of fish_production rows aggregated |
| `active_sites` | BIGINT | sites | Distinct sites with production in the group |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `avg_tonnes_per_record` | DOUBLE | tonnes | AVG(production_tonnes) per site-species-month record |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `avg_survival_pct` | DOUBLE | % | Average survival_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `revenue_per_tonne_usd` | DOUBLE | USD/t | revenue / tonnes |
| `prev_year_tonnes` | DOUBLE | tonnes | Same group, previous year total tonnes (NULL for 2023) |
| `tonnes_yoy_pct` | DOUBLE | % | Year-over-year change in tonnes (2024 vs 2023); NULL for 2023 |
| `revenue_yoy_pct` | DOUBLE | % | Year-over-year change in revenue |
| `profit_yoy_pct` | DOUBLE | % | Year-over-year change in gross profit (NULL if previous profit <= 0) |

## `sum_production_by_country_year`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `country_or_region` | STRING |  | Country/region label of the simulation region |
| `reporting_year` | INT |  | Calendar year |
| `production_records` | BIGINT | count | Number of fish_production rows aggregated |
| `active_sites` | BIGINT | sites | Distinct sites with production in the group |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `avg_tonnes_per_record` | DOUBLE | tonnes | AVG(production_tonnes) per site-species-month record |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `avg_survival_pct` | DOUBLE | % | Average survival_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `revenue_per_tonne_usd` | DOUBLE | USD/t | revenue / tonnes |
| `prev_year_tonnes` | DOUBLE | tonnes | Same group, previous year total tonnes (NULL for 2023) |
| `tonnes_yoy_pct` | DOUBLE | % | Year-over-year change in tonnes (2024 vs 2023); NULL for 2023 |
| `revenue_yoy_pct` | DOUBLE | % | Year-over-year change in revenue |
| `profit_yoy_pct` | DOUBLE | % | Year-over-year change in gross profit (NULL if previous profit <= 0) |

## `sum_production_by_site_type_year`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `site_type` | STRING |  | marine_cage / earthen_pond / longline_raft / land_based_ras / onshore_raceway |
| `reporting_year` | INT |  | Calendar year |
| `production_records` | BIGINT | count | Number of fish_production rows aggregated |
| `active_sites` | BIGINT | sites | Distinct sites with production in the group |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `avg_tonnes_per_record` | DOUBLE | tonnes | AVG(production_tonnes) per site-species-month record |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `avg_survival_pct` | DOUBLE | % | Average survival_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `revenue_per_tonne_usd` | DOUBLE | USD/t | revenue / tonnes |
| `prev_year_tonnes` | DOUBLE | tonnes | Same group, previous year total tonnes (NULL for 2023) |
| `tonnes_yoy_pct` | DOUBLE | % | Year-over-year change in tonnes (2024 vs 2023); NULL for 2023 |
| `revenue_yoy_pct` | DOUBLE | % | Year-over-year change in revenue |
| `profit_yoy_pct` | DOUBLE | % | Year-over-year change in gross profit (NULL if previous profit <= 0) |

## `sum_production_by_species_group_basin`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `species_group` | STRING |  | Taxonomic/functional group |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `reporting_year` | INT |  | Calendar year |
| `production_records` | BIGINT | count | Number of fish_production rows aggregated |
| `active_sites` | BIGINT | sites | Distinct sites with production in the group |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `avg_tonnes_per_record` | DOUBLE | tonnes | AVG(production_tonnes) per site-species-month record |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `avg_survival_pct` | DOUBLE | % | Average survival_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `revenue_per_tonne_usd` | DOUBLE | USD/t | revenue / tonnes |
| `prev_year_tonnes` | DOUBLE | tonnes | Same group, previous year total tonnes (NULL for 2023) |
| `tonnes_yoy_pct` | DOUBLE | % | Year-over-year change in tonnes (2024 vs 2023); NULL for 2023 |
| `revenue_yoy_pct` | DOUBLE | % | Year-over-year change in revenue |
| `profit_yoy_pct` | DOUBLE | % | Year-over-year change in gross profit (NULL if previous profit <= 0) |

## `sum_production_by_species_year`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `species_id` | STRING |  | Unique species key (SP###) |
| `common_name` | STRING |  | English common name |
| `scientific_name` | STRING |  | Latin binomial (real taxon; ranges approximate) |
| `species_group` | STRING |  | Taxonomic/functional group |
| `aquaculture_potential` | STRING |  | Not_suitable / Low / Medium / High (simulated judgement) |
| `reporting_year` | INT |  | Calendar year |
| `production_records` | BIGINT | count | Number of fish_production rows aggregated |
| `active_sites` | BIGINT | sites | Distinct sites with production in the group |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `avg_tonnes_per_record` | DOUBLE | tonnes | AVG(production_tonnes) per site-species-month record |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `avg_survival_pct` | DOUBLE | % | Average survival_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `revenue_per_tonne_usd` | DOUBLE | USD/t | revenue / tonnes |
| `prev_year_tonnes` | DOUBLE | tonnes | Same group, previous year total tonnes (NULL for 2023) |
| `tonnes_yoy_pct` | DOUBLE | % | Year-over-year change in tonnes (2024 vs 2023); NULL for 2023 |
| `revenue_yoy_pct` | DOUBLE | % | Year-over-year change in revenue |
| `profit_yoy_pct` | DOUBLE | % | Year-over-year change in gross profit (NULL if previous profit <= 0) |

## `sum_production_monthly`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `reporting_year` | INT |  | Calendar year |
| `reporting_month` | INT |  | Calendar month 1-12 |
| `year_month` | INT |  | YYYYMM integer, e.g. 202403 |
| `production_records` | BIGINT | count | Number of fish_production rows aggregated |
| `active_sites` | BIGINT | sites | Distinct sites with production in the group |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `avg_tonnes_per_record` | DOUBLE | tonnes | AVG(production_tonnes) per site-species-month record |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `avg_survival_pct` | DOUBLE | % | Average survival_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `revenue_per_tonne_usd` | DOUBLE | USD/t | revenue / tonnes |
| `prev_month_tonnes` | DOUBLE | tonnes | Total tonnes in the previous month |
| `tonnes_mom_pct` | DOUBLE | % | Month-on-month change in tonnes |
| `same_month_last_year_tonnes` | DOUBLE | tonnes | Total tonnes in the same month one year earlier |
| `tonnes_yoy_pct` | DOUBLE | % | Year-over-year change in tonnes (2024 vs 2023); NULL for 2023 |
| `tonnes_3m_moving_avg` | DOUBLE | tonnes | Average of this and the previous two months |

## `sum_site_performance`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `site_id` | STRING |  | Unique site key (S####); 'ALL' in dashboard_kpis portfolio rows |
| `site_name` | STRING |  | Simulated site name (prefixed SIM) |
| `country_or_region` | STRING |  | Country/region label of the simulation region |
| `ocean_basin` | STRING |  | Pacific / Atlantic / Indian / Southern / Arctic (approximate, region-based) |
| `site_type` | STRING |  | marine_cage / earthen_pond / longline_raft / land_based_ras / onshore_raceway |
| `site_status` | STRING |  | Operational / Planned / Under_Construction / Fallow / Suspended |
| `capacity_tonnes_year` | DOUBLE | tonnes/year | Simulated annual capacity |
| `months_reported` | BIGINT | months | Distinct months with production |
| `species_farmed` | BIGINT | count | Distinct species produced at the site |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `total_cost_usd` | DOUBLE | USD | SUM(operating_cost_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `capacity_utilisation_pct` | DOUBLE | % | Annualised tonnes (total/months x 12) as % of capacity_tonnes_year |
| `profit_rank_in_basin` | INT | rank | Rank by gross profit inside the ocean basin (1 = best) |
| `tonnes_rank_global` | INT | rank | Rank by total tonnes, all sites |

## `sum_species_ranking`  _(summary table)_
Aggregated for React dashboard / Power BI

| Column | Type | Unit | Description |
|---|---|---|---|
| `species_id` | STRING |  | Unique species key (SP###) |
| `common_name` | STRING |  | English common name |
| `species_group` | STRING |  | Taxonomic/functional group |
| `aquaculture_potential` | STRING |  | Not_suitable / Low / Medium / High (simulated judgement) |
| `sites_farming` | BIGINT | sites | Sites producing this species |
| `basins` | BIGINT | count | Ocean basins where it is produced |
| `total_tonnes` | DOUBLE | tonnes | SUM(production_tonnes) |
| `total_revenue_usd` | DOUBLE | USD | SUM(revenue_usd) |
| `gross_profit_usd` | DOUBLE | USD | revenue - operating cost |
| `profit_margin_pct` | DOUBLE | % | 100 x gross profit / revenue |
| `feed_conversion_ratio` | DOUBLE | ratio | SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs |
| `avg_mortality_pct` | DOUBLE | % | Average mortality_rate_percent |
| `tonnes_rank` | INT | rank | Rank by total tonnes |
| `profit_rank` | INT | rank | Rank by gross profit |
| `margin_rank` | INT | rank | Rank by profit margin |
| `pct_of_total_tonnes` | DOUBLE | % | Share of all production |
