-- Module 1: Online Retail System — Exercise Solutions

-- EXERCISE 1
SELECT name, email FROM customers;

-- EXERCISE 2
SELECT * FROM products WHERE category = 'Electronics';

-- EXERCISE 3
SELECT * FROM products WHERE price BETWEEN 20 AND 50;

-- EXERCISE 4
SELECT * FROM products ORDER BY price DESC;

-- EXERCISE 5
SELECT * FROM products ORDER BY price DESC LIMIT 5;

-- EXERCISE 6
SELECT COUNT(*) FROM customers;

-- EXERCISE 7
SELECT o.id, c.name, o.order_date, o.status
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- EXERCISE 8
SELECT p.name, oi.quantity, oi.unit_price
FROM order_items oi
JOIN products p ON oi.product_id = p.id
WHERE oi.order_id = 1;

-- EXERCISE 9
SELECT SUM(quantity * unit_price) AS total
FROM order_items
WHERE order_id = 1;

-- EXERCISE 10
SELECT * FROM customers WHERE email LIKE '%@example.com';

-- EXERCISE 11
SELECT * FROM products WHERE description IS NULL;

-- EXERCISE 12
SELECT DISTINCT status FROM orders;

-- EXERCISE 13
SELECT COUNT(*) FROM orders WHERE customer_id = 1;

-- EXERCISE 14
SELECT * FROM products WHERE active = true;

-- EXERCISE 15
SELECT * FROM orders
WHERE order_date >= '2024-02-01' AND order_date < '2024-03-01'
ORDER BY order_date;
