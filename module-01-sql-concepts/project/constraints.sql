-- Module 1: Online Retail System — Constraints
-- Run after schema.sql

-- Ensure unique email per customer
ALTER TABLE customers
  ADD CONSTRAINT uq_customers_email UNIQUE (email);

-- Ensure price is non-negative
ALTER TABLE products
  ADD CONSTRAINT chk_products_price CHECK (price >= 0);

-- Ensure order status is valid
ALTER TABLE orders
  ADD CONSTRAINT chk_orders_status CHECK (
    status IN ('pending', 'shipped', 'delivered', 'cancelled')
  );

-- Ensure quantity is positive
ALTER TABLE order_items
  ADD CONSTRAINT chk_order_items_quantity CHECK (quantity > 0);

-- Ensure unit_price is non-negative
ALTER TABLE order_items
  ADD CONSTRAINT chk_order_items_unit_price CHECK (unit_price >= 0);

-- Optional: add NOT NULL to columns that might have been missed
-- (schema.sql already has key NOT NULLs)
