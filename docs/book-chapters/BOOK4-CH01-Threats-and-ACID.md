# BOOK 4 – Chapter 1: Threats to Data and ACID

---

## 1. Core Concept Explanation (Deep Technical Version)

### Threats to Data Integrity

Data can be lost, corrupted, or exposed through multiple channels:

**Hardware failures**: Disk failure, power loss, memory corruption, network partition. Data on failed disk is lost. In-flight writes may be partially written. Power loss during commit can leave database in inconsistent state.

**User errors**: Accidental DELETE without WHERE, wrong UPDATE, DROP TABLE. Human mistakes. No hardware fault—the system did what was asked.

**Software bugs**: Application logic errors, race conditions, incorrect transaction boundaries. E.g., debit without credit in transfer.

**Malicious actors**: Unauthorized access, SQL injection, privilege escalation. Security threat.

**Concurrent access**: Two transactions modify same data. Without isolation, one can overwrite the other (lost update), see uncommitted data (dirty read), or get inconsistent snapshots (non-repeatable read, phantom).

### ACID: The Database's Response

**ACID** is the set of properties that make database transactions reliable:

| Property | Meaning | Mechanism |
|----------|---------|-----------|
| **Atomicity** | All or nothing | Undo log; rollback on failure |
| **Consistency** | Constraints hold before and after | Constraints + application invariants |
| **Isolation** | Concurrent transactions don't interfere | Locking, MVCC, snapshots |
| **Durability** | Committed data survives crashes | WAL, fsync, replication |

**Atomicity**: Either all statements in a transaction commit or none do. A failure mid-transaction rolls back everything. No partial commits.

**Consistency**: Database constraints (NOT NULL, FK, CHECK, UNIQUE) are enforced. Transaction moves from one valid state to another. "Consistency" in ACID is not the same as "eventual consistency" in distributed systems—it means constraint preservation.

**Isolation**: Concurrent transactions are isolated—each sees a consistent view. The degree of isolation is configurable (isolation levels).

**Durability**: Once committed, data is permanent. Survives power loss, crash. Implemented via Write-Ahead Logging (WAL): changes written to log before data files; log is fsync'd. On crash, replay log to recover.

### Isolation Levels

| Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|-------|------------|---------------------|--------------|
| Read Uncommitted | No* | Yes | Yes |
| Read Committed | No | Yes | Yes |
| Repeatable Read | No | No | No** |
| Serializable | No | No | No |

*PostgreSQL maps Read Uncommitted to Read Committed.
**PostgreSQL's Repeatable Read prevents phantoms via snapshot isolation.

**Read Committed** (PostgreSQL default): Each statement sees a snapshot of data committed before the statement started. Another transaction can commit between your statements → non-repeatable read. Two SELECTs of same row can return different values.

**Repeatable Read**: Transaction sees snapshot from first query. No non-repeatable reads. Use for reports that must be consistent across multiple queries.

**Serializable**: Strictest. Transactions execute as if serial. May abort with "could not serialize access" when conflict detected. Use for financial operations; implement retry.

### Backup and Recovery

**Logical backup** (pg_dump): Exports schema and data as SQL or custom format. Portable. Restore to different PostgreSQL version. Not point-in-time—snapshot at dump time.

**Physical backup** (pg_basebackup): Copy of data directory. For PITR (point-in-time recovery). Requires WAL archiving.

**WAL archiving**: Continuous backup of transaction log. Enables recovery to any point in time. RPO (Recovery Point Objective) = time since last WAL archive.

---

## 2. Why This Matters in Production

### Real-World System Example

E-commerce: Payment transfer must be atomic (debit + credit together). Isolation prevents two concurrent transfers from corrupting balance. Durability ensures committed payment survives crash. Backup + WAL enables recovery from accidental DELETE or disk failure.

### Scalability Impact

- **Isolation vs performance**: Stricter isolation (Serializable) can cause more aborts and retries. Read Committed allows more concurrency.
- **WAL archiving**: Adds I/O. Tune checkpoint, WAL segment size. Replication also uses WAL.

### Performance Impact

- **Long transactions**: Hold snapshots, prevent VACUUM from reclaiming dead tuples. Keep transactions short.
- **fsync**: Durability requires fsync. Can disable for testing (unsafe); never in production.

### Data Integrity Implications

- **Lost update**: Two transactions read balance=100, both write 90 and 80. One overwrites the other. Use SELECT FOR UPDATE or Serializable.
- **Dirty read**: Reading uncommitted data. PostgreSQL prevents at all levels. Other DBMSs (e.g., Read Uncommitted) may allow.

### Production Failure Scenario

