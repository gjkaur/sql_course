# BOOK 3 – Chapter 2: SELECT Deep Dive

---

## 1. Core Concept Explanation (Deep Technical Version)

### Logical Execution Order

SQL is **declarative**—you specify what you want, not how. The DBMS translates your query into an execution plan. Conceptually, clauses are evaluated in this order:

```
FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT/OFFSET
```

**Implication**: You cannot use a column alias from SELECT in WHERE—WHERE runs before SELECT, so the alias doesn't exist yet. Use a subquery or repeat the expression. You *can* use SELECT aliases in ORDER BY (ORDER BY runs after SELECT).

### FROM: The Source

- **Tables**: Named tables, views.
- **JOINs**: Combine tables (covered in Ch 4).
- **Subqueries (derived tables)**: `FROM (SELECT ...) AS sub`. Must have alias.
- **LATERAL**: Subquery can reference columns from preceding FROM items. PostgreSQL extension.

### WHERE: Row Filter (Pre-Aggregation)

- Filters rows **before** GROUP BY.
- Cannot use aggregate functions (COUNT, SUM, etc.)—those operate on groups. Use HAVING for group-level filters.
- Conditions: `=`, `<>`, `>`, `<`, `IN`, `BETWEEN`, `LIKE`, `IS NULL`, `EXISTS`.
- **Short-circuit**: Optimizer may reorder; but putting most selective condition first can help in some cases. Don't rely on evaluation order for side effects.

### GROUP BY: Aggregation

- Groups rows by specified columns. One result row per distinct group.
- All non-aggregated columns in SELECT must appear in GROUP BY (or be functionally dependent).
- PostgreSQL allows `GROUP BY 1, 2` (column position) and `GROUP BY expression`.
- **Aggregates**: COUNT(*), COUNT(column), SUM, AVG, MIN, MAX. COUNT(column) excludes NULLs.

### HAVING: Group Filter (Post-Aggregation)

- Filters **groups** after aggregation.
- Can use aggregate functions: `HAVING COUNT(*) > 5`, `HAVING SUM(total) > 1000`.
- WHERE filters rows; HAVING filters groups. Apply row-level filters in WHERE (more efficient).

### SELECT: Projection

- Which columns/expressions to return.
- Can include aggregates (when using GROUP BY), scalars, subqueries.
- `*` expands to all columns. Avoid in production.

### DISTINCT and DISTINCT ON

- **DISTINCT**: Removes duplicate rows. Cost: sort or hash.
- **DISTINCT ON (col)**: PostgreSQL extension. One row per distinct value of col. Requires ORDER BY that starts with same columns. E.g., "latest order per customer."

### ORDER BY and NULLs

- Sort result set. `ASC` (default) or `DESC`.
- **NULLS FIRST** / **NULLS LAST**: Control NULL ordering. Default varies by DBMS; PostgreSQL sorts NULLs last for ASC.
- Can use column position: `ORDER BY 2` (second column).
- Can use expressions: `ORDER BY LOWER(name)`.

### LIMIT and OFFSET

- **LIMIT n**: First n rows.
- **OFFSET m**: Skip m rows. Often used with LIMIT for pagination.
- **Warning**: OFFSET is O(n)—database must skip m rows. For large offsets (e.g., page 1000), use **keyset pagination**: `WHERE id > last_seen_id ORDER BY id LIMIT 20`.

---

## 2. Why This Matters in Production

### Real-World System Example

Dashboard: "Top 10 customers by order count in last 30 days." FROM orders → WHERE created_at >= ... → GROUP BY customer_id → HAVING (none) → SELECT customer_id, COUNT(*) → ORDER BY COUNT(*) DESC → LIMIT 10. Execution order guides both logic and optimization.

### Scalability Impact

- **WHERE before GROUP BY**: Filtering 1M rows to 10K before grouping is cheaper than grouping 1M then filtering groups.
- **OFFSET pagination**: Page 1000 with OFFSET 20000 scans 20K rows. Keyset pagination: O(1) per page.

### Performance Impact

- **HAVING vs WHERE**: `WHERE status = 'active'` filters rows; `HAVING COUNT(*) > 5` filters groups. Put row filters in WHERE.
- **DISTINCT cost**: Requires deduplication. If duplicates are impossible (e.g., PK in result), use UNION ALL instead of UNION to avoid unnecessary dedup.

### Data Integrity Implications

- **GROUP BY and non-aggregated columns**: Omitting a non-aggregated column causes error (or undefined in some DBMSs). PostgreSQL enforces: every SELECT column must be in GROUP BY or be aggregated.

### Production Failure Scenario

**Case: Alias in WHERE.** Developer wrote `SELECT total * 1.1 AS with_tax FROM orders WHERE with_tax > 100`. Error: column "with_tax" does not exist. WHERE runs before SELECT. Fix: `WHERE total * 1.1 > 100` or wrap in subquery.

