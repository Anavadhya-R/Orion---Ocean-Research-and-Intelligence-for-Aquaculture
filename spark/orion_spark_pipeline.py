r"""
Orion - Member 2: Apache Spark processing pipeline
===================================================
Cleans, standardizes, joins and feature-engineers the Orion marine / aquaculture
data and writes analysis-ready CSVs.

Usage
-----
    spark-submit orion_spark_pipeline.py \
        --workbook OrionDataset.xlsx \      # or --input-dir <folder of per-sheet CSVs>
        --out-dir  output

Input: either the per-sheet CSVs (marine_species.csv, ocean_conditions.csv,
aquaculture_sites.csv, fish_production.csv, finance_transactions.csv) in
--input-dir, or the Excel workbook (converted to CSV by pandas first, because
Spark has no native xlsx reader).

Outputs (in --out-dir, single CSV files):
    ocean_conditions_clean_spark.csv   cleaned ocean measurements (before/after demo)
    site_month_analytical.csv          MAIN analysis-ready dataset, one row per production_id
    site_risk_profile.csv              one row per site (aggregated risk / exposure)
    data_quality_report.csv            row counts, null / duplicate counts per step

Stages
    1 clean      dedupe, type-cast, standardize labels/units, range-check, impute
    2 join       ocean -> site by 10-degree grid cell + year_month (fallback: basin + year_month)
                 finance -> production by related_production_id, species -> production by species_id
    3 features   marine risk score, financial exposure, derived indicators
"""
import argparse
import os

from pyspark.sql import SparkSession, Window, functions as F
from pyspark.sql.types import DoubleType

# --------------------------------------------------------------------------- config
GRID_DEG = 10  # grid cell size used to match site coordinates to ocean measurements

# physically plausible ranges; values outside become NULL and are then imputed
VALID_RANGES = {
    "latitude": (-90, 90), "longitude": (-180, 180), "depth_m": (0, 11000),
    "sea_surface_temperature_c": (-2.5, 40), "water_temperature_c": (-2.5, 40),
    "salinity_psu": (0, 45), "dissolved_oxygen_mg_l": (0, 20), "ph": (6.5, 9.0),
    "chlorophyll_a_mg_m3": (0, 100), "nitrate_umol_l": (0, 100),
    "wave_height_m": (0, 30), "current_speed_m_s": (0, 5),
}
ENV_COLS = ["sea_surface_temperature_c", "water_temperature_c", "salinity_psu",
            "dissolved_oxygen_mg_l", "ph", "chlorophyll_a_mg_m3", "nitrate_umol_l",
            "wave_height_m", "current_speed_m_s"]
NUM_COLS_OCEAN = ["latitude", "longitude", "depth_m"] + ENV_COLS

# risk-score weights (sum = 1.0)
RISK_WEIGHTS = {"temp": 0.30, "oxygen": 0.20, "salinity": 0.15,
                "wave": 0.15, "chlorophyll": 0.10, "ph": 0.10}
# relative risk bands from the portfolio distribution of combined_risk_score:
# <=P50 Low, <=P80 Moderate, <=P95 High, above P95 Severe
BAND_QUANTILES = [0.50, 0.80, 0.95]
BAND_LABELS = ["Low", "Moderate", "High", "Severe"]


def clip01(c):
    return F.least(F.greatest(c, F.lit(0.0)), F.lit(1.0))


def to_bool(col):
    return F.lower(F.trim(col.cast("string"))).isin("true", "1", "yes")


# --------------------------------------------------------------------------- IO
def read_csv(spark, path):
    return spark.read.csv(path, header=True, inferSchema=True)


def load_inputs(spark, args):
    names = ["marine_species", "ocean_conditions", "aquaculture_sites",
             "fish_production", "finance_transactions"]
    in_dir = args.input_dir
    if args.workbook:
        import pandas as pd
        in_dir = os.path.join(args.out_dir, "_staging_csv")
        os.makedirs(in_dir, exist_ok=True)
        sheets = pd.read_excel(args.workbook, sheet_name=None)
        for name in names:
            # sheet names can be truncated by Excel's 31-char limit
            key = next(k for k in sheets if name.startswith(k) or k.startswith(name))
            sheets[key].to_csv(os.path.join(in_dir, f"{name}.csv"), index=False)
    return {n: read_csv(spark, os.path.join(in_dir, f"{n}.csv")) for n in names}


