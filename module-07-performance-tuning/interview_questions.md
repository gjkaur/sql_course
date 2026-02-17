# Module 7: Interview Questions

## Index Tuning

1. **When would you add an index?**
   - Columns in WHERE, JOIN, ORDER BY. When profiling shows Seq Scan on large table.

2. **When would you NOT add an index?**
   - Small tables, low cardinality, write-heavy, rarely queried columns.

3. **What is index bloat?**
   - Index grows from updates/deletes; space not reclaimed. VACUUM, REINDEX.

## Partitioning

4. **When would you partition a table?**
   - Very large table, query pattern filters by partition key (e.g., date), need to drop old data quickly.

5. **What is partition pruning?**
   - Query planner skips partitions that can't contain matching rows.

## Monitoring

6. **How do you find the slowest queries?**
   - pg_stat_statements (total_exec_time, mean_exec_time). Slow query log.

7. **What does pg_stat_activity show?**
   - Current connections, state, current query, query_start.

8. **How do you identify unused indexes?**
   - pg_stat_user_indexes where idx_scan = 0. Consider dropping if never used.

## Bottlenecks

9. **What causes lock contention?**
   - Long transactions, many concurrent updates to same rows. Fix: shorter transactions, lock_timeout.

10. **How do you handle connection exhaustion?**
    - Connection pooling (PgBouncer), increase max_connections (with care), optimize query concurrency.
