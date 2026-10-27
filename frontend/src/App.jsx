
import { useEffect, useState } from "react";
import "./index.css";
import "./species.css";
import "./species-catalog.css";
import "./orion-page-overrides.css";
import Auth from "./Auth";
import "./auth.css";
import SpeciesImage from "./SpeciesImage";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "/api";

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

function getSpeciesName(record) {
  if (typeof record === "string") return record;

  const keys = [
    "species",
    "species_name",
    "common_name",
    "scientific_name",
    "name",
    "species_group",
    "taxon",
    "label",
  ];

  for (const key of keys) {
    const value = record?.[key];

    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }
  }

  return "";
}

function SpeciesExplorer() {
  const [search, setSearch] = useState("");
  const [habitat, setHabitat] = useState("All habitats");
  const [records, setRecords] = useState([]);
  const [status, setStatus] = useState("loading");
  const [retry, setRetry] = useState(0);

  const habitats = [
    "All habitats",
    "Coral reef",
    "Open ocean",
    "Coastal",
    "Deep sea",
  ];

  useEffect(() => {
    let cancelled = false;

    async function loadSpecies() {
      setStatus("loading");

      try {
        const response = await fetch(
          `${API_BASE}/data/species-ranking`
        );

        if (!response.ok) {
          throw new Error("Unable to load species-ranking data");
        }

        const data = await response.json();

        if (!Array.isArray(data)) {
          throw new Error("Unexpected species dataset format");
        }

        if (!cancelled) {
          setRecords(data);
          setStatus("loaded");
        }
      } catch (error) {
        console.error("Species data loading failed:", error);

        if (!cancelled) {
          setStatus("error");
        }
      }
    }

    loadSpecies();

    return () => {
      cancelled = true;
    };
  }, [retry]);

  const filteredRecords = records.filter((record) => {
    const name = getSpeciesName(record);

    const matchesSearch = JSON.stringify(record)
      .toLowerCase()
      .includes(search.trim().toLowerCase());

    // Habitat categories are not inferred from species names.
    // Apply a habitat filter only when the record contains habitat metadata.
    const recordHabitat = String(
      record?.habitat ??
      record?.habitat_type ??
      record?.environment ??
      ""
    ).toLowerCase();

    const matchesHabitat =
      habitat === "All habitats" ||
      (recordHabitat !== "" &&
        recordHabitat.includes(habitat.toLowerCase()));

    return (name || typeof record === "object") &&
      matchesSearch &&
      matchesHabitat;
  });

  return (
    <div className="species-explorer species-catalog-page">
      <section className="catalog-toolbar">
        <div className="catalog-heading">
          <div className="catalog-title-row">
            <span className="catalog-title-icon">◎</span>
            <div>
              <span className="catalog-overline">
                BIODIVERSITY DIRECTORY
              </span>
              <h2>Marine species catalogue</h2>
            </div>
          </div>
          <p>
            Search and explore species-ranking records from the team's
            aquaculture dataset.
          </p>
        </div>

        <a
          className="catalog-source-link"
          href="https://portal.obis.org/data/access/"
          target="_blank"
          rel="noreferrer"
        >
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
            placeholder="Search species or dataset fields..."
            aria-label="Search species records"
          />
          {search && (
            <button
              type="button"
              onClick={() => setSearch("")}
              aria-label="Clear search"
            >
              ×
            </button>
          )}
        </label>

        <div className="catalog-source-status">
          <span className="catalog-status-dot" />
          {status === "loaded"
            ? "Team dataset connected"
            : status === "error"
              ? "Connection failed"
              : "Loading dataset"}
        </div>
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
                className={`catalog-habitat-option ${
                  habitat === item ? "selected" : ""
                }`}
                onClick={() => setHabitat(item)}
                aria-pressed={habitat === item}
              >
                <span className="catalog-radio">
                  {habitat === item ? "●" : "○"}
                </span>
                {item}
              </button>
            ))}
          </div>

          <div className="catalog-filter-note">
            <span>i</span>
            <p>
              Habitat filtering works when records include habitat metadata.
              Records without habitat information are shown under All habitats.
            </p>
          </div>
        </aside>

        <section className="catalog-results">
          <div className="catalog-results-heading">
            <div>
              <span className="catalog-overline">
                TEAM DATA WORKSPACE
              </span>
              <h2>
                {search.trim()
                  ? `Search: “${search.trim()}”`
                  : "Species records"}
              </h2>
              <p>
                Habitat selected: {habitat.toLowerCase()}
              </p>
            </div>

            <span className="catalog-record-count">
              {status === "loaded" ? filteredRecords.length : "—"}
              <small> records</small>
            </span>
          </div>

          {status === "loading" && (
            <div className="catalog-empty-state" role="status">
              <div className="catalog-empty-graphic" aria-hidden="true">
                <span className="catalog-graphic-orbit orbit-one" />
                <span className="catalog-graphic-orbit orbit-two" />
                <span className="catalog-graphic-core">✳</span>
              </div>
              <span className="catalog-empty-kicker">
                LOADING DATA
              </span>
              <h3>Loading species records</h3>
              <p>
                Orion is retrieving the species-ranking dataset from the
                backend.
              </p>
            </div>
          )}

          {status === "error" && (
            <div className="catalog-empty-state" role="alert">
              <div className="catalog-empty-graphic" aria-hidden="true">
                <span className="catalog-graphic-core">!</span>
              </div>
              <span className="catalog-empty-kicker">
                CONNECTION ISSUE
              </span>
              <h3>Could not load species data</h3>
              <p>
                Check that the Express server is running and that
                /api/data/species-ranking returns a JSON array.
              </p>
              <button
                type="button"
                className="catalog-open-mapper"
                onClick={() => setRetry((value) => value + 1)}
              >
                Try again ↻
              </button>
            </div>
          )}

          {status === "loaded" && filteredRecords.length === 0 && (
            <div className="catalog-empty-state">
              <div className="catalog-empty-graphic" aria-hidden="true">
                <span className="catalog-graphic-core">⌕</span>
              </div>
              <span className="catalog-empty-kicker">
                NO MATCHING RECORDS
              </span>
              <h3>No species records match your filters</h3>
              <p>
                Try another search term or select All habitats. The dataset
                may not include habitat metadata.
              </p>
              <button
                type="button"
                className="catalog-open-mapper"
                onClick={() => {
                  setSearch("");
                  setHabitat("All habitats");
                }}
              >
                Clear filters
              </button>
            </div>
          )}

          {status === "loaded" && filteredRecords.length > 0 && (
            <div className="species-record-list">
              {filteredRecords.map((record, index) => {
                const name = getSpeciesName(record);
                const id =
                  record?.id ??
                  record?.species_id ??
                  `${name || "record"}-${index}`;

                const details =
                  record && typeof record === "object"
                    ? Object.entries(record)
                        .filter(
                          ([key, value]) =>
                            key !== "id" &&
                            key !== "species_id" &&
                            value !== null &&
                            value !== undefined &&
                            typeof value !== "object"
                        )
                        .slice(0, 4)
                    : [];


return (
  <article
    className="catalog-reference-card species-photo-card"
    key={String(id)}
  >
    <div className="species-card-photo">
      <SpeciesImage
        speciesName={name || `marine fish species ${index + 1}`}
      />
    </div>

    <span className="reference-icon reference-mint">
      ✳
    </span>

    <span className="species-card-information">
      <strong>
        {name || `Species record ${index + 1}`}
      </strong>

      <small>
        {details.length > 0
          ? details
              .map(
                ([key, value]) =>
                  `${key.replaceAll("_", " ")}: ${value}`
              )
              .join(" · ")
          : "Species-ranking dataset record"}
      </small>
    </span>
  </article>
);

              })}
            </div>
          )}

          <div className="catalog-results-footer">
            <span>
              <span className="catalog-status-dot" />
              {status === "loaded"
                ? `${filteredRecords.length} matching records`
                : status === "error"
                  ? "Data unavailable"
                  : "Retrieving records"}
            </span>
            <span>Source: team species-ranking export</span>
          </div>
        </section>
      </div>

      <section className="catalog-reference-row">
        <div className="catalog-reference-intro">
          <span className="catalog-overline">REFERENCE TOOLS</span>
          <h3>Useful biodiversity resources</h3>
          <p>
            External references for researching marine species.
          </p>
        </div>

        <a
          href="https://portal.obis.org/data/access/"
          target="_blank"
          rel="noreferrer"
          className="catalog-reference-card"
        >
          <span className="reference-icon reference-mint">✳</span>
          <span>
            <strong>OBIS data access</strong>
            <small>Marine occurrence records</small>
          </span>
          <b>↗</b>
        </a>

        <a
          href="https://www.marinespecies.org/"
          target="_blank"
          rel="noreferrer"
          className="catalog-reference-card"
        >
          <span className="reference-icon reference-lilac">◉</span>
          <span>
            <strong>WoRMS</strong>
            <small>Marine taxonomy reference</small>
          </span>
          <b>↗</b>
        </a>
      </section>
    </div>
  );
}


