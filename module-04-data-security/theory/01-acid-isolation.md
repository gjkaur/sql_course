# ACID and Isolation Levels

## ACID

| Property | Meaning |
|----------|---------|
| **Atomicity** | All or nothing; rollback on failure |
| **Consistency** | Database constraints hold before and after |
| **Isolation** | Concurrent transactions don't see each other's uncommitted changes |
| **Durability** | Committed data survives crashes |

## Isolation Levels (PostgreSQL)

| Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|-------|------------|---------------------|--------------|
| Read Uncommitted | No* | Yes | Yes |
| Read Committed | No | Yes | Yes |
| Repeatable Read | No | No | No** |
| Serializable | No | No | No |

*PostgreSQL maps Read Uncommitted to Read Committed.
**PostgreSQL's Repeatable Read prevents phantoms via snapshot.

## Default: Read Committed

Each statement sees a snapshot of data committed before the statement started. Another transaction can commit between your statements → non-repeatable read.

## Repeatable Read

Transaction sees snapshot from first query. No non-repeatable reads. Use for reports that must be consistent.

## Serializable

Strictest. Serialize concurrent transactions. May abort with "could not serialize access."

## Interview Insight

**Q: What isolation level would you use for a financial transfer?**
A: Serializable or Repeatable Read with careful locking. Read Committed can allow lost updates (two transactions read same balance, both update).
