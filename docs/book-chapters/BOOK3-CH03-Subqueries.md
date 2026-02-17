# BOOK 3 – Chapter 3: Subqueries

---

## 1. Core Concept Explanation (Deep Technical Version)

### What Is a Subquery?

A **subquery** is a SELECT statement nested inside another SQL statement. It can appear in SELECT, FROM, WHERE, HAVING, and (in some DBMSs) INSERT/UPDATE. The outer query uses the subquery's result.

**Scalar subquery**: Returns exactly one row and one column. Use where a single value is expected (SELECT list, WHERE comparison).

**Table subquery (derived table)**: Returns multiple rows and columns. Use in FROM with alias.

**Correlated subquery**: References columns from the outer query. Executed once per outer row. Can be slow; consider rewriting as JOIN.

### Scalar Subquery

```sql
SELECT name, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
FROM customers c;
```

The subquery runs for each row of customers. It must return at most one row (error if multiple). Often correlated (references c.id).

### Table Subquery (Derived Table)

```sql
SELECT * FROM (
  SELECT customer_id, SUM(total) AS total_spent
  FROM orders
  GROUP BY customer_id
) sub
WHERE sub.total_spent > 1000;
```

Subquery produces a result set; outer query treats it as a table. **Must have alias** (sub).

### IN / NOT IN / EXISTS

**IN (subquery)**: Membership test. Row matches if column value is in subquery result. Subquery returns one column.

```sql
SELECT * FROM customers WHERE id IN (SELECT customer_id FROM orders WHERE status = 'shipped');
```

**NOT IN**: Rows where value is not in subquery. **NULL trap**: If subquery returns NULL, NOT IN yields no rows (NULL semantics). Use NOT EXISTS instead.

**EXISTS (subquery)**: Returns TRUE if subquery returns at least one row. Subquery typically selects a constant (SELECT 1). Often used with correlation.

```sql
SELECT c.* FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'shipped');
```

**EXISTS vs IN**: For large subquery results, EXISTS can short-circuit (stops at first match). NOT EXISTS avoids NOT IN's NULL issues.

### Correlated Subquery

References outer query. Executed once per outer row.

```sql
SELECT c.name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.total > 500);
```

For each customer, check if any order has total > 500. Can be slow on large tables—O(n*m). Consider JOIN:

```sql
SELECT DISTINCT c.name FROM customers c
JOIN orders o ON o.customer_id = c.id AND o.total > 500;
```

### Rewriting Guidelines

- **Correlated → JOIN**: When logic allows. JOIN is often faster (set-based).
- **IN → EXISTS**: When subquery returns many rows; EXISTS may short-circuit.
- **NOT IN → NOT EXISTS**: Avoids NULL semantics. `NOT EXISTS (SELECT 1 FROM t WHERE t.x = outer.x)`.

---

## 2. Why This Matters in Production

### Real-World System Example

"Customers who have placed an order in the last 30 days." EXISTS subquery: `WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.created_at >= CURRENT_DATE - 30)`. Alternative: JOIN + DISTINCT. Both valid; planner may optimize similarly. EXISTS is often clearer for "has at least one" semantics.

### Scalability Impact

- **Correlated subquery**: O(outer_rows * inner_executions). On 100K customers and 1M orders, can be slow. JOIN or lateral may scale better.
- **IN with large list**: `WHERE id IN (SELECT ...)` — if subquery returns 100K rows, IN-list can be expensive. EXISTS or semi-join may be better.

### Performance Impact

- **Scalar subquery in SELECT**: Runs per row. For 10K rows, 10K subquery executions. Consider JOIN + GROUP BY or lateral.
- **Derived table**: Materialized or inlined by planner. Usually efficient.

### Data Integrity Implications

- **NOT IN with NULL**: Subquery returns (1, 2, NULL). `WHERE x NOT IN (1, 2, NULL)` matches nothing—NULL comparison is UNKNOWN. Use NOT EXISTS.

### Production Failure Scenario

**Case: NOT IN returned no rows.** Query: "Products not in any order." `WHERE product_id NOT IN (SELECT product_id FROM order_items)`. order_items had NULL product_id in some rows. NOT IN with NULL → no matches. Fix: `WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id)`.

---

## 3. PostgreSQL Implementation

### Scalar Subquery

```sql
SELECT 
  c.name,
  (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count,
  (SELECT MAX(total) FROM orders o WHERE o.customer_id = c.id) AS max_order
FROM customers c;
```

### Derived Table

```sql
SELECT sub.customer_id, sub.total_spent
FROM (
  SELECT customer_id, SUM(total) AS total_spent
  FROM orders
  GROUP BY customer_id
) sub
WHERE sub.total_spent > 500
ORDER BY sub.total_spent DESC;
```

### IN and EXISTS

