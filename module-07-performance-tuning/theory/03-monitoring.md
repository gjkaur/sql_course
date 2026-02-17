# PostgreSQL Monitoring

## Key Views

### pg_stat_activity

Current connections and queries.

```sql
SELECT pid, usename, state, query, query_start
FROM pg_stat_activity
WHERE state != 'idle';
```

### pg_stat_statements

Query execution statistics (requires extension).

```sql
SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

### pg_stat_user_tables

Table access stats (seq_scan, idx_scan).

```sql
SELECT relname, seq_scan, idx_scan
FROM pg_stat_user_tables
WHERE seq_scan > 1000;
```

### pg_stat_user_indexes

Index usage.

```sql
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

## Slow Query Log

```ini
log_min_duration_statement = 1000
```

Logs queries taking > 1 second.

## Key Metrics

- Connections: `SELECT count(*) FROM pg_stat_activity`
- Lock waits: `pg_stat_activity` where `wait_event_type = 'Lock'`
- Replication lag (if applicable)
