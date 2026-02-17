-- Capstone: E-Commerce Seed Data

INSERT INTO users (email, name, role) VALUES
  ('alice@shop.com', 'Alice', 'customer'),
  ('bob@shop.com', 'Bob', 'seller'),
  ('admin@shop.com', 'Admin', 'admin');

INSERT INTO categories (name, parent_id) VALUES
  ('Electronics', NULL),
  ('Clothing', NULL),
  ('Books', NULL);

INSERT INTO products (category_id, name, description, price, attributes) VALUES
  (1, 'Laptop', '15" laptop', 999.99, '{"ram_gb": 16, "storage_gb": 512}'),
  (1, 'Phone', 'Smartphone', 699.99, '{"storage_gb": 128}'),
  (2, 'T-Shirt', 'Cotton tee', 24.99, '{"size": "M", "color": "blue"}'),
  (3, 'SQL Book', 'Database guide', 49.99, '{}');

INSERT INTO addresses (user_id, street, city, country, is_default) VALUES
  (1, '123 Main St', 'City', 'USA', true);

INSERT INTO orders (user_id, shipping_address_id, status, total) VALUES
  (1, 1, 'delivered', 1024.98),
  (1, 1, 'pending', 74.98);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 1, 999.99),
  (1, 3, 1, 24.99),
  (2, 3, 2, 24.99),
  (2, 4, 1, 49.99);

INSERT INTO payments (order_id, method, amount, status) VALUES
  (1, 'card', 1024.98, 'completed');

INSERT INTO inventory (product_id, quantity) VALUES
  (1, 10),
  (2, 50),
  (3, 100),
  (4, 25);

INSERT INTO reviews (user_id, product_id, rating, comment) VALUES
  (1, 1, 5, 'Great laptop!');
