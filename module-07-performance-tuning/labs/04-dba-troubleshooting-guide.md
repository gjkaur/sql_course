# DBA Troubleshooting Guide

## Slow Queries

1. **Identify**: pg_stat_statements, slow query log
2. **Analyze**: EXPLAIN (ANALYZE, BUFFERS)
3. **Fix**: Add index, rewrite query, increase work_mem
4. **Verify**: Re-run EXPLAIN, measure

## High CPU

- Check pg_stat_activity for long-running queries
- Check for missing indexes (seq scans)
- Consider connection pooling (PgBouncer)

## Lock Contention

```sql
SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';
```

- Identify blocking queries
- Shorten transactions
- Use lock_timeout

## Connection Exhaustion

```sql
SELECT count(*) FROM pg_stat_activity;
-- Compare to max_connections
```

- Add connection pooling
- Increase max_connections (with care; each uses memory)
- Use PgBouncer in transaction mode

## Bloat

- Run VACUUM ANALYZE regularly
- For large tables: VACUUM (VERBOSE) to see progress
- Consider pg_repack for online bloat removal

## Replication Lag (if applicable)

```sql
SELECT * FROM pg_stat_replication;
```

- Check replay lag
- Add replicas, optimize slow queries on primary
