
import { useState } from "react";
import "./index.css";
import "./species.css";
import"./species-catalog.css";
import "./orion-page-overrides.css";
const navigation = [
  { id: "overview", icon: "⌂", label: "Overview" },
  { id: "species", icon: "◉", label: "Species Explorer" },
  { id: "habitats", icon: "⌁", label: "Habitat Insights" },
  { id: "resources", icon: "▤", label: "Resource Manager" },
  { id: "finance", icon: "◷", label: "Finance Planner" },
];

const sources = [
  {
    title: "Ocean Biodiversity Information System",
    subtitle: "Marine species observations",
    tag: "Species data",
    url: "https://portal.obis.org/data/access/",
    icon: "✳",
  },
  {
    title: "Copernicus Marine",
    subtitle: "Ocean physics and conditions",
    tag: "Ocean data",
    url: "https://data.marine.copernicus.eu/",
    icon: "≈",
  },
  {
    title: "FAO Fisheries & Aquaculture",
    subtitle: "Global aquaculture statistics",
    tag: "Production data",
    url: "https://www.fao.org/statistics/data-collection/fishery-and-aquaculture/en",
    icon: "◌",
  },
];

function EmptyState({ icon = "✳", title, description }) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      <h3>{title}</h3>
      <p>{description}</p>
      <span className="status-pill">
        <span className="status-dot" />
        Awaiting team data
      </span>
    </div>
  );
}

function SpeciesExplorer() {
  const [search, setSearch] = useState("");
  const [habitat, setHabitat] = useState("All habitats");

  const habitats = ["All habitats", "Coral reef", "Open ocean", "Coastal", "Deep sea"];

  return (
    <div className="species-explorer species-catalog-page">
      <section className="catalog-toolbar">
        <div className="catalog-heading">
          <div className="catalog-title-row">
            <span className="catalog-title-icon">◎</span>
            <div>
              <span className="catalog-overline">BIODIVERSITY DIRECTORY</span>
              <h2>Marine species catalogue</h2>
            </div>
          </div>
          <p>Search verified marine observations and prepare to explore species records.</p>
        </div>
        <a className="catalog-source-link" href="https://portal.obis.org/data/access/" target="_blank" rel="noreferrer">
          OBIS data portal <span>↗</span>
        </a>
      </section>

      <section className="catalog-search-strip">
        <label className="catalog-search-field">
          <span aria-hidden="true">⌕</span>
          <input
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search common or scientific name..."
            aria-label="Search marine species"
          />
          {search && <button type="button" onClick={() => setSearch("")} aria-label="Clear search">×</button>}
        </label>
        <div className="catalog-source-status"><span className="catalog-status-dot" /> OBIS pipeline not connected</div>
      </section>

      <div className="catalog-layout">
        <aside className="catalog-filters">
          <div className="catalog-panel-heading">
            <span>REFINE RECORDS</span>
            <span className="catalog-filter-symbol">☷</span>
          </div>
          <h3>Habitat type</h3>
          <div className="catalog-habitat-list">
            {habitats.map((item) => (
              <button
                type="button"
                key={item}
                className={`catalog-habitat-option ${habitat === item ? "selected" : ""}`}
                onClick={() => setHabitat(item)}
                aria-pressed={habitat === item}
              >
                <span className="catalog-radio">{habitat === item ? "●" : "○"}</span>
                {item}
              </button>
            ))}
          </div>
          <div className="catalog-filter-note">
            <span>i</span>
            <p>Filters will apply to verified records when the dataset is connected.</p>
          </div>
        </aside>

        <section className="catalog-results">
          <div className="catalog-results-heading">
            <div>
              <span className="catalog-overline">RECORDS WORKSPACE</span>
              <h2>{search.trim() ? `Search: “${search.trim()}”` : "Species records"}</h2>
              <p>Habitat selected: {habitat.toLowerCase()}</p>
            </div>
            <span className="catalog-record-count">— <small>records</small></span>
          </div>

          <div className="catalog-empty-state">
            <div className="catalog-empty-graphic" aria-hidden="true">
              <span className="catalog-graphic-orbit orbit-one" />
              <span className="catalog-graphic-orbit orbit-two" />
              <span className="catalog-graphic-core">✳</span>
            </div>
            <span className="catalog-empty-kicker">DATA CONNECTION PENDING</span>
            <h3>{search.trim() ? "Ready to search marine records" : "Your catalogue is ready to connect"}</h3>
            <p>
              {search.trim()
                ? "Your search term is captured, but results will appear only after the real OBIS data pipeline is connected."
                : "Species names, taxonomy, occurrence locations and record details will appear here once the team connects verified OBIS data."}
            </p>
            <a className="catalog-open-mapper" href="https://mapper.obis.org/" target="_blank" rel="noreferrer">
              Explore records in OBIS Mapper <span>↗</span>
            </a>
          </div>

          <div className="catalog-results-footer">
            <span><span className="catalog-status-dot" /> No local records loaded</span>
            <span>Source planned: OBIS</span>
          </div>
        </section>
      </div>

      <section className="catalog-reference-row">
        <div className="catalog-reference-intro">
          <span className="catalog-overline">REFERENCE TOOLS</span>
          <h3>Useful biodiversity resources</h3>
          <p>External links for research while the data integration is in progress.</p>
        </div>
        <a href="https://portal.obis.org/data/access/" target="_blank" rel="noreferrer" className="catalog-reference-card">
          <span className="reference-icon reference-mint">✳</span>
          <span><strong>OBIS data access</strong><small>Marine occurrence records</small></span>
          <b>↗</b>
        </a>
        <a href="https://www.marinespecies.org/" target="_blank" rel="noreferrer" className="catalog-reference-card">
          <span className="reference-icon reference-lilac">◉</span>
          <span><strong>WoRMS</strong><small>Marine taxonomy reference</small></span>
          <b>↗</b>
        </a>
      </section>
    </div>
  );
}

