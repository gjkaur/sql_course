# Locking and Deadlocks

## Lock Types

- **Row-level**: Lock specific rows (SELECT FOR UPDATE)
- **Table-level**: Lock entire table
- **Advisory**: Application-controlled locks

## Lock Modes

- **ACCESS SHARE**: SELECT (weakest)
- **ROW SHARE**: SELECT FOR UPDATE
- **ROW EXCLUSIVE**: INSERT, UPDATE, DELETE
- **SHARE**: CREATE INDEX (concurrent)
- **EXCLUSIVE**: DDL (strongest)

## Deadlock

Two transactions wait for each other. Example:
- T1: locks A, waits for B
- T2: locks B, waits for A

PostgreSQL detects and aborts one (victim). Victim gets error: "deadlock detected."

## Avoiding Deadlocks

1. **Lock order**: Always acquire locks in same order (e.g., A before B)
2. **Short transactions**: Release locks quickly
3. **Lock timeout**: `SET lock_timeout = '2s'` to fail fast
4. **Retry**: On deadlock error, retry the transaction

## Interview Insight

**Q: How do you prevent deadlocks?**
A: Consistent lock order across the application. Keep transactions short. Use lock_timeout. Implement retry logic for deadlock errors.
