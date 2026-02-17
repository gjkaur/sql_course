# BOOK 3 – Chapter 5: Set Operators and Cursors

---

## 1. Core Concept Explanation (Deep Technical Version)

### Set Operators: Combining Result Sets Vertically

**Set operators** combine the results of two or more SELECT statements **vertically** (stacking rows), not horizontally (like JOINs). Requirements: same number of columns; compatible data types; column names from the first query.

### UNION

**UNION** combines two result sets and **removes duplicates**. Rows that appear in both appear once.

```sql
SELECT name FROM customers
UNION
SELECT name FROM suppliers;
```

Use when you want distinct rows from both. **UNION ALL** keeps duplicates—faster because no deduplication. Use UNION ALL when duplicates are impossible (e.g., from disjoint tables) or when you want to preserve them.

### INTERSECT

**INTERSECT** returns rows that appear in **both** result sets.

```sql
SELECT product_id FROM order_items
INTERSECT
SELECT product_id FROM wishlist_items;
```

"Products that have been both ordered and wishlisted."

### EXCEPT (Set Difference)

**EXCEPT** returns rows in the first result set that are **not** in the second.

```sql
SELECT product_id FROM products
EXCEPT
SELECT product_id FROM order_items;
```

"Products that have never been ordered." (Alternative to NOT EXISTS.)

### Cursors: Row-by-Row Processing

A **cursor** is a database object that allows row-by-row processing of a query result. You DECLARE a cursor, OPEN it, FETCH rows one at a time, and CLOSE it. Cursors maintain **server-side state**—the database holds the result set and position.

**Use cases**:
- Stored procedures that need to process rows sequentially (e.g., complex business logic per row).
- Streaming large result sets without loading all into memory (fetch in batches).
- Legacy systems or migration scripts.

**Downside**: Round-trip per fetch (or per batch). For large result sets, fetching all rows in one call and processing in the application is usually faster. Cursors add overhead.

### Cursors vs Application Iteration

| Approach | Pros | Cons |
|----------|------|------|
| **Cursor** | Server-side state; low memory on client | Round-trips per fetch; slower |
| **Application** | Single/batch fetch; process in app | Loads data into app memory |
| **Keyset pagination** | O(1) per page; no server state | No random page access |

**Recommendation**: For most applications, fetch in batches (LIMIT/OFFSET or keyset), process in application. Use cursors in stored procedures when row-by-row logic must run in the database, or when streaming very large results to avoid memory pressure.

### Pagination: OFFSET vs Keyset

**OFFSET/LIMIT**: `ORDER BY id LIMIT 20 OFFSET 40`. Simple. Page 3 = skip 40, take 20. **Problem**: OFFSET is O(n)—database must scan and skip rows. Page 1000 is slow.