function HabitatInsights() {
  const [habitat, setHabitat] = useState("Coastal");
  const [temperature, setTemperature] = useState(28);
  const [salinity, setSalinity] = useState(25);
  const [oxygen, setOxygen] = useState(6);
  const [ph, setPh] = useState(8);

  const habitatGuides = {
    Coastal: {
      title: "Coastal waters",
      description: "Monitor changing coastal conditions and protect sensitive marine habitats.",
      temperature: "24–32°C",
      salinity: "25–35 ppt",
    },
    Estuary: {
      title: "Estuary",
      description: "Estuaries mix freshwater and seawater, so salinity can change quickly.",
      temperature: "22–32°C",
      salinity: "5–25 ppt",
    },
    Freshwater: {
      title: "Freshwater",
      description: "Freshwater ponds and lakes need stable oxygen and water quality.",
      temperature: "24–30°C",
      salinity: "0–0.5 ppt",
    },
    Offshore: {
      title: "Offshore waters",
      description: "Offshore sites require attention to water conditions and changing ocean currents.",
      temperature: "20–30°C",
      salinity: "30–36 ppt",
    },
  };

  const guide = habitatGuides[habitat];

  const checks = [
    {
      name: "Temperature",
      value: `${temperature}°C`,
      status: temperature >= 24 && temperature <= 32 ? "Within guide" : "Review",
      good: temperature >= 24 && temperature <= 32,
    },
    {
      name: "Salinity",
      value: `${salinity} ppt`,
      status:
        (habitat === "Freshwater" && salinity <= 0.5) ||
        (habitat === "Estuary" && salinity >= 5 && salinity <= 25) ||
        (habitat === "Coastal" && salinity >= 25 && salinity <= 35) ||
        (habitat === "Offshore" && salinity >= 30 && salinity <= 36)
          ? "Within guide"
          : "Review",
      good:
        (habitat === "Freshwater" && salinity <= 0.5) ||
        (habitat === "Estuary" && salinity >= 5 && salinity <= 25) ||
        (habitat === "Coastal" && salinity >= 25 && salinity <= 35) ||
        (habitat === "Offshore" && salinity >= 30 && salinity <= 36),
    },
    {
      name: "Dissolved oxygen",
      value: `${oxygen} mg/L`,
      status: oxygen >= 5 ? "Within guide" : "Low",
      good: oxygen >= 5,
    },
    {
      name: "pH",
      value: ph.toFixed(1),
      status: ph >= 7 && ph <= 8.5 ? "Within guide" : "Review",
      good: ph >= 7 && ph <= 8.5,
    },
  ];

  return (
    <div className="workspace-page habitat-page">
      <div className="resource-page-heading">
        <div>
          <span className="page-kicker">ENVIRONMENT / WATER QUALITY</span>
          <h2>Habitat Insights</h2>
          <p>Explore habitat types and check example water-quality readings.</p>
        </div>
        <div className="resource-heading-mark" aria-hidden="true">≈</div>
      </div>

      <section className="resource-inventory-panel habitat-selector-panel">
        <div className="resource-table-heading">
          <div>
            <span className="page-kicker">HABITAT EXPLORER</span>
            <h3>Select a habitat</h3>
            <p>Choose a habitat to see its overview and reference ranges.</p>
          </div>
        </div>

        <div className="habitat-options">
          {Object.keys(habitatGuides).map((item) => (
            <button
              type="button"
              key={item}
              className={`habitat-option ${habitat === item ? "active" : ""}`}
              onClick={() => {
                setHabitat(item);
                if (item === "Freshwater") setSalinity(0.3);
                else if (item === "Estuary") setSalinity(15);
                else if (item === "Coastal") setSalinity(30);
                else setSalinity(34);
              }}
            >
              {item}
            </button>
          ))}
        </div>

        <div className="habitat-overview">
          <span className="page-kicker">CURRENT SELECTION</span>
          <h3>{guide.title}</h3>
          <p>{guide.description}</p>
          <div className="habitat-reference-grid">
            <div><span>Reference temperature</span><strong>{guide.temperature}</strong></div>
            <div><span>Reference salinity</span><strong>{guide.salinity}</strong></div>
          </div>
        </div>
      </section>

      <section className="resource-inventory-panel habitat-check-panel">
        <div className="resource-table-heading">
          <div>
            <span className="page-kicker">INTERACTIVE WATER CHECK</span>
            <h3>Sample water-quality readings</h3>
            <p>Adjust the values to see whether they fall within these general guides.</p>
          </div>
          <span className="data-status">DEMO VALUES</span>
        </div>

        <div className="habitat-controls">
          <label>
            Temperature: <strong>{temperature}°C</strong>
            <input type="range" min="10" max="40" value={temperature} onChange={(e) => setTemperature(Number(e.target.value))} />
          </label>
          <label>
            Salinity: <strong>{salinity} ppt</strong>
            <input type="range" min="0" max="40" step="0.5" value={salinity} onChange={(e) => setSalinity(Number(e.target.value))} />
          </label>
          <label>
            Dissolved oxygen: <strong>{oxygen} mg/L</strong>
            <input type="range" min="0" max="12" step="0.5" value={oxygen} onChange={(e) => setOxygen(Number(e.target.value))} />
          </label>
          <label>
            pH: <strong>{ph.toFixed(1)}</strong>
            <input type="range" min="4" max="10" step="0.1" value={ph} onChange={(e) => setPh(Number(e.target.value))} />
          </label>
        </div>

        <div className="habitat-results">
          {checks.map((check) => (
            <div className="habitat-result-row" key={check.name}>
              <div><strong>{check.name}</strong><span>{check.value}</span></div>
              <span className={`habitat-status ${check.good ? "good" : "warning"}`}>
                {check.status}
              </span>
            </div>
          ))}
        </div>

        <p className="habitat-disclaimer">
          Educational demonstration only. These broad reference ranges are not a
          species-specific safety assessment. Actual suitability depends on species,
          life stage, local conditions and reliable field measurements.
        </p>
      </section>
    </div>
  );
}