function HabitatInsights() {
  return (
    <div className="workspace-page habitat-page">
      <div className="habitat-page-heading">
        <div>
          <span className="page-kicker">01 / ENVIRONMENTAL ANALYSIS</span>
          <h2>Habitat Insights</h2>
          <p>Understand ocean conditions and prepare to compare habitat suitability.</p>
        </div>
        <a href="https://data.marine.copernicus.eu/" target="_blank" rel="noreferrer" className="outline-link">Open Copernicus Marine ↗</a>
      </div>

      <div className="habitat-data-strip">
        <div className="habitat-data-symbol">≈</div>
        <div><strong>Ocean conditions workspace</strong><p>Temperature and salinity outputs will appear here after the data pipeline is connected.</p></div>
        <span className="data-status">DATA PENDING</span>
      </div>

      <div className="habitat-metrics-grid">
        <article className="habitat-metric temp-metric"><span className="metric-topline">ENVIRONMENTAL VARIABLE</span><div className="metric-icon">☼</div><h3>Temperature</h3><div className="metric-value">— <small>°C</small></div><p>Ocean temperature records</p><span className="metric-footnote">Awaiting Copernicus data</span></article>
        <article className="habitat-metric salinity-metric"><span className="metric-topline">ENVIRONMENTAL VARIABLE</span><div className="metric-icon">≋</div><h3>Salinity</h3><div className="metric-value">— <small>PSU</small></div><p>Ocean salinity records</p><span className="metric-footnote">Awaiting Copernicus data</span></article>
        <article className="habitat-metric cluster-metric"><span className="metric-topline">ANALYTICS OUTPUT</span><div className="metric-icon">◌</div><h3>Habitat clusters</h3><div className="metric-value">—</div><p>Cluster output from the team</p><span className="metric-footnote">Awaiting clustering results</span></article>
      </div>

      <div className="habitat-analysis-layout">
        <section className="habitat-visual-panel">
          <div className="panel-topline"><div><span className="page-kicker">ANALYSIS CANVAS</span><h3>Habitat comparison</h3></div><span className="small-status">Not connected</span></div>
          <div className="habitat-visual-placeholder">
            <div className="depth-lines"><i/><i/><i/><i/></div>
            <div className="habitat-circle habitat-circle-one"/><div className="habitat-circle habitat-circle-two"/><div className="habitat-circle habitat-circle-three"/>
            <div className="visual-placeholder-copy"><span>≈</span><strong>Environmental visualisations will appear here</strong><p>No chart or suitability score is shown until real analysis output is available.</p></div>
          </div>
        </section>
        <aside className="habitat-method-panel"><span className="page-kicker">WORKFLOW</span><h3>From ocean data to habitat insight</h3><ol><li><span>1</span><div><strong>Environmental data</strong><p>Load verified temperature and salinity data.</p></div></li><li><span>2</span><div><strong>Feature preparation</strong><p>Use cleaned features from the Spark workflow.</p></div></li><li><span>3</span><div><strong>Clustering results</strong><p>Display the team's actual cluster and match outputs.</p></div></li></ol><a href="https://mapper.obis.org/" target="_blank" rel="noreferrer" className="method-map-link">Explore OBIS Mapper ↗</a></aside>
      </div>
    </div>
  );
}

