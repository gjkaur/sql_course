# BOOK 5 – Chapter 6: Connection Pooling

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Connection Problem

Each database connection has **overhead**:
- TCP handshake
- SSL negotiation (if used)
- Authentication
- Session setup (PostgreSQL: ~10MB memory per connection)

**Connection per request**: Open connection, execute query, close. Under load, thousands of connections attempted. PostgreSQL has **max_connections** (default 100). Exhaustion = connection refused. Even before limit, connection setup adds latency (e.g., 5–20ms per request).

### Connection Pooling

A **connection pool** maintains a set of open connections. Application **checks out** a connection, uses it, **returns** it to the pool. Connection is reused. No new TCP/auth for each request.

**Pool size**: Fixed or dynamic. Typically 10–50 for an app instance. Total connections = instances × pool size. Must stay under max_connections (leave room for admin, replication, other apps).

### Pool Modes

- **Session pooling**: Connection held for entire session. When app returns connection, it's reset (DISCARD ALL) and reused. Good for request-response.
- **Transaction pooling**: Connection held only for transaction. When app commits/rollback, connection returned. More connections can be multiplexed. PgBouncer supports this.
- **Statement pooling**: Connection held per statement. Rare. Most aggressive multiplexing.

### Sizing Guidelines

- **Rule of thumb (CPU-bound)**: `pool_size = (core_count * 2) + disk_count`. Oversimplified; measure.
- **I/O-bound**: More connections can help (waiting on disk). But too many = context switching.

**Monitor**: `pg_stat_activity` — active connections. `max_connections` — limit. Size pool so `app_instances * pool_size < max_connections - reserve`.

### Connection Lifecycle

1. App requests connection from pool.
2. Pool returns idle connection or creates new (if under limit).
3. App executes queries, commits/rolls back.
4. App returns connection to pool.
5. Pool marks idle. Reuses for next request.

**Connection health**: Stale connections (server restarted, network blip) can fail. Use `pool_pre_ping` (SQLAlchemy) or periodic health check to validate before use.

---

## 2. Why This Matters in Production

### Real-World System Example

FastAPI app: 10 instances. Each with pool size 10. Total 100 connections. PostgreSQL max_connections=100. At peak, all connections used. New requests wait or fail. Fix: Add PgBouncer (external pooler). App connects to PgBouncer; PgBouncer maintains 100 connections to PostgreSQL, multiplexes thousands of client connections.

### Scalability Impact

- **Without pool**: 1000 concurrent requests = 1000 connection attempts. Exhaustion. Failures.
- **With pool**: 1000 requests share 50 connections. Queue at pool; but connections reused. Throughput higher.

### Performance Impact

- **Connection setup**: 5–20ms. Pool eliminates for reused connections. Latency reduction.
- **Memory**: Each connection ~10MB. 100 connections = 1GB. Pool limits total.

### Data Integrity Implications

- **Transaction scope**: Returning connection to pool with open transaction = next request gets dirty connection. Always commit/rollback before return.
- **Session state**: Connection has session variables, prepared statements. Pool reset (DISCARD ALL) clears. Or use transaction pooling.

---

## 3. PostgreSQL Implementation

### Python (psycopg2)

```python
from psycopg2 import pool

pool = pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=20,
    host='localhost',
    dbname='mydb',
    user='app',
    password='secret'
)

conn = pool.getconn()
try:
    cur = conn.cursor()
    cur.execute("SELECT 1")
    conn.commit()
finally:
    pool.putconn(conn)
```

### SQLAlchemy

```python
from sqlalchemy import create_engine

engine = create_engine(
    'postgresql://app:secret@localhost/mydb',
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True
)

with engine.connect() as conn:
    conn.execute(text("SELECT 1"))
conn.close()  # Returns to pool
```

### PgBouncer (External Pooler)

```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

App connects to PgBouncer (port 6432). PgBouncer connects to PostgreSQL. Multiplexes many clients onto few server connections.

---

## 4. Common Developer Mistakes

### Mistake 1: Pool Size Too Large

50 instances × 20 pool = 1000. max_connections=100. Exhaustion. Size pool: total < max_connections.

### Mistake 2: Not Returning Connection on Exception

Exception before putconn. Connection leaked. Use try/finally or context manager.

### Mistake 3: Holding Connection During Long Operation

Connection checked out during external API call. Pool exhausted. Use connection only for DB work.

### Mistake 4: No pool_pre_ping

Stale connection after server restart. Query fails. Use pre_ping to validate.

### Mistake 5: Transaction Left Open

Return connection with open transaction. Next request sees wrong state. Always commit/rollback.

---

## 5. Interview Deep-Dive Section

**Q: Why use connection pooling?**  
A: Reduce connection overhead, stay within max_connections, improve latency under concurrency.

**Q: How do you size a connection pool?**  
A: Consider max_connections, app instances, and workload. Total connections < max_connections. Rule of thumb: (cores * 2) + disks for CPU-bound. Monitor pg_stat_activity.

**Q: What is PgBouncer?**  
A: External connection pooler. Sits between app and PostgreSQL. Multiplexes many client connections onto fewer server connections. Supports transaction pooling.

---

## 6. Advanced Engineering Notes

### Transaction Pooling Caveats

Connection returned after commit. Session-level features (temp tables, prepared statements) don't persist. Use session pooling if you need session state.

### Connection Pool Exhaustion

When pool is exhausted, request waits or fails. Configure timeout. Consider queue or circuit breaker.

---

## 7. Mini Practical Exercise

1. Create pool (size 5). Spawn 10 threads, each gets connection, sleeps 1s, returns. Observe: only 5 concurrent DB connections.
2. Without pool: 10 threads, each opens new connection. Compare latency.
3. Set pool_size > max_connections. Observe failure.

---

## 8. Summary in 10 Bullet Points

1. **Connection overhead**: TCP, auth, setup. ~10MB per connection.
2. **Pool**: Reuse connections. Check out, use, return.
3. **max_connections**: PostgreSQL limit. Pool total must stay under.
4. **Pool size**: 10–50 per instance. Total = instances × size.
5. **Sizing**: (cores * 2) + disks for CPU-bound. Monitor pg_stat_activity.
6. **pool_pre_ping**: Validate connection before use. Handles stale.
7. **Return on exception**: try/finally putconn. Avoid leak.
8. **PgBouncer**: External pooler. Transaction pooling. Multiplex.
9. **Transaction scope**: Commit/rollback before return. No open transaction.
10. **Reserve**: Leave connections for admin, replication, other apps.
