-- =========================================================
-- DataCo supply chain analysis — findings
-- Database: PostgreSQL (dataco), table: orders (one row per order line)
-- =========================================================


-- =========================================================
-- FINDING 1 — LOSSES
-- =========================================================

-- Q1. How much do money-losing order lines cost us?
-- Result: 33,784 lines (18.7%) lost $3.88M; average loss $115; worst single line −$4,275
SELECT
	COUNT(*)              AS loss_lines,
	SUM(profit)           AS total_loss,
	ROUND(AVG(profit), 2) AS avg_loss,
	MIN(profit)           AS biggest_loss
FROM orders
WHERE profit < 0;

-- Q2. Which markets lose the most money in dollars?
-- Result: Europe $1.15M, LATAM $1.08M, Pacific Asia $0.89M, USCA $0.53M, Africa $0.24M
-- Check: lines and losses add up to the Q1 totals
SELECT
	market,
	COUNT(*)              AS loss_lines,
	ROUND(SUM(profit), 0) AS total_loss
FROM orders
WHERE profit < 0
GROUP BY market
ORDER BY total_loss ASC;

-- Q3. Accounting for market size, which market loses the biggest share of sales?
-- Result: all markets similar; Pacific Asia highest by only ~0.2 percentage points
-- Conclusion: losses are not a regional problem
SELECT
	market,
	ROUND(SUM(sales), 0)                                                 AS total_sales,
	ROUND(SUM(profit) FILTER (WHERE profit < 0), 0)                      AS total_loss,
	ROUND(100.0 * SUM(profit) FILTER (WHERE profit < 0) / SUM(sales), 1) AS loss_pct
FROM orders
GROUP BY market
ORDER BY loss_pct ASC;

-- Q4. Do some categories lose a bigger share than others?
-- Result: yes — worst 10 range from about 11% to 19% of sales
-- Worst: [category 1], [category 2], [category 3]
SELECT
	category,
	ROUND(SUM(sales), 0)                                                 AS total_sales,
	ROUND(SUM(profit) FILTER (WHERE profit < 0), 0)                      AS total_loss,
	ROUND(100.0 * SUM(profit) FILTER (WHERE profit < 0) / SUM(sales), 1) AS loss_pct
FROM orders
GROUP BY category
ORDER BY loss_pct ASC
LIMIT 10;

-- Q5. Company-wide benchmark — and is the business profitable overall?
-- Result: sales $36.7M, losses $3.88M (10.6% of sales), net profit $3.97M
SELECT
	ROUND(SUM(sales), 0)                                                 AS total_sales,
	ROUND(SUM(profit) FILTER (WHERE profit < 0), 0)                      AS total_loss,
	ROUND(100.0 * SUM(profit) FILTER (WHERE profit < 0) / SUM(sales), 1) AS loss_pct,
	ROUND(SUM(profit), 0)                                                AS net_profit
FROM orders;


-- =========================================================
-- FINDING 2 — LATE DELIVERIES
-- Canceled orders are excluded: they were never delivered
-- =========================================================

-- Q6. What share of shipped lines arrive late, company-wide?
-- Result: 98,977 of 172,765 shipped lines = 57.3% late
SELECT
	COUNT(*) AS lines,
	SUM(CASE WHEN days_real > days_scheduled THEN 1 ELSE 0 END) AS late_lines,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct
FROM orders
WHERE delivery_status <> 'Shipping canceled';

-- Q7. Late rate by shipping mode
-- Result: First Class 100.0%, Second Class 79.8%, Same Day 47.9%, Standard Class 39.8%
-- Check: lines add up to 172,765 (= 180,519 minus 7,754 canceled)
SELECT
	shipping_mode,
	COUNT(*) AS lines,
	SUM(CASE WHEN days_real > days_scheduled THEN 1 ELSE 0 END) AS late_lines,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct
FROM orders
WHERE delivery_status <> 'Shipping canceled'
GROUP BY shipping_mode
ORDER BY late_pct DESC;

