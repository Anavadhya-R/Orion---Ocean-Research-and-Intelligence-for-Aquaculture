#!/usr/bin/env python3
"""Prepare the ORION CSVs for HDFS / Hive.

Usage:  python3 data/prepare_csv.py OrionDataset.xlsx cleaneddata/ data/csv

Inputs
  OrionDataset.xlsx  - 10 sheets (species, sites, production, finance, ...). Its `ocean_conditions`
                       sheet is identical to ocean_conditions_raw.csv, so it is NOT exported again.
  cleaneddata/       - folder from cleaneddata.zip: ocean_conditions_raw.csv (BEFORE cleaning),
                       ocean_conditions_cleaned.csv (AFTER cleaning), data_dictionary.csv, dataset_summary.csv
Output (data/csv/): one CSV per Hive raw table, header row kept, ISO dates, booleans as true/false.
Requires: pandas, openpyxl
"""
import shutil
import sys
from datetime import date, datetime
from pathlib import Path

import pandas as pd

SHEET_TO_TABLE = {
    "marine_species": "marine_species",
    "species_occurrences": "species_occurrences",
    "aquaculture_sites": "aquaculture_sites",
    "habitat_suitability": "habitat_suitability",
    "species_environment_compatibili": "species_environment_compat",  # Excel truncates sheet names at 31 chars
    "fish_production": "fish_production",
    "finance_transactions": "finance_transactions",
    "resource_inventory": "resource_inventory",
    "dashboard_kpis": "dashboard_kpis",
}


def tidy(df: pd.DataFrame) -> pd.DataFrame:
    for c in df.columns:
        df[c] = df[c].map(lambda v: v.strftime("%Y-%m-%d") if isinstance(v, (datetime, date)) else v)
        if df[c].dtype == bool:
            df[c] = df[c].map({True: "true", False: "false"})
    return df.replace(r"[\r\n]+", " ", regex=True)


def main(xlsx: str, zip_dir: str, out_dir: str) -> None:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    book = pd.ExcelFile(xlsx)
    for sheet, table in SHEET_TO_TABLE.items():
        df = tidy(book.parse(sheet))
        df.to_csv(out / f"{table}.csv", index=False)
        print(f"{table:28s}{len(df):>8,} rows {len(df.columns):>3} cols")
    for stage in ("raw", "cleaned"):
        df = pd.read_csv(Path(zip_dir) / f"ocean_conditions_{stage}.csv", dtype=str, keep_default_na=False)
        df["is_synthetic"] = df["is_synthetic"].str.lower()          # 'True' -> 'true'
        df.to_csv(out / f"ocean_conditions_{stage}.csv", index=False)
        print(f"{'ocean_conditions_' + stage:28s}{len(df):>8,} rows {len(df.columns):>3} cols")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
