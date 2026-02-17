# Subqueries and Correlated Subqueries

## Subquery Types

### Scalar Subquery

Returns single value. Use in SELECT, WHERE, HAVING.

```sql
SELECT name, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
FROM customers c;
```

### Table Subquery (Derived Table)

Returns rows. Use in FROM with alias.

```sql
SELECT * FROM (SELECT customer_id, SUM(total) AS t FROM orders GROUP BY customer_id) sub
WHERE sub.t > 100;
```

### IN / NOT IN / EXISTS

- `WHERE id IN (SELECT ...)` — membership test
- `WHERE EXISTS (SELECT 1 FROM ... WHERE correlated)` — often faster than IN for large sets
- `NOT IN` with NULL in subquery returns no rows (NULL semantics)

## Correlated Subquery

References outer query. Executed once per outer row.

```sql
SELECT c.name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'shipped');
```

**Performance**: Can be slow; consider JOIN or lateral.

## Rewriting

- Correlated → JOIN when possible
- `IN (subquery)` → `EXISTS` when subquery returns many rows
- `NOT IN` → `NOT EXISTS` to avoid NULL issues