-- Q8. Why? Promised vs actual delivery days by mode
-- Result: First Class promises 1, takes 2; Second Class promises 2, takes ~4
--         (same as Standard Class) — the problem is the promise, not the shipping
SELECT
	shipping_mode,
	ROUND(AVG(days_scheduled), 2) AS avg_promised_days,
	ROUND(AVG(days_real), 2)      AS avg_actual_days
FROM orders
WHERE delivery_status <> 'Shipping canceled'
GROUP BY shipping_mode;

-- Q9. Standard Class is on time on average — so why is it 39.8% late?
-- Result: 41,023 lines took 5–6 days (matches Q7's late_lines exactly)
-- Lesson: the average hides the spread
SELECT
	days_real,
	COUNT(*) AS lines
FROM orders
WHERE shipping_mode = 'Standard Class'
  AND delivery_status <> 'Shipping canceled'
GROUP BY days_real
ORDER BY days_real;


-- =========================================================
-- -- =========================================================
-- FINDING 3 — FRAUD
-- =========================================================

-- Q10. How many lines does each order status have?
-- Result: 4,062 lines are SUSPECTED_FRAUD (about 2.3% of all lines)
SELECT
	order_status,
	COUNT(*) AS lines
FROM orders
GROUP BY order_status
ORDER BY lines DESC;

-- Q11. Which payment types do suspected-fraud lines use?
-- Result: all 4,062 use TRANSFER (one row only; adds up to Q10's total)
SELECT
	payment_type,
	COUNT(*) AS fraud_lines
FROM orders
WHERE order_status = 'SUSPECTED_FRAUD'
GROUP BY payment_type
ORDER BY fraud_lines DESC;

-- Q12. Benchmark: how common is each payment type, and what share is fraud?
-- Result: TRANSFER has 49,883 lines, 8.1% of them suspected fraud (~92% genuine);
--         no suspected fraud recorded for any other payment type
SELECT
	payment_type,
	COUNT(*)                                                                    AS all_lines,
	COUNT(*) FILTER (WHERE order_status = 'SUSPECTED_FRAUD')                    AS fraud_lines,
	ROUND(100.0 * COUNT(*) FILTER (WHERE order_status = 'SUSPECTED_FRAUD') / COUNT(*), 1) AS fraud_pct
FROM orders
GROUP BY payment_type
ORDER BY all_lines DESC;
-- =========================================================



-- =========================================================
-- DELIVERY PROMISE MODEL (what-if scenarios)
-- Canceled orders are excluded: they were never delivered
-- =========================================================

-- Q13. What if every promise were 1, 2 or 3 days longer? (by shipping mode)
-- Result: First Class 100% → 0% with +1; Same Day 47.9% → 0% with +1;
--         Second Class still 39.8% late at +2; Standard Class 0% at +2
SELECT
	shipping_mode,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled     THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_today,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled + 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_plus_1_day,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled + 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_plus_2_day,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled + 3 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_plus_3_day
FROM orders
WHERE delivery_status <> 'Shipping canceled'
GROUP BY shipping_mode;

-- Q14. The same scenarios, company-wide
-- Result: today 57.3% → +1 day 23.7% → +2 days 7.8% → +3 days 3.9%
SELECT
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled     THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_today,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled + 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_plus_1_day,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled + 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_plus_2_day,
	ROUND(100.0 * SUM(CASE WHEN days_real > days_scheduled + 3 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_plus_3_day
FROM orders
WHERE delivery_status <> 'Shipping canceled';

-- Q15. Targeted fix: change only the broken modes (First Class +1 day, Second Class +2 days)
-- Result: 34.1% late (vs 57.3% today, 23.7% with +1 day for everyone)
-- Trade-off: higher late rate than +1 for all, but Standard and Same Day keep their promises
WITH new_promises AS (
	SELECT
		days_real,
		CASE
			WHEN shipping_mode = 'First Class'  THEN days_scheduled + 1
			WHEN shipping_mode = 'Second Class' THEN days_scheduled + 2
			ELSE days_scheduled
		END AS new_promise
	FROM orders
	WHERE delivery_status <> 'Shipping canceled'
)
SELECT
	ROUND(100.0 * SUM(CASE WHEN days_real > new_promise THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct_targeted
FROM new_promises;