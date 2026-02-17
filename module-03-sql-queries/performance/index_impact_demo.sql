-- Module 3: Index Impact Demonstration
-- Run with Online Retail schema. Add indexes, then compare EXPLAIN.

-- ============================================
-- Setup: Ensure we have indexes for comparison
-- ============================================

-- Create indexes if not exist (for module-01 schema)
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);

-- ============================================
-- Query: Orders for customer 1 with items
-- ============================================

-- WITH indexes
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id, o.order_date, oi.product_id, oi.quantity, oi.unit_price
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.customer_id = 1;

-- ============================================
-- To test WITHOUT indexes:
-- DROP INDEX idx_orders_customer;
-- DROP INDEX idx_order_items_order;
-- Run EXPLAIN again, compare
-- Recreate: CREATE INDEX idx_orders_customer ON orders(customer_id);
--          CREATE INDEX idx_order_items_order ON order_items(order_id);
-- ============================================

-- ============================================
-- Metrics to compare
-- ============================================
-- - Planning Time
-- - Execution Time
-- - Node types: Seq Scan vs Index Scan
-- - Buffers: shared hit vs read
