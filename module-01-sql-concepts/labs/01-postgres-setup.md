# Lab 1: PostgreSQL Setup

## Objectives

- Run PostgreSQL via Docker
- Connect with `psql`
- Verify basic connectivity

## Prerequisites

- Docker and Docker Compose installed
- Terminal/command line access

## Alternative: Local PostgreSQL (No Docker)

If you have PostgreSQL and pgAdmin installed locally, you can skip Docker:

1. Create a database in pgAdmin (e.g. `sqlcourse`)
2. Open Query Tool and run in order:
   - `module-01-sql-concepts/project/schema.sql`
   - `module-01-sql-concepts/project/constraints.sql`
   - `module-01-sql-concepts/project/seed_data.sql`
3. Connect: Host=`localhost`, Port=`5432`, User=`postgres`, Password=(your local PostgreSQL password)

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
psql -h localhost -p 5432 -U postgres -d postgres

# Or from inside container
docker exec -it sqlcourse-postgres psql -U postgres -d postgres
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

**Option A — Docker pgAdmin:**

```bash
docker-compose --profile tools up -d
# Open http://localhost:5051
# Login: admin@postgres.local / (your PGADMIN_PASSWORD)
# Add server: host=postgres, port=5432, user=postgres, password=postgres
```

**Option B — Local pgAdmin (no Docker):** Use your installed pgAdmin. Connect to localhost:5432 with your local PostgreSQL credentials. Load schema files manually (see "Alternative: Local PostgreSQL" above).

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 5432 in use | Change port in docker-compose: `"5433:5432"` |
| Connection refused | Wait for healthcheck; `docker logs sqlcourse-postgres` |
| Password auth failed | Check `.env` or use default `postgres` |

## Success Criteria

- [ ] `psql` connects successfully
- [ ] `SELECT version()` returns PostgreSQL 16
- [ ] `SELECT 1` returns 1
