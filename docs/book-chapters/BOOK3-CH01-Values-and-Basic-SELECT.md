# BOOK 3 – Chapter 1: Values and Basic SELECT

---

## 1. Core Concept Explanation (Deep Technical Version)

### Values: Literals and Expressions

In SQL, a **value** is a single datum: a number, string, boolean, date, or NULL. Values appear as **literals** (constants) or as results of **expressions** (computed from columns, functions, operators).

**Literals**:
- **Numeric**: `42`, `3.14`, `1e-5`. No quotes.
- **String**: `'hello'`, `'O''Reilly'` (escape single quote by doubling). Single quotes only; double quotes are for identifiers.
- **Boolean**: `TRUE`, `FALSE`. (PostgreSQL; standard uses 1/0 in some contexts.)
- **Datetime**: `DATE '2024-02-15'`, `TIMESTAMP '2024-02-15 14:30:00'`, `INTERVAL '7 days'`.
- **NULL**: Absence of value. Not a literal in the usual sense; use `NULL` keyword.

**Expressions** combine values, columns, and operators: `price * quantity`, `UPPER(name)`, `created_at + INTERVAL '1 day'`. Expressions evaluate to a scalar value (or NULL).

### Column References and Qualified Names

**Unqualified**: `name`, `price`. Ambiguous when multiple tables in FROM.

**Qualified**: `customers.name`, `o.total`. Table alias or table name. Required when column exists in multiple tables.

**Best practice**: Use short aliases (c, o) and qualify in multi-table queries to avoid ambiguity.

### The SELECT Statement: Minimal Form

```sql
SELECT expression1, expression2, ...
FROM table
WHERE condition;
```

- **SELECT**: Projection—which columns/expressions to return. Can be `*` (all columns) or explicit list.
- **FROM**: Source table(s). Required in standard SQL (some DBMSs allow SELECT without FROM for constants).
- **WHERE**: Row filter. Optional. Applied before aggregation.

**Evaluation**: FROM produces a working set; WHERE filters rows; SELECT projects columns. Conceptually: FROM → WHERE → SELECT. (Full order includes GROUP BY, HAVING, etc.—covered in Ch 2.)

### SELECT Without FROM (PostgreSQL)

```sql
SELECT 1 AS one, 'test' AS str, NOW() AS now;
```

Returns one row with computed values. Useful for constants, function calls, or testing.

---

## 2. Why This Matters in Production

### Real-World System Example

A reporting query: `SELECT customer_id, order_date, total FROM orders WHERE status = 'shipped'`. Values flow from table (columns) through filter (WHERE) to result (SELECT). Expressions like `total * 1.1` for "total with 10% tax" are computed in SELECT.

### Scalability Impact

- **SELECT ***: Returns all columns. If schema grows, result set grows. Application may break if column order changes. Prefer explicit column list.
- **Expressions in SELECT**: Computed per row. For heavy expressions (e.g., regex), consider materialized columns or indexing expression.

### Performance Impact

- **WHERE first**: Filter early. `WHERE status = 'active'` reduces rows before SELECT projects. Planner optimizes; but writing selective WHERE helps.
- **Literal vs parameter**: `WHERE id = 123` vs `WHERE id = $1`. Parameterized queries enable plan caching; literals can cause plan bloat.

### Data Integrity Implications

- **NULL in expressions**: `price * quantity` when quantity is NULL yields NULL. Use COALESCE: `COALESCE(quantity, 0) * price`.
- **Type coercion**: `'123'::INT` vs implicit. Explicit cast avoids surprises.

### Production Failure Scenario

**Case: SELECT * in API.** An API returned `SELECT * FROM users`. Schema added `password_hash` column. API exposed it. Fix: Explicit column list. Lesson: Never SELECT * in production code that returns data to clients.

---

## 3. PostgreSQL Implementation

### Literals

```sql
SELECT 
  42 AS int_val,
  3.14::NUMERIC AS decimal_val,
  'hello' AS str_val,
  TRUE AS bool_val,
  DATE '2024-02-15' AS date_val,
  TIMESTAMP '2024-02-15 14:30:00' AS ts_val,
  NULL AS null_val;
```

### Expressions

