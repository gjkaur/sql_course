-- Capstone: E-Commerce Index Strategy
-- Run after 02_constraints.sql

-- FK indexes for JOINs
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_shipping ON orders(shipping_address_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);

-- Query pattern indexes
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at);
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
CREATE INDEX idx_products_active ON products(active) WHERE active = true;

-- JSONB
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);
