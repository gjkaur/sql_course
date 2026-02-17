-- Module 6: Flexible Product Metadata
-- Hybrid schema: core columns + JSONB attributes

-- ============================================
-- Schema (extends or replaces products for demo)
-- ============================================

CREATE TABLE IF NOT EXISTS products_flex (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  category VARCHAR(50),
  base_price NUMERIC(10, 2),
  attributes JSONB DEFAULT '{}'
);

-- GIN index for attribute queries
CREATE INDEX IF NOT EXISTS idx_products_flex_attributes
  ON products_flex USING GIN (attributes);

-- ============================================
-- Seed: Different product types, different attributes
-- ============================================

INSERT INTO products_flex (name, category, base_price, attributes) VALUES
  ('Wireless Mouse', 'Electronics', 29.99, '{"color": "black", "dpi": 1600, "battery": "AA"}'),
  ('T-Shirt', 'Apparel', 19.99, '{"size": "M", "color": "blue", "material": "cotton"}'),
  ('Laptop', 'Electronics', 999.99, '{"ram_gb": 16, "storage_gb": 512, "screen_inches": 15}'),
  ('Desk Chair', 'Furniture', 299.99, '{"color": "gray", "adjustable": true, "weight_capacity_kg": 120}');

-- ============================================
-- Query: Filter by attribute
-- ============================================

-- Products with color = blue
SELECT * FROM products_flex WHERE attributes->>'color' = 'blue';

-- Electronics with ram_gb >= 16
SELECT * FROM products_flex
WHERE category = 'Electronics' AND (attributes->>'ram_gb')::int >= 16;

-- Products with adjustable = true
SELECT * FROM products_flex WHERE (attributes->>'adjustable')::boolean = true;
