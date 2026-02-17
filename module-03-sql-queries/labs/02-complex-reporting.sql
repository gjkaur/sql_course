-- Module 3: Complex Reporting
-- Uses Online Retail schema. Run seed_data.sql first.

-- ============================================
-- 1. Monthly sales by category
-- ============================================

SELECT
  DATE_TRUNC('month', o.order_date)::DATE AS month,
  p.category,
  SUM(oi.quantity * oi.unit_price) AS revenue,
  COUNT(DISTINCT o.id) AS order_count
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.status != 'cancelled'
GROUP BY DATE_TRUNC('month', o.order_date), p.category
ORDER BY month, revenue DESC;


-- ============================================
-- 2. Top N per category (top 2 products by revenue per category)
-- ============================================

WITH ranked AS (
  SELECT p.category, p.name, SUM(oi.quantity * oi.unit_price) AS revenue,
         ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rn
  FROM products p
  JOIN order_items oi ON p.id = oi.product_id
  GROUP BY p.category, p.id, p.name
)
SELECT category, name, revenue, rn
FROM ranked
WHERE rn <= 2
ORDER BY category, rn;


-- ============================================
-- 3. Running total of order value over time
-- ============================================

WITH order_totals AS (
  SELECT o.id, o.order_date, SUM(oi.quantity * oi.unit_price) AS order_total
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY o.id, o.order_date
)
SELECT order_date, order_total,
       SUM(order_total) OVER (ORDER BY order_date) AS running_total
FROM order_totals
ORDER BY order_date;


-- ============================================
-- 4. Customer cohort: first order date and order count
-- ============================================

SELECT
  c.id,
  c.name,
  MIN(o.order_date) AS first_order_date,
  COUNT(o.id) AS total_orders,
  SUM(oi.quantity * oi.unit_price) AS lifetime_value
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY c.id, c.name
ORDER BY lifetime_value DESC;


-- ============================================
-- 5. Products never sold
-- ============================================

SELECT p.id, p.name, p.price, p.category
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
WHERE oi.id IS NULL;
