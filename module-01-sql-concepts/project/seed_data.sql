-- Module 1: Online Retail System — Seed Data
-- Run after schema.sql and constraints.sql

-- Customers
INSERT INTO customers (name, email, phone, address) VALUES
  ('Alice Johnson', 'alice@example.com', '555-0101', '123 Main St, City'),
  ('Bob Smith', 'bob@example.com', '555-0102', '456 Oak Ave, Town'),
  ('Carol White', 'carol@example.com', '555-0103', '789 Pine Rd, Village'),
  ('David Brown', 'david@example.com', '555-0104', '321 Elm St, City'),
  ('Eve Davis', 'eve@example.com', '555-0105', '654 Maple Dr, Town'),
  ('Frank Miller', 'frank@example.com', '555-0106', '987 Cedar Ln, Village'),
  ('Grace Lee', 'grace@example.com', '555-0107', '147 Birch Way, City'),
  ('Henry Wilson', 'henry@example.com', '555-0108', '258 Willow Blvd, Town'),
  ('Ivy Taylor', 'ivy@example.com', '555-0109', '369 Spruce St, Village'),
  ('Jack Anderson', 'jack@example.com', '555-0110', '741 Ash Ave, City');

-- Products
INSERT INTO products (name, description, price, category, active) VALUES
  ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 'Electronics', true),
  ('USB-C Keyboard', 'Mechanical keyboard', 89.99, 'Electronics', true),
  ('Monitor Stand', 'Adjustable desk stand', 49.99, 'Accessories', true),
  ('Laptop Sleeve', '13-inch padded sleeve', 24.99, 'Accessories', true),
  ('Webcam HD', '1080p webcam with mic', 59.99, 'Electronics', true),
  ('Desk Lamp', 'LED desk lamp', 34.99, 'Office', true),
  ('Notebook Set', 'Pack of 3 ruled notebooks', 12.99, 'Office', true),
  ('Pen Pack', '12 assorted pens', 9.99, 'Office', true),
  ('Headphones', 'Noise-cancelling headphones', 149.99, 'Electronics', true),
  ('Phone Stand', 'Adjustable phone holder', 14.99, 'Accessories', true),
  ('Cable Organizer', 'Desk cable management', 19.99, 'Accessories', true),
  ('Desk Mat', 'Large mouse pad', 29.99, 'Accessories', true),
  ('Sticky Notes', 'Pack of 6 pads', 7.99, 'Office', true),
  ('USB Hub', '4-port USB 3.0 hub', 24.99, 'Electronics', true),
  ('Screen Cleaner', 'LCD cleaning kit', 11.99, 'Accessories', true),
  ('Laptop Bag', '15-inch laptop bag', 39.99, 'Accessories', true),
  ('Standing Desk Mat', 'Anti-fatigue mat', 44.99, 'Office', true),
  ('Bluetooth Speaker', 'Portable speaker', 69.99, 'Electronics', true),
  ('Desk Organizer', 'Multi-compartment tray', 29.99, 'Office', true),
  ('Old Product', 'Discontinued item', 99.99, 'Electronics', false);

-- Orders (customer_id references customers 1-10)
INSERT INTO orders (customer_id, status, order_date) VALUES
  (1, 'delivered', '2024-01-15 10:00:00'),
  (1, 'shipped', '2024-02-01 14:30:00'),
  (2, 'delivered', '2024-01-20 09:15:00'),
  (3, 'pending', '2024-02-10 11:00:00'),
  (4, 'delivered', '2024-01-25 16:45:00'),
  (5, 'shipped', '2024-02-05 08:00:00'),
  (6, 'cancelled', '2024-02-08 12:00:00'),
  (7, 'delivered', '2024-01-30 13:20:00'),
  (8, 'pending', '2024-02-12 10:30:00'),
  (9, 'delivered', '2024-02-02 15:00:00'),
  (10, 'shipped', '2024-02-11 09:00:00'),
  (1, 'pending', '2024-02-14 17:00:00'),
  (1, 'delivered', '2024-01-10 11:00:00'),
  (2, 'delivered', '2024-02-03 14:00:00'),
  (1, 'shipped', '2024-02-01 10:00:00');

-- Order items (order_id, product_id, quantity, unit_price)
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 2, 29.99),
  (1, 2, 1, 89.99),
  (2, 3, 1, 49.99),
  (2, 4, 2, 24.99),
  (3, 5, 1, 59.99),
  (3, 6, 1, 34.99),
  (4, 7, 3, 12.99),
  (4, 8, 2, 9.99),
  (5, 9, 1, 149.99),
  (5, 10, 5, 14.99),
  (6, 11, 2, 19.99),
  (6, 12, 1, 29.99),
  (7, 1, 1, 29.99),
  (8, 13, 4, 7.99),
  (8, 14, 1, 24.99),
  (9, 15, 2, 11.99),
  (10, 16, 1, 39.99),
  (10, 17, 1, 44.99),
  (11, 18, 1, 69.99),
  (12, 1, 1, 29.99),
  (12, 2, 1, 89.99),
  (12, 19, 1, 29.99),
  (13, 1, 3, 29.99),
  (14, 2, 1, 89.99),
  (14, 3, 1, 49.99),
  (15, 4, 2, 24.99);
