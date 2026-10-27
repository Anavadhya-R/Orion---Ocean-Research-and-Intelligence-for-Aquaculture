#!/usr/bin/env python3
"""Build the ORION Hive data dictionary (Markdown + CSV for Power BI).

Usage: python3 docs/build_data_dictionary.py data/csv hive/exports docs
 - data/csv      : CSVs from data/prepare_csv.py (column order/types of the clean tables)
 - hive/exports/csv: summary CSVs from export_summaries.sh (columns of the sum_* tables)
 - docs          : output folder -> DATA_DICTIONARY.md and data_dictionary_hive.csv
Descriptions of source columns come from data/reference/data_dictionary.csv (supplied with the dataset);
derived columns are described below.  Run again whenever a table changes.
"""
import re
import sys
from pathlib import Path

import pandas as pd

CSV, EXP, OUT = (Path(a) for a in sys.argv[1:4])
REF = pd.read_csv(Path(__file__).resolve().parent.parent / "data/reference/data_dictionary.csv")

# clean table -> (source csv, reference dataset, purpose)
CLEAN = {
    "marine_species": ("marine_species", "marine_species", "Species catalogue: tolerances, group, aquaculture potential (simulated, approximate)"),
    "species_occurrences": ("species_occurrences", "species_occurrences", "Simulated sighting points for the map"),
    "aquaculture_sites": ("aquaculture_sites", "aquaculture_sites", "1,000 simulated farms: location, type, status, capacity, quality/risk scores"),
    "habitat_suitability": ("habitat_suitability", "habitat_suitability", "Candidate habitat cells with best-fit species, suitability score/class and ML cluster"),
    "species_environment_compat": ("species_environment_compat", "species_environment_compatibility", "Species x habitat compatibility sub-scores"),
    "fish_production": ("fish_production", "fish_production", "FACT: monthly production, feed, mortality, cost, revenue per site x species (partition: reporting_year)"),
    "finance_transactions": ("finance_transactions", "finance_transactions", "FACT: income/expense ledger (partition: txn_year)"),
    "resource_inventory": ("resource_inventory", "resource_inventory", "Stock on hand per site and resource"),
    "dashboard_kpis": ("dashboard_kpis", "dashboard_kpis", "Pre-aggregated KPIs: site x month, site x year and company-wide 'ALL' rows"),
    "ocean_conditions": ("ocean_conditions_cleaned", "ocean_conditions_cleaned", "Ocean measurements AFTER cleaning (nulls imputed) (partition: obs_year)"),
    "ocean_conditions_raw": ("ocean_conditions_raw", "ocean_conditions", "Ocean measurements BEFORE cleaning (nulls kept) - audit only"),
}
RENAMED = {"obs_date": "measurement_date|observation_date|transaction_date", "txn_date": "transaction_date",
           "capacity_tonnes_year": "estimated_production_capacity_tonnes_year"}
