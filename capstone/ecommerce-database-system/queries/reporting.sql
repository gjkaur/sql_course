-- Capstone: Reporting Queries

-- Monthly sales by status
SELECT
  DATE_TRUNC('month', created_at)::DATE AS month,
  status,
  COUNT(*) AS order_count,
  SUM(total) AS revenue
FROM orders
GROUP BY DATE_TRUNC('month', created_at), status
ORDER BY month, revenue DESC;

-- Top products by quantity sold
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
WHERE o.status != 'cancelled'
GROUP BY p.id, p.name
ORDER BY total_sold DESC
LIMIT 10;

-- Customer lifetime value
SELECT u.name, u.email, COUNT(o.id) AS orders, SUM(o.total) AS lifetime_value
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.status != 'cancelled'
GROUP BY u.id, u.name, u.email
ORDER BY lifetime_value DESC;

-- Products with low stock
SELECT p.name, i.quantity
FROM products p
JOIN inventory i ON p.id = i.product_id
WHERE i.quantity < 20 AND p.active = true;

-- Average rating per product
SELECT p.name, ROUND(AVG(r.rating)::numeric, 2) AS avg_rating, COUNT(r.id) AS review_count
FROM products p
LEFT JOIN reviews r ON p.id = r.product_id
GROUP BY p.id, p.name;