def write_single_csv(df, out_dir, filename):
    tmp = os.path.join(out_dir, "_tmp_" + filename)
    df.coalesce(1).write.mode("overwrite").option("header", True).csv(tmp)
    part = next(f for f in os.listdir(tmp) if f.startswith("part-") and f.endswith(".csv"))
    os.replace(os.path.join(tmp, part), os.path.join(out_dir, filename))
    import shutil
    shutil.rmtree(tmp, ignore_errors=True)


# --------------------------------------------------------------------------- 1. CLEAN
def clean_ocean(df, dq):
    """Dedupe, cast, standardize, range-check and impute ocean_conditions."""
    dq.append(("ocean_conditions", "raw_rows", df.count()))
    dq.append(("ocean_conditions", "raw_null_cells",
               df.select(sum(F.col(c).isNull().cast("int") for c in df.columns)
                         .alias("n")).agg(F.sum("n")).first()[0]))

    df = df.dropDuplicates(["measurement_id"])
    df = df.dropDuplicates([c for c in df.columns if c != "measurement_id"])
    dq.append(("ocean_conditions", "rows_after_dedupe", df.count()))

    for c in NUM_COLS_OCEAN:
        df = df.withColumn(c, F.col(c).cast(DoubleType()))
    df = (df
          .withColumn("measurement_date", F.to_date("measurement_date"))
          .withColumn("ocean_basin", F.initcap(F.trim("ocean_basin")))
          .withColumn("is_synthetic", to_bool(F.col("is_synthetic")))
          .filter(F.col("measurement_date").isNotNull()))

    # range check -> NULL (inconsistent values are treated as missing, not dropped)
    for c, (lo, hi) in VALID_RANGES.items():
        df = df.withColumn(c, F.when(F.col(c).between(lo, hi), F.col(c)))
    df = df.filter(F.col("latitude").isNotNull() & F.col("longitude").isNotNull())

    df = (df.withColumn("year", F.year("measurement_date"))
            .withColumn("month", F.month("measurement_date"))
            .withColumn("year_month", F.date_format("measurement_date", "yyyy-MM")))

    # impute: median of (basin, month) -> median of basin -> global median
    df = df.withColumn("n_imputed", sum(F.col(c).isNull().cast("int") for c in ENV_COLS))
    w_bm = ["ocean_basin", "month"]
    for c in ENV_COLS:
        med_bm = df.groupBy(*w_bm).agg(F.percentile_approx(c, 0.5).alias("_bm"))
        med_b = df.groupBy("ocean_basin").agg(F.percentile_approx(c, 0.5).alias("_b"))
        med_g = df.agg(F.percentile_approx(c, 0.5)).first()[0]
        df = (df.join(med_bm, w_bm, "left").join(med_b, "ocean_basin", "left")
                .withColumn(c, F.round(F.coalesce(F.col(c), F.col("_bm"), F.col("_b"),
                                                  F.lit(med_g)), 4))
                .drop("_bm", "_b"))

    # derived grid keys used for the join
    df = (df.withColumn("grid_lat", F.floor(F.col("latitude") / GRID_DEG).cast("int"))
            .withColumn("grid_lon", F.floor(F.col("longitude") / GRID_DEG).cast("int")))
    dq.append(("ocean_conditions", "clean_rows", df.count()))
    dq.append(("ocean_conditions", "clean_null_cells",
               df.select(sum(F.col(c).isNull().cast("int") for c in ENV_COLS)
                         .alias("n")).agg(F.sum("n")).first()[0]))
    return df


def clean_sites(df):
    df = df.dropDuplicates(["site_id"])
    for c in ["latitude", "longitude", "farm_area_hectares", "water_depth_m",
              "average_temperature_c", "average_salinity_psu",
              "average_dissolved_oxygen_mg_l", "water_quality_index",
              "infrastructure_access_score", "environmental_risk_score",
              "estimated_production_capacity_tonnes_year"]:
        df = df.withColumn(c, F.col(c).cast(DoubleType()))
    return (df.withColumn("ocean_basin", F.initcap(F.trim("ocean_basin")))
              .withColumn("site_type", F.lower(F.trim("site_type")))
              .withColumn("site_status", F.trim("site_status"))
              .withColumn("grid_lat", F.floor(F.col("latitude") / GRID_DEG).cast("int"))
              .withColumn("grid_lon", F.floor(F.col("longitude") / GRID_DEG).cast("int"))
              .select("site_id", "site_name", "country_or_region", "ocean_basin", "site_type",
                      "site_status", "latitude", "longitude", "grid_lat", "grid_lon",
                      "farm_area_hectares", "water_depth_m", "water_quality_index",
                      "infrastructure_access_score",
                      F.col("environmental_risk_score").alias("site_environmental_risk_score"),
                      F.col("estimated_production_capacity_tonnes_year").alias("capacity_tonnes_year")))


