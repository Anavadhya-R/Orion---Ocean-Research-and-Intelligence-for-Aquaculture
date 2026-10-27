# ORION - Hive analytics and SQL summaries (Member 3)

Hive turns the cleaned ORION aquaculture datasets into typed warehouse tables, answers the production
questions (by species, region, year), and publishes flat **summary tables** for the React dashboard and Power BI.
**Every record in this project is synthetic / simulated** - say so on every chart and in the report.

```
OrionDataset.xlsx + cleaneddata.zip ─ data/prepare_csv.py ─▶ data/csv/*.csv ─ scripts/load_to_hdfs.sh ─▶ HDFS /user/orion/raw/<table>/
  01_raw_tables.hql        raw_*  external tables, all STRING (never edited)
  02_clean_tables.hql      typed ORC tables = "cleaned aquaculture datasets"  (fish_production partitioned by year ...)
  03_views.hql             vw_production_enriched, vw_kpi_*, vw_ocean_imputation_audit
  04_summary_tables.hql    13 sum_* tables  ─ scripts/export_summaries.sh ─▶ exports/csv (Power BI) + exports/json (React)
  queries/a01..a09         analysis (production by species / region / year, growth, statistics, finance, environment ...)
```

## Branches
| Branch | Files |
|---|---|
| `feature/hive-analytics` | `00_setup.hql` `01_raw_tables.hql` `02_clean_tables.hql` `03_views.hql`, `queries/*`, `scripts/load_to_hdfs.sh` `run_all.sh` `run_queries.sh`, `tests/` |
| `feature/sql-summaries` | `04_summary_tables.hql`, `scripts/export_summaries.sh` `csv_to_json.py`, `exports/`, `../docs/DATA_DICTIONARY.md` `data_dictionary_hive.csv` `build_data_dictionary.py` |

`04_summary_tables.hql` reads the views from `03_views.hql`, so merge `feature/hive-analytics` first (or branch `sql-summaries` from it).
```bash
git checkout -b feature/hive-analytics   # add 00-03, queries/, scripts, tests; commit; push; PR
git checkout -b feature/sql-summaries    # (from the branch above) add 04, export scripts, exports/, docs; commit; push; PR
```

## Run order
```bash
python3 data/prepare_csv.py OrionDataset.xlsx cleaneddata data/csv     # 1. xlsx + zip -> csv
bash hive/scripts/load_to_hdfs.sh data/csv                             # 2. csv -> HDFS
bash hive/scripts/run_all.sh                                           # 3. build database (BEELINE_URL=jdbc:hive2://host:10000 for beeline)
bash hive/scripts/run_queries.sh docs/query_results                    # 4. run the analysis, keep output for the report
BEELINE_URL=jdbc:hive2://host:10000 bash hive/scripts/export_summaries.sh   # 5. refresh exports for React / Power BI
python3 docs/build_data_dictionary.py data/csv hive/exports/csv docs   # 6. refresh the data dictionary
```
Credentials only via `BEELINE_USER` / `BEELINE_PASS` environment variables - never commit them.
Written for Hive 3.x. **Not yet executed on a real cluster** - the SQL logic was verified on a local SQLite mirror
(`python3 hive/tests/local_sqlite_check.py data/csv`, 0 errors, summary tables cross-checked against pandas),
which does not exercise raw tables / ORC / partitions. Run step 3 on the cluster to confirm those.

## Summary tables (what the dashboard reads)
| Table | Grain | Use |
|---|---|---|
| sum_overview_kpis | metric | KPI cards (tonnes, revenue, profit, margin, FCR, sites ...) |
| sum_production_monthly | month | line chart; MoM %, YoY %, 3-month moving average |
| sum_production_by_species_year | species x year | tonnes, revenue, profit, FCR, mortality, YoY |
| sum_species_ranking | species | league tables (tonnes / profit / margin rank) |
| sum_production_by_basin_year | ocean basin x year | map / bar |
| sum_production_by_country_year | country-or-region x year | country table (labels mix countries and groups) |
| sum_production_by_site_type_year | farm type x year | cage vs pond vs raceway ... |
| sum_production_by_species_group_basin | species group x basin x year | what is farmed where |
| sum_site_performance | site | scorecard, capacity utilisation, ranks |
| sum_ocean_basin_month | basin x year x month | SST / salinity / oxygen / pH charts (cleaned data) |
| sum_habitat_by_basin | basin x suitability class | suitability bars |
| sum_finance_monthly | month x type x category | cash-flow and cost structure |
| sum_inventory_status | basin x category x status | stock health |

Column definitions: `docs/DATA_DICTIONARY.md` (also `docs/data_dictionary_hive.csv`).

## Cleaning: before vs after (`ocean_conditions_raw` vs `ocean_conditions`)
The only change made by the cleaning step is **imputing 4,260 empty cells** in 7 columns (salinity 343, oxygen 644, pH 504,
chlorophyll 854, nitrate 1,064, wave height 431, current speed 420; spread over all 5 basins). No non-empty value was changed
(query A01 #4 = 0). The `ocean_conditions` sheet inside the workbook is identical to the raw CSV. Use `vw_ocean_imputation_audit`
to flag imputed cells in charts - imputed values should not be presented as measurements.

## Things to know before you write the report
1. **Only 2 years of data (2023-2024)**: growth = 2024 vs 2023; there is no multi-year CAGR. 2023 rows have NULL growth by design.
2. **Yearly growth is +4.6 % tonnes, all from higher output per site** (the same 230 sites report in both years; A04 #5). But sites came online gradually during 2023 (178 producing in Jan 2023 -> 229 by Dec), so **monthly YoY for early 2024 (+17-19 %) is inflated by that ramp-up** - quote yearly growth, or compare tonnes per active site.
3. **`dashboard_kpis` mixes 3 row types** (site x month, site x year, company-wide `site_id='ALL'`). Adding them all counts every tonne 4 times; use `vw_kpi_monthly` / `vw_kpi_yearly` (site) and `vw_kpi_global_*` (ALL). Totals reconcile with `fish_production` (A01 #10).
4. **Money reconciles**: production revenue/cost equal the finance ledger exactly (A01 #9). 150 of 7,279 production rows (2 %) are loss-making.
5. **Feed conversion ratio = 0 for algae and filter-feeding molluscs** (no feed). Rank FCR only among fed species.
6. **Only the 593 Operational sites produce** (230 have production rows); Planned / Under_Construction / Fallow / Suspended sites have none.
7. `country_or_region` mixes single countries ("Chile") and groups ("India/Bangladesh/Myanmar"); do not rank them as like-for-like countries.
8. `marine_species.image_url` is 100 % empty (dropped). Species ranges and conservation codes are approximate and marked "not authoritative".
9. The Excel sheet `species_environment_compatibili` is truncated by Excel's 31-character limit; the Hive table is `species_environment_compat`.
