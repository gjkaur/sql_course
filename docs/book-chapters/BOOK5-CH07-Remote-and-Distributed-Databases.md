# BOOK 5 – Chapter 7: Remote and Distributed Databases

---

## 1. Core Concept Explanation (Deep Technical Version)

### Remote Database Access

**Remote** means the database is not on the same machine as the application. Connection over network (TCP). Client connects to host:port. Standard: application connects to any reachable PostgreSQL instance. "Remote" is the default for most deployments.

**Considerations**:
- **Latency**: Network round-trip adds ms. Minimize round-trips (batch, pool, reduce queries).
- **Security**: TLS for encryption. Authentication (password, cert). Firewall.
- **Failover**: Primary fails; replica promoted. Application reconnects.

### Replication

**Replication** copies data from primary to replica(s). Replicas can serve read queries. Offload reporting, analytics. Primary handles writes.

**Streaming replication** (PostgreSQL): WAL shipped to replica. Replica replays. Near real-time. **Synchronous** vs **asynchronous**: Sync waits for replica confirm before commit; async doesn't. Sync = stronger durability, higher latency.

**Read replica**: Application connects to replica for SELECT. Writes go to primary. Eventually consistent (replication lag).

### Foreign Data Wrappers (FDW)

**FDW** allows querying a **remote** database as if it were a local table. PostgreSQL supports postgres_fdw (another PostgreSQL), mysql_fdw, etc.

```sql
CREATE EXTENSION postgres_fdw;
CREATE SERVER remote_db FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'remote-host', dbname 'remote_db');
CREATE USER MAPPING FOR local_user SERVER remote_db
  OPTIONS (user 'remote_user', password '...');
CREATE FOREIGN TABLE remote_customers (
  id INT,
  name TEXT
) SERVER remote_db OPTIONS (schema_name 'public', table_name 'customers');

SELECT * FROM remote_customers;  -- Fetches from remote
```

**Use case**: Cross-database query. Data warehouse pulling from operational DB. Migration. **Limitation**: Fetch can be slow (full table pull). Pushdown: filter/join pushed to remote when possible.

### Distributed Databases

**Distributed** = data spread across multiple nodes. **Sharding**: Partition data by key (e.g., user_id). Each shard is a separate database. Application routes to correct shard.

**Challenges**: Cross-shard joins (expensive), transactions (2PC), consistency. PostgreSQL doesn't have built-in sharding. Use Citus (extension) or application-level sharding.

---

## 2. Why This Matters in Production

### Real-World System Example

E-commerce: Primary in region A. Read replica in region B for low-latency reads. Application: writes to primary, reads from replica (or primary for read-after-write). FDW: analytics DB queries operational DB for reporting. No ETL for some tables.

### Scalability Impact

- **Read replica**: Scale reads horizontally. Add replicas. Writes still single primary.
- **Sharding**: Scale writes. Each shard independent. But operational complexity.

### Performance Impact

- **Replication lag**: Replica may be seconds behind. Read-after-write must use primary.
- **FDW**: Fetch from remote. Can be slow. Use for bulk, not hot path.

### Data Integrity Implications

- **Sync replication**: No data loss if primary fails. Replica has commit. Higher latency.
- **Async**: Possible data loss if primary fails before WAL shipped. Trade-off.

---

## 3. PostgreSQL Implementation

### Connect to Remote (Standard)

```python
# Same as local; just different host
conn = psycopg2.connect(host='db.example.com', port=5432, dbname='mydb', ...)
```

### Read from Replica (Application Logic)

```python
# Config: primary_url, replica_url
# Writes
write_conn = connect(primary_url)

# Reads (can use replica)
read_conn = connect(replica_url) if read_only else connect(primary_url)
```

### postgres_fdw

```sql
CREATE EXTENSION postgres_fdw;

CREATE SERVER remote
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'remote-host', dbname 'remote_db', port '5432');

CREATE USER MAPPING FOR current_user
  SERVER remote
  OPTIONS (user 'remote_user', password 'secret');

CREATE FOREIGN TABLE ft_orders (
  id INT,
  customer_id INT,
  total NUMERIC(10,2)
) SERVER remote OPTIONS (schema_name 'public', table_name 'orders');

-- Query (may pushdown to remote)
SELECT * FROM ft_orders WHERE customer_id = 1;
```

### Import Foreign Schema

```sql
IMPORT FOREIGN SCHEMA public
  FROM SERVER remote
  INTO local_schema;
```

---

## 4. Common Developer Mistakes

### Mistake 1: Read-After-Write from Replica

User creates order, then immediately fetches it. Replica may not have it yet. Use primary for read-after-write.

### Mistake 2: FDW for Hot Path

FDW adds latency. Use for batch, reporting. Not for per-request queries.

### Mistake 3: Assuming Zero Replication Lag

Replica can lag seconds. Design for eventual consistency.

### Mistake 4: Cross-Shard Transactions

Distributed transaction (2PC) is complex. Avoid or use specialized tooling.

---

## 5. Interview Deep-Dive Section

**Q: What is the difference between pg_dump and pg_basebackup?**  
A: pg_dump: logical backup (SQL or custom format). pg_basebackup: physical copy of data directory for PITR, replication setup.

**Q: When would you use WAL archiving?**  
A: For point-in-time recovery; RPO < 24 hours. Or for replication to replica.

**Q: What is postgres_fdw?**  
A: Foreign data wrapper. Query remote PostgreSQL as local table. Use for cross-database query, ETL, migration.

---

## 6. Advanced Engineering Notes

### Citus (Sharding Extension)

Citus extends PostgreSQL for distributed. Transparent sharding. Application uses standard SQL; Citus routes to shards.

### Connection String for Failover

```python
# Multiple hosts; driver tries in order
conn = psycopg2.connect(
    "host=primary,replica1,replica2 hostaddr=... port=5432 dbname=mydb"
)
```

---

## 7. Mini Practical Exercise

1. Set up postgres_fdw to another PostgreSQL instance. Create foreign table. Query.
2. If replica available: configure app to read from replica. Verify lag (SELECT now() on primary vs replica).
3. Document: when to use primary vs replica in your app.

---

## 8. Summary in 10 Bullet Points

1. **Remote**: DB on different host. Standard. Network latency.
2. **Replication**: Primary → replica. WAL streaming. Read scaling.
3. **Sync vs async**: Sync = wait for replica. Stronger durability.
4. **Read replica**: SELECT from replica. Writes to primary.
5. **Replication lag**: Replica behind. Read-after-write use primary.
6. **FDW**: Query remote DB as local table. postgres_fdw.
7. **FDW use**: Cross-DB query, reporting. Not hot path.
8. **Sharding**: Data partitioned. Separate DBs. Application routes.
9. **pg_basebackup**: Physical backup. For PITR, replica setup.
10. **WAL archiving**: Continuous backup. Enables PITR, replication.
