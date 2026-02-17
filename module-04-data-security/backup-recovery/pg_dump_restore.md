# pg_dump and pg_restore

## Backup

### Full database

```bash
pg_dump -h localhost -U sqlcourse -d sqlcourse -F c -f backup.dump
```

- `-F c`: Custom format (compressed, supports parallel restore)
- `-F p`: Plain SQL (human-readable)
- `-F t`: Tar archive

### Schema only

```bash
pg_dump -h localhost -U sqlcourse -d sqlcourse -s -f schema.sql
```

### Data only

```bash
pg_dump -h localhost -U sqlcourse -d sqlcourse -a -f data.sql
```

### Specific tables

```bash
pg_dump -h localhost -U sqlcourse -d sqlcourse -t customers -t orders -f tables.dump
```

## Restore

### Custom format

```bash
pg_restore -h localhost -U sqlcourse -d sqlcourse_new -F c backup.dump
```

### Plain SQL

```bash
psql -h localhost -U sqlcourse -d sqlcourse_new -f schema.sql
```

### Parallel restore (faster)

```bash
pg_restore -h localhost -U sqlcourse -d sqlcourse_new -j 4 -F c backup.dump
```

## Best Practices

- Backup before major changes
- Test restore periodically
- Store backups off-server
- Use WAL archiving for point-in-time recovery