def clean_production(df):
    df = df.dropDuplicates(["production_id"])
    num = ["production_tonnes", "feed_consumption_tonnes", "feed_conversion_ratio",
           "mortality_rate_percent", "survival_rate_percent", "operating_cost_usd", "revenue_usd"]
    for c in num:
        df = df.withColumn(c, F.col(c).cast(DoubleType()))
    df = (df.withColumn("reporting_year", F.col("reporting_year").cast("int"))
            .withColumn("reporting_month", F.col("reporting_month").cast("int"))
            .withColumn("year_month", F.format_string("%04d-%02d", "reporting_year", "reporting_month"))
            # FCR of 0 with zero feed = "no feeding recorded", not a real ratio
            .withColumn("feed_conversion_ratio",
                        F.when(F.col("feed_consumption_tonnes") > 0, F.col("feed_conversion_ratio")))
            .withColumn("feeding_recorded", F.col("feed_consumption_tonnes") > 0))
    return df.drop("data_origin")


def clean_species(df):
    return (df.dropDuplicates(["species_id"])
              .select("species_id", "common_name", "species_group", "habitat_type",
                      "min_temperature_c", "max_temperature_c",
                      "min_salinity_psu", "max_salinity_psu", "conservation_status",
                      "aquaculture_potential"))


def finance_by_production(fin):
    """Pivot transactions to one row per production_id (USD, already one currency)."""
    fin = fin.dropDuplicates(["transaction_id"]).withColumn(
        "amount_usd", F.col("amount_usd").cast(DoubleType()))
    cat = F.regexp_replace(F.lower(F.col("category")), "[^a-z]+", "_")
    fin = fin.withColumn("cat", cat)
    agg = (fin.groupBy("related_production_id")
              .agg(F.sum(F.when(F.col("transaction_type") == "income", F.col("amount_usd"))).alias("fin_income_usd"),
                   F.sum(F.when(F.col("transaction_type") == "expense", F.col("amount_usd"))).alias("fin_expense_usd"),
                   F.count("*").alias("fin_txn_count")))
    cats = (fin.filter(F.col("transaction_type") == "expense")
               .groupBy("related_production_id").pivot("cat").sum("amount_usd"))
    for c in cats.columns[1:]:
        cats = cats.withColumnRenamed(c, f"cost_{c}_usd")
    return (agg.join(cats, "related_production_id", "left")
               .withColumnRenamed("related_production_id", "production_id")
               .na.fill(0.0, [c for c in cats.columns if c.startswith("cost_")]))


# --------------------------------------------------------------------------- 2. JOIN
def ocean_monthly_aggregates(ocean):
    aggs = [F.round(F.avg(c), 4).alias(f"env_{c}") for c in ENV_COLS]
    cell = (ocean.groupBy("grid_lat", "grid_lon", "year_month")
                 .agg(*aggs, F.count("*").alias("env_n_obs")))
    basin = (ocean.groupBy("ocean_basin", "year_month")
                  .agg(*aggs, F.count("*").alias("env_n_obs")))
    return cell, basin


def attach_environment(prod_sites, ocean):
    cell, basin = ocean_monthly_aggregates(ocean)
    env_cols = [f"env_{c}" for c in ENV_COLS] + ["env_n_obs"]
    j1 = prod_sites.join(cell, ["grid_lat", "grid_lon", "year_month"], "left")
    matched = j1.filter(F.col("env_n_obs").isNotNull()).withColumn("env_join_level", F.lit("grid10_month"))
    missed = j1.filter(F.col("env_n_obs").isNull()).drop(*env_cols)
    fb = (missed.join(basin, ["ocean_basin", "year_month"], "left")
                .withColumn("env_join_level",
                            F.when(F.col("env_n_obs").isNotNull(), F.lit("basin_month"))
                             .otherwise(F.lit("unmatched"))))
    return matched.unionByName(fb.select(matched.columns))


