# Connection Pooling

## Problem

Opening a new connection per request is slow (TCP handshake, auth, etc.). Connection limits can be exhausted under load.

## Solution

Reuse connections from a pool. Application checks out, uses, returns.

## PostgreSQL Limits

- `max_connections` (default 100)
- Each connection uses ~10MB memory
- Pool size should be < max_connections (leave room for admin, replication)

## Pool Sizing

- **Rule of thumb**: `pool_size = (core_count * 2) + disk_count` for CPU-bound
- For I/O-bound: more connections; monitor `pg_stat_activity`
- PgBouncer: external pooler; supports transaction pooling

## Python: psycopg2 Pool

```python
from psycopg2 import pool
pool = pool.ThreadedConnectionPool(1, 20, host='localhost', dbname='sqlcourse', user='sqlcourse', password='...')
conn = pool.getconn()
# use conn
pool.putconn(conn)
```

## SQLAlchemy

```python
engine = create_engine('postgresql://...', pool_size=10, max_overflow=20)
# pool_pre_ping=True to verify connection before use
```

## Interview Insight

**Q: Why use connection pooling?**
A: Reduce connection overhead, stay within max_connections, improve latency under concurrency.
