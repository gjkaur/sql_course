-- Module 3: Advanced Query Lab
-- Uses Online Retail schema (module-01). Run seed_data.sql first.

-- ============================================
-- 1. Subquery in WHERE
-- Customers who have placed more than 2 orders
-- ============================================

SELECT c.id, c.name, c.email
FROM customers c
WHERE (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) > 2;


-- ============================================
-- 2. Correlated subquery
-- Products that have never been ordered
-- ============================================

SELECT p.id, p.name, p.price
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM order_items oi WHERE oi.product_id = p.id
);


-- ============================================
-- 3. Scalar subquery in SELECT
-- Orders with customer name and order count for that customer
-- ============================================

SELECT o.id, c.name,
       (SELECT COUNT(*) FROM orders o2 WHERE o2.customer_id = c.id) AS customer_order_count
FROM orders o
JOIN customers c ON o.customer_id = c.id;


-- ============================================
-- 4. Derived table (subquery in FROM)
-- Customers whose total order value exceeds 200
-- ============================================

SELECT customer_id, total_spent
FROM (
  SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS total_spent
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY o.customer_id
) sub
WHERE total_spent > 200;


-- ============================================
-- 5. CTE (Common Table Expression)
-- Top 3 products by total quantity sold
-- ============================================

WITH product_sales AS (
  SELECT product_id, SUM(quantity) AS total_qty
  FROM order_items
  GROUP BY product_id
)
SELECT p.name, ps.total_qty
FROM product_sales ps
JOIN products p ON ps.product_id = p.id
ORDER BY ps.total_qty DESC
LIMIT 3;


-- ============================================
-- 6. HAVING with aggregate
-- Categories with more than 2 products
-- ============================================

SELECT category, COUNT(*) AS product_count
FROM products
WHERE category IS NOT NULL
GROUP BY category
HAVING COUNT(*) > 2;


-- ============================================
-- 7. LEFT JOIN to find non-matching
-- Customers with no orders
-- ============================================

SELECT c.id, c.name
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.id IS NULL;


-- ============================================
-- 8. UNION
-- Combine customer names with product names (both as "names")
-- ============================================

SELECT name AS item_name, 'customer' AS type FROM customers
UNION ALL
SELECT name, 'product' FROM products;


-- ============================================
-- 9. INTERSECT
-- Products in both order 1 and order 2
-- ============================================

SELECT product_id FROM order_items WHERE order_id = 1
INTERSECT
SELECT product_id FROM order_items WHERE order_id = 2;


-- ============================================
-- 10. EXCEPT
-- Products in order 1 but not in order 2
-- ============================================

SELECT product_id FROM order_items WHERE order_id = 1
EXCEPT
SELECT product_id FROM order_items WHERE order_id = 2;
