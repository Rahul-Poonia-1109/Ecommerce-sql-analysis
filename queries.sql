-- ============================================================
-- E-Commerce Order Analysis | queries.sql
-- 15 analysis queries across 5 sections.
-- Run after schema.sql and data.sql.
-- ============================================================

USE ecommerce_analysis;


-- ############################################################
-- SECTION A: Customer & Order Overview
-- ############################################################

-- Q1. Order count per customer (including customers with zero orders)
-- Approach: LEFT JOIN anchored on customers so zero-order customers still appear;
-- COUNT(o.order_id) skips NULLs, giving 0 for them.
SELECT c.cust_name,
       COUNT(o.order_id) AS no_of_orders
FROM customers c
LEFT JOIN orders o ON c.cust_id = o.cust_id
GROUP BY c.cust_name;


-- Q2. Total amount spent by each customer (including customers with no orders)
-- Approach: chain LEFT JOINs customers -> orders -> order_items -> products,
-- SUM(quantity * price), and COALESCE the aggregate to 0 for zero-order customers.
SELECT c.cust_name,
       COALESCE(SUM(oi.quantity * p.price), 0) AS amount_spent
FROM customers c
LEFT JOIN orders o       ON c.cust_id    = o.cust_id
LEFT JOIN order_items oi ON o.order_id   = oi.order_id
LEFT JOIN products p     ON p.product_id = oi.product_id
GROUP BY c.cust_name;


-- Q3. Delivered orders with customer name, order date and total order value
-- Approach: group at the ORDER level (order_id) and include every non-aggregated
-- column in GROUP BY.
SELECT c.cust_name,
       o.order_id,
       o.order_date,
       SUM(oi.quantity * p.price) AS total_order_value
FROM customers c
JOIN orders o            ON c.cust_id    = o.cust_id
LEFT JOIN order_items oi ON o.order_id   = oi.order_id
LEFT JOIN products p     ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY c.cust_name, o.order_id, o.order_date;


-- Q4. Customers who have never placed an order
-- Approach: NOT EXISTS (safe against NULLs, unlike NOT IN).
SELECT c.cust_name
FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM orders o WHERE c.cust_id = o.cust_id
);


-- ############################################################
-- SECTION B: Product & Category Insights
-- ############################################################

-- Q5. Total revenue per product (including products never sold)
-- Approach: anchor on products; LEFT JOIN order_items; COALESCE to 0.
SELECT p.product_name,
       COALESCE(SUM(oi.quantity * p.price), 0) AS revenue
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_name;


-- Q6. Total revenue per category
SELECT p.category,
       COALESCE(SUM(oi.quantity * p.price), 0) AS revenue
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.category;


-- Q7. Best-selling product by total quantity sold (tie-safe)
-- Approach: per-product quantity as a derived table, find the single max,
-- then match every product tied at that max (IN handles ties).
SELECT product_name
FROM products
WHERE product_id IN (
  SELECT product_id
  FROM order_items
  GROUP BY product_id
  HAVING SUM(quantity) = (
    SELECT MAX(quantity_sold)
    FROM (
      SELECT product_id, SUM(quantity) AS quantity_sold
      FROM order_items
      GROUP BY product_id
    ) qs
  )
);


-- Q8. Each product with the number of distinct customers who bought it
-- Approach: anchor on products so never-ordered products still appear with 0.
SELECT p.product_id,
       p.product_name,
       COUNT(DISTINCT o.cust_id) AS no_of_customers
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o       ON o.order_id    = oi.order_id
GROUP BY p.product_id, p.product_name;


-- ############################################################
-- SECTION C: Subquery-Driven Analysis
-- ############################################################

