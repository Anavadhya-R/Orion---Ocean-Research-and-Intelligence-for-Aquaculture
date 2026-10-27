#!/usr/bin/env bash
# ORION | run every analytical query and save the output (evidence for the report).
# Usage: bash hive/scripts/run_queries.sh [output_dir]     default: docs/query_results
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-../docs/query_results}"
mkdir -p "$OUT"
for q in queries/a*.hql; do
  n=$(basename "$q" .hql); echo ">>> $n"
  if [[ -n "${BEELINE_URL:-}" ]]; then
    beeline -u "$BEELINE_URL" ${BEELINE_USER:+-n "$BEELINE_USER"} ${BEELINE_PASS:+-p "$BEELINE_PASS"} --outputformat=table -f "$q" > "$OUT/$n.txt"
  else
    hive -f "$q" > "$OUT/$n.txt"
  fi
done
