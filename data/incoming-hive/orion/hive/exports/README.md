# Exports for React and Power BI
`csv/` = one file per `sum_*` table (header row, UTF-8). `json/` = same data as row-object arrays + `manifest.json`.
**These preview files were generated from a local SQLite mirror of the Hive logic** (identical formulas). After the first
real Hive run, overwrite them with `BEELINE_URL=... bash hive/scripts/export_summaries.sh`.

**Power BI**: Get Data -> Text/CSV (or Folder, `exports/csv`). Load `data_dictionary_hive.csv` too as a documentation table.
Suggested relationships: none needed - each sum_ table is self-contained. Show the synthetic-data disclaimer on every page.

**React**: `import monthly from '../data/sum_production_monthly.json'` (copy `exports/json/*` into `frontend/src/data/`).
`manifest.json` lists tables, row counts, columns and the disclaimer string to display.
Values: `*_usd` = US dollars, `*_pct` = percent 0-100, `*_yoy_pct` null for 2023.
