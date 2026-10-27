"""Local logic check for the ORION Hive SQL - NO Hadoop/Hive needed.

Mirrors the CLEAN layer (02_clean_tables.hql) in in-memory SQLite, then runs 03_views.hql,
04_summary_tables.hql and every query in queries/ (small shims: STORED AS ORC / USE / SET removed,
CORR, STDDEV_POP, PERCENTILE_APPROX, DATEDIFF added). Proves joins, windows, growth maths run and
that nothing errors. It does NOT test the raw tables / ORC / partitioning - run scripts/run_all.sh on
the cluster for that.

Usage:  python3 hive/tests/local_sqlite_check.py data/csv [export_dir]
        with export_dir: also writes every sum_* table to <export_dir>/<table>.csv (preview of the Hive export)
Needs:  pandas, numpy
"""
import glob, math, os, re, sqlite3, sys
import numpy as np
import pandas as pd

D = sys.argv[1].rstrip('/') + '/'
EXPORT = sys.argv[2] if len(sys.argv) > 2 else None
H = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..') + '/'
con = sqlite3.connect(':memory:')


class Corr:
    def __init__(s): s.x, s.y = [], []
    def step(s, a, b):
        if a is not None and b is not None: s.x.append(a); s.y.append(b)
    def finalize(s):
        if len(s.x) < 2: return None
        v = np.corrcoef(s.x, s.y)[0, 1]; return None if math.isnan(v) else float(v)


class StdPop:
    def __init__(s): s.v = []
    def step(s, a):
        if a is not None: s.v.append(a)
    def finalize(s): return float(np.std(s.v)) if s.v else None


class Pct:
    def __init__(s): s.v, s.p = [], 0.5
    def step(s, a, p):
        s.p = p
        if a is not None: s.v.append(a)
    def finalize(s): return float(np.percentile(s.v, s.p * 100)) if s.v else None


con.create_aggregate('corr', 2, Corr)
con.create_aggregate('stddev_pop', 1, StdPop)
con.create_aggregate('percentile_approx', 2, Pct)
con.create_function('datediff', 2, lambda a, b: None if a is None or b is None else
                    int(round(pd.Timestamp(a).to_julian_date() - pd.Timestamp(b).to_julian_date())))

r = lambda n: pd.read_csv(D + n + '.csv', low_memory=False)
b = lambda s: s.astype(str).str.lower().eq('true').astype(int)
put = lambda df, n: df.to_sql(n, con, index=False)

for t in ['marine_species', 'aquaculture_sites', 'habitat_suitability', 'species_environment_compat', 'resource_inventory']:
    df = r(t)
    if t == 'marine_species': df = df.drop(columns='image_url')
    if 'is_synthetic' in df: df['is_synthetic'] = b(df.is_synthetic)
    if t == 'aquaculture_sites': df = df.rename(columns={'estimated_production_capacity_tonnes_year': 'capacity_tonnes_year'})
    put(df, t)
o = r('species_occurrences').rename(columns={'observation_date': 'obs_date'}); o['obs_year'] = o.obs_date.str[:4].astype(int); o['is_synthetic'] = b(o.is_synthetic); put(o, 'species_occurrences')
put(r('fish_production'), 'fish_production')
t = r('finance_transactions').rename(columns={'transaction_date': 'txn_date'}); t['txn_year'] = t.txn_date.str[:4].astype(int); t['txn_month'] = t.txn_date.str[5:7].astype(int); t['is_simulated'] = b(t.is_simulated); put(t, 'finance_transactions')
k = r('dashboard_kpis'); k.insert(1, 'kpi_scope', np.where(k.site_id == 'ALL', 'all', 'site')); k.insert(1, 'kpi_grain', np.where(k.kpi_id.str.startswith('KPI-M-'), 'monthly', np.where(k.kpi_id.str.startswith('KPI-Y-'), 'yearly', 'other'))); put(k, 'dashboard_kpis')
rw = r('ocean_conditions_raw').rename(columns={'measurement_date': 'obs_date'}).drop(columns='is_synthetic'); put(rw, 'ocean_conditions_raw')
c = r('ocean_conditions_cleaned').rename(columns={'measurement_date': 'obs_date'}); c['obs_year'] = c.obs_date.str[:4].astype(int); c['obs_month'] = c.obs_date.str[5:7].astype(int); c['is_synthetic'] = b(c.is_synthetic); put(c, 'ocean_conditions')


def statements(path):
    sql = re.sub(r'--[^\n]*', '', open(path).read())
    for st in sql.split(';'):
        st = st.strip()
        if not st or re.match(r'(USE|SET|ANALYZE)\b', st, re.I): continue
        st = re.sub(r'STORED AS ORC\s*', '', st).replace('CREATE OR REPLACE VIEW', 'CREATE VIEW')
        st = re.sub(r"CAST\('([\d-]+)' AS DATE\)", r"'\1'", st)
        yield st


def run(path):
    errs = 0
    for st in statements(path):
        m = re.match(r'CREATE VIEW (\w+)', st)
        if m: con.execute(f'DROP VIEW IF EXISTS {m.group(1)}')
        try:
            cur = con.execute(st)
            if re.match(r'(SELECT|WITH)', st, re.I):
                print(f'  OK {len(cur.fetchall()):>5} rows | {st[:70]!r}')
        except Exception as ex:
            errs += 1; print('  ERR', ex, '\n    ', st[:200].replace('\n', ' '))
    return errs


total = 0
for f in ['03_views.hql', '04_summary_tables.hql'] + [os.path.relpath(p, H) for p in sorted(glob.glob(H + 'queries/a*.hql'))]:
    print('==', f); total += run(H + f)
print('TOTAL ERRORS', total)
if EXPORT:
    os.makedirs(EXPORT, exist_ok=True)
    for (n,) in con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'sum\\_%' ESCAPE '\\'").fetchall():
        pd.read_sql(f'SELECT * FROM {n}', con).to_csv(f'{EXPORT}/{n}.csv', index=False)
        print('exported', n)
sys.exit(1 if total else 0)
