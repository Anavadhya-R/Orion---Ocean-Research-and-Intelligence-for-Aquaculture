from pathlib import Path

import pandas as pd
import streamlit as st

# --------------------------------------------------
# ORION: Ocean Research and Intelligence for Aquaculture
# --------------------------------------------------

ROOT = Path(__file__).resolve().parent

st.set_page_config(
    page_title="ORION | Ocean Intelligence",
    page_icon="🌊",
    layout="wide",
    initial_sidebar_state="expanded",
)


st.markdown(
    """
    <style>
    .stApp {
        background: linear-gradient(135deg, #071b2b, #103b50);
        color: #f4f8fc;
    }
    [data-testid="stSidebar"] {
        background-color: #102d42;
    }
    [data-testid="stSidebar"] * {
        color: #f4f8fc !important;
    }
    [data-testid="stMetric"] {
        background: #17445a;
        border: 1px solid #39758b;
        padding: 18px;
        border-radius: 14px;
    }
    [data-testid="stMetricLabel"] {
        color: #d4e9f2 !important;
    }
    [data-testid="stMetricValue"] {
        color: #ffffff !important;
    }
    h1, h2, h3 {
        color: #65d6d0 !important;
    }
    p, label, [data-testid="stCaptionContainer"] {
        color: #e0edf5;
    }
    </style>
    """,
    unsafe_allow_html=True,
)



def load_csv(relative_path):
    """Load a project CSV safely."""
    path = ROOT / relative_path
    if not path.exists():
        return None
    try:
        return pd.read_csv(path)
    except Exception:
        return None


DATASETS = {
    "Cluster assignments": "analytics/cluster_assignments.csv",
    "Cluster summary": "analytics/cluster_summary.csv",
    "Habitat match scores": "analytics/habitat_match_top5_per_site_detailed.csv",
    "Species missing data": "analytics/species_missing_data.csv",
    "Site risk profile": "spark/site_risk_profile.csv",
    "Site-month analytics": "spark/site_month_analytical.csv",
    "Data quality report": "spark/data_quality_report.csv",
    "Production by species": (
        "data/incoming-hive/orion/hive/exports/csv/"
        "sum_production_by_species_year.csv"
    ),
    "Production by region": (
        "data/incoming-hive/orion/hive/exports/csv/"
        "sum_production_by_basin_year.csv"
    ),
    "Overview KPIs": (
        "data/incoming-hive/orion/hive/exports/csv/"
        "sum_overview_kpis.csv"
    ),
    "Site performance": (
        "data/incoming-hive/orion/hive/exports/csv/"
        "sum_site_performance.csv"
    ),
    "Habitat by basin": (
        "data/incoming-hive/orion/hive/exports/csv/"
        "sum_habitat_by_basin.csv"
    ),
}

datasets = {
    name: df
    for name, path in DATASETS.items()
    if (df := load_csv(path)) is not None and not df.empty
}

st.sidebar.title("🌊 ORION")
st.sidebar.caption("Ocean Research & Intelligence for Aquaculture")
page = st.sidebar.radio(
    "Navigation",
    ["Dashboard", "Analytics Explorer", "Data Catalogue", "About ORION"],
)

st.sidebar.divider()
st.sidebar.caption("Data is loaded from the project's GitHub repository.")

