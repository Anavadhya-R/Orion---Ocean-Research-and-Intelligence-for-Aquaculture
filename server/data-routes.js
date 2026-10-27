const express = require("express");
const fs = require("fs/promises");
const path = require("path");

const router = express.Router();
const dataDir = path.join(__dirname, "data");

const datasets = {
  "overview-kpis": "sum_overview_kpis.json",
  "species-ranking": "sum_species_ranking.json",
  "production-by-species": "sum_production_by_species_year.json",
  "habitat-by-basin": "sum_habitat_by_basin.json",
  "ocean-basin-month": "sum_ocean_basin_month.json",
  "inventory-status": "sum_inventory_status.json",
  "finance-monthly": "sum_finance_monthly.json",
  "production-monthly": "sum_production_monthly.json",
  "production-by-basin": "sum_production_by_basin_year.json",
  "production-by-country": "sum_production_by_country_year.json",
  "production-by-site-type": "sum_production_by_site_type_year.json",
  "production-by-species-group": "sum_production_by_species_group_basin.json",
  "site-performance": "sum_site_performance.json"
};

router.get("/:dataset", async (req, res) => {
  const filename = datasets[req.params.dataset];

  if (!filename) {
    return res.status(404).json({ error: "Dataset not found" });
  }

  try {
    const contents = await fs.readFile(path.join(dataDir, filename), "utf8");
    res.json(JSON.parse(contents));
  } catch (error) {
    console.error("Dataset read failed:", error.message);
    res.status(500).json({ error: "Unable to load dataset" });
  }
});

module.exports = router;