**Case: Accidental DELETE.** Developer ran `DELETE FROM orders` without WHERE. 50K rows gone. No backup. Lesson: Always backup before bulk operations. Use transactions: BEGIN; DELETE ... WHERE ...; verify row count; COMMIT or ROLLBACK. Consider soft delete.

---

## 3. PostgreSQL Implementation

### Setting Isolation Level

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts WHERE id = 1;
-- Snapshot frozen; other commits invisible
COMMIT;
```

### Read Committed (Default) Behavior

```sql
-- Session 1
BEGIN;
UPDATE accounts SET balance = 90 WHERE id = 1;

-- Session 2 (concurrent)
BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- Blocks until Session 1 commits or rolls back
-- After Session 1 commits: sees 90 (no dirty read)
```

### Repeatable Read

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE id = 1;  -- 100
-- Session 2 commits UPDATE to 90
SELECT balance FROM accounts WHERE id = 1;  -- Still 100 (same snapshot)
COMMIT;
```

### Backup (pg_dump)

```bash
# Full database, custom format
pg_dump -h localhost -U app -d mydb -F c -f backup.dump

# Schema only
pg_dump -s -f schema.sql mydb

# Restore
pg_restore -d mydb_new -F c backup.dump
```

---

## 4. Common Developer Mistakes

### Mistake 1: Long-Running Transactions

Holding transaction open during external API call or user input. Blocks VACUUM, holds locks. Shorten: do DB work, COMMIT, then external call.

### Mistake 2: Assuming Read Committed Prevents Lost Updates

Two transactions read same row, both update. Last write wins; first update lost. Use SELECT FOR UPDATE or Serializable.

### Mistake 3: No Backup Before Bulk Operations

DELETE, UPDATE, TRUNCATE without backup. One mistake = data loss. Backup first; test restore.

### Mistake 4: Disabling fsync for "Performance"

Dangerous. Crash = data loss. Never in production.

### Mistake 5: Ignoring Isolation Level for Financial Logic

Read Committed allows non-repeatable read. Balance check and debit in separate statements can race. Use Repeatable Read or Serializable for money.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What does ACID mean?**  
A: Atomicity (all or nothing), Consistency (constraints hold), Isolation (concurrent transactions don't interfere), Durability (committed data survives crash).

**Q: What is a dirty read?**  
A: Reading uncommitted data from another transaction. PostgreSQL prevents at all isolation levels.

**Q: What is a non-repeatable read?**  
A: Same query in same transaction returns different result because another transaction committed. Read Committed allows it; Repeatable Read prevents it.

**Q: What isolation level for financial transfer?**  
A: Serializable or Repeatable Read with SELECT FOR UPDATE. Read Committed can allow lost updates.

### Scenario-Based Questions

**Q: How do you recover from accidental DELETE?**  
A: Restore from backup. If WAL archiving, PITR to moment before DELETE. Prevention: backup before bulk ops; use transactions; soft delete.

**Q: Why does PostgreSQL map Read Uncommitted to Read Committed?**  
A: Read Uncommitted (dirty reads) has little practical use and complicates implementation. PostgreSQL never returns uncommitted data.

---

## 6. Advanced Engineering Notes

### MVCC (Multi-Version Concurrency Control)

PostgreSQL uses MVCC: each transaction sees a snapshot. No readers block writers; writers don't block readers (for most cases). Versions stored until no longer needed; VACUUM reclaims.

### WAL and Durability

Every change written to WAL first. On commit, WAL record fsync'd. On crash, replay WAL to recover. full_page_writes prevents partial page writes from corrupting recovery.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Open two sessions. Session 1: BEGIN; UPDATE a row. Session 2: SELECT same row. Observe block. Session 1: COMMIT. Session 2: see new value.
2. Repeatable Read: Session 1: BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; SELECT. Session 2: UPDATE and COMMIT. Session 1: SELECT again—same as first.
3. Run pg_dump. Inspect output. Restore to new database.

---

## 8. Summary in 10 Bullet Points

1. **Threats**: Hardware failure, user error, bugs, malice, concurrent access.
2. **ACID**: Atomicity, Consistency, Isolation, Durability. Foundation of reliable transactions.
3. **Atomicity**: All or nothing. Rollback on failure.
4. **Durability**: WAL, fsync. Committed data survives crash.
5. **Read Committed**: Default. Each statement sees committed snapshot. Non-repeatable read possible.
6. **Repeatable Read**: Snapshot from first query. No non-repeatable read.
7. **Serializable**: Strictest. May abort. Use for financial logic; retry.
8. **Backup**: pg_dump (logical), pg_basebackup (physical). Test restore.
9. **WAL archiving**: Enables PITR. RPO = time since last archive.
10. **Short transactions**: Avoid long-held snapshots and locks. Call external APIs after COMMIT.
