# BOOK 3 – Chapter 4: JOINs

---

## 1. Core Concept Explanation (Deep Technical Version)

### What Is a JOIN?

A **JOIN** combines rows from two (or more) tables based on a **join condition**. The result is a new result set with columns from both tables. JOINs implement relationships defined by foreign keys and extend the relational model's power to query across tables.

### INNER JOIN

**INNER JOIN** returns only rows where the join condition matches in **both** tables. Rows with no match in the other table are excluded.

```sql
SELECT * FROM orders o
INNER JOIN customers c ON o.customer_id = c.id;
```

Only orders with a matching customer appear. Orders with invalid customer_id (orphan) are excluded. "INNER" is often omitted—JOIN defaults to INNER.

### LEFT JOIN (LEFT OUTER JOIN)

**LEFT JOIN** returns **all** rows from the left table. For each left row, if there is a matching right row, it is included; otherwise, right columns are NULL.

```sql
SELECT * FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

All customers appear. Customers with no orders have NULL for order columns. Use case: "customers and their orders, including customers with no orders."

### RIGHT JOIN

**RIGHT JOIN** returns all rows from the right table; left columns NULL where no match. Rarely used—flip tables and use LEFT JOIN for readability.

### FULL OUTER JOIN

**FULL OUTER JOIN** returns all rows from both tables. Matched rows are combined; unmatched rows have NULLs on the other side.

Use case: Compare two lists—find rows in A only, in B only, and in both. E.g., "employees and their managers; include employees without managers and managers without direct reports."

### CROSS JOIN

**CROSS JOIN** produces the **Cartesian product**: every row of A combined with every row of B. No join condition. N rows in A, M in B → N*M rows.

Use case: Generating combinations (e.g., all product × store combinations). Rarely intended for ad-hoc querying—usually a bug if you get millions of rows.

### ON vs WHERE

- **ON**: Join condition. Determines which rows from the two tables are combined. For LEFT JOIN, conditions on the right table in ON still include left rows (with NULL right side); conditions in WHERE filter those out.
- **WHERE**: Filter applied **after** the join. Filters the result set.

**INNER JOIN**: `ON a.x = b.y AND a.z = 1` is equivalent to `ON a.x = b.y WHERE a.z = 1`. No difference.

**LEFT JOIN**: `ON a.x = b.y WHERE b.id IS NOT NULL` effectively turns it into INNER—rows with no match (b.id NULL) are filtered out. Put right-table filters in ON if you want to filter which right rows match, but keep left rows; put in WHERE if you want to exclude left rows with no match.

### Self-Join

A table joined to itself. Use different aliases. E.g., employees and their managers (both in employees table).

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

---

## 2. Why This Matters in Production

### Real-World System Example

E-commerce: orders JOIN order_items JOIN products. Get order details with product names. INNER JOIN ensures only valid references. LEFT JOIN orders to shipments if some orders aren't shipped yet.

### Scalability Impact

- **Join order**: Planner chooses. For complex joins, join order affects performance. Hint in some DBMSs; PostgreSQL relies on statistics and cost model.
- **Index on join columns**: FK columns should be indexed. JOIN on unindexed column → hash join or nested loop with seq scan.

### Performance Impact

- **Nested Loop**: Small inner table, index on join column. O(n * log m).
- **Hash Join**: Larger tables, equality join. Build hash on one side; probe with other. O(n + m).
- **Merge Join**: Both sides sorted on join column. O(n + m). Requires sort or index.

### Data Integrity Implications

- **INNER JOIN excludes orphans**: Orders with invalid customer_id don't appear. Use LEFT JOIN if you want to see them (and fix data).
- **Duplicate rows**: One-to-many join (customer → orders) multiplies customer rows. Use DISTINCT or aggregate if you need unique customers.

### Production Failure Scenario

**Case: LEFT JOIN filter in WHERE.** Query: "Customers and their last order." Used LEFT JOIN orders, then `WHERE order_date = (SELECT MAX(...))`. WHERE filtered out customers with no orders (NULL order_date). Intended to keep them. Fix: Use subquery or LATERAL for "last order" in ON, or use separate query for customers with no orders.

---

## 3. PostgreSQL Implementation

### INNER JOIN

```sql
SELECT o.id, o.total, c.name AS customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.status = 'shipped';
```

### LEFT JOIN

```sql
SELECT c.name, o.id AS order_id, o.total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'shipped';
-- Customers with no shipped orders: order_id, total are NULL
```

### FULL OUTER JOIN

```sql
SELECT COALESCE(a.id, b.id) AS id, a.col AS a_col, b.col AS b_col
FROM table_a a
FULL OUTER JOIN table_b b ON a.id = b.id
WHERE a.id IS NULL OR b.id IS NULL;  -- Rows in one table only
```

### Self-Join

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

### Multi-Table Join

```sql
SELECT o.id, c.name, p.name AS product_name, oi.quantity
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id;
```

---

## 4. Common Developer Mistakes

### Mistake 1: Cartesian Product (Missing ON)

`FROM a, b` or `FROM a CROSS JOIN b` without ON. Produces N*M rows. Usually a bug.

### Mistake 2: Filter in WHERE That Should Be in ON (LEFT JOIN)

`LEFT JOIN orders o ON o.customer_id = c.id WHERE o.status = 'shipped'` — excludes customers with no shipped orders (o.status is NULL). If you want to keep them, put status in ON: `ON o.customer_id = c.id AND o.status = 'shipped'`.

### Mistake 3: Duplicate Rows from One-to-Many

Customer has 10 orders. JOIN produces 10 rows for that customer. If you need one row per customer, use DISTINCT, GROUP BY, or subquery for aggregation.

### Mistake 4: Joining on Wrong Columns

customer_id = product_id (typo). Wrong results. Verify FK relationships.

### Mistake 5: Using RIGHT JOIN When LEFT Is Clearer

Flip tables and use LEFT. More readable.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the difference between INNER and LEFT JOIN?**  
A: INNER: only rows with match in both tables. LEFT: all rows from left; match from right or NULL. Use LEFT when you want to keep left rows with no match.

**Q: When would you use FULL OUTER JOIN?**  
A: When you need all rows from both tables, matched where possible. E.g., comparing two lists—find in A only, B only, both.

**Q: ON vs WHERE for JOIN conditions?**  
A: ON is the join condition. For INNER JOIN, adding filter in ON vs WHERE is equivalent. For LEFT JOIN, filter on right table in WHERE excludes left rows with no match (turns into INNER effectively). Put right-table filter in ON to keep left rows.

### Scenario-Based Questions

**Q: How do you find customers with no orders?**  
A: `SELECT c.* FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE o.id IS NULL`. Or NOT EXISTS.

**Q: Self-join for employee and manager?**  
A: `FROM employees e LEFT JOIN employees m ON e.manager_id = m.id`. Two aliases for same table.

---

## 6. Advanced Engineering Notes

### Join Algorithms (PostgreSQL)

- **Nested Loop**: Inner table small or indexed. Good for selective joins.
- **Hash Join**: Build hash table on inner; probe with outer. Good for larger tables, equality.
- **Merge Join**: Both sides sorted. Good when indexes support order.

EXPLAIN shows which. Planner picks based on cost.

### LATERAL Join

```sql
SELECT c.name, o.order_date, o.total
FROM customers c
CROSS JOIN LATERAL (
  SELECT order_date, total FROM orders
  WHERE customer_id = c.id
  ORDER BY order_date DESC
  LIMIT 1
) o;
```

LATERAL allows subquery to reference c.id. "Latest order per customer."

---

## 7. Mini Practical Exercise

### Hands-On Task

1. INNER JOIN: orders and customers. List order id, customer name, total.
2. LEFT JOIN: customers and orders. Include customers with no orders.
3. Self-join: employees and managers.
4. Multi-table: orders, order_items, products. List order id, product name, quantity.

### Analysis Task

When does `LEFT JOIN ... WHERE right.id IS NULL` equal `WHERE NOT EXISTS`? Write equivalent queries.

---

## 8. Summary in 10 Bullet Points

1. **INNER JOIN**: Only matching rows. Default JOIN. Excludes orphans.
2. **LEFT JOIN**: All from left; match from right or NULL. Keeps left rows with no match.
3. **RIGHT JOIN**: All from right. Prefer flipping and using LEFT.
4. **FULL OUTER**: All from both. Matched where possible. For comparing two lists.
5. **CROSS JOIN**: Cartesian product. N*M rows. Rarely intended.
6. **ON**: Join condition. WHERE: filter after join.
7. **LEFT + WHERE on right**: Filters out NULLs. Effectively INNER.
8. **Self-join**: Same table, different aliases. E.g., employee and manager.
9. **Index join columns**: FK columns. Speeds up JOIN.
10. **Duplicate rows**: One-to-many join multiplies. Use DISTINCT or aggregate if needed.