-- Q9. Customers whose total spend is above the average total spend per customer
-- Approach: aggregate to the customer grain first (derived table), then average
-- those per-customer totals. The average is taken over customers who placed at
-- least one order (zero-order customers have no rows in the derived table).
SELECT cust_name
FROM customers
WHERE cust_id IN (
  SELECT o.cust_id
  FROM orders o
  JOIN order_items oo ON o.order_id    = oo.order_id
  JOIN products pp    ON oo.product_id = pp.product_id
  GROUP BY o.cust_id
  HAVING SUM(oo.quantity * pp.price) > (
    SELECT AVG(total_expenses)
    FROM (
      SELECT SUM(oi.quantity * p.price) AS total_expenses
      FROM orders o
      JOIN order_items oi ON o.order_id    = oi.order_id
      JOIN products p     ON oi.product_id = p.product_id
      GROUP BY o.cust_id
    ) ts
  )
);


-- Q10. Product(s) with the single highest total revenue (tie-safe)
SELECT pp.product_name
FROM products pp
WHERE pp.product_id IN (
  SELECT pr.product_id
  FROM products pr
  JOIN order_items ot ON pr.product_id = ot.product_id
  GROUP BY pr.product_id
  HAVING SUM(pr.price * ot.quantity) = (
    SELECT MAX(revenue)
    FROM (
      SELECT p.product_id, SUM(oi.quantity * p.price) AS revenue
      FROM products p
      JOIN order_items oi ON oi.product_id = p.product_id
      GROUP BY p.product_id
    ) tr
  )
);


-- Q11. Customers who have placed more than one order
SELECT cust_name
FROM customers
WHERE cust_id IN (
  SELECT o.cust_id
  FROM orders o
  GROUP BY o.cust_id
  HAVING COUNT(o.order_id) > 1
);


-- Q12. Customers who have never ordered a 'Furniture' product
-- Approach: NOT EXISTS with all three conditions bundled in one correlated check.
SELECT c.cust_name
FROM customers c
WHERE NOT EXISTS (
  SELECT 1
  FROM orders o
  JOIN order_items oi ON o.order_id    = oi.order_id
  JOIN products p     ON oi.product_id = p.product_id
  WHERE c.cust_id = o.cust_id
    AND p.category = 'Furniture'
);


-- ############################################################
-- SECTION D: Set Operations
-- ############################################################

-- Q13. Combined, deduplicated list of customer cities and product categories,
-- labeled by source table
SELECT city     AS value, 'customers' AS source_type FROM customers
UNION
SELECT category AS value, 'products'  AS source_type FROM products;


-- Q14. Customers with at least one Delivered order and no Cancelled orders
-- Approach: two independent conditions -> EXISTS AND NOT EXISTS.
SELECT c.cust_name
FROM customers c
WHERE EXISTS (
        SELECT 1 FROM orders o
        WHERE o.cust_id = c.cust_id AND o.status = 'Delivered'
      )
  AND NOT EXISTS (
        SELECT 1 FROM orders o
        WHERE o.cust_id = c.cust_id AND o.status = 'Cancelled'
      );


-- ############################################################
-- SECTION E: Summary Report
-- ############################################################

-- Q15. One-row-per-customer summary: city, total orders, total spend, latest order date
-- Approach: customers anchor a chain of LEFT JOINs; three aggregates in one GROUP BY;
-- zero-order customers show 0 orders, 0 spend and a NULL latest order date.
-- NOTE: joining to order_items repeats each order once per line item, so orders
-- must be counted with COUNT(DISTINCT ...). A plain COUNT(o.order_id) would
-- count line items instead of orders.
SELECT c.cust_name,
       c.city,
       COUNT(DISTINCT o.order_id)              AS total_orders,
       COALESCE(SUM(oi.quantity * p.price), 0) AS total_spend,
       MAX(o.order_date)                       AS recent_order_date
FROM customers c
LEFT JOIN orders o       ON c.cust_id    = o.cust_id
LEFT JOIN order_items oi ON o.order_id   = oi.order_id
LEFT JOIN products p     ON oi.product_id = p.product_id
GROUP BY c.cust_name, c.city;
