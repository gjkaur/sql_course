# Major Components of SQL

## DDL — Data Definition Language

Defines and alters database structure.

| Statement | Purpose |
|-----------|---------|
| CREATE | Tables, indexes, views, schemas |
| ALTER | Modify existing objects |
| DROP | Remove objects |
| TRUNCATE | Remove all rows, keep structure |

**Idempotency**: Use `CREATE TABLE IF NOT EXISTS` or migrations for repeatable setups.

## DML — Data Manipulation Language

Operates on data within tables.

| Statement | Purpose |
|-----------|---------|
| SELECT | Query data |
| INSERT | Add rows |
| UPDATE | Modify rows |
| DELETE | Remove rows |
| MERGE | Upsert (INSERT or UPDATE) |

**Note**: SELECT is often called DQL (Data Query Language) but grouped with DML.

## DCL — Data Control Language

Manages security and access.

| Statement | Purpose |
|-----------|---------|
| GRANT | Give privileges to users/roles |
| REVOKE | Remove privileges |
| (Implicit) | Roles, ownership |

## Execution Order (SELECT)

```
FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
```

Understanding this order explains why you can't use column aliases in WHERE (they're defined in SELECT, which runs later).

## Interview Insight

**Q: What's the difference between DELETE and TRUNCATE?**

A: DELETE removes rows one by one, fires triggers, can have WHERE, is transactional. TRUNCATE drops and recreates the table structure, is faster, resets sequences, doesn't fire row-level triggers. Use TRUNCATE for "empty the table" in dev; use DELETE for selective removal in production.
