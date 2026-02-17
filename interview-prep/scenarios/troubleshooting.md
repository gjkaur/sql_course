# Troubleshooting Scenarios

## Scenario 1: Slow Report Query

**Symptom**: Monthly sales report takes 30 seconds.

**Steps**:
1. Run EXPLAIN (ANALYZE, BUFFERS) on the query
2. Look for Seq Scan on large tables
3. Add indexes on filter/join columns (e.g., order_date, status)
4. Run ANALYZE
5. Re-run EXPLAIN; verify Index Scan and reduced time

## Scenario 2: Deadlocks in Checkout

**Symptom**: Random "deadlock detected" errors during checkout.

**Steps**:
1. Identify tables involved (orders, order_items, inventory)
2. Ensure consistent lock order: e.g., always lock inventory before order_items
3. Shorten transaction: do minimal work between BEGIN and COMMIT
4. Add lock_timeout to fail fast
5. Implement retry logic for deadlock errors

## Scenario 3: Connection Exhaustion

**Symptom**: "too many connections" errors under load.

**Steps**:
1. Check max_connections: `SHOW max_connections`
2. Check current: `SELECT count(*) FROM pg_stat_activity`
3. Add connection pooling (PgBouncer or app-level)
4. Reduce connection hold time; ensure connections are returned to pool
5. Consider read replicas for reporting

## Scenario 4: High CPU

**Symptom**: Database CPU at 100%.

**Steps**:
1. pg_stat_activity: identify long-running queries
2. pg_stat_statements: find queries with high total_exec_time
3. EXPLAIN slow queries; add indexes or rewrite
4. Check for missing indexes (seq scans)
5. Consider query caching for repeated reads
