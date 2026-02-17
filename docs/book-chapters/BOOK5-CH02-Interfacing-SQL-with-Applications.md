# BOOK 5 – Chapter 2: Interfacing SQL with Applications

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Application–Database Boundary

Applications run in a **host language** (Python, Java, Node, Go). Databases speak **SQL**. The **interface** bridges them: connection, statement execution, result retrieval, transaction control.

### Connection

A **connection** is a session between application and DBMS. Established via:
- **Connection string**: host, port, database, user, password.
- **Driver**: Language-specific library (psycopg2, pg, go-pg) that implements the protocol.

PostgreSQL uses a wire protocol. Driver opens TCP socket, performs startup/auth, maintains session. Connection is stateful: transaction state, prepared statements, session variables.

### Statement Execution

1. **Prepare** (optional): Send SQL to server; server parses and plans. Plan cached.
2. **Execute**: Run with parameters. For parameterized query, parameters bound at execute time.
3. **Fetch**: Retrieve result rows. Cursor holds position.

**One-shot**: Prepare + execute + fetch in one call (e.g., `cur.execute` + `fetchall`). **Prepared statement**: Prepare once, execute many times with different parameters. Plan reuse.

### Result Handling

- **Result set**: Rows returned by SELECT. Consumed via fetch (one row, many rows, or iterator).
- **Row count**: For INSERT/UPDATE/DELETE. `cur.rowcount`.
- **Returning**: `INSERT ... RETURNING *` — get inserted row in same round-trip.

### Transaction Control

- **Autocommit**: Each statement is its own transaction. Default in some drivers.
- **Explicit**: BEGIN (or implicit on first statement), COMMIT, ROLLBACK. Application controls boundaries.

**Best practice**: Explicit transactions for multi-statement operations. Commit on success; rollback on error.

---

## 2. Why This Matters in Production

### Real-World System Example

FastAPI app: Connects to PostgreSQL via SQLAlchemy. Each request gets connection from pool. Executes parameterized queries. Commits on success, rolls back on exception. Returns JSON from result rows.

### Scalability Impact

- **Connection limit**: max_connections (default 100). Many app instances × connections each = exhaustion. Use pooling.
- **Prepared statements**: Reduce parse/plan overhead. Reuse for repeated queries.

### Performance Impact

- **Round-trips**: Each execute is a round-trip. Batch operations (multi-row INSERT) reduce trips.
- **N+1**: Loop with query per iteration. Fix: batch query or JOIN.

### Data Integrity Implications

- **Transaction scope**: Too large (long transaction) holds locks. Too small (autocommit per statement) can leave partial state on app crash. Match transaction to logical operation.

---

## 3. PostgreSQL Implementation

### Python (psycopg2)

```python
import psycopg2

conn = psycopg2.connect(
    host='localhost', dbname='mydb',
    user='app', password='secret'
)
conn.autocommit = False  # Explicit transactions

cur = conn.cursor()
cur.execute("SELECT id, name FROM customers WHERE id = %s", (1,))
row = cur.fetchone()

cur.execute("INSERT INTO orders (customer_id, total) VALUES (%s, %s) RETURNING id",
            (1, 99.99))
new_id = cur.fetchone()[0]

conn.commit()
cur.close()
conn.close()
```

### Context Manager (Auto Rollback)

```python
with conn.cursor() as cur:
    cur.execute("INSERT INTO t (x) VALUES (%s)", (1,))
    conn.commit()
# On exception: conn.rollback() implicitly if not committed
```

### Java (JDBC)

```java
try (Connection conn = DriverManager.getConnection(url, user, pass);
     PreparedStatement stmt = conn.prepareStatement("SELECT * FROM customers WHERE id = ?")) {
    stmt.setInt(1, id);
    ResultSet rs = stmt.executeQuery();
    while (rs.next()) {
        String name = rs.getString("name");
    }
    conn.commit();
} catch (SQLException e) {
    conn.rollback();
}
```

### Node (pg)

```javascript
const { Pool } = require('pg');
const pool = new Pool({ connectionString: 'postgresql://...' });

const res = await pool.query('SELECT * FROM customers WHERE id = $1', [id]);
const rows = res.rows;
```

---

## 4. Common Developer Mistakes

### Mistake 1: Not Handling Rollback on Error

Exception leaves transaction open. Next operation may run in failed transaction. Always rollback in except/finally.

### Mistake 2: Autocommit for Multi-Statement

Each statement commits. Crash between two statements = partial state. Use explicit transaction.

### Mistake 3: Not Closing Cursor/Connection

Leak connections. Use context managers or try/finally.

### Mistake 4: Fetching Large Result Set Into Memory

`fetchall()` on 1M rows. OOM. Use `fetchmany` or server-side cursor.

---

## 5. Interview Deep-Dive Section

**Q: How do you handle transaction rollback in application code?**  
A: try/except: on error, conn.rollback(). On success, conn.commit(). Use context managers. Never leave transaction open.

**Q: What is the difference between autocommit and explicit transactions?**  
A: Autocommit: each statement is a transaction. Explicit: BEGIN, multiple statements, COMMIT/ROLLBACK. Use explicit for multi-statement atomic operations.

---

## 6. Advanced Engineering Notes

### RETURNING Clause

`INSERT ... RETURNING *` returns inserted rows. Avoids extra SELECT. Use for generated IDs, defaults.

### Batch Insert

```python
cur.executemany("INSERT INTO t (a, b) VALUES (%s, %s)", [(1,2), (3,4)])
# Or: execute_values for PostgreSQL-specific optimization
```

---

## 7. Mini Practical Exercise

1. Write Python script: connect, BEGIN, INSERT, SELECT, COMMIT.
2. Force error (e.g., duplicate key). Verify ROLLBACK. Check no partial insert.
3. Use RETURNING to get inserted id without second query.

---

## 8. Summary in 10 Bullet Points

1. **Connection**: Session to DB. Connection string + driver.
2. **Execute**: Prepare (optional), execute, fetch. Parameterized for safety.
3. **Transaction**: Explicit BEGIN/COMMIT/ROLLBACK. Rollback on error.
4. **Autocommit**: One statement = one transaction. Avoid for multi-step.
5. **Context managers**: Auto-close, ensure rollback on exception.
6. **RETURNING**: Get inserted/updated rows in same round-trip.
7. **rowcount**: Rows affected by INSERT/UPDATE/DELETE.
8. **Prepared statements**: Plan reuse. Fewer round-trips for repeated query.
9. **Close resources**: Cursor, connection. Use pool or context manager.
10. **Driver-specific**: Placeholders (%s, ?, $1). Connection API varies.
