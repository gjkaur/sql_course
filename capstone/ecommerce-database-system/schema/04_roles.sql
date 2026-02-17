-- Capstone: E-Commerce Roles
-- Run as superuser

CREATE ROLE ecom_customer NOLOGIN;
CREATE ROLE ecom_seller NOLOGIN;
CREATE ROLE ecom_admin NOLOGIN;
CREATE ROLE ecom_analytics NOLOGIN;

GRANT USAGE ON SCHEMA public TO ecom_customer, ecom_seller, ecom_admin, ecom_analytics;

-- Customer: read products, own orders/addresses, insert orders
GRANT SELECT ON products, categories TO ecom_customer;
GRANT SELECT, INSERT, UPDATE ON orders, order_items, addresses TO ecom_customer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ecom_customer;

-- Seller: + products, inventory
GRANT ecom_customer TO ecom_seller;
GRANT SELECT, INSERT, UPDATE ON products, inventory TO ecom_seller;

-- Admin: full
GRANT ALL ON ALL TABLES IN SCHEMA public TO ecom_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ecom_admin;

-- Analytics: read-only
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ecom_analytics;
