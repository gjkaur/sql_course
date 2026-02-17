# BOOK 7 – Chapter 2: Partitioning and Environment

---

## 1. Core Concept Explanation (Deep Technical Version)

### When to Partition

**Partitioning** splits a table into smaller physical pieces (partitions). Use when:

- **Table too large**: VACUUM, backup, index maintenance become slow. Partition = smaller units.
- **Query pattern matches partition key**: `WHERE order_date >= '2024-01-01'` — planner can **prune** to only scan matching partitions.
- **Data lifecycle**: Drop old data by detaching partition. Faster than DELETE. Archival by moving partition.

### Partition Types

- **Range**: By range of values. Date, ID. `FOR VALUES FROM ('2024-01-01') TO ('2024-02-01')`.
- **List**: By discrete values. Region, category. `FOR VALUES IN ('US', 'EU')`.
- **Hash**: Distribute by hash of key. Even spread. No natural ordering.

### Partition Pruning

**Pruning**: Planner excludes partitions that cannot contain matching rows. `WHERE order_date BETWEEN '2024-01-15' AND '2024-01-20'` — only scans orders_2024_01. Other partitions skipped. Requires partition key in WHERE.

### Trade-offs

**Pros**: Smaller partitions, faster scans, easier archival, parallel maintenance.  
**Cons**: More objects (tables), global unique indexes complex, constraint management, partition key must be in PRIMARY KEY.

### PostgreSQL Configuration (Environment)

Key parameters for tuning:

- **shared_buffers**: Memory for cache. 25% of RAM typical. Restart required.
- **work_mem**: Per-operation sort/hash memory. Too low = disk spill. Per query can use multiple work_mem.
- **maintenance_work_mem**: For VACUUM, CREATE INDEX. Larger = faster.
- **effective_cache_size**: Hint for planner. Total RAM available for caching. Doesn't allocate.
- **max_connections**: Connection limit. Each ~10MB. Use pooling.

---

## 2. Why This Matters in Production

### Real-World System Example

Orders: 100M rows. Range partition by month. Query "orders in January 2024" scans only orders_2024_01 (~8M rows). Full table scan would be 100M. Drop 2020 data: DETACH PARTITION. Instant vs DELETE millions.

### Scalability Impact

- **Pruning**: O(partition size) vs O(table size). Critical for time-series.
- **Maintenance**: VACUUM one partition at a time. Less blocking.

### Performance Impact

- **Partition key in query**: Essential for pruning. `WHERE order_date = ...` good. `WHERE customer_id = ...` without order_date — scans all partitions.
- **Default partition**: Catch-all for values not in explicit partitions. Can hurt pruning if many rows.

### Data Integrity Implications

- **PRIMARY KEY**: Must include partition key. (order_date, id) for range on order_date.
- **Unique constraints**: Global unique (e.g., id alone) requires unique index on parent. Complex with partitions.

---

## 3. PostgreSQL Implementation

### Range Partitioning

```sql
CREATE TABLE orders (
  id BIGSERIAL,
  customer_id BIGINT,
  order_date DATE NOT NULL,
  total NUMERIC(10,2),
  PRIMARY KEY (id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_01 PARTITION OF orders
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE orders_2024_02 PARTITION OF orders
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

### List Partitioning

```sql
CREATE TABLE sales (
  id SERIAL,
  region TEXT NOT NULL,
  amount NUMERIC
) PARTITION BY LIST (region);

CREATE TABLE sales_us PARTITION OF sales FOR VALUES IN ('US');
CREATE TABLE sales_eu PARTITION OF sales FOR VALUES IN ('EU', 'UK');
```

### Hash Partitioning

```sql
CREATE TABLE events (
  id BIGSERIAL,
  user_id BIGINT,
  payload JSONB
) PARTITION BY HASH (user_id);

CREATE TABLE events_0 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE events_1 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 1);
-- etc.
```

### Detach and Drop

```sql
ALTER TABLE orders DETACH PARTITION orders_2023_01;
-- Now a standalone table. Archive or drop.
DROP TABLE orders_2023_01;
```

### Key Config Parameters

```ini
# postgresql.conf
shared_buffers = 256MB
work_mem = 64MB
maintenance_work_mem = 256MB
effective_cache_size = 1GB
```

---

## 4. Common Developer Mistakes

### Mistake 1: Partitioning Without Matching Query Pattern

Partition by date but query by customer_id. No pruning. All partitions scanned.

### Mistake 2: Too Many Partitions

Thousands of partitions. Overhead. Planner, DDL, catalog. Keep to hundreds or less.

### Mistake 3: Default Partition with Many Rows

Default partition catches unmapped values. If large, hurts. Use explicit partitions or constrain inserts.

### Mistake 4: Forgetting Partition Key in PK

PRIMARY KEY must include partition key. (id, order_date) for range on order_date.

### Mistake 5: work_mem Too Low

Complex sort spills to disk. Slow. Increase work_mem for heavy queries. Monitor temp file usage.

---

## 5. Interview Deep-Dive Section

**Q: When would you partition a table?**  
A: Very large table, query pattern filters by partition key (e.g., date), need to drop old data quickly. Or when maintenance (VACUUM, backup) is too slow.

**Q: What is partition pruning?**  
A: Planner skips partitions that can't contain matching rows. Requires partition key in WHERE. Critical for performance.

**Q: What is the difference between range and list partitioning?**  
A: Range: continuous values (dates, IDs). List: discrete values (regions, categories). Hash: distribute by hash for even spread.

---

## 6. Advanced Engineering Notes

### Partitioning Existing Table

Create partitioned table, migrate data, swap. Or use pg_partman extension for automated management.

### Subpartitioning

Partition of partition. E.g., range by month, list by region within month. Adds complexity.

### work_mem and temp files

`temp_file_size` in EXPLAIN. Spill = disk. Increase work_mem or optimize query to reduce sort size.

---

## 7. Mini Practical Exercise

1. Create range-partitioned table. Insert data. Query with partition key in WHERE. EXPLAIN — verify pruning.
2. Query without partition key. EXPLAIN — all partitions scanned.
3. DETACH old partition. Verify it's standalone. DROP.
4. Tune work_mem for a heavy sort query. Compare EXPLAIN before/after.

---

## 8. Summary in 10 Bullet Points

1. **Partition**: Split table into smaller pieces. Range, list, hash.
2. **When**: Large table, query filters by key, drop old data fast.
3. **Pruning**: Planner skips irrelevant partitions. Key in WHERE.
4. **Range**: Dates, IDs. **List**: Regions, categories. **Hash**: Even spread.
5. **PK**: Must include partition key.
6. **DETACH**: Remove partition. Becomes standalone. Archive or drop.
7. **shared_buffers**: Cache. 25% RAM. Restart to change.
8. **work_mem**: Sort/hash memory. Low = spill. Per operation.
9. **effective_cache_size**: Planner hint. Not allocation.
10. **Match partition key to query**: No key in WHERE = no pruning.
