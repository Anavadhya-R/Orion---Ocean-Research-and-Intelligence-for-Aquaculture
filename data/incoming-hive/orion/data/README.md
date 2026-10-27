# data/ - ORION datasets

| File | Rows | Description |
|---|---|---|
| OrionDataset.xlsx (10 sheets used) | | marine_species 130, species_occurrences 15,814, aquaculture_sites 1,000, habitat_suitability 10,600, species_environment_compat 10,500, fish_production 7,279, finance_transactions 56,270, resource_inventory 3,354, dashboard_kpis 5,699 (+ ocean_conditions = same as the raw CSV) |
| cleaneddata.zip: ocean_conditions_raw.csv | 21,996 | ocean measurements BEFORE cleaning (4,260 empty cells) |
| cleaneddata.zip: ocean_conditions_cleaned.csv | 21,996 | AFTER cleaning (empty cells imputed) |
| reference/data_dictionary.csv, dataset_summary.csv | | supplied with the dataset; source of the column descriptions |

`prepare_csv.py` writes `data/csv/` (git-ignored, regenerated). `sample/` has the first 100 rows of each CSV.

## Provenance and licence
All datasets are **simulated / synthetic** (flags `is_synthetic`, `is_simulated`, `data_origin = synthetic_simulation`, `SIMULATED_*` source labels,
and the dataset summary says so). Species names are real taxa with approximate ranges. There is therefore no third-party licence,
but results describe a simulation, not real farms: never present them as real production, finance or ecosystem data.
Record who generated the simulation and how (script / seed) here before submitting the report.
