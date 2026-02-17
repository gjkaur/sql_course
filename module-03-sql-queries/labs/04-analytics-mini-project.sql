-- Module 3: Analytics Mini-Project
-- Uses Online Retail schema. Run seed_data.sql first.

-- ============================================
-- Business Questions to Answer
-- ============================================

-- 1. What is the average order value?
SELECT ROUND(AVG(order_total), 2) AS avg_order_value
FROM (
  SELECT SUM(oi.quantity * oi.unit_price) AS order_total
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  WHERE o.status != 'cancelled'
  GROUP BY o.id
) sub;


-- 2. Which customer has the highest lifetime value?
SELECT c.name, SUM(oi.quantity * oi.unit_price) AS lifetime_value
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY c.id, c.name
ORDER BY lifetime_value DESC
LIMIT 1;


-- 3. What is the best-selling product by quantity?
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM products p
JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name
ORDER BY total_sold DESC
LIMIT 1;


-- 4. Conversion rate: customers with at least one order vs total customers
SELECT
  COUNT(DISTINCT o.customer_id)::FLOAT / NULLIF(COUNT(DISTINCT c.id), 0) * 100 AS conversion_pct
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id AND o.status != 'cancelled';


-- 5. Revenue by status
SELECT status, SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.status
ORDER BY revenue DESC;
