#!/usr/bin/env bash
# ORION | export every sum_* table to CSV (Power BI) and JSON (React dashboard).
# Usage: BEELINE_URL=jdbc:hive2://host:10000 bash hive/scripts/export_summaries.sh [output_dir]
# Output: <output_dir>/csv/<table>.csv   (header row, comma separated, UTF-8)
#         <output_dir>/json/<table>.json (+ manifest.json)         default output_dir: hive/exports
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-exports}"
: "${BEELINE_URL:?set BEELINE_URL, e.g. jdbc:hive2://localhost:10000}"
mkdir -p "$OUT/csv"
TABLES=$(beeline -u "$BEELINE_URL" ${BEELINE_USER:+-n "$BEELINE_USER"} ${BEELINE_PASS:+-p "$BEELINE_PASS"} \
         --outputformat=csv2 --silent=true --showHeader=false -e "SHOW TABLES IN orion LIKE 'sum_*'")
for t in $TABLES; do
  beeline -u "$BEELINE_URL" ${BEELINE_USER:+-n "$BEELINE_USER"} ${BEELINE_PASS:+-p "$BEELINE_PASS"} \
          --outputformat=csv2 --silent=true -e "SELECT * FROM orion.${t}" > "$OUT/csv/${t}.csv"
  echo "exported ${t}"
done
python3 scripts/csv_to_json.py "$OUT/csv" "$OUT/json"
