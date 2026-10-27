-- ORION | A09 Inventory and KPI checks
USE orion;

-- 1. Stock status by resource category
SELECT resource_category, resource_status, SUM(items) AS items, ROUND(SUM(stock_value_usd), 0) AS stock_value_usd
FROM sum_inventory_status
GROUP BY resource_category, resource_status
ORDER BY resource_category, items DESC;

-- 2. Sites with the most low / out-of-stock items (restock priority)
SELECT r.site_id, s.site_name, s.ocean_basin,
       SUM(CASE WHEN r.resource_status = 'Out_of_Stock' THEN 1 ELSE 0 END) AS out_of_stock,
       SUM(CASE WHEN r.resource_status = 'Low_Stock' THEN 1 ELSE 0 END)    AS low_stock,
       COUNT(*) AS items
FROM resource_inventory r JOIN aquaculture_sites s ON r.site_id = s.site_id
GROUP BY r.site_id, s.site_name, s.ocean_basin
HAVING SUM(CASE WHEN r.resource_status <> 'In_Stock' THEN 1 ELSE 0 END) > 0
ORDER BY out_of_stock DESC, low_stock DESC
LIMIT 20;

-- 3. Items below reorder threshold, regardless of the status label (checks the label is consistent)
SELECT resource_status, COUNT(*) AS items,
       SUM(CASE WHEN quantity_available < reorder_threshold THEN 1 ELSE 0 END) AS below_threshold
FROM resource_inventory
GROUP BY resource_status;

-- 4. Stale stock: not restocked for more than 365 days relative to the newest restock date in the data
SELECT r.resource_category, COUNT(*) AS items_not_restocked_365d
FROM resource_inventory r
CROSS JOIN (SELECT MAX(last_restock_date) AS newest FROM resource_inventory) m
WHERE DATEDIFF(m.newest, r.last_restock_date) > 365
GROUP BY r.resource_category
ORDER BY items_not_restocked_365d DESC;

-- 5. KPI table (site x month rows only, via vw_kpi_monthly) vs fish_production: totals must match
SELECT ROUND(SUM(k.total_production_tonnes), 2) AS kpi_tonnes, ROUND(MAX(p.t), 2) AS production_tonnes,
       ROUND(SUM(k.total_revenue_usd), 0) AS kpi_revenue, ROUND(MAX(p.r), 0) AS production_revenue
FROM vw_kpi_monthly k
CROSS JOIN (SELECT SUM(production_tonnes) AS t, SUM(revenue_usd) AS r FROM fish_production) p;

-- 6. Company-wide KPI by year (the 'ALL' rows) next to the site-level sum: they should agree
SELECT g.period_start, g.total_production_tonnes AS all_row_tonnes, ROUND(SUM(y.total_production_tonnes), 2) AS sum_of_sites_tonnes,
       g.active_site_count
FROM vw_kpi_global_yearly g
JOIN vw_kpi_yearly y ON g.period_start = y.period_start
GROUP BY g.period_start, g.total_production_tonnes, g.active_site_count
ORDER BY g.period_start;

-- 7. Yearly KPI per site: top 10 profit 2024
SELECT site_id, total_production_tonnes, total_revenue_usd, total_expenses_usd, net_profit_usd,
       average_mortality_rate_percent, average_water_quality_score
FROM vw_kpi_yearly
WHERE period_start = CAST('2024-01-01' AS DATE)
ORDER BY net_profit_usd DESC
LIMIT 10;
