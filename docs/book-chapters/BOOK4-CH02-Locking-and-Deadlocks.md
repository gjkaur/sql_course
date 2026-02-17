# BOOK 4 – Chapter 2: Locking and Deadlocks

---

## 1. Core Concept Explanation (Deep Technical Version)

### Why Locking?

Concurrent transactions can conflict. Two transactions updating the same row: without coordination, one overwrites the other (lost update). Locking ensures that only one transaction can modify a row at a time, or that readers and writers coordinate appropriately.

PostgreSQL uses **MVCC** (Multi-Version Concurrency Control) for reads—readers don't block writers. But **writes** (INSERT, UPDATE, DELETE) acquire row-level locks. **Explicit locks** (SELECT FOR UPDATE) allow application-controlled locking.

### Lock Granularity

- **Row-level**: Lock specific rows. INSERT, UPDATE, DELETE acquire row locks. SELECT FOR UPDATE locks rows.
- **Page-level**: (Internal) Lock a page of rows.
- **Table-level**: Lock entire table. DDL (ALTER TABLE, TRUNCATE) acquires table locks. CREATE INDEX (non-concurrent) locks table.
- **Advisory locks**: Application-defined. `pg_advisory_lock(id)` — coordinate across sessions without locking rows.

### Lock Modes (PostgreSQL)

| Mode | Acquired By | Conflicts With |
|------|-------------|---------------|
| ACCESS SHARE | SELECT | ACCESS EXCLUSIVE |
| ROW SHARE | SELECT FOR UPDATE, SELECT FOR SHARE | EXCLUSIVE, ACCESS EXCLUSIVE |
| ROW EXCLUSIVE | INSERT, UPDATE, DELETE | SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, ACCESS EXCLUSIVE |
| SHARE | CREATE INDEX (concurrent) | ROW EXCLUSIVE, etc. |
| ACCESS EXCLUSIVE | DROP TABLE, TRUNCATE, VACUUM FULL | All |

**SELECT** takes ACCESS SHARE—doesn't block other SELECTs or most writes. **INSERT/UPDATE/DELETE** take ROW EXCLUSIVE—block other writers on same rows. **SELECT FOR UPDATE** takes ROW SHARE (or stronger)—blocks other SELECT FOR UPDATE and writers.

### Deadlock

**Deadlock**: Two (or more) transactions wait for each other's locks. Circular wait.

Example:
- T1: Locks row A, waits for row B
- T2: Locks row B, waits for row A

Neither can proceed. PostgreSQL **detects** deadlocks (periodic check) and **aborts** one transaction (victim). Victim receives: `ERROR: deadlock detected`.

### Avoiding Deadlocks

1. **Consistent lock order**: Always acquire locks in the same order (e.g., lower ID first). If all transactions lock (A, B) in that order, no circular wait.
2. **Short transactions**: Release locks quickly. Don't hold locks during external calls.
3. **lock_timeout**: `SET lock_timeout = '2s'` — abort if lock not acquired in 2 seconds. Fail fast instead of waiting indefinitely.
4. **Retry logic**: On deadlock error (40P01), retry the transaction. Deadlocks are transient.

### SELECT FOR UPDATE

Explicit row lock. Use when you need to read and then update, preventing others from modifying between read and write.

```sql
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
-- Hold lock; update
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

**SELECT FOR UPDATE SKIP LOCKED**: Skip rows already locked. For job queues: multiple workers can process different rows without blocking.

---

## 2. Why This Matters in Production

### Real-World System Example

Order processing: Worker 1 locks order 100, then inventory item A. Worker 2 locks inventory item A (for different order), then order 100. Deadlock. Fix: Lock in consistent order—always (order_id, then inventory_id). Or lock orders first, then inventory, globally.

### Scalability Impact

- **Lock contention**: Many transactions updating same rows (e.g., popular product inventory). Queue forms. Consider partitioning, sharding, or optimistic concurrency.
- **Table-level locks**: ALTER TABLE, CREATE INDEX (non-concurrent) block all access. Use CREATE INDEX CONCURRENTLY for production.

### Performance Impact

- **Long-held locks**: Transaction holds lock during API call. Others wait. Shorten transaction.
- **lock_timeout**: Prevents indefinite wait. Application can retry or return error to user.

### Data Integrity Implications

- **Lost update without lock**: Two transactions read balance=100, both subtract 10. Result: 90 instead of 80. SELECT FOR UPDATE prevents.
- **Advisory locks**: Coordinate "only one instance runs this job" across app servers. pg_advisory_lock(job_id).

### Production Failure Scenario

**Case: Deadlock in order processing.** Two workers: one locked order then inventory, other locked inventory then order. Deadlocks every few minutes. Fix: Enforced lock order (order_id ASC). Reduced to zero.

---

## 3. PostgreSQL Implementation

### SELECT FOR UPDATE

```sql
BEGIN;
SELECT * FROM orders WHERE id = 123 FOR UPDATE;
-- Update order; other sessions block on same row
UPDATE orders SET status = 'processing' WHERE id = 123;
COMMIT;
```

### SELECT FOR UPDATE SKIP LOCKED (Job Queue)

```sql
-- Worker 1
SELECT * FROM jobs WHERE status = 'pending' FOR UPDATE SKIP LOCKED LIMIT 1;

