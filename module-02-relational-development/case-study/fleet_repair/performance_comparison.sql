-- Fleet Repair System — Performance Comparison
-- Demonstrates index impact on query performance
-- Run with sufficient data (add more seed data for meaningful results)

-- ============================================
-- SETUP: Enable timing
-- ============================================
\timing on

-- ============================================
-- SCENARIO 1: Query WITH index on vehicle_id
-- ============================================
-- Index exists: idx_repair_orders_vehicle
SELECT COUNT(*) FROM repair_orders WHERE vehicle_id = 1;

-- ============================================
-- SCENARIO 2: Query WITHOUT index (simulated)
-- Drop index, run query, recreate index
-- ============================================
-- DROP INDEX IF EXISTS idx_repair_orders_vehicle;
-- SELECT COUNT(*) FROM repair_orders WHERE vehicle_id = 1;
-- CREATE INDEX idx_repair_orders_vehicle ON repair_orders(vehicle_id);

-- ============================================
-- SCENARIO 3: EXPLAIN comparison
-- ============================================
-- With index:
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM repair_orders WHERE vehicle_id = 1;

-- Without index (comment out index, run again):
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT * FROM repair_orders WHERE vehicle_id = 1;

-- ============================================
-- SCENARIO 4: Full table scan cost
-- ============================================
EXPLAIN (COSTS, FORMAT TEXT)
SELECT * FROM repair_orders WHERE status = 'completed';

-- With composite index (status, opened_date):
EXPLAIN (COSTS, FORMAT TEXT)
SELECT * FROM repair_orders
WHERE status = 'completed' AND opened_date >= '2024-01-01';

-- ============================================
-- METRICS TO COMPARE
-- ============================================
-- - Execution Time: Lower is better
-- - Planning Time: Usually negligible
-- - Buffers: shared hit (cache) vs read (disk)
-- - Rows: Estimated vs Actual (large gap = bad statistics)
