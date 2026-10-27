-- =============================================================================
-- ORION | Hive layer 3: reusable VIEWS                          (branch: feature/hive-analytics)
-- =============================================================================

USE orion;

-- Production joined to site and species attributes + derived profit columns
CREATE OR REPLACE VIEW vw_production_enriched AS
SELECT p.production_id, p.reporting_year, p.reporting_month,
       p.reporting_year * 100 + p.reporting_month AS year_month,
       p.site_id, s.site_name, s.country_or_region, s.ocean_basin, s.site_type, s.site_status,
       s.farm_area_hectares, s.capacity_tonnes_year,
       p.species_id, sp.common_name, sp.scientific_name, sp.species_group, sp.habitat_type, sp.aquaculture_potential,
       p.production_tonnes, p.feed_consumption_tonnes, p.feed_conversion_ratio,
       p.mortality_rate_percent, p.survival_rate_percent,
       p.operating_cost_usd, p.revenue_usd,
       p.revenue_usd - p.operating_cost_usd AS gross_profit_usd
FROM fish_production p
LEFT JOIN aquaculture_sites s ON p.site_id = s.site_id
LEFT JOIN marine_species sp   ON p.species_id = sp.species_id;

-- dashboard_kpis holds site rows AND company-wide ('ALL') rows at monthly and yearly grain: one view per slice
CREATE OR REPLACE VIEW vw_kpi_monthly        AS SELECT * FROM dashboard_kpis WHERE kpi_grain = 'monthly' AND kpi_scope = 'site';
CREATE OR REPLACE VIEW vw_kpi_yearly         AS SELECT * FROM dashboard_kpis WHERE kpi_grain = 'yearly'  AND kpi_scope = 'site';
CREATE OR REPLACE VIEW vw_kpi_global_monthly AS SELECT * FROM dashboard_kpis WHERE kpi_grain = 'monthly' AND kpi_scope = 'all';
CREATE OR REPLACE VIEW vw_kpi_global_yearly  AS SELECT * FROM dashboard_kpis WHERE kpi_grain = 'yearly'  AND kpi_scope = 'all';

-- Which cells did the cleaning step fill in? (raw NULL -> cleaned value), one row per measurement that changed
CREATE OR REPLACE VIEW vw_ocean_imputation_audit AS
SELECT r.measurement_id, r.ocean_basin, c.obs_year,
       CASE WHEN r.salinity_psu          IS NULL AND c.salinity_psu          IS NOT NULL THEN 1 ELSE 0 END AS salinity_imputed,
       CASE WHEN r.dissolved_oxygen_mg_l IS NULL AND c.dissolved_oxygen_mg_l IS NOT NULL THEN 1 ELSE 0 END AS oxygen_imputed,
       CASE WHEN r.ph                    IS NULL AND c.ph                    IS NOT NULL THEN 1 ELSE 0 END AS ph_imputed,
       CASE WHEN r.chlorophyll_a_mg_m3   IS NULL AND c.chlorophyll_a_mg_m3   IS NOT NULL THEN 1 ELSE 0 END AS chlorophyll_imputed,
       CASE WHEN r.nitrate_umol_l        IS NULL AND c.nitrate_umol_l        IS NOT NULL THEN 1 ELSE 0 END AS nitrate_imputed,
       CASE WHEN r.wave_height_m         IS NULL AND c.wave_height_m         IS NOT NULL THEN 1 ELSE 0 END AS wave_imputed,
       CASE WHEN r.current_speed_m_s     IS NULL AND c.current_speed_m_s     IS NOT NULL THEN 1 ELSE 0 END AS current_imputed
FROM ocean_conditions_raw r
JOIN ocean_conditions c ON r.measurement_id = c.measurement_id;
