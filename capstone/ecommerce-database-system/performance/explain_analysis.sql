-- Capstone: EXPLAIN Analysis
-- Run after loading seed data

-- Orders by user
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE user_id = 1;

-- Products by category
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM products WHERE category_id = 1;

-- Monthly sales (uses composite index)
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*), SUM(total)
FROM orders
WHERE created_at >= '2024-01-01'
GROUP BY status;

-- JSONB containment
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM products WHERE attributes @> '{"ram_gb": 16}';
