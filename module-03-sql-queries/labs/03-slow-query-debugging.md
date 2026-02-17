# Slow Query Debugging Scenario

## Scenario

A report "Monthly sales by customer" runs in 15 seconds. It should run in under 1 second.

## Query (Before Optimization)

```sql
SELECT
  c.name,
  DATE_TRUNC('month', o.order_date)::DATE AS month,
  SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status != 'cancelled'
GROUP BY c.id, c.name, DATE_TRUNC('month', o.order_date)
ORDER BY month, revenue DESC;
```

## Step-by-Step Debugging

### 1. Run EXPLAIN (ANALYZE, BUFFERS)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ... ;
```

### 2. Identify Red Flags

| Red Flag | Meaning |
|----------|---------|
| Seq Scan on large table | Full table scan; consider index |
| High "rows" estimate vs actual | Bad statistics; run ANALYZE |
| Nested Loop with large inner | Consider Hash Join |
| Sort with large rows | Expensive; may need index for ORDER BY |
| Buffers: read >> hit | Disk I/O; data not cached |

### 3. Check Indexes

```sql
-- Indexes on join/filter columns?
\d orders
\d order_items
```

Required indexes:
- `orders(customer_id)` for JOIN
- `orders(status)` for WHERE
- `order_items(order_id)` for JOIN

### 4. Apply Fixes

- Add missing indexes
- Run `ANALYZE orders; ANALYZE order_items;`
- Consider materialized view for repeated reports

### 5. Verify

Re-run EXPLAIN (ANALYZE). Compare execution time and plan.

## Expected Outcome

- Index Scan instead of Seq Scan on orders, order_items
- Execution time < 1 second
- Lower buffer read count
