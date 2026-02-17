# Point-in-Time Recovery (PITR)

## Concept

Restore database to a specific moment in time (e.g., before a bad DELETE).

## Requirements

- Base backup (full backup)
- WAL archive from backup time to target time

## Steps

### 1. Base Backup

```bash
pg_basebackup -h localhost -U sqlcourse -D /path/to/backup -F tar -P
```

### 2. Enable WAL archiving (see WAL_archiving.md)

### 3. Restore

1. Stop PostgreSQL
2. Replace data directory with base backup
3. Create `recovery.signal` in data directory
4. Add to postgresql.conf:

```ini
restore_command = 'cp /path/to/archive/%f %p'
recovery_target_time = '2024-02-15 14:30:00'
```

5. Start PostgreSQL; it replays WAL until target time

### 4. Promote

After recovery, remove `recovery.signal` and restart for normal operation.

## recovery_target options

- `recovery_target_time`: Specific timestamp
- `recovery_target_xid`: Transaction ID
- `recovery_target_name`: Named restore point (created with `pg_create_restore_point`)