function ResourceManager() {
  const [resources, setResources] = useState(() => {
  try {
    const saved = JSON.parse(
      localStorage.getItem("orion-resource-inventory") || "[]"
    );
    return Array.isArray(saved) ? saved : [];
  } catch {
    return [];
  }
});
  const [name, setName] = useState("");
  const [category, setCategory] = useState("Equipment");
  const [quantity, setQuantity] = useState("1");
  const [condition, setCondition] = useState("Available");
  useEffect(() => {
  try {
    localStorage.setItem(
      "orion-resource-inventory",
      JSON.stringify(resources)
    );
  } catch (error) {
    console.error("Unable to save resources:", error);
  }
}, [resources]);
  const addResource = (event) => {
    event.preventDefault();
    const trimmedName = name.trim();
    const amount = Number(quantity);

    if (!trimmedName || !Number.isInteger(amount) || amount < 1) return;

    setResources((current) => [
      ...current,
      {
        id: `${Date.now()}-${Math.random()}`,
        name: trimmedName,
        category,
        quantity: amount,
        condition,
        updated: new Date().toLocaleDateString(),
      },
    ]);

    setName("");
    setQuantity("1");
    setCategory("Equipment");
    setCondition("Available");
  };

  const available = resources.filter(
    (item) => item.condition === "Available"
  ).length;

  const needsAttention = resources.filter(
    (item) => item.condition !== "Available"
  ).length;

  return (
    <div className="workspace-page resource-page">
      <div className="resource-page-heading">
        <div>
          <span className="page-kicker">PROJECT OPERATIONS / INVENTORY</span>
          <h2>Resource Manager</h2>
          <p>Add and manage equipment, supplies and project resources.</p>
        </div>
        <div className="resource-heading-mark" aria-hidden="true">▤</div>
      </div>

      <div className="resource-summary-row">
        <div className="resource-summary-card">
          <span className="summary-symbol">▤</span>
          <div><span>Total resources</span><strong>{resources.length}</strong><small>Inventory records</small></div>
        </div>
        <div className="resource-summary-card">
          <span className="summary-symbol summary-mint">✓</span>
          <div><span>Available</span><strong>{available}</strong><small>Ready to use</small></div>
        </div>
        <div className="resource-summary-card">
          <span className="summary-symbol summary-lilac">!</span>
          <div><span>Needs attention</span><strong>{needsAttention}</strong><small>Check condition</small></div>
        </div>
      </div>

      <section className="resource-inventory-panel">
        <div className="resource-table-heading">
          <div>
            <span className="page-kicker">INVENTORY REGISTER</span>
            <h3>Project resources</h3>
            <p>Enter a resource below to add it to this session's inventory.</p>
          </div>
          <span className="data-status">SESSION STORAGE</span>
        </div>

        <form className="resource-add-form" onSubmit={addResource}>
          <label>
            Resource name
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Water quality sensor" required />
          </label>
          <label>
            Category
            <select value={category} onChange={(e) => setCategory(e.target.value)}>
              <option>Equipment</option>
              <option>Supplies</option>
              <option>Feed</option>
              <option>Testing</option>
              <option>Other</option>
            </select>
          </label>
          <label>
            Quantity
            <input type="number" min="1" step="1" value={quantity} onChange={(e) => setQuantity(e.target.value)} required />
          </label>
          <label>
            Condition
            <select value={condition} onChange={(e) => setCondition(e.target.value)}>
              <option>Available</option>
              <option>Low stock</option>
              <option>Needs repair</option>
              <option>Unavailable</option>
            </select>
          </label>
          <button type="submit" className="primary-button">+ Add resource</button>
        </form>

        <div className="inventory-table-wrap">
          <table className="inventory-table">
            <thead>
              <tr>
                <th>RESOURCE NAME</th>
                <th>CATEGORY</th>
                <th>QUANTITY</th>
                <th>AVAILABILITY</th>
                <th>LAST UPDATED</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {resources.length === 0 ? (
                <tr>
                  <td colSpan={6} className="table-empty">
                    <span className="table-empty-icon">▤</span>
                    <strong>Your inventory is empty</strong>
                    <br />Add your first resource using the form above.
                  </td>
                </tr>
              ) : (
                resources.map((item) => (
                  <tr key={item.id}>
                    <td>{item.name}</td>
                    <td>{item.category}</td>
                    <td>{item.quantity}</td>
                    <td>{item.condition}</td>
                    <td>{item.updated}</td>
                    <td>
                      <button type="button" onClick={() => setResources((current) => current.filter((r) => r.id !== item.id))}>
                        Delete
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="resource-table-footer">
          <span><i /> {resources.length} inventory records</span>
          <span>Not yet saved to the backend</span>
        </div>
      </section>
    </div>
  );
}



function FinancePlanner() {
  const STORAGE_KEY = "orion-finance-estimates";

  const [estimates, setEstimates] = useState(() => {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
      if (!saved || typeof saved !== "object") return null;
      return saved;
    } catch {
      return null;
    }
  });

  const [budget, setBudget] = useState(estimates?.budget ?? "");
  const [equipment, setEquipment] = useState(estimates?.equipment ?? "");
  const [operations, setOperations] = useState(estimates?.operations ?? "");
  const [maintenance, setMaintenance] = useState(estimates?.maintenance ?? "");
  const [currency, setCurrency] = useState(estimates?.currency ?? "INR");
  const [savedMessage, setSavedMessage] = useState("");
  const [planName, setPlanName] = useState("");
const [planHistory, setPlanHistory] = useState(() => {
  try {
    return JSON.parse(
      localStorage.getItem("orion-finance-history") || "[]"
    );
  } catch {
    return [];
  }
});

useEffect(() => {
  const data = {
    budget,
    equipment,
    operations,
    maintenance,
    currency,
  };

  const hasValues = [
    budget,
    equipment,
    operations,
    maintenance,
  ].some((value) => String(value).trim() !== "");

  if (!hasValues) {
    setSavedMessage("Enter your estimates to begin planning.");
    return;
  }

  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    setSavedMessage("Your estimates are saved in this browser.");
  } catch (error) {
    console.error("Finance save failed:", error);
    setSavedMessage("Unable to save estimates. Check browser storage settings.");
  }
}, [budget, equipment, operations, maintenance, currency]);


  const money = (value) =>
    new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency,
      maximumFractionDigits: 2,
    }).format(value);

  const validAmount = (value) =>
    value.trim() !== "" &&
    Number.isFinite(Number(value)) &&
    Number(value) >= 0;

  const validAmounts = [equipment, operations, maintenance].every(validAmount);
  const validBudget = validAmount(budget);

  const total = validAmounts
    ? Number(equipment) + Number(operations) + Number(maintenance)
    : null;

  const difference =
    total !== null && validBudget ? Number(budget) - total : null;

  const clearEstimates = () => {
  localStorage.removeItem(STORAGE_KEY);
  setBudget("");
  setEquipment("");
  setOperations("");
  setMaintenance("");
  setSavedMessage("Estimates cleared.");
};

const saveFinancePlan = () => {
  const name = planName.trim();

  if (!name) {
    setSavedMessage("Please enter a name for this finance plan.");
    return;
  }

  const plan = {
    id: `${Date.now()}-${Math.random()}`,
    name,
    date: new Date().toLocaleString(),
    budget,
    equipment,
    operations,
    maintenance,
    currency,
  };

  const updatedHistory = [plan, ...planHistory];

  try {
    localStorage.setItem(
      "orion-finance-history",
      JSON.stringify(updatedHistory)
    );

    setPlanHistory(updatedHistory);
    setPlanName("");
    setSavedMessage(`"${name}" saved to finance history.`);
  } catch (error) {
    console.error("Unable to save finance history:", error);
    setSavedMessage("Unable to save this plan. Check browser storage.");
  }
};

  return (
    <div className="workspace-page finance-page">
      <div className="finance-page-heading">
        <div>
          <span className="page-kicker">PROJECT PLANNING / FINANCE</span>
          <h2>Finance Planner</h2>
          <p>Estimate your aquaculture project costs and track your budget.</p>
        </div>

        <label className="finance-currency-select">
          Currency
          <select
            value={currency}
            onChange={(event) => setCurrency(event.target.value)}
          >
            <option value="INR">INR · ₹</option>
            <option value="USD">USD · $</option>
            <option value="EUR">EUR · €</option>
          </select>
        </label>
      </div>

      <div className="finance-planner-layout">
        <section className="finance-input-panel">
          <div className="finance-panel-heading">
            <span className="finance-panel-icon">＋</span>
            <div>
              <h3>Enter project estimates</h3>
              <p>Use the same currency for every amount.</p>
            </div>
          </div>

          <div className="finance-fields">
            <label>
              Planned budget
              <input
                type="number"
                min="0"
                step="any"
                value={budget}
                onChange={(event) => setBudget(event.target.value)}
                placeholder="e.g. 50000"
              />
              <small>Your available budget</small>
            </label>

            <label>
              Equipment costs
              <input
                type="number"
                min="0"
                step="any"
                value={equipment}
                onChange={(event) => setEquipment(event.target.value)}
                placeholder="Enter estimate"
              />
              <small>Equipment and setup</small>
            </label>

            <label>
              Operating costs
              <input
                type="number"
                min="0"
                step="any"
                value={operations}
                onChange={(event) => setOperations(event.target.value)}
                placeholder="Enter estimate"
              />
              <small>Feed, electricity and daily operations</small>
            </label>

            <label>
              Maintenance costs
              <input
                type="number"
                min="0"
                step="any"
                value={maintenance}
                onChange={(event) => setMaintenance(event.target.value)}
                placeholder="Enter estimate"
              />
              <small>Repairs and upkeep</small>
            </label>
          </div>

          <button
            className="finance-reset"
            type="button"
            onClick={clearEstimates}
          >
            Clear all estimates
          </button>
        </section>

        <aside className="finance-results-panel">
          <span className="page-kicker">YOUR ESTIMATE</span>
          <h3>Cost summary</h3>
          <p className="finance-results-intro">
            Results update automatically as you enter amounts.
          </p>

          <div className="finance-total-label">ESTIMATED PROJECT COST</div>
          <div className="finance-total-value">
            {total === null ? "—" : money(total)}
          </div>

          <div className="finance-result-divider" />

          <div className="finance-budget-row">
            <span>Planned budget</span>
            <strong>{validBudget ? money(Number(budget)) : "—"}</strong>
          </div>

          <div className="finance-budget-row">
            <span>{difference !== null && difference < 0 ? "Over budget" : "Budget remaining"}</span>
            <strong className={difference !== null && difference < 0 ? "over-budget" : ""}>
              {difference === null ? "—" : money(Math.abs(difference))}
            </strong>
          </div>

          <div className={`finance-budget-note ${difference !== null ? (difference < 0 ? "over" : "under") : ""}`}>
            {difference === null
              ? "Enter all cost fields and a budget to compare."
              : difference < 0
                ? "Your estimates exceed the planned budget."
                : difference === 0
                  ? "Your estimates exactly match the budget."
                  : "Your estimates fit within the planned budget."}
          </div>
        </aside>
      </div>

      <div className="finance-disclaimer">
        <span>i</span>
        <p>
          <strong>Planning estimate only.</strong> Your estimates are saved
          locally in this browser. They are not connected to accounting
          records or shared with other users.
        </p>
      </div>


<section className="finance-history-panel">
  <div className="finance-history-heading">
    <div>
      <span className="page-kicker">FINANCE ARCHIVE</span>
      <h3>Saved Finance Plans</h3>
      <p>Save and revisit your previous estimates.</p>
    </div>
    <span>{planHistory.length} saved plans</span>
  </div>

  <form
    className="finance-save-form"
    onSubmit={(event) => {
      event.preventDefault();
      saveFinancePlan();
    }}
  >
    <label htmlFor="finance-plan-name">Plan name</label>
    <input
      id="finance-plan-name"
      value={planName}
      onChange={(event) => setPlanName(event.target.value)}
      placeholder="e.g. Coastal Farm Budget"
      required
    />
    <button type="submit" className="primary-button">
      Save current plan
    </button>
  </form>

  {planHistory.length === 0 ? (
    <p>No saved plans yet. Save your first estimate above.</p>
  ) : (
    <div className="finance-history-list">
      {planHistory.map((plan) => {
        const costs = [
          plan.equipment,
          plan.operations,
          plan.maintenance,
        ];
        const costsValid = costs.every(
          (value) =>
            String(value).trim() !== "" &&
            Number.isFinite(Number(value)) &&
            Number(value) >= 0
        );
        const totalCosts = costsValid
          ? costs.reduce((sum, value) => sum + Number(value), 0)
          : null;

        return (
          <article className="finance-history-item" key={plan.id}>
            <div>
              <strong>{plan.name}</strong>
              <p>{plan.date}</p>
              <small>
                Budget: {plan.currency} {plan.budget || "—"}
                {" · "}Total costs:{" "}
                {totalCosts === null
                  ? "—"
                  : new Intl.NumberFormat("en-IN", {
                      maximumFractionDigits: 2,
                    }).format(totalCosts)}
              </small>
            </div>

            <div className="finance-history-actions">
              <button
                type="button"
                onClick={() => {
                  setBudget(plan.budget);
                  setEquipment(plan.equipment);
                  setOperations(plan.operations);
                  setMaintenance(plan.maintenance);
                  setCurrency(plan.currency);
                  setSavedMessage(`Loaded "${plan.name}".`);
                }}
              >
                Load
              </button>

              <button
                type="button"
                onClick={() => {
                  const updated = planHistory.filter(
                    (item) => item.id !== plan.id
                  );
                  try {
                    localStorage.setItem(
                      "orion-finance-history",
                      JSON.stringify(updated)
                    );
                    setPlanHistory(updated);
                    setSavedMessage(`Deleted "${plan.name}" from history.`);
                  } catch (error) {
                    console.error(error);
                    setSavedMessage("Unable to update finance history.");
                  }
                }}
              >
                Delete
              </button>
            </div>
          </article>
        );
      })}
    </div>
  )}
  <small className="finance-save-status" role="status">
    {savedMessage}
  </small>
</section>

    </div>

  );
}