function ResourceManager() {
  return (
    <div className="workspace-page resource-page">
      <div className="resource-page-heading">
        <div><span className="page-kicker">PROJECT OPERATIONS / INVENTORY</span><h2>Resource Manager</h2><p>A practical workspace for organising project equipment, supplies and resource needs.</p></div>
        <div className="resource-heading-mark" aria-hidden="true">▤</div>
      </div>

      <div className="resource-summary-row">
        <div className="resource-summary-card"><span className="summary-symbol">▤</span><div><span>Total resources</span><strong>—</strong><small>Records not connected</small></div></div>
        <div className="resource-summary-card"><span className="summary-symbol summary-mint">✓</span><div><span>Available</span><strong>—</strong><small>Requires inventory data</small></div></div>
        <div className="resource-summary-card"><span className="summary-symbol summary-lilac">!</span><div><span>Needs attention</span><strong>—</strong><small>Requires inventory data</small></div></div>
      </div>

      <section className="resource-inventory-panel">
        <div className="resource-table-heading"><div><span className="page-kicker">INVENTORY REGISTER</span><h3>Project resources</h3><p>Real records will appear here once storage is connected.</p></div><span className="data-status">NO RECORDS YET</span></div>
        <div className="inventory-table-wrap"><table className="inventory-table"><thead><tr><th>RESOURCE NAME</th><th>CATEGORY</th><th>QUANTITY</th><th>AVAILABILITY</th><th>LAST UPDATED</th></tr></thead><tbody><tr><td colSpan={5} className="table-empty"><span className="table-empty-icon">▤</span><strong>Your inventory is empty</strong><br/>No resource records have been loaded. We will connect this table to the app's saved inventory later.</td></tr></tbody></table></div>
        <div className="resource-table-footer"><span><i/> Inventory data not connected</span><span>Storage integration planned</span></div>
      </section>

      <div className="resource-guidance-grid"><article><span className="guidance-icon">＋</span><div><h3>Add resources later</h3><p>A future form can capture item name, category, quantity, condition and notes.</p></div></article><article><span className="guidance-icon guidance-lilac">⇄</span><div><h3>Track availability</h3><p>Availability should be calculated from saved records, not placeholder examples.</p></div></article></div>
    </div>
  );
}