-- Worker 2: Gets different row (skips locked one)
SELECT * FROM jobs WHERE status = 'pending' FOR UPDATE SKIP LOCKED LIMIT 1;
```

### Lock Timeout

```sql
SET lock_timeout = '2s';
BEGIN;
SELECT * FROM orders WHERE id = 1 FOR UPDATE;
-- If blocked > 2s: ERROR: canceling statement due to lock timeout
```

### Advisory Lock

```sql
SELECT pg_try_advisory_lock(12345);
-- Returns true if acquired, false if another session holds it
-- Use for application-level coordination
SELECT pg_advisory_unlock(12345);
```

### Checking Locks

```sql
SELECT * FROM pg_locks WHERE NOT granted;
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

---

## 4. Common Developer Mistakes

### Mistake 1: Inconsistent Lock Order

Transaction 1: lock A, lock B. Transaction 2: lock B, lock A. Deadlock. Enforce global order.

### Mistake 2: Holding Locks During External Call

BEGIN → SELECT FOR UPDATE → call payment API (5s) → UPDATE → COMMIT. Others block 5s. Move API call after COMMIT or use async.

### Mistake 3: No Retry on Deadlock

Application gets 40P01, shows error to user. Should retry transparently (with backoff).

### Mistake 4: CREATE INDEX Without CONCURRENTLY

CREATE INDEX locks table. Use CREATE INDEX CONCURRENTLY for production—allows reads/writes during build.

### Mistake 5: Forgetting to Commit or Rollback

Transaction holds locks until COMMIT/ROLLBACK. Connection pool may not close connection; next request reuses it with open transaction. Always terminate transactions.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is a deadlock?**  
A: Two transactions waiting for each other's locks. Circular wait. DB detects and aborts one (victim).

**Q: How do you prevent deadlocks?**  
A: Consistent lock order across all transactions. Short transactions. lock_timeout. Retry on deadlock error.

**Q: What is lock_timeout?**  
A: Abort if lock cannot be acquired within specified time. Prevents indefinite wait. SET lock_timeout = '2s'.

### Scenario-Based Questions

**Q: When would you use SELECT FOR UPDATE SKIP LOCKED?**  
A: Job queue. Multiple workers fetch "next job." SKIP LOCKED lets each get a different row without blocking. Avoids thundering herd.

**Q: How do you implement "only one instance runs job X"?**  
A: Advisory lock: pg_try_advisory_lock(job_id). If true, run job; unlock when done. If false, another instance has it.

---

## 6. Advanced Engineering Notes

### Lock Escalation

PostgreSQL doesn't escalate row locks to table locks. Each row lock is independent. Some DBMSs escalate when too many row locks—PostgreSQL keeps row-level.

### NOWAIT

`SELECT ... FOR UPDATE NOWAIT` — fail immediately if row is locked. No waiting. Alternative to lock_timeout for single statement.

### Deadlock Detection

PostgreSQL checks for deadlocks when a transaction waits for a lock. Detection is O(n) in number of wait edges. Rare deadlocks are cheap; frequent deadlocks add overhead.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Two sessions. Session 1: BEGIN; SELECT * FROM t WHERE id=1 FOR UPDATE. Session 2: SELECT * FROM t WHERE id=1 FOR UPDATE. Observe block. Session 1: COMMIT. Session 2: proceeds.
2. Create deadlock: Session 1 lock row 1, Session 2 lock row 2; Session 1 try lock row 2, Session 2 try lock row 1. Observe abort.
3. Use lock_timeout. Set 1s. Try to lock row held by other session. Observe timeout.

---

## 8. Summary in 10 Bullet Points

1. **Locking**: Coordinates concurrent access. Row-level for DML; table-level for DDL.
2. **SELECT FOR UPDATE**: Explicit row lock. Read-modify-write without lost update.
3. **SELECT FOR UPDATE SKIP LOCKED**: Skip locked rows. For job queues.
4. **Deadlock**: Circular wait. T1 waits for T2, T2 waits for T1.
5. **Deadlock resolution**: DB aborts victim. Error 40P01.
6. **Prevention**: Consistent lock order. Short transactions. lock_timeout.
7. **Retry**: On deadlock, retry transaction. Transient error.
8. **Advisory locks**: Application-level. pg_advisory_lock. For coordination.
9. **CREATE INDEX CONCURRENTLY**: Doesn't block writes. Use in production.
10. **Hold locks briefly**: No external calls inside locked transaction.