function App() {
  const [activePage, setActivePage] = useState(() => {
  return sessionStorage.getItem("orion_active_page") || "overview";
});

  const [user, setUser] = useState(() => {
    try {
      return JSON.parse(sessionStorage.getItem("orion_user")) || null;
    } catch {
      return null;
    }
  });

  const [authChecking, setAuthChecking] = useState(() =>
    Boolean(sessionStorage.getItem("orion_token"))
  );

  const [kpis, setKpis] = useState([]);
  const [kpiStatus, setKpiStatus] = useState("loading");
  useEffect(() => {
  sessionStorage.setItem("orion_active_page", activePage);
}, [activePage]);
  useEffect(() => {
    let cancelled = false;

    async function loadKpis() {
      try {
        const response = await fetch(
          `${API_BASE}/data/overview-kpis`
        );

        if (!response.ok) {
          throw new Error("Unable to load KPIs");
        }

        const data = await response.json();

        if (!Array.isArray(data)) {
          throw new Error("Unexpected KPI dataset format");
        }

        if (!cancelled) {
          setKpis(data);
          setKpiStatus("loaded");
        }
      } catch (error) {
        console.error("KPI loading failed:", error);

        if (!cancelled) {
          setKpiStatus("error");
        }
      }
    }

    loadKpis();

    return () => {
      cancelled = true;
    };
  }, []);

  const formatKpi = (value, unit) => {
    const number = Number(value);

    if (!Number.isFinite(number)) {
      return value ?? "—";
    }

    if (unit === "USD") {
      return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
        maximumFractionDigits: 0,
      }).format(number);
    }

    const formatted = new Intl.NumberFormat("en-US", {
      maximumFractionDigits: 2,
    }).format(number);

    if (unit === "tonnes") return `${formatted} t`;
    if (unit === "%") return `${formatted}%`;

    return formatted;
  };

  useEffect(() => {
    const token = sessionStorage.getItem("orion_token");

    if (!token) {
      sessionStorage.removeItem("orion_user");
      setUser(null);
      setAuthChecking(false);
      return;
    }

    let cancelled = false;

    async function verifySession() {
      try {
        const response = await fetch(`${API_BASE}/auth/me`, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error("Session expired or invalid");
        }

        const data = await response.json();
        const verifiedUser = data.user || data;

        if (!verifiedUser || !verifiedUser.role) {
          throw new Error("Invalid user response");
        }

        if (!cancelled) {
          sessionStorage.setItem(
            "orion_user",
            JSON.stringify(verifiedUser)
          );
          setUser(verifiedUser);
        }
      } catch (error) {
        if (!cancelled) {
          console.error("Session verification failed:", error);
          sessionStorage.removeItem("orion_token");
          sessionStorage.removeItem("orion_user");
          setUser(null);
        }
      } finally {
        if (!cancelled) {
          setAuthChecking(false);
        }
      }
    }

    verifySession();

    return () => {
      cancelled = true;
    };
  }, []);

  const handleLogout = async () => {
    const token = sessionStorage.getItem("orion_token");

    try {
      await fetch(`${API_BASE}/auth/logout`, {
        method: "POST",
        headers: token
          ? { Authorization: `Bearer ${token}` }
          : {},
      });
    } catch (error) {
      console.error("Logout request failed:", error);
    } finally {
      sessionStorage.removeItem("orion_token");
      sessionStorage.removeItem("orion_user");
      setUser(null);
      setActivePage("overview");
    }
  };

  if (authChecking) {
    return (
      <div className="auth-loading" role="status">
        Verifying your Orion session...
      </div>
    );
  }

  if (!user) {
    return (
      <Auth
        onAuthenticated={(authenticatedUser) => {
          setUser(authenticatedUser);
          setActivePage("overview");
        }}
      />
    );
  }

  const role = user.role;

  const allowedPages =
    role === "Admin"
      ? ["overview", "species", "habitats", "resources", "finance"]
      : role === "Farmer"
        ? ["overview", "species", "habitats", "resources"]
        : role === "Researcher"
          ? ["overview", "species", "habitats"]
          : [];

  const visibleNavigation = navigation.filter((item) =>
    allowedPages.includes(item.id)
  );

  const safeActivePage = allowedPages.includes(activePage)
    ? activePage
    : "overview";

  const activeLabel =
    navigation.find((item) => item.id === safeActivePage)?.label ||
    "Overview";

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
        <a
          className="brand"
          href="#overview"
          onClick={() => setActivePage("overview")}
        >
          <div className="brand-mark">O</div>
          <div>
            <div className="brand-name">
              orion<span>.</span>
            </div>
            <div className="brand-caption">OCEAN INTELLIGENCE</div>
          </div>
        </a>

        <div className="workspace-label">WORKSPACE</div>

        <nav className="navigation">
          {visibleNavigation.map((item) => (
            <button
              key={item.id}
              className={`nav-item ${
                safeActivePage === item.id ? "active" : ""
              }`}
              onClick={() => setActivePage(item.id)}
            >
              <span className="nav-icon">{item.icon}</span>
              <span>{item.label}</span>
              {safeActivePage === item.id && (
                <span className="active-indicator" />
              )}
            </button>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="ocean-card">
            <div className="ocean-card-icon">≈</div>
            <div className="ocean-card-title">Research with purpose</div>
            <p>
              Better ocean insights for a more sustainable future.
            </p>
            <div className="wave-decoration">〜 〜 〜</div>
          </div>

          <div className="profile-row">
            <div className="avatar">
              {(user.name || user.email || "OR")
                .slice(0, 2)
                .toUpperCase()}
            </div>

            <div className="profile-copy">
              <strong>{user.name || user.email || "Orion user"}</strong>
              <span>{user.role || "User"}</span>
            </div>

            <button
              type="button"
              className="profile-menu"
              onClick={handleLogout}
              aria-label="Log out"
            >
              Logout
            </button>
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
          <section
            className={`welcome-row ${
              safeActivePage !== "overview" ? "welcome-row-hidden" : ""
            }`}
          >
            <div>
              <div className="eyebrow">
                <span className="eyebrow-line" />
                OCEAN RESEARCH PLATFORM
              </div>

              <h1>
                {safeActivePage === "overview" ? (
                  <>
                    A clearer view of <span>our oceans.</span>
                  </>
                ) : (
                  activeLabel
                )}
              </h1>

              <p className="page-subtitle">
                {pageDescriptions[safeActivePage]}
              </p>
            </div>

            <div className="date-note">
              <span className="date-icon">✧</span>
              <span>Explore. Understand. Sustain.</span>
            </div>
          </section>

          {safeActivePage === "overview" ? (
            <>
              <section className="hero-banner">
                <div className="hero-copy">
                  <span className="hero-kicker">WELCOME TO ORION</span>
                  <h2>
                    Discover the ocean
                    <br />
                    through data.
                  </h2>
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
                  <span className="art-label label-three">
                    SUSTAINABILITY
                  </span>
                </div>

                <div className="hero-bottom-note">
                  <span className="tiny-star">✳</span>
                  Built for ocean research and sustainable aquaculture
                </div>
              </section>

              <section className="section-block">
                <div className="section-heading">
                  <div>
                    <h2>Aquaculture at a glance</h2>
                    <p>Metrics from the team's exported dataset.</p>
                  </div>

                  <span className="muted-label">
                    {kpiStatus === "loaded"
                      ? "LIVE DATA"
                      : kpiStatus === "error"
                        ? "DATA UNAVAILABLE"
                        : "LOADING"}
                  </span>
                </div>

                {kpiStatus === "loading" && (
                  <p>Loading aquaculture metrics...</p>
                )}

                {kpiStatus === "error" && (
                  <p role="alert">
                    Could not load the dataset. Check that the backend is
                    running and the API is available.
                  </p>
                )}

                {kpiStatus === "loaded" && (
                  <div className="module-grid">
                    {[
                      ["total_production_tonnes", "Total production", "tonnes"],
                      ["total_revenue_usd", "Total revenue", "USD"],
                      ["profit_margin_pct", "Profit margin", "%"],
                      ["species_catalogue", "Species catalogue", "count"],
                      ["sites_total", "Total sites", "count"],
                      [
                        "high_suitability_cells_pct",
                        "High-suitability habitats",
                        "%",
                      ],
                    ].map(([key, label, unit]) => {
                      const metric = kpis.find(
                        (item) => item.metric === key
                      );

                      return (
                        <article className="module-card" key={key}>
                          <h3>{label}</h3>
                          <p>
                            {metric
                              ? formatKpi(
                                  metric.metric_value,
                                  unit === "count" ? "" : unit
                                )
                              : "—"}
                          </p>
                        </article>
                      );
                    })}
                  </div>
                )}
              </section>

              <section className="section-block">
                <div className="section-heading">
                  <div>
                    <h2>Your research modules</h2>
                    <p>
                      One connected space for your ocean intelligence
                      workflow.
                    </p>
                  </div>
                  <span className="muted-label">
                    {allowedPages.length.toString().padStart(2, "0")} MODULES
                  </span>
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
                  ]
                    .filter((module) => allowedPages.includes(module.id))
                    .map((module) => (
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
                    <p>
                      Open trusted sources for the datasets behind Orion.
                    </p>
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
                    <p>
                      Open online tools without downloading map datasets.
                    </p>
                  </div>
                </div>

                <div className="map-link-grid">
                  <a
                    href="https://mapper.obis.org/"
                    target="_blank"
                    rel="noreferrer"
                    className="map-link"
                  >
                    <span>◎</span>
                    <div>
                      <strong>OBIS Mapper</strong>
                      <small>Marine biodiversity map</small>
                    </div>
                    <b>↗</b>
                  </a>

                  <a
                    href="https://data.marine.copernicus.eu/"
                    target="_blank"
                    rel="noreferrer"
                    className="map-link"
                  >
                    <span>≈</span>
                    <div>
                      <strong>Copernicus Marine</strong>
                      <small>Ocean data and viewers</small>
                    </div>
                    <b>↗</b>
                  </a>
                </div>
              </section>
            </>
          ) : safeActivePage === "species" ? (
            <SpeciesExplorer />
          ) : safeActivePage === "habitats" ? (
            <HabitatInsights />
          ) : safeActivePage === "resources" ? (
            <ResourceManager />
          ) : safeActivePage === "finance" ? (
            <FinancePlanner />
          ) : (
            <EmptyState
              title="Workspace unavailable"
              description="This section is not available yet."
            />
          )}

          <footer className="footer">
            <span>
              ORION · Ocean Research &amp; Intelligence for Aquaculture
            </span>
            <span>
              Built for a more sustainable blue future <b>✳</b>
            </span>
          </footer>
        </div>
      </main>
    </div>
  );
}

export default App;