function FinancePlanner() {
  const [budget, setBudget] = useState("");
  const [equipment, setEquipment] = useState("");
  const [operations, setOperations] = useState("");
  const [maintenance, setMaintenance] = useState("");
  const [currency, setCurrency] = useState("INR");
  const money = (value) => new Intl.NumberFormat("en-IN", { style: "currency", currency, maximumFractionDigits: 2 }).format(value);
  const validAmounts = [equipment, operations, maintenance].every((value) => value.trim() !== "" && Number.isFinite(Number(value)) && Number(value) >= 0);
  const validBudget = budget.trim() !== "" && Number.isFinite(Number(budget)) && Number(budget) >= 0;
  const total = validAmounts ? Number(equipment) + Number(operations) + Number(maintenance) : null;
  const difference = total !== null && validBudget ? Number(budget) - total : null;

  return (
    <div className="workspace-page finance-page">
      <div className="finance-page-heading"><div><span className="page-kicker">PROJECT PLANNING / FINANCE</span><h2>Finance Planner</h2><p>Build a simple estimate from your own project costs. Nothing is saved or presented as real project finance data.</p></div><label className="finance-currency-select">Currency<select value={currency} onChange={(e) => setCurrency(e.target.value)}><option value="INR">INR · ₹</option><option value="USD">USD · $</option><option value="EUR">EUR · €</option></select></label></div>

      <div className="finance-planner-layout">
        <section className="finance-input-panel"><div className="finance-panel-heading"><span className="finance-panel-icon">＋</span><div><h3>Enter project estimates</h3><p>Use the same currency for every amount.</p></div></div>
          <div className="finance-fields"><label>Planned budget<input type="number" min="0" step="any" value={budget} onChange={(e) => setBudget(e.target.value)} placeholder="e.g. 50000"/><small>Your available budget</small></label><label>Equipment costs<input type="number" min="0" step="any" value={equipment} onChange={(e) => setEquipment(e.target.value)} placeholder="Enter estimate"/><small>Equipment and setup</small></label><label>Operating costs<input type="number" min="0" step="any" value={operations} onChange={(e) => setOperations(e.target.value)} placeholder="Enter estimate"/><small>Day-to-day operations</small></label><label>Maintenance costs<input type="number" min="0" step="any" value={maintenance} onChange={(e) => setMaintenance(e.target.value)} placeholder="Enter estimate"/><small>Repairs and upkeep</small></label></div>
          <button className="finance-reset" type="button" onClick={() => { setBudget(""); setEquipment(""); setOperations(""); setMaintenance(""); }}>Clear all estimates</button>
        </section>

        <aside className="finance-results-panel"><span className="page-kicker">YOUR ESTIMATE</span><h3>Cost summary</h3><p className="finance-results-intro">Results update from the amounts you enter.</p><div className="finance-total-label">ESTIMATED PROJECT COST</div><div className="finance-total-value">{total === null ? "—" : money(total)}</div><div className="finance-result-divider"/><div className="finance-budget-row"><span>Planned budget</span><strong>{validBudget ? money(Number(budget)) : "—"}</strong></div><div className="finance-budget-row"><span>Budget difference</span><strong className={difference !== null && difference < 0 ? "over-budget" : ""}>{difference === null ? "—" : money(difference)}</strong></div><div className={`finance-budget-note ${difference !== null ? (difference < 0 ? "over" : "under") : ""}`}>{difference === null ? "Enter all cost fields and a budget to compare." : difference < 0 ? "Your entered estimates exceed the planned budget." : "Your entered estimates fit within the planned budget."}</div></aside>
      </div>

      <div className="finance-disclaimer"><span>i</span><p><strong>Planning estimate only.</strong> These calculations use values you enter in this browser session. They are not connected to accounting records, persisted storage or team finance data.</p></div>
      <section className="finance-future-panel"><div className="future-icon">▥</div><div><span className="page-kicker">FUTURE REPORTING</span><h3>Project cost history and reports</h3><p>Saved scenarios, downloadable reports and comparisons can be added after backend storage is available.</p></div></section>
    </div>
  );
}

