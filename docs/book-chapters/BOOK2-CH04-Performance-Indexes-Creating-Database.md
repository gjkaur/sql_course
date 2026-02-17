# BOOK 2 – Chapter 4: Performance, Indexes, and Creating a Database

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Integrity–Performance Tension

**Integrity** favors: normalized schema, constraints, consistency, single source of truth. **Performance** favors: fewer JOINs, denormalization, caching, read replicas. These goals can conflict. The engineer's job is to balance them based on workload and requirements.

**Rule of thumb**: Start with integrity. Normalize to 3NF. Add constraints. Then profile. Denormalize or add performance optimizations only when data shows a bottleneck. Premature optimization is as harmful in databases as in code.

### Index Fundamentals

An **index** is a data structure that speeds up lookups. PostgreSQL's default is **B-tree**: sorted structure supporting equality, range, and ORDER BY. Lookup: O(log n) vs O(n) for sequential scan.

**When indexes help**:
- WHERE clause (equality, range)
- JOIN columns
- ORDER BY, GROUP BY (sometimes)
- UNIQUE, PRIMARY KEY (implicit index)

**When indexes hurt**:
- **Write cost**: Every INSERT, UPDATE, DELETE must update indexes. More indexes = slower writes.
- **Storage**: Indexes consume disk. Large tables with many indexes can double storage.
- **Low cardinality**: Column with 3 values (e.g., status: pending/active/done). Index rarely helps; planner may prefer seq scan.
- **Small tables**: Seq scan is fast; index overhead not worth it.

### Composite Indexes and Column Order

**Composite index** (a, b, c): Left-prefix rule. Index supports queries on (a), (a, b), (a, b, c). Does NOT support (b), (c), (b, c) alone—the leftmost column must be in the predicate.

**Column order**:
- **Equality first, range last**: WHERE a = 1 AND b = 2 AND c > 3 → (a, b, c). Range on c can use index.
- **Most selective first**: For equality-only, put the column that filters most rows first. Depends on data distribution.
- **Covering index**: INCLUDE non-key columns so index-only scan can satisfy query without touching table.

### Index Types (PostgreSQL)

| Type | Use Case |
|------|----------|
| **B-tree** | Default. Equality, range, ORDER BY, LIKE 'prefix%' |
| **Hash** | Equality only. Usually B-tree is better. |
| **GIN** | JSONB, arrays, full-text. Multiple values per row. |
| **GiST** | Geometric, full-text, range types. |
| **BRIN** | Block range. Large tables with natural order (e.g., created_at). Small index. |

### Creating a Database: End-to-End

1. **CREATE DATABASE**: Top-level container. In PostgreSQL, each database has its own schemas, tables, users.
2. **CREATE SCHEMA**: Namespace (e.g., `public`, `reporting`). Organize tables.
3. **CREATE TABLE**: DDL from logical design. Constraints, data types.
4. **CREATE INDEX**: After tables exist. Based on query patterns.
5. **GRANT**: Privileges for roles/users.
6. **Migrations**: Version-controlled DDL for evolution.

---

## 2. Why This Matters in Production

### Real-World System Example

Events table: 1M rows. Queries: by user_id, by event_type + date range, aggregations. Index on (user_id) for "events for user X". Composite (event_type, created_at) for "clicks in last 7 days". Covering index (user_id) INCLUDE (created_at) for "latest 10 for user" with ORDER BY created_at DESC. Each index adds ~5–10% write overhead. Four indexes may be acceptable for read-heavy workload.

### Scalability Impact

- **Missing index on FK**: JOIN on customer_id with no index. Seq scan on orders for every customer lookup. At 10M rows, unacceptable.
- **Too many indexes**: 20 indexes on a write-heavy table. Inserts slow; lock contention. Choose indexes based on actual queries.

### Performance Impact

- **Seq Scan on large table**: Full table read. Acceptable for small tables or when returning most rows. For "WHERE id = 123" on 10M rows, index is essential.
- **Index-only scan**: Query satisfied from index. No heap access. Best case. Use INCLUDE for covering.

### Data Integrity Implications

- **Integrity first**: Don't drop constraints for performance without measuring. Often the real issue is missing index, not the constraint.
- **Denormalization**: Adds redundancy. Must maintain consistency. Triggers or ETL. Document.

### Production Failure Scenario

**Case: Index added in panic.** A query was slow. Team added 5 indexes without analyzing. Writes slowed 40%. Replication lag increased. One index helped; four were unused. Lesson: Add indexes one at a time; measure; use pg_stat_user_indexes to find unused indexes.

---

## 3. PostgreSQL Implementation

### Creating Database and Schema

```sql
CREATE DATABASE fleet_repair
  ENCODING 'UTF8'
  LC_COLLATE 'en_US.UTF-8'
  LC_CTYPE 'en_US.UTF-8';

\c fleet_repair

CREATE SCHEMA IF NOT EXISTS app;
SET search_path TO app, public;
```

### Tables with Indexes

```sql
CREATE TABLE events (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Query 1: All events for user_id = 123
CREATE INDEX idx_events_user ON events(user_id);

-- Query 2: Events of type 'click' in last 7 days
CREATE INDEX idx_events_type_created ON events(event_type, created_at);

-- Query 3: Count events per user in January 2024
-- (user_id, created_at) supports GROUP BY user_id with date filter
CREATE INDEX idx_events_user_created ON events(user_id, created_at);

-- Query 4: Latest 10 events for user 123 (covering)
CREATE INDEX idx_events_user_created_covering ON events(user_id, created_at DESC)
  INCLUDE (event_type);
```