EXTRA = {  # columns that exist only in Hive (not in the source dictionary)
    "kpi_grain": ("", "monthly | yearly, derived from kpi_id (KPI-M-* / KPI-Y-*)"),
    "kpi_scope": ("", "site | all - 'all' = company-wide row (site_id = 'ALL'); never add site and all rows together"),
    "txn_year": ("", "Partition column: year of txn_date"), "txn_month": ("", "Month number 1-12 of txn_date"),
    "obs_year": ("", "Partition column / derived: year of obs_date"), "obs_month": ("", "Month number 1-12 of obs_date"),
    "reporting_year": ("", "Partition column: reporting year (2023-2024)"),
}
DERIVED = {  # sum_* columns
    "year_month": ("", "YYYYMM integer, e.g. 202403"),
    "production_records": ("count", "Number of fish_production rows aggregated"),
    "active_sites": ("sites", "Distinct sites with production in the group"),
    "total_tonnes": ("tonnes", "SUM(production_tonnes)"),
    "avg_tonnes_per_record": ("tonnes", "AVG(production_tonnes) per site-species-month record"),
    "feed_conversion_ratio": ("ratio", "SUM(feed)/SUM(production) - tonnes of feed per tonne produced; 0 for unfed algae/molluscs"),
    "avg_mortality_pct": ("%", "Average mortality_rate_percent"), "avg_survival_pct": ("%", "Average survival_rate_percent"),
    "total_revenue_usd": ("USD", "SUM(revenue_usd)"), "total_cost_usd": ("USD", "SUM(operating_cost_usd)"),
    "gross_profit_usd": ("USD", "revenue - operating cost"), "profit_margin_pct": ("%", "100 x gross profit / revenue"),
    "revenue_per_tonne_usd": ("USD/t", "revenue / tonnes"),
    "prev_year_tonnes": ("tonnes", "Same group, previous year total tonnes (NULL for 2023)"),
    "tonnes_yoy_pct": ("%", "Year-over-year change in tonnes (2024 vs 2023); NULL for 2023"),
    "revenue_yoy_pct": ("%", "Year-over-year change in revenue"), "profit_yoy_pct": ("%", "Year-over-year change in gross profit (NULL if previous profit <= 0)"),
    "prev_month_tonnes": ("tonnes", "Total tonnes in the previous month"), "tonnes_mom_pct": ("%", "Month-on-month change in tonnes"),
    "same_month_last_year_tonnes": ("tonnes", "Total tonnes in the same month one year earlier"),
    "tonnes_3m_moving_avg": ("tonnes", "Average of this and the previous two months"),
    "months_reported": ("months", "Distinct months with production"), "species_farmed": ("count", "Distinct species produced at the site"),
    "capacity_utilisation_pct": ("%", "Annualised tonnes (total/months x 12) as % of capacity_tonnes_year"),
    "profit_rank_in_basin": ("rank", "Rank by gross profit inside the ocean basin (1 = best)"), "tonnes_rank_global": ("rank", "Rank by total tonnes, all sites"),
    "sites_farming": ("sites", "Sites producing this species"), "basins": ("count", "Ocean basins where it is produced"),
    "tonnes_rank": ("rank", "Rank by total tonnes"), "profit_rank": ("rank", "Rank by gross profit"), "margin_rank": ("rank", "Rank by profit margin"),
    "pct_of_total_tonnes": ("%", "Share of all production"),
    "measurements": ("count", "Number of ocean measurements averaged"), "avg_sst_c": ("degC", "Mean sea-surface temperature"),
    "avg_water_temp_c": ("degC", "Mean water temperature"), "avg_salinity_psu": ("PSU", "Mean salinity"),
    "avg_dissolved_oxygen_mg_l": ("mg/L", "Mean dissolved oxygen"), "avg_ph": ("pH", "Mean pH"),
    "avg_chlorophyll_mg_m3": ("mg/m3", "Mean chlorophyll-a"), "avg_nitrate_umol_l": ("umol/L", "Mean nitrate"),
    "avg_wave_height_m": ("m", "Mean wave height"), "avg_current_speed_m_s": ("m/s", "Mean current speed"),
    "habitat_cells": ("count", "Habitat cells in the group"), "avg_suitability_score": ("0-100", "Mean suitability_score"),
    "avg_water_quality_score": ("0-100", "Mean water_quality_score"), "avg_env_risk_score": ("0-100", "Mean environmental_risk_score"),
    "pct_of_basin": ("%", "Share of the basin's rows (habitat cells)"),
    "transactions": ("count", "Number of transactions"), "total_usd": ("USD", "SUM(amount_usd)"),
    "items": ("count", "Inventory items"), "stock_value_usd": ("USD", "SUM(quantity_available x unit_cost_usd)"),
    "pct_of_category": ("%", "Share of items in the same basin + category"),
    "txn_year": ("", "Calendar year of the transactions"), "txn_month": ("", "Month number 1-12"),
    "obs_year": ("", "Calendar year of the measurements"), "obs_month": ("", "Month number 1-12"),
    "metric": ("", "KPI name"), "metric_value": ("", "KPI value"), "unit": ("", "Unit of metric_value"),
}


INT_COLS = {"reporting_month", "reporting_year", "cluster_id", "low_inventory_item_count", "active_site_count",
            "obs_year", "obs_month", "txn_year", "txn_month", "year_month"}
BIGINT_COLS = {"production_records", "active_sites", "species_farmed", "months_reported", "sites_farming", "basins", "measurements",
               "habitat_cells", "transactions", "items"}
RANK_COLS = {"tonnes_rank", "profit_rank", "margin_rank", "profit_rank_in_basin", "tonnes_rank_global"}


