-- Module 7: Before/After Performance Comparison
-- Run with large_orders from 01-slow-db-simulation

\timing on

-- ============================================
-- BEFORE: No index on customer_id
-- ============================================
-- DROP INDEX IF EXISTS idx_lo_customer;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM large_orders WHERE customer_id = 100;

-- ============================================
-- AFTER: Add index
-- ============================================
CREATE INDEX IF NOT EXISTS idx_lo_customer ON large_orders(customer_id);
ANALYZE large_orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM large_orders WHERE customer_id = 100;

-- ============================================
-- Compare metrics
-- ============================================
-- Before: Seq Scan, Execution Time: ~XX ms
-- After: Index Scan using idx_lo_customer, Execution Time: ~Y ms