```sql
-- Customers with at least one shipped order
SELECT * FROM customers
WHERE id IN (SELECT customer_id FROM orders WHERE status = 'shipped');

-- Same with EXISTS (often better for large subquery)
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.status = 'shipped');
```

### NOT EXISTS (Avoid NOT IN with NULLs)

```sql
-- Products never ordered
SELECT * FROM products p
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);
```

### LATERAL (PostgreSQL)

Subquery can reference columns from preceding FROM items.

```sql
SELECT c.name, o.order_date, o.total
FROM customers c
CROSS JOIN LATERAL (
  SELECT order_date, total
  FROM orders
  WHERE customer_id = c.id
  ORDER BY order_date DESC
  LIMIT 3
) o;
```

---

## 4. Common Developer Mistakes

### Mistake 1: NOT IN with Possible NULL in Subquery

Returns no rows. Use NOT EXISTS.

### Mistake 2: Scalar Subquery Returning Multiple Rows

Error. Ensure subquery returns at most one row (e.g., use MAX, or add condition that guarantees uniqueness).

### Mistake 3: Derived Table Without Alias

`FROM (SELECT ...)` fails. Must be `FROM (SELECT ...) AS sub`.

### Mistake 4: Correlated Subquery When JOIN Would Do

Correlated subquery executed per row. JOIN is set-based. Prefer JOIN when logic is equivalent.

### Mistake 5: Subquery in SELECT Returning Multiple Rows

`SELECT name, (SELECT id FROM orders WHERE customer_id = c.id)` — error if customer has multiple orders. Use aggregate or LIMIT 1, or move to JOIN.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: When would you use EXISTS instead of IN?**  
A: When subquery returns many rows; EXISTS can short-circuit. Also NOT EXISTS avoids NULL issues with NOT IN.

**Q: What is a correlated subquery?**  
A: Subquery references outer query columns. Executed once per outer row. Often slower; consider JOIN.

**Q: Why does NOT IN with NULL in subquery return no rows?**  
A: NOT IN is equivalent to NOT (x = a AND x = b AND x = NULL). x = NULL is UNKNOWN. AND with UNKNOWN yields UNKNOWN. NOT UNKNOWN is UNKNOWN. Row doesn't match. Use NOT EXISTS.

### Scenario-Based Questions

**Q: Rewrite this correlated subquery as a JOIN: "Customers with at least one order > 500"**  
A: `SELECT DISTINCT c.* FROM customers c JOIN orders o ON o.customer_id = c.id WHERE o.total > 500`.

**Q: How do you get "customers who have never ordered"?**  
A: `WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)`. Avoid NOT IN (NULL trap).

---

## 6. Advanced Engineering Notes

### Semi-Join and Anti-Join

EXISTS/IN often optimized to **semi-join** (return outer row if match exists). NOT EXISTS to **anti-join**. Planner may choose hash or nested loop. EXPLAIN shows.

### CTEs (Common Table Expressions)

```sql
WITH top_customers AS (
  SELECT customer_id, SUM(total) AS total_spent
  FROM orders
  GROUP BY customer_id
  HAVING SUM(total) > 1000
)
SELECT c.name, tc.total_spent
FROM customers c
JOIN top_customers tc ON c.id = tc.customer_id;
```

CTE can replace derived table. More readable for complex queries. In PostgreSQL, CTE is an "optimization fence" by default (materialized); PostgreSQL 12+ allows inlining with NOT MATERIALIZED.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Scalar subquery: Add order count to each customer in SELECT.
2. Derived table: Customers with total spent > 500. Use subquery for SUM.
3. EXISTS: Customers with at least one pending order.
4. NOT EXISTS: Products with no order_items.

### Rewriting Task

Given: `SELECT * FROM customers WHERE id IN (SELECT customer_id FROM orders WHERE total > 100)`. Rewrite using EXISTS. Rewrite using JOIN. Compare EXPLAIN output.

---

## 8. Summary in 10 Bullet Points

1. **Subquery**: SELECT nested in another statement. Scalar (one value), table (rows), or correlated.
2. **Scalar subquery**: Returns one row, one column. Use in SELECT, WHERE. Must return at most one row.
3. **Derived table**: Subquery in FROM. Must have alias. Treated as table.
4. **IN (subquery)**: Membership test. One column from subquery.
5. **EXISTS**: TRUE if subquery returns ≥1 row. Use SELECT 1. Can short-circuit.
6. **NOT IN + NULL**: Returns no rows. Use NOT EXISTS instead.
7. **Correlated subquery**: References outer query. Runs per outer row. Often slow.
8. **Rewrite**: Correlated → JOIN; NOT IN → NOT EXISTS.
9. **LATERAL**: Subquery references preceding FROM. PostgreSQL. For per-row subqueries.
10. **CTE**: WITH name AS (SELECT ...). Replaces derived table; often clearer.
