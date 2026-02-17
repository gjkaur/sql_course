-- Module 3: Query Optimization Exercises
-- For each query, run EXPLAIN (ANALYZE, BUFFERS) and optimize.

-- ============================================
-- Exercise 1: Find orders for customer
-- Add index if Seq Scan appears
-- ============================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE customer_id = 1;


-- ============================================
-- Exercise 2: Order items for an order
-- ============================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.*, p.name FROM order_items oi
JOIN products p ON oi.product_id = p.id
WHERE oi.order_id = 1;


-- ============================================
-- Exercise 3: Products in category
-- Add index on category if needed
-- ============================================

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM products WHERE category = 'Electronics';


-- ============================================
-- Exercise 4: Rewrite correlated subquery as JOIN
-- Compare performance
-- ============================================

-- Correlated (may be slower)
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.name, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS cnt
FROM customers c;

-- JOIN (often faster)
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.name, COUNT(o.id) AS cnt
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name;