# --------------------------------------------------------------------------- 3. FEATURES
def add_features(df):
    # ---- environmental stress components, each scaled 0 (no stress) .. 1 (max stress)
    t, s = F.col("env_water_temperature_c"), F.col("env_salinity_psu")
    t_out = F.greatest(F.col("min_temperature_c") - t, t - F.col("max_temperature_c"), F.lit(0.0))
    s_out = F.greatest(F.col("min_salinity_psu") - s, s - F.col("max_salinity_psu"), F.lit(0.0))
    df = (df
          .withColumn("temp_deviation_c", F.round(t_out, 3))          # degrees outside species tolerance
          .withColumn("salinity_deviation_psu", F.round(s_out, 3))
          .withColumn("temp_stress", clip01(t_out / 10.0))
          .withColumn("salinity_stress", clip01(s_out / 10.0))
          .withColumn("oxygen_stress", clip01((F.lit(6.0) - F.col("env_dissolved_oxygen_mg_l")) / 3.0))
          .withColumn("wave_stress", clip01((F.col("env_wave_height_m") - 1.0) / 3.0))
          .withColumn("chlorophyll_stress", clip01((F.col("env_chlorophyll_a_mg_m3") - 5.0) / 15.0))
          .withColumn("ph_stress", clip01(F.abs(F.col("env_ph") - 8.1) / 0.5)))

    w = RISK_WEIGHTS
    score = (w["temp"] * F.col("temp_stress") + w["oxygen"] * F.col("oxygen_stress")
             + w["salinity"] * F.col("salinity_stress") + w["wave"] * F.col("wave_stress")
             + w["chlorophyll"] * F.col("chlorophyll_stress") + w["ph"] * F.col("ph_stress")) * 100
    df = df.withColumn("marine_risk_score", F.round(score, 2))
    # blend with the site's own baseline environmental risk (0-100) from aquaculture_sites
    df = df.withColumn("combined_risk_score",
                       F.round(0.7 * F.col("marine_risk_score")
                               + 0.3 * F.col("site_environmental_risk_score"), 2))
    q = df.approxQuantile("combined_risk_score", BAND_QUANTILES, 0.001)
    cs = F.col("combined_risk_score")
    df = df.withColumn("risk_band",
                       F.when(cs <= q[0], BAND_LABELS[0]).when(cs <= q[1], BAND_LABELS[1])
                        .when(cs <= q[2], BAND_LABELS[2]).otherwise(BAND_LABELS[3]))

    # ---- financial indicators
    rev, cost = F.col("revenue_usd"), F.col("operating_cost_usd")
    df = (df
          .withColumn("net_profit_usd", F.round(rev - cost, 2))
          .withColumn("profit_margin_pct", F.round(F.when(rev > 0, (rev - cost) / rev * 100), 2))
          .withColumn("revenue_per_tonne_usd", F.round(rev / F.col("production_tonnes"), 2))
          .withColumn("cost_per_tonne_usd", F.round(cost / F.col("production_tonnes"), 2))
          .withColumn("feed_cost_share_pct",
                      F.round(F.when(cost > 0, F.col("cost_feed_usd") / cost * 100), 2))
          .withColumn("mortality_loss_usd", F.round(rev * F.col("mortality_rate_percent") / 100, 2))
          .withColumn("capacity_utilization_pct",
                      F.round(F.col("production_tonnes") * 12 / F.col("capacity_tonnes_year") * 100, 2))
          # financial exposure: share of revenue / cost base exposed to the environmental risk score
          .withColumn("revenue_at_risk_usd", F.round(rev * F.col("combined_risk_score") / 100, 2))
          .withColumn("cost_at_risk_usd", F.round(cost * F.col("combined_risk_score") / 100, 2))
          .withColumn("exposure_ratio", F.round(F.col("revenue_at_risk_usd") / F.col("net_profit_usd"), 3))
          .withColumn("risk_adjusted_profit_usd",
                      F.round(F.col("net_profit_usd") - F.col("revenue_at_risk_usd") * 0.25, 2))
          .withColumn("loss_making", F.col("net_profit_usd") < 0))
    # exposure_ratio is only meaningful when profit > 0
    df = df.withColumn("exposure_ratio", F.when(F.col("net_profit_usd") > 0, F.col("exposure_ratio")))

    # ---- time-series features per site (3-month rolling, month-over-month)
    wsite = Window.partitionBy("site_id", "species_id").orderBy("year_month")
    wroll = wsite.rowsBetween(-2, 0)
    df = (df.withColumn("rolling3_risk_score", F.round(F.avg("combined_risk_score").over(wroll), 2))
            .withColumn("rolling3_net_profit_usd", F.round(F.avg("net_profit_usd").over(wroll), 2))
            .withColumn("prev_month_production_tonnes", F.lag("production_tonnes").over(wsite))
            .withColumn("production_mom_change_pct",
                        F.round(F.when(F.col("prev_month_production_tonnes") > 0,
                                       (F.col("production_tonnes") / F.col("prev_month_production_tonnes") - 1) * 100), 2))
            .drop("prev_month_production_tonnes"))
    return df


