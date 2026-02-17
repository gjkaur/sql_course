# Module 4: Interview Questions

## ACID & Isolation

1. **What does ACID mean?**
   - Atomicity, Consistency, Isolation, Durability.

2. **What is a dirty read?**
   - Reading uncommitted data from another transaction. PostgreSQL prevents it.

3. **What is a non-repeatable read?**
   - Same query in same transaction returns different rows because another transaction committed changes.

4. **What isolation level does PostgreSQL use by default?**
   - Read Committed.

5. **When would you use Serializable?**
   - When you need strict serializability (e.g., financial transactions) and can handle aborts/retries.

## Locking & Deadlocks

6. **What is a deadlock?**
   - Two transactions waiting for each other's locks. DB detects and aborts one.

7. **How do you prevent deadlocks?**
   - Consistent lock order, short transactions, lock_timeout, retry logic.

8. **What is lock_timeout?**
   - Abort if lock cannot be acquired within the specified time.

## RBAC

9. **What is the difference between a role and a user?**
   - In PostgreSQL, they're the same. A "user" is a role with LOGIN. Roles can inherit other roles.

10. **How do you grant read-only access?**
    - Create role, GRANT SELECT on tables/schemas. REVOKE other privileges.

11. **What does REVOKE do?**
    - Removes a privilege from a role.

## Error Handling

12. **What is SQLSTATE 23505?**
    - Unique violation (duplicate key).

13. **What is SQLSTATE 40P01?**
    - Deadlock detected.

## Backup

14. **What is the difference between pg_dump and pg_basebackup?**
    - pg_dump: logical backup (SQL or custom format). pg_basebackup: physical copy of data directory for PITR.

15. **When would you use WAL archiving?**
    - For point-in-time recovery; RPO < 24 hours.