```sql
SELECT 
  name,
  price * quantity AS line_total,
  UPPER(LEFT(name, 1)) AS first_letter,
  created_at + INTERVAL '7 days' AS due_date
FROM order_items
WHERE quantity > 0;
```

### Column Aliases

```sql
SELECT 
  customer_id AS cid,
  SUM(total) AS total_spent
FROM orders
GROUP BY customer_id;
-- Alias used in ORDER BY (evaluated after SELECT)
ORDER BY total_spent DESC;
```

### Basic Filtering

```sql
SELECT * FROM products WHERE price > 100;
SELECT * FROM orders WHERE status IN ('pending', 'shipped');
SELECT * FROM customers WHERE email LIKE '%@gmail.com';
SELECT * FROM events WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';
```

---

## 4. Common Developer Mistakes

### Mistake 1: SELECT * in Production

Schema changes add columns; application may break or expose sensitive data. Use explicit column list.

### Mistake 2: Unqualified Columns in Multi-Table Query

`SELECT name FROM customers c JOIN orders o ON c.id = o.customer_id`—ambiguous if orders has `name`. Use `c.name` or `o.name`.

### Mistake 3: String Comparison with Wrong Quotes

`WHERE status = "pending"` fails in PostgreSQL (double quotes = identifier). Use `WHERE status = 'pending'`.

### Mistake 4: NULL in Comparisons

`WHERE phone = NULL` matches nothing. Use `WHERE phone IS NULL`.

### Mistake 5: Expression Without Alias for Complex Output

`SELECT price * quantity`—column name may be `?column?` or ugly. Add `AS line_total`.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the difference between a literal and an expression?**  
A: Literal is a constant (42, 'hello'). Expression computes a value (price * quantity, UPPER(name)). Both produce values.

**Q: When would you use qualified column names?**  
A: When the same column name exists in multiple tables in FROM. Prevents ambiguity. Use table alias: c.name, o.total.

**Q: Why avoid SELECT * in production?**  
A: Schema changes add columns; app may break. May expose sensitive columns. Explicit list is stable and clear.

### Scenario-Based Questions

**Q: How do you return a constant value in a query?**  
A: `SELECT 1 AS id, 'active' AS status` or `SELECT 1, 'active' FROM table LIMIT 1`. Some DBMSs allow SELECT without FROM.

**Q: Expression returns NULL when one operand is NULL. How do you handle it?**  
A: COALESCE(column, default) or NULLIF. For arithmetic: COALESCE(quantity, 0) * price.

---

## 6. Advanced Engineering Notes

### Expression Indexes

```sql
CREATE INDEX idx_orders_total_tax ON orders((total * 1.1));
-- Query: WHERE total * 1.1 > 100 can use index
```

### Computed/Generated Columns

```sql
ALTER TABLE order_items ADD COLUMN line_total NUMERIC GENERATED ALWAYS AS (quantity * unit_price) STORED;
```

Stored at write time; no recomputation on read.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Write `SELECT 1, 'test', NOW();` — observe single-row result.
2. Write `SELECT id, name, price FROM products WHERE price > 50;` — filter and project.
3. Add expression: `SELECT id, name, price, price * 1.1 AS price_with_tax FROM products;`
4. Use COALESCE: `SELECT name, COALESCE(phone, 'N/A') AS phone FROM customers;`

### Verification Task

Given `orders` (id, customer_id, total), write a query that returns customer_id and total for orders where total is not NULL. Use explicit column list, no SELECT *.

---

## 8. Summary in 10 Bullet Points

1. **Values**: Literals (42, 'hello') or expressions (price * quantity). SQL operates on values.
2. **Literals**: Numeric (no quotes), string (single quotes), boolean (TRUE/FALSE), datetime (DATE '...'), NULL.
3. **Expressions**: Combine columns, operators, functions. Evaluate to scalar or NULL.
4. **Qualified names**: table.column or alias.column. Required when column exists in multiple tables.
5. **SELECT**: Projection. Explicit columns preferred over *.
6. **FROM**: Source table(s). Required for table data.
7. **WHERE**: Row filter. Applied before SELECT. Use IS NULL, not = NULL.
8. **Aliases**: AS name for columns. Useful for expressions and readability.
9. **SELECT ***: Avoid in production. Schema changes break apps; may expose sensitive data.
10. **NULL in expressions**: Most operations yield NULL. Use COALESCE for defaults.