def site_profile(df):
    return (df.groupBy("site_id", "site_name", "country_or_region", "ocean_basin", "site_type", "site_status")
              .agg(F.count("*").alias("n_production_records"),
                   F.round(F.sum("production_tonnes"), 2).alias("total_production_tonnes"),
                   F.round(F.sum("revenue_usd"), 2).alias("total_revenue_usd"),
                   F.round(F.sum("operating_cost_usd"), 2).alias("total_cost_usd"),
                   F.round(F.sum("net_profit_usd"), 2).alias("total_net_profit_usd"),
                   F.round(F.avg("combined_risk_score"), 2).alias("avg_combined_risk_score"),
                   F.round(F.max("combined_risk_score"), 2).alias("max_combined_risk_score"),
                   F.round(F.sum("revenue_at_risk_usd"), 2).alias("total_revenue_at_risk_usd"),
                   F.round(F.sum("mortality_loss_usd"), 2).alias("total_mortality_loss_usd"),
                   F.round(F.avg("mortality_rate_percent"), 2).alias("avg_mortality_rate_percent"),
                   F.round(F.stddev("net_profit_usd"), 2).alias("net_profit_volatility_usd"),
                   F.round(F.avg(F.col("loss_making").cast("int")) * 100, 2).alias("loss_making_months_pct"))
              .withColumn("revenue_at_risk_pct",
                          F.round(F.col("total_revenue_at_risk_usd") / F.col("total_revenue_usd") * 100, 2)))


# --------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workbook")
    ap.add_argument("--input-dir")
    ap.add_argument("--out-dir", default="output")
    args = ap.parse_args()
    assert args.workbook or args.input_dir, "give --workbook or --input-dir"
    os.makedirs(args.out_dir, exist_ok=True)

    spark = (SparkSession.builder.appName("orion-pipeline")
             .config("spark.sql.session.timeZone", "UTC").getOrCreate())
    raw = load_inputs(spark, args)
    dq = []

    ocean = clean_ocean(raw["ocean_conditions"], dq).cache()
    sites = clean_sites(raw["aquaculture_sites"])
    prod = clean_production(raw["fish_production"])
    species = clean_species(raw["marine_species"])
    fin = finance_by_production(raw["finance_transactions"])
    for name, d in [("aquaculture_sites", sites), ("fish_production", prod), ("marine_species", species)]:
        dq.append((name, "clean_rows", d.count()))

    base = (prod.join(sites, "site_id", "left")
                .join(species, "species_id", "left")
                .join(fin, "production_id", "left"))
    joined = attach_environment(base, ocean)
    dq.append(("site_month_analytical", "rows", joined.count()))
    dq.append(("site_month_analytical", "env_unmatched_rows",
               joined.filter(F.col("env_join_level") == "unmatched").count()))
    final = add_features(joined)

    ordered = (["production_id", "site_id", "species_id", "year_month", "reporting_year", "reporting_month"]
               + [c for c in final.columns if c not in
                  ("production_id", "site_id", "species_id", "year_month", "reporting_year",
                   "reporting_month", "grid_lat", "grid_lon")])
    final = final.select(*ordered).orderBy("site_id", "year_month", "production_id")

    write_single_csv(ocean.drop("grid_lat", "grid_lon").orderBy("measurement_id"),
                     args.out_dir, "ocean_conditions_clean_spark.csv")
    write_single_csv(final, args.out_dir, "site_month_analytical.csv")
    write_single_csv(site_profile(final).orderBy("site_id"), args.out_dir, "site_risk_profile.csv")
    dq_df = spark.createDataFrame([(a, b, int(c)) for a, b, c in dq], ["dataset", "metric", "value"])
    write_single_csv(dq_df, args.out_dir, "data_quality_report.csv")
    spark.stop()


if __name__ == "__main__":
    main()
