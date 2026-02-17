# BOOK 7 – Chapter 1: Index and Query Tuning

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Query Execution Pipeline

A query goes through: **parse** → **analyze** → **rewrite** → **plan** → **execute**. The **planner** chooses an execution plan based on table statistics, indexes, and cost estimates. Tuning means giving the planner better options (indexes) and accurate statistics (ANALYZE).

### When to Add Indexes

- **WHERE clause**: Filter columns. `WHERE status = 'active'` → index on status.
- **JOIN columns**: FK columns. `JOIN ON orders.customer_id = customers.id` → index on orders.customer_id.
- **ORDER BY**: Sort columns. `ORDER BY created_at DESC` → index on created_at (or composite).
- **GROUP BY**: Sometimes. If grouping is selective, index helps. Often Hash Aggregate is fine without.

### When NOT to Index

- **Small tables**: Seq scan is fast. Index overhead not worth it. Rule of thumb: < 1000 rows.
- **Low cardinality**: Column with 3 values (e.g., status: pending/active/done). Index rarely helps; planner may prefer seq scan.
- **Write-heavy**: Every INSERT/UPDATE/DELETE updates indexes. More indexes = slower writes.
- **Rarely queried**: Index that's never used wastes space and write cost. Remove (pg_stat_user_indexes).

### Index Types (PostgreSQL)

| Type | Use Case |
|------|----------|
| **B-tree** | Default. Equality, range, ORDER BY. General purpose. |
| **Hash** | Equality only. B-tree usually preferred. |
| **GIN** | JSONB, arrays, full-text. Multiple values per row. |
| **GiST** | Geometric, full-text, range types. |
| **BRIN** | Block range. Large tables with natural order (e.g., created_at). Tiny index. |

### Composite Index Order

- **Left-prefix**: (a, b, c) supports queries on (a), (a, b), (a, b, c). Not (b) or (c) alone.
- **Equality first, range last**: `WHERE a = 1 AND b = 2 AND c > 3` → (a, b, c). Range on c can use index.
- **Most selective first**: For equality-only, put column that filters most rows first. Depends on data distribution.

### EXPLAIN and EXPLAIN ANALYZE

**EXPLAIN**: Shows planned execution. No execution. Cost estimates only.

**EXPLAIN (ANALYZE, BUFFERS)**: Executes query. Shows actual rows, time, buffer hits/reads. Use for tuning.

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 123;
```

**Key metrics**: Seq Scan vs Index Scan; rows estimate vs actual; Buffers: shared hit (cache) vs read (disk); Time per node.

### Index Maintenance

- **VACUUM**: Reclaims dead tuple space. Frees pages for reuse. Doesn't shrink file (usually).
- **ANALYZE**: Updates statistics. Planner uses for cost estimates. Run after bulk load.
- **REINDEX**: Rebuilds index. For corruption or severe bloat.
- **Index bloat**: Updates/deletes leave dead entries. Index grows. VACUUM doesn't fully reclaim. REINDEX or pg_repack.

---

## 2. Why This Matters in Production

### Real-World System Example

Orders table: 10M rows. Query: "orders for customer 123." Without index: seq scan, 30s. Index on customer_id: index scan, 0.5s. Add index. Verify with EXPLAIN ANALYZE.

### Scalability Impact

- **Missing index**: O(n) per query. Grows with table size.
- **Wrong composite order**: Index not used. Query slow. Match index to query shape.

### Performance Impact

- **Seq Scan on large table**: Full read. Acceptable for small tables or when returning most rows. For selective filter, index is essential.
- **Buffers read**: High disk I/O. Increase shared_buffers or optimize query to reduce work.

### Data Integrity Implications

- **Statistics stale**: ANALYZE not run. Planner chooses bad plan. Schedule ANALYZE (autovacuum does it, but bulk load may need manual).

---

## 3. PostgreSQL Implementation

### Add Index

```sql
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_customer_created ON orders(customer_id, created_at);
```

### GIN for JSONB

```sql
CREATE INDEX idx_events_payload ON events USING GIN (payload);
```

### Expression Index

```sql
CREATE INDEX idx_orders_status_lower ON orders(LOWER(status));
CREATE INDEX idx_events_page ON events ((payload->>'page'));
```

### EXPLAIN ANALYZE

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE customer_id = 123 ORDER BY created_at DESC LIMIT 10;
```