def hive_type(col, s):
    """Type exactly as declared in 02_clean_tables.hql / 04_summary_tables.hql (numbers are DOUBLE unless listed)."""
    if col in ("is_synthetic", "is_simulated"): return "BOOLEAN"
    if re.search(r"(_date|period_start|period_end)$", col): return "DATE"
    if col in INT_COLS or col in RANK_COLS: return "INT"
    if col in BIGINT_COLS: return "BIGINT"
    if col == "population": return "BIGINT"
    if pd.api.types.is_numeric_dtype(s) and not pd.api.types.is_bool_dtype(s): return "DOUBLE"
    return "STRING"


def ref_lookup(ds, col):
    names = [col] + RENAMED.get(col, "").split("|")
    for n in names:
        row = REF[(REF.dataset == ds) & (REF.column_name == n)]
        if len(row): return row.iloc[0]
    return None


rows = []
for tbl, (src, ds, purpose) in CLEAN.items():
    df = pd.read_csv(CSV / f"{src}.csv", nrows=2000, low_memory=False)
    if tbl == "marine_species": df = df.drop(columns="image_url")
    cols = list(df.columns)
    if tbl in ("fish_production", "finance_transactions", "ocean_conditions"): pass
    extra = [c for c in ("kpi_grain", "kpi_scope") if tbl == "dashboard_kpis"] + \
            (["txn_month", "txn_year"] if tbl == "finance_transactions" else []) + \
            (["obs_month", "obs_year"] if tbl == "ocean_conditions" else []) + (["obs_year"] if tbl == "species_occurrences" else [])
    ren = {"measurement_date": "obs_date", "observation_date": "obs_date", "transaction_date": "txn_date",
           "estimated_production_capacity_tonnes_year": "capacity_tonnes_year"}
    for c in cols + extra:
        hc = ren.get(c, c)
        s = df[c] if c in df else pd.Series([1])
        if hc in ("kpi_grain", "kpi_scope"): s = pd.Series(["x"])
        if hc in ("txn_year", "txn_month", "obs_year", "obs_month"): s = pd.Series([1])
        r = ref_lookup(ds, hc) if c not in extra else None
        unit, desc = (("" if pd.isna(r.unit) else r.unit), r.description) if r is not None else EXTRA.get(hc, ("", ""))
        rows.append((tbl, "clean table", purpose, hc, hive_type(hc, s), unit, desc))
for f in sorted(EXP.glob("sum_*.csv")):
    df = pd.read_csv(f, nrows=500)
    for c in df.columns:
        r = None
        for ds in ("fish_production", "aquaculture_sites", "marine_species", "habitat_suitability", "resource_inventory", "finance_transactions", "ocean_conditions"):
            r = ref_lookup(ds, c)
            if r is not None: break
        unit, desc = DERIVED.get(c, (("" if r is None or pd.isna(r.unit) else r.unit), "" if r is None else r.description))
        rows.append((f.stem, "summary table", "Aggregated for React dashboard / Power BI", c, hive_type(c, df[c]), unit, desc))

d = pd.DataFrame(rows, columns=["table_name", "layer", "table_purpose", "column_name", "hive_type", "unit", "description"])
missing = d[d.description.str.strip() == ""]
OUT.mkdir(parents=True, exist_ok=True)
d.to_csv(OUT / "data_dictionary_hive.csv", index=False)

md = ["# ORION - Hive data dictionary\n",
      "Database `orion`. **All data is synthetic/simulated** (every table carries an `is_synthetic` / `data_origin` flag or `SIMULATED` label).",
      "Raw tables `raw_*` mirror the CSV files with every column as STRING and are not repeated here.",
      "Machine-readable copy: `data_dictionary_hive.csv` (import into Power BI as a documentation table).\n"]
for tbl, g in d.groupby("table_name", sort=False):
    md.append(f"\n## `{tbl}`  _({g.layer.iloc[0]})_\n{g.table_purpose.iloc[0]}\n")
    md.append("| Column | Type | Unit | Description |\n|---|---|---|---|")
    for _, r in g.iterrows():
        md.append(f"| `{r.column_name}` | {r.hive_type} | {r.unit} | {str(r.description).replace('|', '/')} |")
(OUT / "DATA_DICTIONARY.md").write_text("\n".join(md) + "\n", encoding="utf-8")
print(f"{d.table_name.nunique()} tables, {len(d)} columns documented; columns without description: {len(missing)}")
if len(missing): print(missing[["table_name", "column_name"]].to_string())
