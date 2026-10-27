-- ORION | A07 Finance: income, expenses, cost structure
USE orion;

-- 1. Income vs expense per year
SELECT txn_year, transaction_type, ROUND(SUM(total_usd), 0) AS total_usd
FROM sum_finance_monthly
GROUP BY txn_year, transaction_type
ORDER BY txn_year, transaction_type;

-- 2. Cost structure: each expense category as a share of all expenses
SELECT category, ROUND(SUM(total_usd), 0) AS total_usd,
       ROUND(100.0 * SUM(total_usd) / SUM(SUM(total_usd)) OVER (), 2) AS pct_of_expenses
FROM sum_finance_monthly
WHERE transaction_type = 'expense'
GROUP BY category
ORDER BY total_usd DESC;

-- 3. Net cash flow by month and cumulative
SELECT year_month, ROUND(net, 0) AS net_usd,
       ROUND(SUM(net) OVER (ORDER BY year_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS cumulative_net_usd
FROM (SELECT year_month,
             SUM(CASE WHEN transaction_type = 'income' THEN total_usd ELSE -total_usd END) AS net
      FROM sum_finance_monthly GROUP BY year_month) t
ORDER BY year_month;

-- 4. Payment methods used
SELECT payment_method, transaction_type, COUNT(*) AS transactions, ROUND(SUM(amount_usd), 0) AS total_usd
FROM finance_transactions
GROUP BY payment_method, transaction_type
ORDER BY total_usd DESC;

-- 5. Feed cost as share of expenses by farm type (feed is the largest cost lever in aquaculture)
SELECT s.site_type,
       ROUND(100.0 * SUM(CASE WHEN t.category = 'Feed' THEN t.amount_usd ELSE 0 END)
             / SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount_usd ELSE 0 END), 2) AS feed_pct_of_expenses
FROM finance_transactions t
JOIN aquaculture_sites s ON t.site_id = s.site_id
GROUP BY s.site_type
ORDER BY feed_pct_of_expenses DESC;

-- 6. Biggest single transactions
SELECT transaction_id, site_id, txn_date, transaction_type, category, ROUND(amount_usd, 0) AS amount_usd
FROM finance_transactions
ORDER BY amount_usd DESC
LIMIT 10;