### Maintenance

```sql
VACUUM ANALYZE orders;
REINDEX TABLE orders;
```

### Find Unused Indexes

```sql
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%_pkey';
```

---

## 4. Common Developer Mistakes

### Mistake 1: Indexing Every Column

Each index costs writes. Index only columns used in WHERE, JOIN, ORDER BY. Remove unused.

### Mistake 2: Wrong Composite Order

(a, b, c) doesn't help WHERE b = 1. Put equality columns first, range last.

### Mistake 3: No ANALYZE After Bulk Load

Statistics stale. Planner chooses seq scan. Run ANALYZE.

### Mistake 4: Assuming Index Always Helps

Low cardinality, small table, or "return most rows" — seq scan may be correct. Verify with EXPLAIN.

### Mistake 5: CREATE INDEX Without CONCURRENTLY in Production

Locks table. Use CREATE INDEX CONCURRENTLY. Takes longer but doesn't block.

---

## 5. Interview Deep-Dive Section

**Q: When would you add an index?**  
A: Columns in WHERE, JOIN, ORDER BY. When profiling shows Seq Scan on large table and filter is selective.

**Q: When would you NOT add an index?**  
A: Small tables, low cardinality, write-heavy, rarely queried columns.

**Q: What is index bloat?**  
A: Index grows from updates/deletes; dead entries not reclaimed. VACUUM helps; REINDEX rebuilds. Monitor with pg_stat_user_indexes.

**Q: How do you debug a slow query?**  
A: EXPLAIN (ANALYZE, BUFFERS). Look for Seq Scan on large table, high cost nodes, bad row estimates. Add index, rewrite query, or increase work_mem.

---

## 6. Advanced Engineering Notes

### Plan Node Types

| Node | Meaning |
|------|---------|
| Seq Scan | Full table scan |
| Index Scan | Index to find rows; fetch from table |
| Index Only Scan | Query satisfied from index. Best. |
| Bitmap Index Scan | Build bitmap; fetch in batch |
| Nested Loop | Small inner; index on join column |
| Hash Join | Equality join; larger tables |
| Merge Join | Sorted; merge |

### work_mem

In-memory sort/hash. Too low = disk spill. Too high = memory pressure. Per-operation. Increase for complex sorts/joins.

---

## 7. Mini Practical Exercise

1. Create table with 100K rows. Query without index. EXPLAIN ANALYZE. Note Seq Scan.
2. Add index. EXPLAIN ANALYZE again. Note Index Scan, time reduction.
3. Add composite index. Query with two columns. Verify index use.
4. Find unused indexes. Consider dropping.

---

## 8. Summary in 10 Bullet Points

1. **Index**: Speeds up WHERE, JOIN, ORDER BY. B-tree default. Cost: writes.
2. **When to add**: Selective filter on large table. FK columns. ORDER BY columns.
3. **When not**: Small table, low cardinality, write-heavy, unused.
4. **Composite order**: Equality first, range last. Left-prefix rule.
5. **EXPLAIN ANALYZE**: Execute and show plan. Actual rows, time, buffers.
6. **Seq Scan**: OK for small or unselective. Bad for large + selective.
7. **VACUUM ANALYZE**: Reclaim space, update stats. Run after bulk load.
8. **REINDEX**: Rebuild index. For bloat, corruption.
9. **CONCURRENTLY**: Create index without blocking. Use in production.
10. **Unused indexes**: pg_stat_user_indexes.idx_scan = 0. Consider drop.