---

## 3. PostgreSQL Implementation

### Execution Order Example

```sql
SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS total_spent
FROM orders
WHERE status = 'shipped'
GROUP BY customer_id
HAVING COUNT(*) >= 3
ORDER BY total_spent DESC
LIMIT 10;
```

### WHERE vs HAVING

```sql
-- Row filter: only shipped orders
-- Group filter: only customers with 3+ orders
SELECT customer_id, COUNT(*), SUM(total)
FROM orders
WHERE status = 'shipped'        -- Filters rows first
GROUP BY customer_id
HAVING COUNT(*) >= 3;           -- Filters groups after
```

### DISTINCT ON (PostgreSQL)

```sql
-- Latest order per customer
SELECT DISTINCT ON (customer_id) customer_id, id, created_at
FROM orders
ORDER BY customer_id, created_at DESC;
```

### Keyset Pagination

```sql
-- Page 1
SELECT * FROM orders ORDER BY id LIMIT 20;

-- Page 2 (given last id from page 1 = 42)
SELECT * FROM orders WHERE id > 42 ORDER BY id LIMIT 20;
```

### NULL Ordering

```sql
SELECT * FROM products ORDER BY price NULLS LAST;
SELECT * FROM products ORDER BY name NULLS FIRST;
```

---

## 4. Common Developer Mistakes

### Mistake 1: Using SELECT Alias in WHERE

`WHERE total_spent > 100` when total_spent is defined in SELECT. Use expression or subquery.

### Mistake 2: Aggregate in WHERE

`WHERE COUNT(*) > 5` is invalid. Use HAVING.

### Mistake 3: Non-Aggregated Column Not in GROUP BY

`SELECT customer_id, order_date, SUM(total) FROM orders GROUP BY customer_id`—order_date not in GROUP BY. Error in PostgreSQL.

### Mistake 4: OFFSET for Deep Pagination

OFFSET 100000 on large table. Use keyset: `WHERE id > last_id ORDER BY id LIMIT n`.

### Mistake 5: DISTINCT When Not Needed

UNION already deduplicates. Use UNION ALL when duplicates are impossible—faster.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the execution order of SELECT?**  
A: FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT.

**Q: Why can't you use a column alias from SELECT in WHERE?**  
A: WHERE runs before SELECT; the alias doesn't exist yet. Use the expression or a subquery.

**Q: What is the difference between WHERE and HAVING?**  
A: WHERE filters rows before aggregation. HAVING filters groups after aggregation. Use WHERE for row-level filters; HAVING for aggregate conditions.

### Scenario-Based Questions

**Q: How do you get "latest order per customer"?**  
A: PostgreSQL: `SELECT DISTINCT ON (customer_id) * FROM orders ORDER BY customer_id, created_at DESC`. Other DBMSs: window function ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at DESC) and filter rn = 1.

**Q: What is keyset pagination?**  
A: `WHERE id > last_seen_id ORDER BY id LIMIT n`. O(1) per page vs OFFSET's O(n). No random page access (can't jump to page 100 directly).

---

## 6. Advanced Engineering Notes

### FILTER Clause (PostgreSQL)

Conditional aggregates without CASE:

```sql
SELECT customer_id,
  COUNT(*) FILTER (WHERE status = 'shipped') AS shipped_count,
  COUNT(*) FILTER (WHERE status = 'pending') AS pending_count
FROM orders
GROUP BY customer_id;
```

### GROUPING SETS, CUBE, ROLLUP

Multiple levels of aggregation in one query. For analytics.

```sql
SELECT region, product, SUM(sales)
FROM sales
GROUP BY ROLLUP(region, product);
-- Returns: (region, product), (region, NULL), (NULL, NULL)
```

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Write query: customer_id, order count, total spent. Filter to shipped orders. Only customers with 2+ orders. Order by total spent DESC. Limit 5.
2. Use DISTINCT ON: latest order per customer.

### Pagination Task

Implement keyset pagination for orders. Assume API returns last order id. Write the next page query.

---

## 8. Summary in 10 Bullet Points

1. **Execution order**: FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT.
2. **WHERE**: Row filter. Before aggregation. No aggregates.
3. **HAVING**: Group filter. After aggregation. Can use aggregates.
4. **GROUP BY**: All non-aggregated SELECT columns must be in GROUP BY.
5. **DISTINCT ON**: PostgreSQL. One row per distinct value of specified columns. Requires matching ORDER BY.
6. **ORDER BY**: Can use SELECT aliases. NULLS FIRST/LAST for NULL ordering.
7. **OFFSET**: O(n). Avoid for deep pagination.
8. **Keyset pagination**: WHERE id > last_id ORDER BY id LIMIT n. O(1) per page.
9. **Filter early**: WHERE before GROUP BY reduces work.
10. **Aggregate in HAVING**: COUNT(*), SUM() etc. in HAVING, not WHERE.
