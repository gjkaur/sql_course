-- Fleet Repair System — Index Strategy
-- Run after schema_normalized.sql
-- Indexes may already exist from schema; this documents rationale

-- ============================================
-- FOREIGN KEY INDEXES (for JOINs and FK checks)
-- ============================================

-- vehicles.customer_id: "Find all vehicles for customer X"
CREATE INDEX IF NOT EXISTS idx_vehicles_customer ON vehicles(customer_id);

-- repair_orders.vehicle_id: "Repair history for vehicle X"
CREATE INDEX IF NOT EXISTS idx_repair_orders_vehicle ON repair_orders(vehicle_id);

-- repair_orders.technician_id: "Workload for technician X"
CREATE INDEX IF NOT EXISTS idx_repair_orders_technician ON repair_orders(technician_id);

-- part_usage.repair_order_id: "Parts used in repair X"
CREATE INDEX IF NOT EXISTS idx_part_usage_repair ON part_usage(repair_order_id);

-- part_usage.part_id: "Where is part X used?"
CREATE INDEX IF NOT EXISTS idx_part_usage_part ON part_usage(part_id);

-- ============================================
-- QUERY PATTERN INDEXES
-- ============================================

-- Filter by status: "All open repairs"
CREATE INDEX IF NOT EXISTS idx_repair_orders_status ON repair_orders(status);

-- Filter by date range: "Repairs in January 2024"
CREATE INDEX IF NOT EXISTS idx_repair_orders_opened ON repair_orders(opened_date);

-- Composite: status + date (common report)
CREATE INDEX IF NOT EXISTS idx_repair_orders_status_date
  ON repair_orders(status, opened_date);

-- Lookup by VIN
CREATE UNIQUE INDEX IF NOT EXISTS idx_vehicles_vin ON vehicles(vin);

-- Part lookup by part_number
CREATE UNIQUE INDEX IF NOT EXISTS idx_parts_part_number ON parts(part_number);

-- ============================================
-- RATIONALE
-- ============================================
-- 1. FK columns: Always index for JOIN performance
-- 2. WHERE columns: Index columns used in filters
-- 3. Composite: When queries filter on multiple columns
-- 4. UNIQUE: Enforced by constraint; index comes free
-- 5. Avoid over-indexing: Each index costs writes (INSERT/UPDATE/DELETE)
