-- Module 6: JSON Indexing Performance Comparison
-- Run EXPLAIN (ANALYZE, BUFFERS) with and without GIN index

-- ============================================
-- Setup: Use events table from 01-event-logging-system.sql
-- ============================================

-- Query: Find events where payload contains product_id
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events WHERE payload ? 'product_id';

-- With GIN index: Index Scan using idx_events_payload
-- Without: Seq Scan (drop index to test)

-- ============================================
-- Query: Containment (@>)
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events WHERE payload @> '{"order_id": 101}';

-- GIN supports @> and ? operators

-- ============================================
-- Expression index for specific path
-- ============================================
CREATE INDEX IF NOT EXISTS idx_events_payload_page
  ON events ((payload->>'page'));

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events WHERE payload->>'page' = '/home';

-- ============================================
-- Compare
-- ============================================
-- 1. Run with GIN index, note execution time
-- 2. DROP INDEX idx_events_payload;
-- 3. Run again, compare time and plan (Seq Scan)
