-- Capstone: Analytics Queries

-- Revenue by category
SELECT c.name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM categories c
JOIN products p ON c.id = p.category_id
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY c.id, c.name
ORDER BY revenue DESC;

-- Conversion: users with at least one order
SELECT
  COUNT(DISTINCT u.id) AS total_users,
  COUNT(DISTINCT o.user_id) AS users_with_orders,
  ROUND(100.0 * COUNT(DISTINCT o.user_id) / NULLIF(COUNT(DISTINCT u.id), 0), 2) AS conversion_pct
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND o.status != 'cancelled';

-- Products with JSONB attributes filter
SELECT name, price, attributes
FROM products
WHERE attributes @> '{"ram_gb": 16}';
