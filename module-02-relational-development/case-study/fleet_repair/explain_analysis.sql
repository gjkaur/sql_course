-- Fleet Repair System — EXPLAIN Analysis Tasks
-- Run with: EXPLAIN (ANALYZE, BUFFERS) <query>;
-- Requires sufficient data for meaningful plans

-- ============================================
-- QUERY 1: Repair history for a vehicle
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT ro.*, t.name AS technician_name
FROM repair_orders ro
JOIN technicians t ON ro.technician_id = t.id
WHERE ro.vehicle_id = 1
ORDER BY ro.opened_date DESC;

-- Expected: Index Scan on idx_repair_orders_vehicle
-- Check: Seq Scan = bad (no index used)


-- ============================================
-- QUERY 2: Parts used in a repair
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.part_number, p.description, pu.quantity_used, pu.unit_price
FROM part_usage pu
JOIN parts p ON pu.part_id = p.id
WHERE pu.repair_order_id = 1;

-- Expected: Index Scan on idx_part_usage_repair


-- ============================================
-- QUERY 3: Open repairs (filter by status)
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM repair_orders
WHERE status = 'open'
ORDER BY opened_date;

-- Expected: Index Scan on idx_repair_orders_status or idx_repair_orders_status_date


-- ============================================
-- QUERY 4: Technician workload (aggregate)
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT t.name, COUNT(ro.id) AS repair_count, SUM(ro.labor_hours) AS total_hours
FROM technicians t
LEFT JOIN repair_orders ro ON t.id = ro.technician_id
WHERE ro.opened_date >= '2024-01-01'
GROUP BY t.id, t.name;

-- Check: Hash Join vs Nested Loop; appropriate for data size


-- ============================================
-- QUERY 5: Vehicle with customer and repair count
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT v.vin, v.make, v.model, c.company_name,
       (SELECT COUNT(*) FROM repair_orders ro WHERE ro.vehicle_id = v.id) AS repair_count
FROM vehicles v
JOIN customers c ON v.customer_id = c.id;

-- Note: Correlated subquery may be slow; consider JOIN + GROUP BY instead


-- ============================================
-- INTERPRETATION GUIDE
-- ============================================
-- Seq Scan: Full table scan. OK for small tables; bad for large.
-- Index Scan: Uses index. Good for selective queries.
-- Index Only Scan: Best; reads only index, no heap.
-- Nested Loop: Good for small inner table.
-- Hash Join: Good for larger tables, equality joins.
-- Sort: Check if necessary; avoid for large result sets.
-- Buffers: shared hit = cache; read = disk. More read = slower.