function App() {
  const [activePage, setActivePage] = useState("overview");
  const [search, setSearch] = useState("");

  const activeLabel =
    navigation.find((item) => item.id === activePage)?.label || "Overview";

  const pageDescriptions = {
    overview: "Your ocean research workspace, all in one place.",
    species: "Explore marine biodiversity using verified species records.",
    habitats: "Prepare habitat suitability insights from ocean conditions.",
    resources: "Organise your aquaculture resources and project requirements.",
    finance: "Plan operating costs using your own project estimates.",
  };

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="#overview" onClick={() => setActivePage("overview")}>
          <div className="brand-mark">O</div>
          <div>
            <div className="brand-name">orion<span>.</span></div>
            <div className="brand-caption">OCEAN INTELLIGENCE</div>
          </div>
        </a>

        <div className="workspace-label">WORKSPACE</div>

        <nav className="navigation">
          {navigation.map((item) => (
            <button
              key={item.id}
              className={`nav-item ${activePage === item.id ? "active" : ""}`}
              onClick={() => setActivePage(item.id)}
            >
              <span className="nav-icon">{item.icon}</span>
              <span>{item.label}</span>
              {activePage === item.id && <span className="active-indicator" />}
            </button>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="ocean-card">
            <div className="ocean-card-icon">≈</div>
            <div className="ocean-card-title">Research with purpose</div>
            <p>Better ocean insights for a more sustainable future.</p>
            <div className="wave-decoration">〜 〜 〜</div>
          </div>
          <div className="profile-row">
            <div className="avatar">OR</div>
            <div className="profile-copy">
              <strong>Research workspace</strong>
              <span>Member 5 · Frontend</span>
            </div>
            <span className="profile-menu">•••</span>
          </div>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div className="breadcrumb">
            Workspace <span>/</span> <strong>{activeLabel}</strong>
          </div>
          <div className="topbar-right">
            <span className="environment-pill">
              <span className="status-dot" /> Development
            </span>
            <div className="top-avatar">O</div>
          </div>
        </header>

        <div className="page-content">
          <section className={`welcome-row ${activePage !== "overview" ? "welcome-row-hidden" : ""}`}>
            <div>
              <div className="eyebrow">
                <span className="eyebrow-line" /> OCEAN RESEARCH PLATFORM
              </div>
              <h1>
                {activePage === "overview" ? (
                  <>A clearer view of <span>our oceans.</span></>
                ) : activeLabel}
              </h1>
              <p className="page-subtitle">{pageDescriptions[activePage]}</p>
            </div>
            <div className="date-note">
              <span className="date-icon">✧</span>
              <span>Explore. Understand. Sustain.</span>
            </div>
          </section>

          {activePage === "overview" ? (
            <>
              <section className="hero-banner">
                <div className="hero-copy">
                  <span className="hero-kicker">WELCOME TO ORION</span>
                  <h2>Discover the ocean<br />through data.</h2>
                  <p>
                    Bring marine biodiversity, ocean conditions and
                    aquaculture insights together in one thoughtful workspace.
                  </p>
                  <button
                    className="primary-button"
                    onClick={() => setActivePage("species")}
                  >
                    Explore your workspace <span>↗</span>
                  </button>
                </div>
                <div className="hero-art" aria-hidden="true">
                  <div className="orb orb-one" />
                  <div className="orb orb-two" />
                  <div className="orb orb-three" />
                  <div className="hero-ring ring-one" />
                  <div className="hero-ring ring-two" />
                  <div className="hero-ocean-symbol">≈</div>
                  <span className="art-label label-one">MARINE LIFE</span>
                  <span className="art-label label-two">OCEAN DATA</span>
                  <span className="art-label label-three">SUSTAINABILITY</span>
                </div>
                <div className="hero-bottom-note">
                  <span className="tiny-star">✳</span>
                  Built for ocean research and sustainable aquaculture
                </div>
              </section>

              <section className="section-block">
                <div className="section-heading">
                  <div>
                    <h2>Your research modules</h2>
                    <p>One connected space for your ocean intelligence workflow.</p>
                  </div>
                  <span className="muted-label">05 MODULES</span>
                </div>

                <div className="module-grid">
                  {[
                    {
                      id: "species",
                      icon: "✳",
                      title: "Species Explorer",
                      desc: "Marine species records and biodiversity.",
                      tone: "mint",
                    },
                    {
                      id: "habitats",
                      icon: "≈",
                      title: "Habitat Insights",
                      desc: "Prepare habitat matching and clustering results.",
                      tone: "blue",
                    },
                    {
                      id: "resources",
                      icon: "▤",
                      title: "Resource Manager",
                      desc: "Track your project resources and needs.",
                      tone: "lavender",
                    },
                    {
                      id: "finance",
                      icon: "◷",
                      title: "Finance Planner",
                      desc: "Estimate project costs and budgets.",
                      tone: "peach",
                    },
                  ].map((module) => (
                    <button
                      className="module-card"
                      key={module.id}
                      onClick={() => setActivePage(module.id)}
                    >
                      <div className={`module-icon ${module.tone}`}>
                        {module.icon}
                      </div>
                      <div className="module-arrow">↗</div>
                      <h3>{module.title}</h3>
                      <p>{module.desc}</p>
                      <div className="module-footer">
                        <span className="mini-status" />
                        Ready for integration
                      </div>
                    </button>
                  ))}
                </div>
              </section>

              <section className="section-block">
                <div className="section-heading">
                  <div>
                    <h2>Research data sources</h2>
                    <p>Open trusted sources for the datasets behind Orion.</p>
                  </div>
                  <span className="muted-label">EXTERNAL SOURCES</span>
                </div>

                <div className="source-list">
                  {sources.map((source) => (
                    <a
                      className="source-row"
                      href={source.url}
                      target="_blank"
                      rel="noreferrer"
                      key={source.title}
                    >
                      <div className="source-icon">{source.icon}</div>
                      <div className="source-copy">
                        <strong>{source.title}</strong>
                        <span>{source.subtitle}</span>
                      </div>
                      <span className="source-tag">{source.tag}</span>
                      <span className="external-arrow">↗</span>
                    </a>
                  ))}
                </div>
              </section>

              <section className="section-block">
                <div className="section-heading">
                  <div>
                    <h2>Ocean map links</h2>
                    <p>Open online tools without downloading map datasets.</p>
                  </div>
                </div>
                <div className="map-link-grid">
                  <a href="https://mapper.obis.org/" target="_blank" rel="noreferrer" className="map-link">
                    <span>◎</span>
                    <div><strong>OBIS Mapper</strong><small>Marine biodiversity map</small></div>
                    <b>↗</b>
                  </a>
                  <a href="https://data.marine.copernicus.eu/" target="_blank" rel="noreferrer" className="map-link">
                    <span>≈</span>
                    <div><strong>Copernicus Marine</strong><small>Ocean data and viewers</small></div>
                    <b>↗</b>
                  </a>
                </div>
              </section>
            </>
          ) : activePage === "species" ? (
            <SpeciesExplorer />
          ) : activePage === "habitats" ? (
            <HabitatInsights />
          ) : activePage === "resources" ? (
            <ResourceManager />
          ) : activePage === "finance" ? (
            <FinancePlanner />
          ) : (
            <EmptyState
              title="Workspace unavailable"
              description="This section is not available yet."
            />
          )}


          <footer className="footer">
            <span>ORION · Ocean Research & Intelligence for Aquaculture</span>
            <span>Built for a more sustainable blue future <b>✳</b></span>
          </footer>
        </div>
      </main>
    </div>
  );
}

export default App;
