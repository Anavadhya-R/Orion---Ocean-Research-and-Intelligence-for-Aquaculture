#!/usr/bin/env bash
# ORION | copy the CSVs from data/prepare_csv.py into HDFS, one directory per raw table.
# Usage: bash hive/scripts/load_to_hdfs.sh data/csv        (needs `hdfs dfs` on the PATH)
set -euo pipefail
SRC="${1:-data/csv}"
BASE="/user/orion/raw"
TABLES=(marine_species species_occurrences aquaculture_sites habitat_suitability species_environment_compat
        fish_production finance_transactions resource_inventory dashboard_kpis
        ocean_conditions_raw ocean_conditions_cleaned)
for t in "${TABLES[@]}"; do
  [[ -f "${SRC}/${t}.csv" ]] || { echo "missing ${SRC}/${t}.csv" >&2; exit 1; }
  hdfs dfs -mkdir -p "${BASE}/${t}"
  hdfs dfs -put -f "${SRC}/${t}.csv" "${BASE}/${t}/${t}.csv"
  echo "loaded ${t} -> ${BASE}/${t}"
done
hdfs dfs -du -h "${BASE}"
