-- Module 7: Slow DB Simulation - Seed Large Data
-- Creates a poorly indexed scenario for optimization practice

-- ============================================
-- Create tables (minimal indexes)
-- ============================================

DROP TABLE IF EXISTS large_orders;
DROP TABLE IF EXISTS large_customers;

CREATE TABLE large_customers (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(255),
  region VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE large_orders (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  status VARCHAR(20),
  total NUMERIC(10,2),
  order_date TIMESTAMPTZ DEFAULT NOW()
);

-- Intentionally NO indexes on customer_id, status, order_date

-- ============================================
-- Generate data (run multiple times or use generate_series)
-- ============================================

INSERT INTO large_customers (name, email, region, created_at)
SELECT
  'Customer ' || i,
  'user' || i || '@example.com',
  (ARRAY['North','South','East','West'])[1 + (i % 4)],
  NOW() - (i || ' days')::INTERVAL
FROM generate_series(1, 10000) i;

INSERT INTO large_orders (customer_id, status, total, order_date)
SELECT
  1 + (random() * 9999)::BIGINT,
  (ARRAY['pending','shipped','delivered'])[1 + (random() * 3)::INT],
  (random() * 500 + 10)::NUMERIC(10,2),
  NOW() - (random() * 365 || ' days')::INTERVAL
FROM generate_series(1, 100000) i;

-- ============================================
-- Run slow queries (before adding indexes)
-- ============================================
-- EXPLAIN (ANALYZE) SELECT * FROM large_orders WHERE customer_id = 100;
-- EXPLAIN (ANALYZE) SELECT * FROM large_orders WHERE status = 'shipped';
-- EXPLAIN (ANALYZE) SELECT * FROM large_orders WHERE order_date > NOW() - INTERVAL '30 days';