### EXPLAIN: Verifying Index Use

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events WHERE user_id = 123 ORDER BY created_at DESC LIMIT 10;

-- Look for: Index Scan using idx_events_user_created_covering
-- Not: Seq Scan on events
```

### Integrity vs Performance: Materialized View

```sql
-- Normalized base; materialized view for reporting
CREATE MATERIALIZED VIEW repair_summary AS
SELECT c.company_name, v.vin, ro.opened_date, ro.status, ro.parts_cost
FROM repair_orders ro
JOIN vehicles v ON ro.vehicle_id = v.id
JOIN customers c ON v.customer_id = c.id;

CREATE UNIQUE INDEX ON repair_summary (company_name, vin, opened_date);
-- REFRESH MATERIALIZED VIEW CONCURRENTLY requires unique index
```

---

## 4. Common Developer Mistakes

### Mistake 1: Indexing Every Column

Each index costs writes. Index only columns used in WHERE, JOIN, ORDER BY. Use pg_stat_user_indexes to find unused indexes.

### Mistake 2: Wrong Composite Index Order

(a, b, c) does not help WHERE b = 1. Put equality columns first, range last. Match query shape.

### Mistake 3: Denormalizing Before Profiling

"JOINs are slow" without data. Often the fix is an index, not denormalization. Measure first.

### Mistake 4: Dropping Constraints for Performance

CHECK and FK have small overhead. Dropping them risks bad data. Find the real bottleneck (usually missing index).

### Mistake 5: No Migration Strategy

Creating tables manually in prod. Use migrations (Flyway, Liquibase, Alembic). Version control for DDL.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: When should you index a column?**  
A: When it appears in WHERE, JOIN, or ORDER BY and the table is large enough that seq scan is slow. FK columns for JOINs. When read benefit outweighs write cost.

**Q: What is a composite index? When is column order important?**  
A: Index on (a, b, c). Left-prefix: (a), (a,b), (a,b,c) can use it; (b) or (c) alone cannot. Put equality columns first, range column last. Most selective first for equality-only.

**Q: What is an index-only scan?**  
A: Query satisfied entirely from index without touching table. Use INCLUDE to add non-key columns to index. Reduces I/O.

### Scenario-Based Questions

**Q: You have events (user_id, event_type, created_at). Query: "clicks in last 7 days." What index?**  
A: (event_type, created_at). Equality on event_type first; range on created_at. Or (created_at, event_type) if most queries filter by date first—depends on data distribution.

**Q: How many indexes is too many?**  
A: No fixed number. Each index costs INSERT/UPDATE/DELETE. For write-heavy tables, fewer (2–5). For read-heavy, more. Monitor write latency and index usage. Remove unused indexes.

**Q: When would you use a materialized view?**  
A: When a complex query (many JOINs, aggregates) runs frequently and can tolerate stale data. Pre-compute; refresh periodically. Trade freshness for speed.

---

## 6. Advanced Engineering Notes

### BRIN for Time-Series

For tables with natural time order (e.g., events by created_at), BRIN stores min/max per block. Tiny index. Good for range scans on time. Not for random lookups.

```sql
CREATE INDEX idx_events_created_brin ON events USING BRIN(created_at);
```

### Partial Indexes

Index a subset of rows. E.g., only active orders.

```sql
CREATE INDEX idx_orders_active ON orders(status) WHERE status = 'active';
```

Smaller index; faster for "active orders" queries.

### Index Bloat

Over time, indexes can bloat (dead tuples). VACUUM reclaims space. REINDEX rebuilds. Monitor pg_stat_user_indexes.idx_scan and pg_stat_user_tables.n_dead_tup.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Create `events` table with 10K rows (use generate_series).
2. Run: `SELECT * FROM events WHERE user_id = 500`. Run EXPLAIN. Note: Seq Scan?
3. Create index on user_id. Run EXPLAIN again. Note: Index Scan?
4. Run: `SELECT * FROM events WHERE event_type = 'click' AND created_at > NOW() - INTERVAL '7 days'`. Add composite index. Verify with EXPLAIN.

### Index Design Task

For `orders` (id, customer_id, status, created_at) with queries:
- Orders by customer
- Pending orders in last 30 days
- Count orders per customer

Propose indexes. Consider: Would one composite index serve multiple queries? What's the write cost?

---

## 8. Summary in 10 Bullet Points

1. **Integrity first**: Normalize, add constraints. Optimize only when profiling shows need.
2. **Index** speeds up WHERE, JOIN, ORDER BY. B-tree is default. Cost: writes, storage.
3. **Composite index** (a,b,c): Left-prefix. Supports (a), (a,b), (a,b,c). Not (b) or (c) alone.
4. **Column order**: Equality first, range last. Most selective first for equality-only.
5. **Covering index**: INCLUDE columns for index-only scan. Avoid heap access.
6. **When not to index**: Small tables, low cardinality, write-heavy, rarely queried columns.
7. **Materialized view**: Pre-compute heavy query. Refresh periodically. Trade freshness for speed.
8. **CREATE DATABASE → SCHEMA → TABLE → INDEX → GRANT**: Standard creation order.
9. **Migrations**: Version DDL. Repeatable deployments. Never ad-hoc ALTER in prod.
10. **Monitor**: pg_stat_user_indexes for usage; remove unused indexes. VACUUM/ANALYZE for statistics.
