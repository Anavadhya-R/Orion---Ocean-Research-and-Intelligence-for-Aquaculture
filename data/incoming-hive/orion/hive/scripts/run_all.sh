#!/usr/bin/env bash
# ORION | build the whole Hive warehouse from scratch (setup -> raw -> clean -> views -> summaries).
# Usage:  bash hive/scripts/run_all.sh                       (hive CLI)
#         BEELINE_URL=jdbc:hive2://host:10000 bash hive/scripts/run_all.sh   (beeline; BEELINE_USER / BEELINE_PASS from the environment)
# Never write passwords into scripts or the repo.
set -euo pipefail
cd "$(dirname "$0")/.."
run() {
  echo ">>> $1"
  if [[ -n "${BEELINE_URL:-}" ]]; then
    beeline -u "$BEELINE_URL" ${BEELINE_USER:+-n "$BEELINE_USER"} ${BEELINE_PASS:+-p "$BEELINE_PASS"} -f "$1"
  else
    hive -f "$1"
  fi
}
for f in 00_setup.hql 01_raw_tables.hql 02_clean_tables.hql 03_views.hql 04_summary_tables.hql; do run "$f"; done
echo "Done. Next: bash hive/scripts/run_queries.sh   and   bash hive/scripts/export_summaries.sh"