if page == "Dashboard":
    st.title("🌊 ORION Ocean Intelligence")
    st.write(
        "An integrated view of aquaculture production, habitat suitability, "
        "site risk, and data quality."
    )

    st.subheader("Project overview")

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Datasets available", len(datasets))
    c2.metric(
        "Cluster records",
        f"{len(datasets['Cluster assignments']):,}"
        if "Cluster assignments" in datasets else "—",
    )
    c3.metric(
        "Habitat match records",
        f"{len(datasets['Habitat match scores']):,}"
        if "Habitat match scores" in datasets else "—",
    )
    c4.metric(
        "Site risk records",
        f"{len(datasets['Site risk profile']):,}"
        if "Site risk profile" in datasets else "—",
    )

    st.divider()
    left, right = st.columns(2)

    with left:
        st.subheader("Aquaculture production")
        production = datasets.get("Production by species")
        if production is not None:
            st.dataframe(production.head(10), use_container_width=True)
            numeric = production.select_dtypes(include="number")
            if not numeric.empty:
                column = st.selectbox(
                    "Production chart metric",
                    numeric.columns.tolist(),
                    key="production_metric",
                )
                st.bar_chart(production.set_index(
                    production.columns[0]
                )[column])
        else:
            st.info("Production summary CSV is not available.")

    with right:
        st.subheader("Site risk insights")
        risk = datasets.get("Site risk profile")
        if risk is not None:
            st.dataframe(risk.head(10), use_container_width=True)
            numeric = risk.select_dtypes(include="number")
            if not numeric.empty:
                column = st.selectbox(
                    "Risk chart metric",
                    numeric.columns.tolist(),
                    key="risk_metric",
                )
                st.bar_chart(risk.set_index(
                    risk.columns[0]
                )[column])
        else:
            st.info("Site risk profile CSV is not available.")

    st.subheader("Habitat suitability")
    habitat = datasets.get("Habitat match scores")
    if habitat is not None:
        st.write(
            f"Loaded {len(habitat):,} habitat-matching records."
        )
        st.dataframe(habitat.head(10), use_container_width=True)
    else:
        st.info("Habitat matching data is not available.")

elif page == "Analytics Explorer":
    st.title("📊 Analytics Explorer")
    st.write("Explore the analytical outputs generated by Orion.")

    if not datasets:
        st.warning("No CSV datasets were found. Check the repository paths.")
    else:
        selected = st.selectbox("Choose a dataset", list(datasets.keys()))
        df = datasets[selected]

        st.subheader(selected)
        st.caption(f"{len(df):,} rows · {len(df.columns)} columns")

        search = st.text_input("Filter rows by text")
        if search:
            mask = df.astype(str).apply(
                lambda col: col.str.contains(
                    search, case=False, na=False
                )
            ).any(axis=1)
            df = df[mask]

        st.dataframe(df, use_container_width=True, height=420)

        numeric = df.select_dtypes(include="number")
        if not numeric.empty:
            st.subheader("Visual analysis")
            metric = st.selectbox(
                "Choose a numeric column",
                numeric.columns.tolist(),
            )
            chart_data = df.copy()
            chart_data[metric] = pd.to_numeric(
                chart_data[metric], errors="coerce"
            )
            chart_data = chart_data.dropna(subset=[metric]).head(100)

            if not chart_data.empty:
                st.bar_chart(
                    chart_data.set_index(chart_data.columns[0])[metric]
                )

        st.download_button(
            "Download filtered CSV",
            data=df.to_csv(index=False).encode("utf-8"),
            file_name=f"{selected.lower().replace(' ', '_')}.csv",
            mime="text/csv",
        )

elif page == "Data Catalogue":
    st.title("🗂️ Orion Data Catalogue")
    st.write("Available project datasets and their dimensions.")

    if datasets:
        catalogue = pd.DataFrame([
            {
                "Dataset": name,
                "Rows": len(df),
                "Columns": len(df.columns),
                "Fields": ", ".join(map(str, df.columns)),
            }
            for name, df in datasets.items()
        ])
        st.dataframe(catalogue, use_container_width=True)
    else:
        st.warning("No datasets could be loaded.")

elif page == "About ORION":
    st.title("About ORION")
    st.write(
        """
        **ORION — Ocean Research and Intelligence for Aquaculture**

        ORION brings together data-driven insights to support aquaculture
        planning and monitoring.

        **Core capabilities**
        - Aquaculture production summaries
        - Habitat suitability and species matching
        - Site clustering and risk analysis
        - Data quality reporting
        - Interactive data exploration and CSV export

        The dashboard reads existing CSV outputs from the project repository.
        Missing datasets are reported rather than fabricated.
        """
    )

st.divider()
st.caption("ORION | Ocean Research and Intelligence for Aquaculture")
