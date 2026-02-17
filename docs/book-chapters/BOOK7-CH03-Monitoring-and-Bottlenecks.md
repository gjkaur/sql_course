# BOOK 7 – Chapter 3: Monitoring and Bottlenecks

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Tuning Loop

1. **Identify**: Find slow queries, lock waits, connection exhaustion.
2. **Analyze**: EXPLAIN, pg_stat_*, logs.
3. **Fix**: Add index, rewrite query, shorten transaction, add pool.
4. **Verify**: Re-measure. Confirm improvement.

### Key Monitoring Views

**pg_stat_activity**: Current connections. State (active, idle), current query, query_start, wait_event. Essential for real-time troubleshooting.

**pg_stat_statements**: Query execution statistics. Requires extension. Total time, calls, mean time. Find slowest queries.

**pg_stat_user_tables**: Table access. seq_scan, idx_scan, n_tup_ins/upd/del. Find tables with high seq scan.

**pg_stat_user_indexes**: Index usage. idx_scan. Find unused indexes (idx_scan = 0).

### Common Bottlenecks

1. **Slow queries**: Missing index, bad plan, large result set. Fix: index, rewrite, limit.
2. **Lock contention**: Long transactions, many updates to same rows. Fix: shorten transactions, lock_timeout, consistent lock order.
3. **Connection exhaustion**: Too many connections. Fix: pooling, reduce per-app connections.
4. **CPU**: Long-running queries, missing indexes (seq scans). Fix: optimize queries, add indexes.
5. **I/O**: High buffer read. Fix: increase shared_buffers, optimize query to reduce work.
6. **Bloat**: Dead tuples, index bloat. Fix: VACUUM, REINDEX, autovacuum tuning.

### Slow Query Log

```ini
log_min_duration_statement = 1000
```

Logs queries taking > 1000ms. Adjust for your SLA. Use to identify candidates for optimization.

### Lock Detection

```sql
SELECT pid, usename, state, query, wait_event_type, wait_event
FROM pg_stat_activity
WHERE wait_event_type = 'Lock';
```

Blocked sessions. Find blocker: `pg_blocking_pids(pid)`.

---

## 2. Why This Matters in Production

### Real-World System Example

Dashboard slow. pg_stat_statements: one query 80% of total time. EXPLAIN: seq scan on 10M rows. Add index. Query drops from 5s to 50ms. Total load drops.

### Scalability Impact

- **Lock contention**: Cascading waits. One long transaction blocks many. Shorten transactions.
- **Connection exhaustion**: All connections used. New requests fail. Pool or increase (with care).

### Performance Impact

- **Unused indexes**: Wasted writes. Drop. Monitor idx_scan.
- **Stale statistics**: Bad plans. ANALYZE. Autovacuum handles; bulk load may need manual.

### Data Integrity Implications

- **Long transactions**: Hold snapshots. Prevent VACUUM from reclaiming. Keep short.
- **Bloat**: Table/index grows. Queries slower. VACUUM regularly.

---

## 3. PostgreSQL Implementation

### Find Slow Queries

```sql
-- Requires pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Current Activity

```sql
SELECT pid, usename, state, query, query_start, wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;
```

### Tables with High Seq Scan

```sql
SELECT relname, seq_scan, idx_scan, n_live_tup
FROM pg_stat_user_tables
WHERE seq_scan > 1000
ORDER BY seq_scan DESC;
```

### Unused Indexes

```sql
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexrelname NOT LIKE '%_pkey';
```

### Lock Waits

```sql
SELECT blocked.pid AS blocked_pid,
       blocking.pid AS blocking_pid,
       blocked.query AS blocked_query,
       blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks ON blocked.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocked_locks.locktype = blocking_locks.locktype
  AND blocked_locks.database = blocking_locks.database
  AND blocked_locks.relation = blocking_locks.relation
  AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.granted;
```

### Connection Count

```sql
SELECT count(*) FROM pg_stat_activity;
-- Compare to: SHOW max_connections;
```

### Slow Query Log Config

```ini
# postgresql.conf
log_min_duration_statement = 1000
log_statement = 'none'
```

---

## 4. Common Developer Mistakes

### Mistake 1: Not Installing pg_stat_statements

Missing extension. Can't find slow queries. Install and enable.

### Mistake 2: Ignoring Lock Waits

Sessions blocked. Users see hangs. Check pg_stat_activity for wait_event_type = 'Lock'.

### Mistake 3: Dropping "Unused" Index That Supports FK

Unique index on FK may show idx_scan = 0 for direct queries but used for constraint. Verify before drop.

### Mistake 4: No Slow Query Log

Blind to slow queries. Enable log_min_duration_statement. Adjust threshold.

### Mistake 5: VACUUM Never Run

Autovacuum may be insufficient for heavy write tables. Monitor n_dead_tup. Tune autovacuum or run manual VACUUM.

---

## 5. Interview Deep-Dive Section

**Q: How do you find the slowest queries?**  
A: pg_stat_statements (total_exec_time, mean_exec_time). Slow query log (log_min_duration_statement).

**Q: What does pg_stat_activity show?**  
A: Current connections, state, current query, query_start, wait_event. Essential for real-time debugging.

**Q: How do you identify unused indexes?**  
A: pg_stat_user_indexes where idx_scan = 0. Consider dropping if never used. Exclude PK, unique constraints.

**Q: What causes lock contention?**  
A: Long transactions, many concurrent updates to same rows. Fix: shorter transactions, lock_timeout, consistent lock order.

**Q: How do you handle connection exhaustion?**  
A: Connection pooling (PgBouncer), increase max_connections (with care; each uses memory), optimize query concurrency.

---

## 6. Advanced Engineering Notes

### pg_stat_statements Reset

```sql
SELECT pg_stat_statements_reset();
```

Reset statistics. Do periodically if tracking trends.

### Replication Lag

```sql
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication;
```

Lag = primary LSN - replay_lsn. Monitor for read replicas.

### Bloat Estimation

pgstattuple extension. Or check n_dead_tup in pg_stat_user_tables. High ratio = need VACUUM.

---

## 7. Mini Practical Exercise

1. Enable pg_stat_statements. Run workload. Query top 5 slowest. Pick one, EXPLAIN ANALYZE.
2. Simulate lock: Session 1 BEGIN; UPDATE row. Session 2 UPDATE same row. Query pg_stat_activity for wait.
3. Check connection count. Compare to max_connections.
4. Find tables with high n_dead_tup. Run VACUUM ANALYZE.

---

## 8. Summary in 10 Bullet Points

1. **pg_stat_activity**: Current connections, queries, wait events. Real-time.
2. **pg_stat_statements**: Query stats. Total/mean time. Find slowest.
3. **pg_stat_user_tables**: seq_scan, idx_scan, n_dead_tup. Find seq scan heavy, bloat.
4. **pg_stat_user_indexes**: idx_scan. Find unused indexes.
5. **Slow query log**: log_min_duration_statement. Log queries over threshold.
6. **Lock contention**: wait_event_type = 'Lock'. Shorten transactions, lock_timeout.
7. **Connection exhaustion**: Count vs max_connections. Pool, reduce concurrency.
8. **Bloat**: n_dead_tup high. VACUUM. Tune autovacuum.
9. **Tuning loop**: Identify → Analyze → Fix → Verify.
10. **pg_stat_statements**: Requires extension. Essential for query tuning.
