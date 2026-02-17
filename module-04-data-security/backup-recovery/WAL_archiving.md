# WAL Archiving

## What is WAL?

Write-Ahead Logging: changes are written to WAL before data files. Enables crash recovery and point-in-time recovery (PITR).

## Archiving

WAL segments can be archived to external storage (e.g., S3, NFS) for PITR.

## Configuration

```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /path/to/archive/%f'
```

- `%p`: path of file to archive
- `%f`: filename

## Restore from Archive

1. Restore base backup (pg_basebackup or pg_dump)
2. Create `recovery.signal` in data directory
3. Configure `restore_command` in postgresql.conf to fetch WAL from archive
4. Start PostgreSQL; it replays WAL to reach target time

## When to Use

- RPO (Recovery Point Objective) < 24 hours
- Compliance requirements
- Disaster recovery