**Keyset (seek method)**: `WHERE id > last_seen_id ORDER BY id LIMIT 20`. O(1) per page. **Limitation**: No random page access (can't jump to page 100). Ideal for infinite scroll.

---

## 2. Why This Matters in Production

### Real-World System Example

**UNION**: Combine "active users" from two tables (e.g., web_users and app_users) into one list. UNION ALL if tables are disjoint. **INTERSECT**: Users who used both web and app. **EXCEPT**: Products in catalog but never sold.

**Cursors**: Rare in application code. More common in PL/pgSQL procedures for batch processing (e.g., "for each order, call external API, update status"). Or in ETL scripts.

### Scalability Impact

- **UNION vs UNION ALL**: UNION deduplicates (sort or hash). Cost. If no duplicates possible, UNION ALL is faster.
- **Cursor for 1M rows**: 1M round-trips (or batch fetches). Application fetch-all or keyset pagination is usually better.

### Performance Impact

- **EXCEPT vs NOT EXISTS**: Both can find "rows in A not in B." Planner may optimize similarly. NOT EXISTS with proper indexing is often efficient.
- **Cursor batch size**: FETCH 100 vs FETCH 1. Larger batch reduces round-trips but increases memory per fetch.

### Data Integrity Implications

- **UNION column order**: Must match. Wrong order → wrong data combined. Same for INTERSECT, EXCEPT.
- **NULL in set operations**: UNION treats two NULLs as equal (one kept). INTERSECT/EXCEPT: NULL = NULL is UNKNOWN; behavior can vary. Prefer filtering NULLs if semantics matter.

### Production Failure Scenario

**Case: Cursor in hot path.** Application used a cursor to iterate 100K rows, processing each. Each FETCH was a round-trip. Took minutes. Rewrote to fetch in batches of 1000; process in app. Seconds. Lesson: Avoid cursor for bulk processing; use set-based operations or batch fetch.

---

## 3. PostgreSQL Implementation

### UNION and UNION ALL

```sql
SELECT name FROM customers
UNION
SELECT name FROM suppliers
ORDER BY name;

-- Keep duplicates (faster)
SELECT product_id FROM order_items WHERE order_id = 1
UNION ALL
SELECT product_id FROM order_items WHERE order_id = 2;
```

### INTERSECT

```sql
SELECT customer_id FROM orders WHERE status = 'shipped'
INTERSECT
SELECT customer_id FROM orders WHERE status = 'pending';
-- Customers with both shipped and pending orders
```

### EXCEPT

```sql
SELECT id FROM products
EXCEPT
SELECT product_id FROM order_items;
-- Products never ordered
```

### Cursor (PL/pgSQL)

```sql
DO $$
DECLARE
  cur CURSOR FOR SELECT id, total FROM orders WHERE status = 'pending';
  rec RECORD;
BEGIN
  OPEN cur;
  LOOP
    FETCH cur INTO rec;
    EXIT WHEN NOT FOUND;
    -- Process rec.id, rec.total
    RAISE NOTICE 'Order % total %', rec.id, rec.total;
  END LOOP;
  CLOSE cur;
END $$;
```

### Cursor in Application (psycopg2)

```python
cur = conn.cursor(name='fetch_orders')  # Server-side cursor
cur.execute("SELECT * FROM orders")
while True:
    rows = cur.fetchmany(1000)
    if not rows:
        break
    process(rows)
```

### Keyset Pagination

```sql
-- Page 1
SELECT * FROM orders ORDER BY id LIMIT 20;

-- Page 2 (last id from page 1 = 42)
SELECT * FROM orders WHERE id > 42 ORDER BY id LIMIT 20;
```

---

## 4. Common Developer Mistakes

### Mistake 1: UNION When UNION ALL Would Do

If tables are disjoint (e.g., archived vs active), UNION ALL is faster. No need to deduplicate.

### Mistake 2: Wrong Column Order in Set Operations

SELECT a, b UNION SELECT b, a — columns combined incorrectly. Match order and types.

### Mistake 3: Cursor for Simple Query

Using cursor when a single SELECT would suffice. Fetch and process in app.

### Mistake 4: OFFSET for Deep Pagination

OFFSET 100000 on large table. Use keyset: WHERE id > last_id.

### Mistake 5: Forgetting to Close Cursor

Cursor holds server resources. Always CLOSE. In application, use context manager or try/finally.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: UNION vs UNION ALL?**  
A: UNION removes duplicates; UNION ALL keeps them. UNION ALL is faster when duplicates are impossible or desired.

**Q: What does INTERSECT do?**  
A: Returns rows that appear in both result sets. Set intersection.

**Q: What is keyset pagination?**  
A: WHERE id > last_seen_id ORDER BY id LIMIT n. O(1) per page vs OFFSET's O(n). No random page access. Good for infinite scroll.

### Scenario-Based Questions

**Q: How do you combine two tables' rows without duplicates?**  
A: UNION. Use UNION ALL if duplicates are acceptable or impossible.

**Q: When would you use a cursor?**  
A: Stored procedure with row-by-row logic. Streaming very large result without loading all into memory. Legacy compatibility. For most app code, batch fetch is better.

**Q: How do you implement "products never ordered"?**  
A: EXCEPT (SELECT id FROM products EXCEPT SELECT product_id FROM order_items) or NOT EXISTS. Both valid.

---

## 6. Advanced Engineering Notes

### Set Operation Column Types

Types must be compatible. VARCHAR and TEXT are compatible in PostgreSQL. INT and BIGINT may require cast. First query's column names are used.

### Cursor WITH HOLD

`DECLARE cur CURSOR WITH HOLD FOR SELECT ...` — cursor survives transaction commit. For long-running reads across commits. Uses more server resources.

### Pagination with OFFSET (When Acceptable)

For small page numbers (1–10), OFFSET is fine. For "load more" or infinite scroll, keyset is better. For "jump to page N" in admin UI with small N, OFFSET acceptable.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. UNION: Combine customer names and supplier names. Use UNION and UNION ALL; compare results.
2. EXCEPT: Products with no order_items.
3. Keyset pagination: Implement "next page" for orders. Assume last_seen_id from previous page.

### Cursor Task (Optional)

In psql or PL/pgSQL, declare a cursor for orders, fetch 5 rows, print, close. Compare with simple SELECT LIMIT 5.

---

## 8. Summary in 10 Bullet Points

1. **UNION**: Combine result sets; removes duplicates. Same column count and compatible types.
2. **UNION ALL**: Keeps duplicates. Faster when dedup not needed.
3. **INTERSECT**: Rows in both result sets.
4. **EXCEPT**: Rows in first but not second. Set difference.
5. **Set op requirements**: Same columns; compatible types; names from first query.
6. **Cursor**: Row-by-row fetch. Server-side state. For stored procedures or streaming.
7. **Cursor downside**: Round-trips. Often slower than batch fetch.
8. **Keyset pagination**: WHERE id > last_id ORDER BY id LIMIT n. O(1) per page.
9. **OFFSET**: O(n). Avoid for deep pagination.
10. **Prefer**: Batch fetch + app processing for most cases. Cursors for DB-side row logic.
