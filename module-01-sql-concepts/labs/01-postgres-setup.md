# Lab 1: PostgreSQL Setup

## Objectives

- Run PostgreSQL via Docker
- Connect with `psql`
- Verify basic connectivity

## Prerequisites

- Docker and Docker Compose installed
- Terminal/command line access

## Steps

### 1. Start PostgreSQL

```bash
# From repo root
docker-compose up -d

# Verify container is running
docker ps
```

### 2. Connect with psql

```bash
# From host (if psql is installed)
psql -h localhost -p 5432 -U sqlcourse -d sqlcourse

# Or from inside container
docker exec -it sqlcourse-postgres psql -U sqlcourse -d sqlcourse
```

### 3. Verify Connection

```sql
-- Check version
SELECT version();

-- List databases
\l

-- List extensions
\dx

-- Create a test table
CREATE TABLE test (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO test (name) VALUES ('Hello from SQL');
SELECT * FROM test;
DROP TABLE test;
```

### 4. Optional: pgAdmin

```bash
# Start pgAdmin (includes postgres)
docker-compose --profile tools up -d

# Open http://localhost:5050
# Login: admin@sqlcourse.local / (your PGADMIN_PASSWORD)
# Add server: host=postgres, port=5432, user=sqlcourse
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 5432 in use | Change port in docker-compose: `"5433:5432"` |
| Connection refused | Wait for healthcheck; `docker logs sqlcourse-postgres` |
| Password auth failed | Check `.env` or use default `sqlcourse` |

## Success Criteria

- [ ] `psql` connects successfully
- [ ] `SELECT version()` returns PostgreSQL 16
- [ ] `SELECT 1` returns 1
