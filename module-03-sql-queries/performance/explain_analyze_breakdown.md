# EXPLAIN ANALYZE Breakdown

## Running EXPLAIN

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
```

- **ANALYZE**: Execute query, show actual rows and time
- **BUFFERS**: Show buffer hits/reads (cache vs disk)
- **FORMAT**: TEXT, JSON, YAML

## Plan Node Types

| Node | Meaning |
|------|---------|
| Seq Scan | Full table scan. OK for small tables. |
| Index Scan | Use index to find rows; fetch from table. |
| Index Only Scan | Satisfy query from index only. Best. |
| Bitmap Index Scan | Build bitmap from index; fetch in batch. |
| Nested Loop | For each outer row, scan inner. Good for small inner. |
| Hash Join | Build hash table from inner; probe with outer. |
| Merge Join | Sort both; merge. Good for sorted data. |
| Sort | In-memory or external sort. |
| Aggregate | SUM, COUNT, etc. |
| Limit | Stop after n rows. |

## Key Metrics

- **cost**: Estimated (before ANALYZE) or actual
- **rows**: Rows returned
- **width**: Avg row size in bytes
- **Buffers**: shared hit (cache), read (disk)
- **Time**: ms per node

## What to Look For

1. **Seq Scan on large table**: Add index on filter/join column
2. **High "rows" estimate**: Run ANALYZE
3. **Nested Loop with large inner**: Consider Hash Join (check enable_hashjoin)
4. **Sort with many rows**: Index on ORDER BY columns
5. **Buffers read**: High disk I/O; increase cache or optimize query
