-- Fleet Repair System — Normalized Schema (3NF)
-- Run in a fresh database or after dropping existing objects

DROP TABLE IF EXISTS part_usage;
DROP TABLE IF EXISTS repair_orders;
DROP TABLE IF EXISTS parts;
DROP TABLE IF EXISTS technicians;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS customers;

-- Customers: fleet owners
CREATE TABLE customers (
  id BIGSERIAL PRIMARY KEY,
  company_name VARCHAR(200) NOT NULL,
  contact_person VARCHAR(100),
  phone VARCHAR(20),
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles: owned by customers
CREATE TABLE vehicles (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(id),
  vin VARCHAR(17) NOT NULL UNIQUE,
  make VARCHAR(50) NOT NULL,
  model VARCHAR(50) NOT NULL,
  year INTEGER NOT NULL CHECK (year >= 1900 AND year <= 2100),
  license_plate VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Technicians: repair shop staff
CREATE TABLE technicians (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  specialization VARCHAR(100),
  hire_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Parts: inventory
CREATE TABLE parts (
  id BIGSERIAL PRIMARY KEY,
  part_number VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  unit_cost NUMERIC(10, 2) NOT NULL CHECK (unit_cost >= 0),
  quantity_in_stock INTEGER NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Repair orders: one per vehicle visit
CREATE TABLE repair_orders (
  id BIGSERIAL PRIMARY KEY,
  vehicle_id BIGINT NOT NULL REFERENCES vehicles(id),
  technician_id BIGINT NOT NULL REFERENCES technicians(id),
  opened_date DATE NOT NULL,
  completed_date DATE,
  status VARCHAR(20) NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
  labor_hours NUMERIC(5, 2) DEFAULT 0 CHECK (labor_hours >= 0),
  parts_cost NUMERIC(10, 2) DEFAULT 0 CHECK (parts_cost >= 0),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Part usage: junction table (parts used in each repair)
CREATE TABLE part_usage (
  id BIGSERIAL PRIMARY KEY,
  repair_order_id BIGINT NOT NULL REFERENCES repair_orders(id),
  part_id BIGINT NOT NULL REFERENCES parts(id),
  quantity_used INTEGER NOT NULL CHECK (quantity_used > 0),
  unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
  UNIQUE (repair_order_id, part_id)
);

-- Indexes: see index_strategy.sql for full strategy
CREATE INDEX idx_vehicles_customer ON vehicles(customer_id);
CREATE INDEX idx_repair_orders_vehicle ON repair_orders(vehicle_id);
CREATE INDEX idx_repair_orders_technician ON repair_orders(technician_id);
CREATE INDEX idx_repair_orders_status ON repair_orders(status);
CREATE INDEX idx_part_usage_repair ON part_usage(repair_order_id);
CREATE INDEX idx_part_usage_part ON part_usage(part_id);
