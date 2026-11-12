-- Build a clean, analysis-ready table from raw_orders.
-- Renames columns to snake_case, sets proper types, parses dates,
-- and leaves out personal data. Run with:  psql -d dataco -f sql/01_clean.sql
DROP TABLE IF EXISTS orders;

CREATE TABLE orders AS
SELECT
    "Order Item Id"::int                                                AS order_item_id,
    "Order Id"::int                                                     AS order_id,
    to_timestamp("order date (DateOrders)", 'MM/DD/YYYY HH24:MI')::timestamp    AS order_date,
    to_timestamp("shipping date (DateOrders)", 'MM/DD/YYYY HH24:MI')::timestamp AS shipping_date,
    to_timestamp("order date (DateOrders)", 'MM/DD/YYYY HH24:MI')::date         AS order_day,
    "Type"                                                              AS payment_type,
    "Order Status"                                                      AS order_status,
    "Delivery Status"                                                   AS delivery_status,
    "Late_delivery_risk"::int                                           AS late_flag,
    "Shipping Mode"                                                     AS shipping_mode,
    "Days for shipping (real)"::int                                     AS days_real,
    "Days for shipment (scheduled)"::int                                AS days_scheduled,
    "Customer Segment"                                                  AS customer_segment,
    "Market"                                                            AS market,
    "Order Region"                                                      AS order_region,
    "Order Country"                                                     AS order_country,
    "Department Name"                                                   AS department,
    "Category Name"                                                     AS category,
    "Product Name"                                                      AS product,
    "Order Item Quantity"::int                                          AS quantity,
    "Sales"::numeric(12,2)                                              AS sales,
    "Order Item Discount"::numeric(12,2)                                AS discount,
    "Order Item Total"::numeric(12,2)                                   AS item_total,
    "Order Profit Per Order"::numeric(12,2)                             AS profit
FROM raw_orders;

ALTER TABLE orders ADD PRIMARY KEY (order_item_id);
CREATE INDEX ON orders (order_day);

-- Let the read-only user see the new table (rebuilding it drops old grants).
GRANT USAGE ON SCHEMA public TO dataco_reader;
GRANT SELECT ON orders TO dataco_reader;

-- Checks: compare each result with the expected value.
SELECT COUNT(*) AS rows_expect_180519 FROM orders;
SELECT COUNT(*) AS null_dates_expect_0 FROM orders
WHERE order_date IS NULL OR shipping_date IS NULL;
SELECT COUNT(*) AS late_flag_mismatches_expect_0 FROM orders
WHERE (delivery_status = 'Late delivery') <> (late_flag = 1);
SELECT MIN(order_day) AS first_day, MAX(order_day) AS last_day FROM orders;