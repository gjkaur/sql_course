-- Fleet Repair System — Seed Data
-- Run after schema_normalized.sql

INSERT INTO customers (company_name, contact_person, phone, address) VALUES
  ('Acme Logistics', 'John Smith', '555-1001', '100 Industrial Blvd'),
  ('Fast Freight Inc', 'Jane Doe', '555-1002', '200 Highway Ave'),
  ('Metro Delivery', 'Bob Wilson', '555-1003', '300 Commerce St');

INSERT INTO vehicles (customer_id, vin, make, model, year, license_plate) VALUES
  (1, '1HGBH41JXMN109186', 'Honda', 'Civic', 2021, 'ABC-1234'),
  (1, '2HGFG3B54CH501234', 'Honda', 'Accord', 2022, 'DEF-5678'),
  (2, '3VWFE21C04M000001', 'Volkswagen', 'Passat', 2020, 'GHI-9012'),
  (2, '4T1BF1FK5CU000001', 'Toyota', 'Camry', 2023, 'JKL-3456'),
  (3, '5YJSA1E26HF000001', 'Tesla', 'Model 3', 2022, 'MNO-7890');

INSERT INTO technicians (name, specialization, hire_date) VALUES
  ('Alice Johnson', 'Engine', '2020-01-15'),
  ('Charlie Brown', 'Brakes', '2019-06-01'),
  ('Diana Prince', 'Electrical', '2021-03-10');

INSERT INTO parts (part_number, description, unit_cost, quantity_in_stock) VALUES
  ('BRK-001', 'Brake pads front', 89.99, 50),
  ('BRK-002', 'Brake rotor', 120.00, 30),
  ('ENG-001', 'Oil filter', 12.99, 200),
  ('ENG-002', 'Air filter', 24.99, 100),
  ('ELEC-001', 'Battery 12V', 149.99, 25),
  ('ELEC-002', 'Alternator', 299.99, 10);

INSERT INTO repair_orders (vehicle_id, technician_id, opened_date, completed_date, status, labor_hours, parts_cost) VALUES
  (1, 1, '2024-01-10', '2024-01-12', 'completed', 4.5, 250.00),
  (2, 2, '2024-01-15', '2024-01-16', 'completed', 2.0, 89.99),
  (3, 3, '2024-01-20', NULL, 'in_progress', 1.5, 149.99),
  (4, 1, '2024-01-25', NULL, 'open', 0, 0),
  (5, 2, '2024-02-01', '2024-02-02', 'completed', 3.0, 424.98);

INSERT INTO part_usage (repair_order_id, part_id, quantity_used, unit_price) VALUES
  (1, 3, 2, 12.99),
  (1, 4, 1, 24.99),
  (1, 1, 1, 89.99),
  (2, 1, 1, 89.99),
  (3, 5, 1, 149.99),
  (5, 1, 1, 89.99),
  (5, 2, 1, 120.00),
  (5, 6, 1, 299.99);
