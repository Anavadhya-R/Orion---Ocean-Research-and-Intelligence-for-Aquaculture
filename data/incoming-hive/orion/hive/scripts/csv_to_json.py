#!/usr/bin/env python3
"""Turn the exported summary CSVs into JSON for the React dashboard.

Usage: python3 hive/scripts/csv_to_json.py hive/exports/csv hive/exports/json
Writes one <table>.json (array of row objects, numbers typed, empty -> null) and manifest.json
({table: {rows, columns}}), plus the standing disclaimer so the UI can show it.
Stdlib only.
"""
import csv, json, sys
from pathlib import Path

DISCLAIMER = "All ORION data is synthetic / simulated and must not be used for real investment or operational decisions."


def typed(v):
    if v is None or v == "" or v.upper() == "NULL": return None
    try:
        f = float(v)
        return int(f) if f.is_integer() and "." not in v and "e" not in v.lower() else f
    except ValueError:
        return v


def main(src, dst):
    src, dst = Path(src), Path(dst)
    dst.mkdir(parents=True, exist_ok=True)
    manifest = {"disclaimer": DISCLAIMER, "tables": {}}
    for f in sorted(src.glob("sum_*.csv")):
        with open(f, newline="", encoding="utf-8") as fh:
            rows = [{k: typed(v) for k, v in r.items()} for r in csv.DictReader(fh)]
        (dst / f"{f.stem}.json").write_text(json.dumps(rows, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        manifest["tables"][f.stem] = {"rows": len(rows), "columns": list(rows[0].keys()) if rows else []}
        print(f"{f.stem}: {len(rows)} rows")
    (dst / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 3: sys.exit(__doc__)
    main(*sys.argv[1:])
